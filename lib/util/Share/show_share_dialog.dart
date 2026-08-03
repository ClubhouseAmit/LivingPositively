import 'package:flutter/material.dart';
import 'package:mazilon/util/Share/LP_share_alert_dialog.dart';

Future<void> showShareDialog(context) {
  return showDialog(
    context: context,
    builder: (context) {
      return const LPShareAlertDialog();
    },
  );
}
