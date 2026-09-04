import 'package:flutter/material.dart';
import 'package:fluttericon/elusive_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/layout/directional_widgets.dart';
import 'package:mazilon/util/Share/personal_plan_download.dart';
import 'package:mazilon/util/Share/show_share_dialog.dart';
import 'package:mazilon/util/theme/app_theme.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class PersonalPlanSectionWidget extends StatelessWidget {
  final List<String> items;

  /// Callback invoked when "See all" or the empty state card is tapped.
  /// Also serves as the default fallback action for title taps when [onTitleTap] is omitted.
  final VoidCallback onSeeAll;

  /// Optional custom callback invoked when the section title or leading icon is tapped.
  /// When omitted and [enableTitleTap] is `true`, defaults to [onSeeAll].
  final VoidCallback? onTitleTap;

  /// Whether tapping the section title and leading icon is enabled.
  /// Defaults to `true`.
  final bool enableTitleTap;

  /// Optional [FileService] override for sharing and downloading Personal Plan exports.
  final FileService? fileService;

  const PersonalPlanSectionWidget({
    required this.items,
    required this.onSeeAll,
    this.onTitleTap,
    this.enableTitleTap = true,
    this.fileService,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final appLocale = AppLocalizations.of(context)!;
    final userInfo = Provider.of<UserInformation>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderWidget(
          title: appLocale.myPlan,
          titleKey: const Key('personalPlanHeaderTitle'),
          leadingIcon: Icons.assignment_outlined,
          subtitle: appLocale.myPlanSubTitle,
          onTitleTap: enableTitleTap ? (onTitleTap ?? onSeeAll) : null,
          actionWidget: PopupMenuButton<String>(
            key: const Key('personalPlanHeaderMenu'),
            icon: Icon(Icons.more_vert, color: AppColors.neutralDark),
            onSelected: (value) =>
                _handleMenuSelection(context, value, appLocale, userInfo),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'share',
                key: const Key('personalPlanHeaderShare'),
                child: Row(
                  children: [
                    Icon(
                      Elusive.share,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(appLocale.sharePlanTooltip),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'download',
                key: const Key('personalPlanHeaderDownload'),
                child: Row(
                  children: [
                    Icon(
                      Icons.download,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(appLocale.downloadPlanTooltip),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (items.isNotEmpty)
          _buildItemsList(context)
        else
          _buildEmptyState(context, appLocale, userInfo.gender),
        _buildSeeAllButton(context, appLocale, userInfo.gender),
      ],
    );
  }

  Future<void> _handleMenuSelection(
    BuildContext context,
    String value,
    AppLocalizations appLocale,
    UserInformation userInfo,
  ) async {
    if (value == 'share') {
      showShareDialog(context);
    } else if (value == 'download') {
      final appInfoProvider = Provider.of<AppInformation>(
        context,
        listen: false,
      );
      final service = fileService ?? GetIt.instance<FileService>();
      await downloadPersonalPlanFile(
        appLocale: appLocale,
        gender: userInfo.gender,
        username: userInfo.name,
        appInformation: appInfoProvider,
        userInformation: userInfo,
        fileService: service,
      );
    }
  }

  Widget _buildItemsList(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Container(
            width: 140,
            margin: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
            child: CardContainer(
              hasShadow: false,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              child: Text(
                items[index],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: const Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.start,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations appLocale,
    String gender,
  ) {
    return SizedBox(
      height: 45,
      child: CardContainer(
        hasShadow: false,
        onTap: onSeeAll,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        child: Row(
          children: [
            Icon(
              Icons.add_circle_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                appLocale.personalPlanPageHasFilled(gender),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeeAllButton(
    BuildContext context,
    AppLocalizations appLocale,
    String gender,
  ) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          end: AppSpacing.md,
          top: AppSpacing.lg,
        ),
        child: TextButton.icon(
          onPressed: onSeeAll,
          label: Text(
            appLocale.personalPlanPageAllPlan(gender),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          icon: Icon(
            Directionality.of(context) == TextDirection.rtl
                ? Icons.chevron_left
                : Icons.chevron_right,
            color: Theme.of(context).colorScheme.primary,
            size: 16,
          ),
          iconAlignment: IconAlignment.end,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }
}
