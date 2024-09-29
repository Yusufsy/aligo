import 'package:aligo/components/aligo_appbar.dart';
import 'package:aligo/components/aligo_drawer.dart';
import 'package:aligo/screens/inventory/inventory_list.dart';
import 'package:aligo/screens/report/charts.dart';
import 'package:aligo/screens/disbursement/disbursement_list.dart';
import 'package:aligo/screens/scan.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AligoAppbar(title: 'Dashboard'),
      drawer: const AligoDrawer(),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Options',
                style: TextStyle(fontFamily: "Roboto", fontSize: 25),
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Scan()),
                            );
                          },
                          icon: const Icon(Icons.barcode_reader),
                          iconSize: 50,
                          color: Colors.white,
                        ),
                      ),
                      const Text("Scanner", style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ChartsPage()),
                            );
                          },
                          icon: const Icon(Icons.bar_chart),
                          iconSize: 50,
                          color: Colors.white,
                        ),
                      ),
                      const Text("Reports", style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const InventoryList()),
                            );
                          },
                          icon: const Icon(Icons.all_inbox),
                          iconSize: 50,
                          color: Colors.white,
                        ),
                      ),
                      const Text("Inventory", style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const DisbursementList()),
                            );
                          },
                          icon: const Icon(Icons.nature_people),
                          iconSize: 50,
                          color: Colors.white,
                        ),
                      ),
                      const Text("Disburse", style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
