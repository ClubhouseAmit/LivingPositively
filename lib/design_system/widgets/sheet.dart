import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide Text;

import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/tokens/shadows.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';

const String _routeName = 'sheet';
const double _maxWidth = 500;
const double _maxHeightFactor = 0.85;

/// Pushes [sheet] up from the bottom. Pop with `Navigator.of(context).pop`.
///
/// A second [showSheet] from an open sheet replaces it — sheets do not stack.
Future<T?> showSheet<T>({
  required BuildContext context,
  required Widget sheet,
  bool barrierDismissible = true,
}) {
  final NavigatorState navigator = Navigator.of(context);
  final FocusNode? previous = FocusManager.instance.primaryFocus;
  final RawDialogRoute<T> route = RawDialogRoute<T>(
    barrierDismissible: barrierDismissible,
    barrierColor: AppColors.onSurface.withValues(alpha: 0.5),
    barrierLabel: 'Dismiss',
    pageBuilder: _page,
    transitionBuilder: _slide,
    transitionDuration: const Duration(milliseconds: 200),
    settings: RouteSettings(name: _routeName, arguments: sheet),
  );
  final bool replace = ModalRoute.of(context)?.settings.name == _routeName;
  final Future<T?> pushed = replace
      ? navigator.pushReplacement<T, void>(route)
      : navigator.push<T>(route);
  return pushed.whenComplete(() {
    if (previous != null && previous.canRequestFocus) {
      previous.requestFocus();
    }
  });
}

Widget _page(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
) {
  final Object? arguments = ModalRoute.of(context)?.settings.arguments;
  return arguments is Widget ? arguments : const SizedBox.shrink();
}

Widget _slide(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  if (MediaQuery.disableAnimationsOf(context)) {
    return child;
  }
  return SlideTransition(
    position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
    child: child,
  );
}

KeyEventResult _onEscape(BuildContext context, KeyEvent event) {
  if (event is! KeyDownEvent) {
    return KeyEventResult.ignored;
  }
  if (event.logicalKey != LogicalKeyboardKey.escape) {
    return KeyEventResult.ignored;
  }
  final ModalRoute<dynamic>? route = ModalRoute.of(context);
  if (route != null && route.barrierDismissible && route.navigator!.canPop()) {
    route.navigator!.pop();
  }
  return KeyEventResult.handled;
}

/// Bottom panel — top corners `AppRadii.card`, shadow `AppShadows.sheet`.
///
/// Height caps at 85% of the viewport and width at 500. The child supplies
/// any Cancel/Done actions.
class Sheet extends StatelessWidget {
  const Sheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return FocusScope(
      autofocus: true,
      child: Focus(
        onKeyEvent: (FocusNode _, KeyEvent event) =>
            _onEscape(context, event),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: size.height * _maxHeightFactor,
              maxWidth: _maxWidth,
            ),
            child: SizedBox(width: double.infinity, child: _chrome(context)),
          ),
        ),
      ),
    );
  }

  Widget _chrome(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.card),
        ),
        boxShadow: AppShadows.sheet,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(child: child),
        ),
      ),
    );
  }
}
