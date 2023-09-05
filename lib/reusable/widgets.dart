import 'package:flutter/material.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final Function onDelete;

  const DeleteConfirmationDialog({super.key, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Confirm Deletion',
        style: TextStyle(color: Color(0xFF941751)),
      ),
      content: const Text('Are you sure you want to delete this product?'),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF941751)),
          ),
        ),
        TextButton(
          onPressed: () {
            onDelete(); // Call the provided onDelete function
            Navigator.of(context).pop(); // Close the dialog
          },
          child: const Text(
            'Delete',
            style: TextStyle(color: Color(0xFF941751)),
          ),
        ),
      ],
    );
  }
}