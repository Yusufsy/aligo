import 'package:aligo/screens/home.dart';
import 'package:aligo/screens/login.dart';
import 'package:flutter/material.dart';

class AligoAppbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showLogout;

  const AligoAppbar({super.key, required this.title, this.showLogout = true});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MyHomePage()),
            );
          },
          icon: const Icon(Icons.home),
        ),
        IconButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
          icon: const Icon(Icons.logout),
        ),
      ],
      backgroundColor: Colors.black54,
    );
  }
}
