import 'package:flutter/material.dart';
import 'package:mazilon/util/Share/LP_share_alert_dialog.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';

/// Shows the Personal Plan sharing dialog.
///
/// When provided, [memoryService] overrides the persistence source used to
/// prepare and read the PDF data. When omitted, the dialog uses the
/// [UserInformation] service supplied by its provider.
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
