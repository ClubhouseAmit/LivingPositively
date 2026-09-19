import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LPAlertDialog extends StatefulWidget {
  final List<Widget> actions;
  final String title;

  const LPAlertDialog({super.key, required this.actions, required this.title});

  @override
  State<LPAlertDialog> createState() => _LPAlertDialogState();
}

class _LPAlertDialogState extends State<LPAlertDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(
        widget.title,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
      ),
      actions: [...widget.actions],
    );
  }
}
