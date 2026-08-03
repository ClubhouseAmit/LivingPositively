import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LPAlertDialog extends StatefulWidget {

  const LPAlertDialog({required this.actions, required this.title, super.key});
  final List<Widget> actions;
  final String title;

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
