import 'package:flutter/material.dart';

// A StatefulWidget that creates a customizable form container with optional password field visibility toggle
class FormContainer extends StatefulWidget { // Input type for the form field (e.g., text, number)

  const FormContainer({
    super.key,
    this.controller,
    this.isPasswordField,
    this.fieldKey,
    this.hintText,
    this.labelText,
    this.helperText,
    this.onSaved,
    this.validator,
    this.onFieldSubmitted,
    this.inputType,
  });
  final TextEditingController? controller; // Controller for managing text input
  final Key? fieldKey; // Key to uniquely identify the form field
  final bool? isPasswordField; // Determines if the field is a password field
  final String? hintText; // Hint text displayed inside the form field
  final String? labelText; // Label text displayed above the form field
  final String? helperText; // Helper text displayed below the form field
  final FormFieldSetter<String>?
  onSaved; // Callback when the form field is saved
  final FormFieldValidator<String>? validator; // Validator for the form field
  final ValueChanged<String>?
  onFieldSubmitted; // Callback when the form field is submitted
  final TextInputType?
  inputType;

  @override
  FormContainerState createState() => FormContainerState();
}

// The state class for FormContainer, managing the internal state (e.g., password visibility)
class FormContainerState extends State<FormContainer> {
  bool _obscureText =
      true; // Controls whether the password is hidden or visible

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 600),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
          alpha: .35,
        ), // Background color with opacity
        borderRadius: BorderRadius.circular(10), // Rounded corners
      ),
      child: TextFormField(
        style: TextStyle(
          fontWeight: FontWeight.normal,
          color: Theme.of(context).colorScheme.onSurface,
        ), // Text style for input
        controller: widget.controller, // Controller for managing text input
        keyboardType: widget.inputType, // Input type (e.g., text, number)
        key: widget.fieldKey, // Unique key for the form field
        obscureText: widget.isPasswordField == true && _obscureText, // Toggles visibility for password fields
        onSaved: widget.onSaved, // Callback when the field is saved
        validator: widget.validator, // Validator for the field
        onFieldSubmitted:
            widget.onFieldSubmitted, // Callback when the field is submitted
        decoration: InputDecoration(
          border: InputBorder.none, // No border for the input field
          filled: true,
          hintText: widget.hintText, // Hint text inside the field
          hintStyle: TextStyle(
            fontWeight: FontWeight.normal,
            color: Theme.of(context).colorScheme.outline,
          ), // Style for hint text
          suffixIcon: GestureDetector(
            onTap: () {
              setState(() {
                _obscureText =
                    !_obscureText; // Toggle the visibility of the password
              });
            },
            child: widget.isPasswordField == true
                ? Icon(
                    _obscureText
                        ? Icons.visibility_off
                        : Icons.visibility, // Icon based on visibility state
                    color: !_obscureText
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  )
                : const Text(''), // No icon for non-password fields
          ),
        ),
      ),
    );
  }
}
