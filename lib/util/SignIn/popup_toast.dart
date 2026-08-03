import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Function to display a toast message on the screen
void showToast({required String message}) {
  Fluttertoast.showToast(
    msg: message, // The message to display in the toast
    gravity: ToastGravity.BOTTOM, // The position of the toast (bottom of the screen)
    backgroundColor: Colors.blue, // Background color of the toast
    toastLength: Toast.LENGTH_SHORT, // Duration type (short duration)
  );
}
