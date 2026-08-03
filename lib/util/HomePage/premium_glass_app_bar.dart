import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../horizontal_logo.dart';
import '../theme/spacing.dart';

enum AppBarVariant {
  rootTab,
  detailScreen,
}

class PremiumGlassAppBar extends StatelessWidget {
  final AppBarVariant variant;
  final bool isHome;
  final VoidCallback? onBackPressed;
  final Widget? title;
  final String? titleText;
  final String? subtitleText;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final double blurStrength;
  final bool floating;
  final bool snap;
  final bool pinned;
  final bool centerTitle;
  final double? toolbarHeight;
  final bool showLogo;

  const PremiumGlassAppBar({
    super.key,
    required this.variant,
    this.isHome = false,
    this.onBackPressed,
    this.title,
    this.titleText,
    this.subtitleText,
    this.leading,
    this.actions,
    this.bottom,
    this.blurStrength = 10.0,
    this.floating = true,
    this.snap = true,
    this.pinned = false,
    this.centerTitle = false,
    this.toolbarHeight,
    this.showLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget? leadingWidget;
    if (variant == AppBarVariant.detailScreen) {
      final isIOS = Theme.of(context).platform == TargetPlatform.iOS ||
          Theme.of(context).platform == TargetPlatform.macOS;
      final backIcon = isIOS ? LucideIcons.chevronLeft : LucideIcons.arrowLeft;
      leadingWidget = leading ?? IconButton(
        key: const Key('appBarBackButton'),
        icon: Icon(backIcon, size: 28),
        color: colorScheme.onSurface,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: onBackPressed ?? () => Navigator.maybePop(context),
      );
    }

    final List<Widget>? activeActions = variant == AppBarVariant.rootTab
        ? (isHome ? actions : null)
        : actions;

    final double actualToolbarHeight = toolbarHeight ?? kToolbarHeight;

    return SliverAppBar(
      leading: leadingWidget,
      floating: floating,
      snap: snap,
      pinned: true, // Always pinned for header consistency
      toolbarHeight: actualToolbarHeight,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      title: titleText != null
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (variant == AppBarVariant.rootTab) ...[
                  const HorizontalLogo(height: 32),
                  if (titleText!.isNotEmpty) const SizedBox(width: 12),
                ],
                if (titleText!.isNotEmpty)
                  Expanded(
                    child: Text(
                      titleText!,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            )
          : title,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
          child: Container(
            color: colorScheme.surface.withValues(alpha: 0.85),
          ),
        ),
      ),
      actions: [
        if (showLogo && variant != AppBarVariant.detailScreen)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(child: HorizontalLogo(height: 32)),
          ),
        if (activeActions != null) ...activeActions,
      ],
      bottom: bottom,
    );
  }
}

