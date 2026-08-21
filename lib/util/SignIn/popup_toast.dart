import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Displays a brief toast message at the bottom of the screen.
///
/// Callers may `await` the returned future to observe platform completion,
/// or invoke it fire-and-forget when non-blocking visual feedback is desired.
///
/// Returns `true` if the toast platform channel successfully accepted the request,
/// `false` if rejected by the platform, or `null` if platform toast presentation
/// is unavailable, unsupported, or encounters a handled [PlatformException] or
/// [MissingPluginException]. Unexpected exceptions propagate to the caller.
Future<bool?> showToast({required String message}) async {
  try {
    return await Fluttertoast.showToast(
      msg: message, // The message to display in the toast
      gravity:
          ToastGravity.BOTTOM, // The position of the toast (bottom of the screen)
      backgroundColor: Colors.blue, // Background color of the toast
      timeInSecForIosWeb: 1, // Duration the toast is shown (1 second)
      toastLength: Toast.LENGTH_SHORT, // Duration type (short duration)
    );
  } on PlatformException {
    return null;
  } on MissingPluginException {
    return null;
  }
}
