import 'package:flutter/material.dart';

class Notificationicon extends StatelessWidget {
  final VoidCallback onPressed;

  const Notificationicon({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        Icons.notifications,
        size: 32,
      ),
      color: Colors.black,
    );
  }
}
