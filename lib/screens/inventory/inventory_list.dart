import 'dart:typed_data';

import 'package:aligo/components/aligo_appbar.dart';
import 'package:aligo/components/aligo_drawer.dart';
import 'package:aligo/helpers/inventory_helper.dart';
import 'package:aligo/models/inventory.dart';
import 'package:aligo/screens/inventory/update_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InventoryList extends StatefulWidget {
  const InventoryList({Key? key}) : super(key: key);

  @override
  State<InventoryList> createState() => _InventoryListState();
}

class _InventoryListState extends State<InventoryList> {
  TextStyle tableHead = const TextStyle(fontSize: 18.0);
  TextStyle summaryHead = const TextStyle(
    fontSize: 18.0,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  final formatCurrency = NumberFormat.currency(symbol: "");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AligoAppbar(title: 'Inventory'),
      drawer: const AligoDrawer(),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 15),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FutureBuilder(
                    future: InventoryDBHelper.instance.numProducts(),
                    builder:
                        (BuildContext context, AsyncSnapshot<String> snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return snapshot.data == null
                          ? const SizedBox()
                          : Container(
                              padding: const EdgeInsets.all(10),
                              color: Colors.blueAccent,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.all_inbox,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  const Text(
                                    "Products: ",
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.white),
                                  ),
                                  Text(
                                    snapshot.data!,
                                    style: summaryHead,
                                  ),
                                ],
                              ),
                            );
                    },
                  ),
                  FutureBuilder(
                    future: InventoryDBHelper.instance.sumQty(),
                    builder:
                        (BuildContext context, AsyncSnapshot<String> snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return snapshot.data == null
                          ? const SizedBox()
                          : Container(
                              padding: const EdgeInsets.all(10),
                              color: Colors.green,
                              child: Row(
                                children: [
                                  const Text(
                                    "Quantity: ",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  snapshot.data == 'null'
                                      ? Text(
                                          "0",
                                          style: summaryHead,
                                        )
                                      : Text(
                                          snapshot.data!,
                                          style: summaryHead,
                                        ),
                                ],
                              ),
                            );
                    },
                  ),
                  // FutureBuilder(
                  //   future: InventoryDBHelper.instance.sumPrice(),
                  //   builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                  //     if (!snapshot.hasData) {
                  //       return const Center(child: CircularProgressIndicator());
                  //     }
                  //     return snapshot.data == null
                  //         ? const SizedBox()
                  //         : Container(
                  //             padding: const EdgeInsets.all(10),
                  //             color: Colors.blueGrey,
                  //             child: Row(
                  //               children: [
                  //                 const Text(
                  //                   "Asset: ",
                  //                   style: TextStyle(fontSize: 18, fontFamily: 'Roboto', color: Colors.white),
                  //                 ),
                  //                 snapshot.data == 'null'
                  //                     ? Text(
                  //                         "0",
                  //                         style: summaryHead,
                  //                       )
                  //                     : Text(
                  //                         formatCurrency.format(int.parse(snapshot.data!)),
                  //                         style: summaryHead,
                  //                       ),
                  //               ],
                  //             ),
                  //           );
                  //   },
                  // ),
                ],
              ),
            ),
            FutureBuilder<List<Inventory>>(
              future: InventoryDBHelper.instance.getInventories(),
              builder: (BuildContext context,
                  AsyncSnapshot<List<Inventory>> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                List<DataRow> rows = snapshot.data!.isEmpty
                    ? []
                    : snapshot.data!.map((inventory) {
                        return DataRow(
                          cells: <DataCell>[
                            DataCell(
                              GestureDetector(
                                  onTap: () {
                                    expandImageDialog(context, inventory.image);
                                  },
                                  child: Image.memory(inventory.image)),
                            ),
                            DataCell(
                              Text(
                                  '${inventory.brand} ${inventory.variety} ${inventory.colour}'),
                            ),
                            DataCell(
                              Text(inventory.quantity),
                            ),
                            // DataCell(
                            //   Text(formatCurrency.format(int.parse(inventory.price))),
                            // ),
                            DataCell(
                              Text(inventory.dateAdded),
                            ),
                          ],
                          onSelectChanged: (selected) {
                            showDialog(
                              context: context,
                              builder: (context) => UpdateProduct(
                                inventory: inventory,
                              ),
                            );
                          },
                          onLongPress: () {
                            showAlertDialog(context, inventory.id!);
                          },
                        );
                      }).toList();
                return snapshot.data!.isEmpty
                    ? const Center(child: Text('No products yet.'))
                    : DataTable(
                        showCheckboxColumn: false,
                        columns: <DataColumn>[
                          DataColumn(label: Text('Image', style: tableHead)),
                          DataColumn(label: Text('Name', style: tableHead)),
                          DataColumn(label: Text('Qty', style: tableHead)),
                          // DataColumn(label: Text('Price', style: tableHead)),
                          DataColumn(label: Text('Date', style: tableHead)),
                        ],
                        rows: rows,
                      );
              },
            )
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  showAlertDialog(BuildContext context, int id) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: const Text("Cancel"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = TextButton(
      child: const Text(
        "Delete",
        style: TextStyle(color: Colors.red),
      ),
      onPressed: () async {
        await InventoryDBHelper.instance.remove(id).then((value) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Product delete')));
        });
        setState(() {});
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Confirm Delete"),
      content: SizedBox(
        height: MediaQuery.of(context).size.height * 0.18,
        child: const Column(
          children: <Widget>[
            Icon(
              Icons.warning_amber_outlined,
              size: 100,
              color: Colors.orange,
            ),
            Text("Are you sure you want to delete?"),
          ],
        ),
      ),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  expandImageDialog(BuildContext context, Uint8List imageBlob) {
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Product Image"),
      content: SizedBox(
          // height: MediaQuery.of(context).size.height * 0.18,
          child: Image.memory(imageBlob)),
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
