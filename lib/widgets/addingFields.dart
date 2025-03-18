import 'package:flutter/material.dart';

class Addingfields extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String label;
  final bool isDateField;

  const Addingfields({
    super.key,
    required this.controller,
    required this.validator,
    required this.label,
    this.isDateField = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        // Ensures text is always visible
        labelText: label,
        labelStyle: const TextStyle(
          color: Color.fromARGB(255, 0, 122, 255),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        prefixIcon: isDateField
            ? const Icon(Icons.calendar_today, color: Colors.blueAccent)
            : const Icon(Icons.edit, color: Color.fromARGB(255, 0, 122, 255)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 0, 122, 255),
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 0, 122, 255),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Colors.blueAccent,
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator,
      readOnly: isDateField,
      onTap: isDateField
          ? () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (pickedDate != null) {
                controller.text = "${pickedDate.toLocal()}".split(' ')[0];
              }
            }
          : null,
    );
  }
}
