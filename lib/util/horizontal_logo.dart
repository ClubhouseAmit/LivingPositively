import 'package:flutter/material.dart';

class HorizontalLogo extends StatelessWidget {
  final double height;
  final Color? color;

  const HorizontalLogo({
    super.key,
    this.height = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Cropped Leaf portion of the logo
        SizedBox(
          height: height,
          width: height * 1.1, // Approximate aspect ratio of the leaf
          child: ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 540,
                height: 465 * 0.6, // Crop the top 60% which contains the leaf
                child: Image.asset(
                  'assets/images/Logo.png',
                  fit: BoxFit.none,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        // The "LP" text horizontally
        Text(
          'LP',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: height * 0.75,
            fontWeight: FontWeight.w900,
            color: color ?? Theme.of(context).colorScheme.primary,
            letterSpacing: -1.0,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}
