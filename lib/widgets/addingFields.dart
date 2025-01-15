import 'package:flutter/material.dart';

class Addingfields extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String label;
  final bool isDateField; // Add a flag to distinguish date fields

  const Addingfields({
    super.key,
    required this.controller,
    required this.validator,
    required this.label,
    this.isDateField = false, // Default to false if not a date field
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      validator: validator,
      readOnly: isDateField,
      // Make field read-only if it's a date field
      onTap: isDateField
          ? () async {
              // Show the date picker if it's a date field
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (pickedDate != null) {
                // Format the date as yyyy-MM-dd and set it to the controller
                controller.text = "${pickedDate.toLocal()}".split(' ')[0];
              }
            }
          : null, // Do nothing if it's not a date field
    );
  }
}
