import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Function to display a toast message on the screen
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
  } catch (_) {
    return null;
  }
}
