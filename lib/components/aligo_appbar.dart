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
      leadingWidth: 100,
      leading: Row(
        children: [
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
      ),
      title: Text(title,
          textDirection: TextDirection.rtl,
          style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.black54,
    );
  }
}
