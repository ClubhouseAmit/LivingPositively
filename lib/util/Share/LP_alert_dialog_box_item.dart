import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LPAlertDialogBoxItem extends StatelessWidget {
  final Function onPressed;
  final String buttonText;
  final IconData icon;

  const LPAlertDialogBoxItem({
    super.key,
    required this.onPressed,
    required this.buttonText,
    required this.icon,
  });
  void press() async {
    await onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      margin: EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(width: 10.0),
          Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurface,
            size: 30.sp,
          ),
          Expanded(
            child: TextButton(
              onPressed: press,
              child: Text(
                buttonText,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
