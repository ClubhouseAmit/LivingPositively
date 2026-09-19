import 'package:flutter/widgets.dart' hide Text;

import 'package:mazilon/design_system/widgets/card.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';

/// Anchored overlay. Tap [child] to toggle; tap the barrier to close.
class Popover extends StatefulWidget {
  const Popover({
    super.key,
    required this.child,
    required this.overlay,
  });

  final Widget child;

  /// Receives a [close] callback so a selection can dismiss the overlay.
  final Widget Function(VoidCallback close) overlay;

  @override
  State<Popover> createState() => _PopoverState();
}

class _PopoverState extends State<Popover> {
  OverlayEntry? _entry;

  @override
  void dispose() {
    _remove();
    super.dispose();
  }

  void _remove() {
    _entry?.remove();
    _entry = null;
  }

  void _toggle() {
    if (_entry != null) {
      _remove();
      return;
    }
    final RenderBox box = context.findRenderObject()! as RenderBox;
    final OverlayState overlay = Overlay.of(context);
    final RenderBox overlayBox =
        overlay.context.findRenderObject()! as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    final Size size = box.size;
    _entry = OverlayEntry(
      builder: (BuildContext context) {
        return _Layer(
          left: offset.dx,
          top: offset.dy + size.height + AppSpacing.xs,
          width: size.width,
          onDismiss: _remove,
          child: widget.overlay(_remove),
        );
      },
    );
    overlay.insert(_entry!);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: _toggle, child: widget.child);
  }
}

class _Layer extends StatelessWidget {
  const _Layer({
    required this.left,
    required this.top,
    required this.width,
    required this.onDismiss,
    required this.child,
  });

  final double left;
  final double top;
  final double width;
  final VoidCallback onDismiss;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
          ),
        ),
        Positioned(
          left: left,
          top: top,
          width: width,
          child: Card(child: child),
        ),
      ],
    );
  }
}
