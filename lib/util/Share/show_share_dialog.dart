import 'package:flutter/material.dart';
import 'package:mazilon/util/Share/LP_share_alert_dialog.dart';
import 'package:mazilon/util/persistent_memory_service.dart';

/// Shows the Personal Plan sharing dialog using an optional persistence override.
Future<void> showShareDialog(
  BuildContext context, {
  PersistentMemoryService? memoryService,
}) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return LPShareAlertDialog(memoryService: memoryService);
    },
  );
}
