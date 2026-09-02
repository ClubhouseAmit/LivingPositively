import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/layout/directional_widgets.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

/// Reusable section widget for home page list sections (e.g., Gratitude and Virtues).
class DashedListWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final String iconAsset;
  final List<String> items;
  final List<String> suggestions;
  final int totalCount;
  final VoidCallback onAddItem;
  final VoidCallback? onAddNew;
  final void Function(int index)? onEditItem;
  final void Function(int index)? onRemoveItem;
  final void Function(String suggestion)? onAddSuggestion;

  const DashedListWidget({
    required this.title,
    required this.subtitle,
    required this.iconAsset,
    required this.items,
    required this.suggestions,
    required this.totalCount,
    required this.onAddItem,
    this.onAddNew,
    this.onEditItem,
    this.onRemoveItem,
    this.onAddSuggestion,
    super.key,
  });

  @override
  State<DashedListWidget> createState() => _DashedListWidgetState();
}

class _DashedListWidgetState extends State<DashedListWidget>
    with TickerProviderStateMixin {
  // Suggestion slots currently shown
  List<String> _displayedSuggestions = [];

  // Which slot is collapsing right now (null = none)
  int? _collapsingIndex;

  // True while the promoted item at position 0 is fading in
  bool _showFadeIn = false;

  // Controller 1: drives collapse (opacity + height of departing suggestion)
  late final AnimationController _collapseController;
  late final Animation<double> _collapseOpacity;
  late final Animation<double> _collapseHeight;

  // Controller 2: drives fade-in + slide-in of the newly promoted PillItemRow
  late final AnimationController _fadeInController;
  late final Animation<double> _fadeInValue; // 0 → 1

  static const int _kMaxSuggestions = 3;
  static const double _kPillHeight = 44.0;
  static const Duration _kCollapseDuration = Duration(milliseconds: 400);
  static const Duration _kFadeInDuration = Duration(milliseconds: 480);

  @override
  void initState() {
    super.initState();

    _collapseController = AnimationController(
      vsync: this,
      duration: _kCollapseDuration,
    );
    _collapseOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _collapseController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeIn),
      ),
    );
    _collapseHeight = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _collapseController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _fadeInController = AnimationController(
      vsync: this,
      duration: _kFadeInDuration,
    );
    _fadeInValue = CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _collapseController.dispose();
    _fadeInController.dispose();
    super.dispose();
  }

  // ── Pool management ──────────────────────────────────────────────────────────

  void _syncDisplayedSuggestions(List<String> available) {
    final stillValid = _displayedSuggestions
        .where((s) => available.contains(s))
        .toList();
    for (final s in available) {
      if (stillValid.length >= _kMaxSuggestions) break;
      if (!stillValid.contains(s)) stillValid.add(s);
    }
    _displayedSuggestions = stillValid.take(_kMaxSuggestions).toList();
  }

  void _refreshSuggestion(int index, List<String> available) {
    if (available.length <= _displayedSuggestions.length) return;
    final current = _displayedSuggestions[index];
    int pos = available.indexOf(current);
    if (pos == -1) pos = 0;
    for (int step = 1; step <= available.length; step++) {
      final candidate = available[(pos + step) % available.length];
      if (!_displayedSuggestions.contains(candidate)) {
        setState(() {
          _displayedSuggestions[index] = candidate;
        });
        return;
      }
    }
  }

  // ── Promotion ────────────────────────────────────────────────────────────────

  Future<void> _promoteSuggestion(
    int slotIndex,
    String suggestion,
    List<String> available,
  ) async {
    if (_collapsingIndex != null) return; // guard: one animation at a time

    setState(() {
      _collapsingIndex = slotIndex;
    });

    await _collapseController.forward();
    if (!mounted) return;
    _collapseController.reset();

    // Commit the data update (parent rebuilds, new item appears at #1)
    widget.onAddSuggestion?.call(suggestion);

    // ONE setState: clear animation state + backfill + arm fade-in flag
    setState(() {
      _showFadeIn = true;
      if (slotIndex < _displayedSuggestions.length) {
        _displayedSuggestions.removeAt(slotIndex);
      }
      final remaining = available
          .where((s) => s != suggestion && !_displayedSuggestions.contains(s))
          .toList();
      if (remaining.isNotEmpty) _displayedSuggestions.add(remaining.first);
      _collapsingIndex = null;
    });

    // Drive the fade-in independently of Provider rebuild timing
    await _fadeInController.forward(from: 0.0);
    if (!mounted) return;
    _fadeInController.reset();
    setState(() {
      _showFadeIn = false;
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appLocale = AppLocalizations.of(context)!;
    final userInfo = Provider.of<UserInformation>(context);

    final availableSuggestions = widget.suggestions
        .where((s) => !widget.items.contains(s))
        .toList();

    // Guard: don't resync the suggestion list while a collapse is in flight —
    // premature removal mid-animation causes layout jumps
    if (_collapsingIndex == null) {
      _syncDisplayedSuggestions(availableSuggestions);
    }

    // Callers pass items newest-first; take the first 3
    final displayedItems = widget.items.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              key: const Key('dashedListTitleTapTarget'),
              onTap: widget.onAddItem,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 36),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      widget.iconAsset,
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.onSurface,
                        BlendMode.srcIn,
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.onSurface,
                size: 22,
              ),
              onPressed: widget.onAddNew ?? widget.onAddItem,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          widget.subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.outline,
            fontSize: 14,
          ),
        ),
        SizedBox(height: AppSpacing.sm + 4),

        // ── Selected items (newest-first, up to 3) ───────────────────────────
        if (displayedItems.isNotEmpty)
          ...List.generate(displayedItems.length, (index) {
            Widget row = PillItemRow(
              index: index,
              text: displayedItems[index],
              onEdit: widget.onEditItem != null
                  ? () => widget.onEditItem!(index)
                  : widget.onAddNew ?? widget.onAddItem,
              onRemove: widget.onRemoveItem != null
                  ? () => widget.onRemoveItem!(index)
                  : null,
            );

            // Wrap position 0 in a fade+slide-in while promotion is animating.
            // AnimatedBuilder is driven by _fadeInController — fully vsync-synced,
            // no dependency on string matching or Provider rebuild ordering.
            if (_showFadeIn && index == 0) {
              row = AnimatedBuilder(
                animation: _fadeInValue,
                builder: (_, child) => Opacity(
                  opacity: _fadeInValue.value,
                  child: Transform.translate(
                    // Slide in from 8px above — feels like it enters from the suggestion area
                    offset: Offset(0, (1.0 - _fadeInValue.value) * -8.0),
                    child: child,
                  ),
                ),
                child: row,
              );
            }

            return row;
          }),

        // ── Suggested section (always up to 3) ───────────────────────────────
        if (_displayedSuggestions.isNotEmpty) ...[
          SizedBox(height: AppSpacing.xs),
          ...List.generate(_displayedSuggestions.length, (i) {
            final suggestion = _displayedSuggestions[i];
            final isCollapsing = _collapsingIndex == i;

            Widget pill = DashedPillAddSlot(
              placeholder: suggestion,
              onTap: () =>
                  _promoteSuggestion(i, suggestion, availableSuggestions),
              onRefresh:
                  availableSuggestions.length > _displayedSuggestions.length
                  ? () => _refreshSuggestion(i, availableSuggestions)
                  : null,
            );

            if (isCollapsing) {
              // AnimatedBuilder on a single controller — opacity + height
              // in perfect sync, no intermediate setState flicker
              return AnimatedBuilder(
                animation: _collapseController,
                builder: (_, child) => SizedBox(
                  height: _collapseHeight.value * _kPillHeight,
                  child: Opacity(opacity: _collapseOpacity.value, child: child),
                ),
                child: pill,
              );
            }

            return pill;
          }),
        ] else if (displayedItems.isEmpty) ...[
          DashedPillAddSlot(
            placeholder: appLocale.addItemTooltip,
            onTap: widget.onAddNew ?? widget.onAddItem,
          ),
        ],

        SizedBox(height: AppSpacing.sm + 4),

        // ── See all (N) → footer ─────────────────────────────────────────────
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: widget.onAddItem,
            label: Text(
              '${appLocale.showAll(userInfo.gender)} (${widget.totalCount})',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            icon: Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.primary,
              size: 16,
            ),
            iconAlignment: IconAlignment.end,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }
}
