import 'package:flutter/material.dart';
import 'package:mazilon/util/theme/spacing.dart';

class PageLayoutWrapper extends StatelessWidget {
  final Widget? sliverAppBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  const PageLayoutWrapper({
    super.key,
    this.sliverAppBar,
    required this.body,
    this.bottomNavigationBar,
    this.padding = const EdgeInsets.symmetric(horizontal: Spacing.md),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest,
      extendBodyBehindAppBar: true, // Crucial for glassmorphism
      bottomNavigationBar: bottomNavigationBar,
      body: CustomScrollView(
        slivers: [
          if (sliverAppBar != null) sliverAppBar!,
          SliverPadding(
            padding: padding,
            sliver: SliverToBoxAdapter(
              child: body,
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.only(bottom: Spacing.bottomPadding),
          ),
        ],
      ),
    );
  }
}
