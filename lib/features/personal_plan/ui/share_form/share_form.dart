import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get_it/get_it.dart';

import 'package:mazilon/util/async/file_service.dart';
import 'package:mazilon/features/personal_plan/ui/form_page_template/form_page_template.dart';
import 'package:mazilon/features/personal_plan/ui/custom_category/card.dart';
import 'package:mazilon/features/personal_plan/ui/custom_category/editor.dart';
import 'package:mazilon/features/personal_plan/ui/custom_category/options.dart';
import 'package:mazilon/features/wizard/ui/wizard_step.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/features/shell/ui/persistence_retry_snack_bar.dart';
import 'package:mazilon/util/async/logger_service.dart';
import 'package:mazilon/util/async/persistent_memory_service.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/features/shell/ui/styles.dart';

import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/features/personal_plan/ui/share/personal_plan_download.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/features/personal_plan/ui/share/show_share_dialog.dart';
import 'package:mazilon/features/personal_plan/ui/retrieveInformation.dart';
import 'package:mazilon/features/personal_plan/data/dreams_and_goals_models.dart';
import 'package:mazilon/features/personal_plan/ui/my_plan_section.dart';

part 'categories.dart';
part 'dreams.dart';
part 'export.dart';

const double _shareImageGap = 30;
const double _exportButtonPad = 10;

/// The result of preparing a Share action that depends on Dreams and Goals.
///
/// The variants make each preparation path explicit so callers cannot run an
/// action for a newly added, unhandled preparation state.
class ShareForm extends WizardStep {
  final Function prev;
  final FutureOr<void> Function(BuildContext context) submit;
  final PersistentMemoryService? memoryService;
  final void Function(int step)? goToStep;
  final int? shareStepIndex;

  const ShareForm({
    required super.key,
    required this.prev,
    required this.submit,
    this.memoryService,
    this.goToStep,
    this.shareStepIndex,
  });

  @override
  String primaryActionLabel(BuildContext context) => AppLocalizations.of(
    context,
  )!.sharePageFinishButton(Provider.of<UserInformation>(context).gender);

  @override
  WizardStepState<ShareForm> createState() => _ShareFormState();
}

class _ShareFormState extends WizardStepState<ShareForm>
    with _ShareFormCategories, _ShareFormDreams, _ShareFormExport {
  void setHasFilled() {
    unawaited(_setHasFilled());
  }

  Future<void> _setHasFilled() async {
    final UserInformation userInformation = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    try {
      await userInformation.persistHasFilled();
    } catch (error, stackTrace) {
      try {
        await GetIt.instance<IncidentLoggerService>().captureLog(
          error,
          stackTrace: stackTrace,
        );
      } catch (_) {
        // The storage service already attempted its own logging. This
        // best-effort initialization write must not escape as an async error.
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fileService = GetIt.instance<FileService>();
    setHasFilled();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _userInformation?.loadCustomCategories(
          memoryService: widget.memoryService,
        );
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Future<void> onPrimaryAction() async {
    final UserInformation userInformation = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    await _runDreamsAndGoalsAction(
      userInformation,
      () => widget.submit(context),
    );
  }

  @override
  Future<void> persistBeforeExit() async {
    final UserInformation userInformation = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    await Future.wait<void>([
      _persistInlineDreamsAndGoals(userInformation),
      userInformation.pendingCustomCategoriesSave,
    ]);
  }

  @override
  Future<void> retryPersistBeforeExit() async {
    final UserInformation userInformation = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    await Future.wait<void>([
      _persistInlineDreamsAndGoals(userInformation, retry: true),
      userInformation.retryCustomCategoriesSave(
        userInformation.customCategoriesSaveRevision,
        memoryService: widget.memoryService,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final appInfoProvider = Provider.of<AppInformation>(context, listen: true);
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );
    final gender = userInfoProvider.gender;

    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            Text(
              appLocale.sharePageHeader(gender),
              style: TextStyle(
                fontSize: 30.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              appLocale.sharePageSubTitle(gender),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 16.sp,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            myImage('assets/images/FormSubmit.png', context, 0.6, 0.25),
            SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.8,
              child: Text(
                appLocale.sharePageMidTitle(gender),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 16.sp,
                ),
              ),
            ),
            const SizedBox(height: _shareImageGap),
            _shareExportButtons(
              context,
              userInfoProvider,
              appInfoProvider,
              gender,
            ),
            ..._buildPlanSummary(context, userInfoProvider, gender),
            buildDreamsAndGoalsSection(context, gender),
            buildCustomCategoriesSection(context, gender),
          ],
        ),
      ),
    );
  }
}
