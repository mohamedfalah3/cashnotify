import 'package:flutter/material.dart';

class Editdeletebutton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icons;
  final Color color;
  final String name;

  const Editdeletebutton(
      {Key? key,
      required this.onPressed,
      required this.icons,
      required this.color,
      required this.name})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icons, color: color),
      tooltip: name,
      onPressed: onPressed,
    );
  }
}
