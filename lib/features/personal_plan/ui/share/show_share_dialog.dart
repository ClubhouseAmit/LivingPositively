import 'package:flutter/material.dart';
import 'package:mazilon/features/personal_plan/ui/share/LP_share_alert_dialog.dart';
import 'package:mazilon/util/async/persistent_memory_service.dart';

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
