import 'package:flutter/material.dart';

class AllergenChip extends StatelessWidget {
  final String label;
  final VoidCallback onDelete;
  final Color color;
  
  const AllergenChip({
    super.key,
    required this.label,
    required this.onDelete,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
      deleteIcon: const Icon(
        Icons.close,
        size: 18,
        color: Colors.white,
      ),
      onDeleted: onDelete,
    );
  }
}
