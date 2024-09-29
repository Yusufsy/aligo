import 'dart:typed_data';

import 'package:aligo/components/aligo_appbar.dart';
import 'package:aligo/components/aligo_drawer.dart';
import 'package:aligo/helpers/inventory_helper.dart';
import 'package:aligo/models/inventory.dart';
import 'package:aligo/screens/disbursement/add_disbursement_dialog.dart';
import 'package:aligo/screens/inventory/add_product.dart';
import 'package:aligo/screens/scan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddDisbursement extends StatefulWidget {
  const AddDisbursement({Key? key}) : super(key: key);

  @override
  State<AddDisbursement> createState() => _AddDisbursementState();
}

class _AddDisbursementState extends State<AddDisbursement> {
  final formatCurrency = NumberFormat.currency(symbol: "");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AligoAppbar(title: 'Add Disbursement'),
      drawer: const AligoDrawer(),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(
                height: 5,
              ),
              Container(
                height: 300,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: FutureBuilder(
                  future: InventoryDBHelper.instance.getInventories(),
                  builder: (BuildContext context,
                      AsyncSnapshot<List<Inventory>> snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return snapshot.data!.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'No stock to select.',
                                style: TextStyle(fontSize: 20),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddProduct(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Add product",
                                  style: TextStyle(fontSize: 20),
                                ),
                              )
                            ],
                          )
                        : GridView(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2),
                            children: snapshot.data!.map((inventory) {
                              return GestureDetector(
                                onTap: () async {
                                  await showDialog(
                                    context: context,
                                    builder: (context) {
                                      return StatefulBuilder(
                                          builder: (context, setState) {
                                        return AddDisbursementDialog(
                                            inventory: inventory);
                                      });
                                    },
                                  );
                                },
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Expanded(
                                          child: Center(
                                            child: Image.memory(
                                              inventory.image,
                                            ),
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Text(
                                            //   formatCurrency.format(int.parse(inventory.price)),
                                            //   style: const TextStyle(
                                            //     fontSize: 15,
                                            //     color: Colors.green,
                                            //     fontWeight: FontWeight.bold,
                                            //   ),
                                            // ),
                                            Text(
                                                "${inventory.brand} ${inventory.variety}"),
                                            Text(
                                              "x${inventory.quantity}",
                                              style: const TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList());
                  },
                ),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Scan()),
        ),
        child: const Icon(Icons.barcode_reader),
      ),
    );
  }

  expandImageDialog(BuildContext context, Uint8List imageBlob) {
    AlertDialog alert = AlertDialog(
      title: const Text("Product Image"),
      content: SizedBox(child: Image.memory(imageBlob)),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
