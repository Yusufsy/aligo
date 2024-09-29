import 'package:aligo/screens/home.dart';
import 'package:aligo/screens/inventory/add_product.dart';
import 'package:aligo/screens/inventory/inventory_list.dart';
import 'package:aligo/screens/login.dart';
import 'package:aligo/screens/disbursement/add_disbursement.dart';
import 'package:aligo/screens/disbursement/disbursement_list.dart';
import 'package:flutter/material.dart';

class AligoDrawer extends StatelessWidget {
  const AligoDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const SizedBox(
            height: 88,
            child: DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black54,
              ),
              child: Text(
                'MOH Disburse',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Disbursement'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const DisbursementList()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_shopping_cart),
            title: const Text('Add Disbursement'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddDisbursement()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.all_inbox),
            title: const Text('Inventory'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const InventoryList()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.post_add),
            title: const Text('Add Product'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AddProduct()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MyHomePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Reports'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MyHomePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
