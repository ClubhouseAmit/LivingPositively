import 'package:flutter/material.dart';
import 'package:mazilon/pages/onboarding_page.dart';

// Function to handle the callback after an operation (e.g., sign-in or sign-up)
void callback(result, widget, context) {
  // If the result is successful (result is true)
  if (result) {
    // Navigate to the InitialFormProgressIndicator page, removing all previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => InitialFormProgressIndicator(
          phonePageData:
              widget.phonePageData, // Pass phone page data to the next page
          changeLocale: widget
              .changeLocale, // Pass the changeLocale function to the next page
        ),
      ),
      (route) => false, // Remove all previous routes from the stack
    );
  }
}
