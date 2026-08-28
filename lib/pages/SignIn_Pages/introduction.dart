import 'package:flutter/material.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/layout/directional_widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Introduction widget serves as an initial loading screen or introduction page.
class Introduction extends StatefulWidget {
  final Widget?
  child; // Optional child widget that can be passed to this screen
  const Introduction({super.key, this.child});

  @override
  State<Introduction> createState() => _IntroductionState();
}

class _IntroductionState extends LPExtendedState<Introduction>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: colorScheme.surface),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              // Center Logo (LP Butterfly)
              Center(
                child: LpLogo(
                  width: 180.w,
                  fit: BoxFit.contain,
                ),
              ),
              const Spacer(flex: 2),
              if (widget.child != null)
                widget.child!
              else ...[
                // Custom Gradient Progress Bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 48.w),
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Container(
                        height: 10.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(5.r),
                          border: Border.all(
                            color: colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            FractionallySizedBox(
                              widthFactor: _animation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5.r),
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primary.withValues(alpha: 0.2),
                                      colorScheme.surface,
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Localized Loading Text
                Text(
                  appLocale.asyncLoadingLabel,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.normal,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
