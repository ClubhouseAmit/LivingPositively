import 'package:flutter/widgets.dart' hide Text;

import 'package:mazilon/design_system/widgets/text.dart';
import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';

/// Hover / long-press tip. Also sets `Semantics.tooltip`.
class Tooltip extends StatefulWidget {
  const Tooltip({super.key, required this.message, required this.child});

  final String message;
  final Widget child;

  @override
  State<Tooltip> createState() => _TooltipState();
}

class _TooltipState extends State<Tooltip> {
  OverlayEntry? _entry;

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  void _hide() {
    _entry?.remove();
    _entry = null;
  }

  void _show() {
    if (_entry != null || !mounted) {
      return;
    }
    final RenderBox box = context.findRenderObject()! as RenderBox;
    final OverlayState overlay = Overlay.of(context);
    final RenderBox overlayBox =
        overlay.context.findRenderObject()! as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    _entry = OverlayEntry(
      builder: (BuildContext context) {
        return _Tip(
          left: offset.dx,
          top: offset.dy - AppSpacing.xxxl,
          message: widget.message,
        );
      },
    );
    overlay.insert(_entry!);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      tooltip: widget.message,
      child: MouseRegion(
        onEnter: (_) => _show(),
        onExit: (_) => _hide(),
        child: GestureDetector(
          onLongPress: _show,
          onLongPressEnd: (_) => _hide(),
          child: widget.child,
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({
    required this.left,
    required this.top,
    required this.message,
  });

  final double left;
  final double top;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.onSurface,
            borderRadius: BorderRadius.circular(AppRadii.input),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              message,
              style: AppTextStyle.labelSmall,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
