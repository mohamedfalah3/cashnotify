import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final String id;
  final bool isEditing;
  final VoidCallback onSave;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ActionButtons({
    super.key,
    required this.id,
    required this.isEditing,
    required this.onSave,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(isEditing ? Icons.save : Icons.edit),
          onPressed: isEditing ? onSave : onEdit,
        ),
        if (!isEditing)
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
      ],
    );
  }
}
