import 'package:flutter/material.dart';

class AligoAppbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const AligoAppbar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.black54,
    );
  }
}
