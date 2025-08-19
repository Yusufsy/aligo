import 'package:aligo/screens/custody/custody_list_screen.dart';
import 'package:aligo/screens/home.dart';
import 'package:aligo/screens/inventory/add_product.dart';
import 'package:aligo/screens/inventory/inventory_list.dart';
import 'package:aligo/screens/login.dart';
import 'package:aligo/screens/disbursement/add_disbursement.dart';
import 'package:aligo/screens/disbursement/disbursement_list.dart';
import 'package:aligo/screens/report/charts.dart';
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
            trailing: const Icon(Icons.list_alt),
            title: const Text('تسليم مواد', textDirection: TextDirection.rtl),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const DisbursementList()),
              );
            },
          ),
          ListTile(
            trailing: const Icon(Icons.add_shopping_cart),
            title: const Text('إضافة الصرف', textDirection: TextDirection.rtl),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddDisbursement()),
              );
            },
          ),
          ListTile(
            trailing: const Icon(Icons.all_inbox),
            title: const Text('المخزون', textDirection: TextDirection.rtl),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const InventoryList()),
              );
            },
          ),
          ListTile(
            trailing: const Icon(Icons.post_add),
            title:
                const Text('إضافة المخزون', textDirection: TextDirection.rtl),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AddProduct()),
              );
            },
          ),
          ListTile(
            trailing: const Icon(Icons.people),
            title: const Text('جرد', textDirection: TextDirection.rtl),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const CustodyListScreen()),
              );
            },
          ),
          ListTile(
            trailing: const Icon(Icons.home),
            title: const Text('لوحة التحكم', textDirection: TextDirection.rtl),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MyHomePage()),
              );
            },
          ),
          // ListTile(
          //   leading: const Icon(Icons.bar_chart),
          //   title: const Text('Reports'),
          //   onTap: () {
          //     Navigator.pushReplacement(
          //       context,
          //       MaterialPageRoute(builder: (context) => const ChartsPage()),
          //     );
          //   },
          // ),
          ListTile(
            trailing: const Icon(Icons.logout),
            title: const Text('تسجيل الخروج', textDirection: TextDirection.rtl),
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
