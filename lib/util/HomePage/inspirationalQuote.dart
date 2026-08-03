import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/theme/app_theme.dart';
import 'package:mazilon/util/theme/spacing.dart';

// =============================================================================
// AffirmationCard (Variant B: Left-Accent Layout)
// - No background, no box container.
// - Left colored border/rule as the only visual separator.
// - Controls are moved to a dedicated row below the text with expanded hitboxes 
//   to prevent accidental taps.
// =============================================================================

class AffirmationCard extends StatefulWidget {
  const AffirmationCard({required this.quotes, super.key});
  final List<String> quotes;
  @override
  _AffirmationCardState createState() => _AffirmationCardState();
}

class _AffirmationCardState extends LPExtendedState<AffirmationCard>
    with SingleTickerProviderStateMixin {
  bool showCard = true;
  int _currentIndex = 0;
  int _displayIndex = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final AnalyticsService _analytics = GetIt.instance<AnalyticsService>();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    if (widget.quotes.isNotEmpty) {
      _currentIndex = Random().nextInt(widget.quotes.length);
      _displayIndex = _currentIndex;
    }
    _fadeController.value = 1.0;
  }

  @override
  void didUpdateWidget(AffirmationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quotes.isEmpty) return;
    if (oldWidget.quotes != widget.quotes || _currentIndex >= widget.quotes.length) {
      _currentIndex = Random().nextInt(widget.quotes.length);
      _displayIndex = _currentIndex;
      _fadeController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _dismiss() {
    setState(() => showCard = false);
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(appLocale.quoteDismissedMessage),
        action: SnackBarAction(
          label: appLocale.quoteUndoAction,
          onPressed: () {
            if (!mounted) return;
            setState(() => showCard = true);
          },
        ),
      ),
    );
  }

  Future<void> _nextAffirmation() async {
    if (widget.quotes.length < 2) return;
    await _fadeController.reverse();
    if (!mounted) return;

    final prevIndex = _currentIndex;
    int nextIndex;
    do {
      nextIndex = Random().nextInt(widget.quotes.length);
    } while (nextIndex == prevIndex && widget.quotes.length > 1);

    setState(() {
      _currentIndex = nextIndex;
      _displayIndex = nextIndex;
    });

    unawaited(_analytics.trackEvent('Inspirational Quotes Refreshed', {
      'Old Quote': widget.quotes[prevIndex],
      'New Quote': widget.quotes[nextIndex],
    }));

    if (mounted) await _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quotes.isEmpty || !showCard) return const SizedBox.shrink();
    
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Padding(
      // Outer padding matches page sections
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Container(
        decoration: BoxDecoration(
          // Thin accent border on the starting edge only
          border: Border(
            left: isRtl
                ? BorderSide.none
                : BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 2),
            right: isRtl
                ? BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 2)
                : BorderSide.none,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14), // Offset content from border
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Hug content
          children: [
            Row(
              children: [
                const Icon(LucideIcons.leaf, size: 14, color: AppColors.affirmationMuted),
                const SizedBox(width: 8),
                Text(
                  appLocale.affirmationCardLabel.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.9,
                    color: AppColors.affirmationMuted,
                    height: 1.0,
                  ),
                ),
                const Spacer(),
                // Controls moved to header row
                if (widget.quotes.length > 1)
                  Semantics(
                    button: true,
                    child: Tooltip(
                      message: appLocale.nextAffirmationTooltip,
                      child: GestureDetector(
                        onTap: _nextAffirmation,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Icon(LucideIcons.chevronRight, size: 16, color: AppColors.affirmationMuted),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                Semantics(
                  button: true,
                  child: Tooltip(
                    message: appLocale.dismissQuoteTooltip,
                    child: GestureDetector(
                      onTap: _dismiss,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Icon(Icons.close, size: 16, color: AppColors.affirmationMuted),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                widget.quotes[_displayIndex],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                  height: 1.55,
                  color: AppColors.affirmationForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
