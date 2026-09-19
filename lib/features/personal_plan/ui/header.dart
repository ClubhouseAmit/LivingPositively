part of '../../../pages/personal_plan_editor_page.dart';

const double _appBarHeight = 70;

mixin _PlanWizardNav on LPExtendedState<FormProgressIndicator> {
  List<WizardStep> get steps;
  int get currentStep;
  bool get _headerNavigationInFlight;
  set _headerNavigationInFlight(bool value);

  Future<void> _persistThenNavigate(
    BuildContext context,
    VoidCallback navigate, {
    bool retry = false,
  }) async {
    if (_headerNavigationInFlight) {
      return;
    }
    _headerNavigationInFlight = true;
    try {
      final WizardStepState? stepState =
          steps[currentStep].stepKey.currentState;
      if (retry) {
        await stepState?.retryPersistBeforeExit();
      } else {
        await stepState?.persistBeforeExit();
      }
      if (mounted) {
        navigate();
      }
    } catch (error, stackTrace) {
      if (retry) {
        await _captureHeaderRetryFailure(error, stackTrace);
      }
      if (mounted) {
        _showHeaderPersistenceFailure(
          () => _persistThenNavigate(context, navigate, retry: true),
        );
      }
    } finally {
      _headerNavigationInFlight = false;
    }
  }

  void _showHeaderPersistenceFailure(Future<void> Function() retry) {
    showPersistenceRetrySnackBar(context, retry);
  }

  Future<void> _captureHeaderRetryFailure(
    Object error,
    StackTrace stackTrace,
  ) async {
    try {
      await GetIt.instance<IncidentLoggerService>().captureLog(
        error,
        stackTrace: stackTrace,
      );
    } catch (_) {
      // Logging is best effort; it must not hide the retry affordance.
    }
  }
}

class _PlanWizardHeader extends StatelessWidget implements PreferredSizeWidget {
  const _PlanWizardHeader({
    required this.stepCount,
    required this.currentStep,
    required this.gender,
    required this.onBack,
    required this.onQuit,
  });

  final int stepCount;
  final int currentStep;
  final String gender;
  final VoidCallback onBack;
  final VoidCallback onQuit;

  @override
  Size get preferredSize => const Size.fromHeight(_appBarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _screenInset),
            child: Stack(
              alignment: Alignment.center,
              children: [
                StepDotsIndicator(
                  context,
                  stepCount: stepCount,
                  currentStep: currentStep,
                ),
                if (currentStep > 0)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.arrow_back_ios, size: 20),
                      onPressed: onBack,
                    ),
                  ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: headerSideControlMaxWidth(
                        MediaQuery.sizeOf(context).width,
                        stepCount,
                      ),
                    ),
                    child: InkWell(
                      key: const Key('plan-save-and-quit'),
                      onTap: onQuit,
                      child: myAutoSizedText(
                        AppLocalizations.of(
                          context,
                        )!.saveAndQuitButton(gender),
                        TextStyle(
                          fontWeight: AppFontWeight.medium,
                          fontSize: 16.sp,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        null,
                        16,
                        1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
