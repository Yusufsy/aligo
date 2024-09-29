import 'dart:typed_data';

import 'package:aligo/components/aligo_appbar.dart';
import 'package:aligo/components/aligo_drawer.dart';
import 'package:aligo/helpers/inventory_helper.dart';
import 'package:aligo/helpers/disbursement_helper.dart';
import 'package:aligo/models/inventory.dart';
import 'package:aligo/models/disbursement.dart';
import 'package:aligo/screens/home.dart';
import 'package:aligo/screens/login.dart';
import 'package:aligo/screens/report/inventory_chart.dart';
import 'package:aligo/screens/report/sales_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChartsPage extends StatefulWidget {
  const ChartsPage({Key? key}) : super(key: key);

  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  TextStyle tableHead =
      const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold);
  TextStyle summaryHead = const TextStyle(
      fontSize: 20.0,
      fontFamily: 'Roboto',
      fontWeight: FontWeight.bold,
      color: Colors.white);

  final formatCurrency = NumberFormat.currency(symbol: "");

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.black54,
      ),
      drawer: const AligoDrawer(),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(
                height: 15,
              ),
              Row(
                children: [
                  const Spacer(),
                  FutureBuilder(
                      future: InventoryDBHelper.instance.numProducts(),
                      builder: (BuildContext context,
                          AsyncSnapshot<String> snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
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
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                    const Text(
                                      "Products: ",
                                      style: TextStyle(
                                          fontSize: 20, color: Colors.white),
                                    ),
                                    Text(
                                      snapshot.data!,
                                      style: summaryHead,
                                    ),
                                  ],
                                ),
                              );
                      }),
                  // FutureBuilder(
                  //     future: DisbursementDBHelper.instance.sumAmount(null),
                  //     builder: (BuildContext context,
                  //         AsyncSnapshot<String> snapshot) {
                  //       if (!snapshot.hasData) {
                  //         return const Center(
                  //             child: CircularProgressIndicator());
                  //       }
                  //       return snapshot.data == null
                  //           ? const SizedBox()
                  //           : Container(
                  //               padding: const EdgeInsets.all(10),
                  //               color: Colors.green,
                  //               child: Row(
                  //                 children: [
                  //                   const Text(
                  //                     "₦",
                  //                     style: TextStyle(
                  //                         fontSize: 41.5,
                  //                         fontFamily: 'Roboto',
                  //                         color: Colors.white),
                  //                   ),
                  //                   const Text(
                  //                     "Revenue: ",
                  //                     style: TextStyle(
                  //                         fontSize: 20,
                  //                         fontFamily: 'Roboto',
                  //                         color: Colors.white),
                  //                   ),
                  //                   snapshot.data == 'null'
                  //                       ? Text(
                  //                           "0",
                  //                           style: summaryHead,
                  //                         )
                  //                       : Text(
                  //                           formatCurrency.format(
                  //                               int.parse(snapshot.data!)),
                  //                           style: summaryHead,
                  //                         ),
                  //                 ],
                  //               ),
                  //             );
                  //     }),
                  // FutureBuilder(
                  //     future: InventoryDBHelper.instance.sumPrice(),
                  //     builder: (BuildContext context,
                  //         AsyncSnapshot<String> snapshot) {
                  //       if (!snapshot.hasData) {
                  //         return const Center(
                  //             child: CircularProgressIndicator());
                  //       }
                  //       return snapshot.data == null
                  //           ? const SizedBox()
                  //           : Container(
                  //               padding: const EdgeInsets.all(10),
                  //               color: Colors.blueGrey,
                  //               child: Row(
                  //                 children: [
                  //                   const Text(
                  //                     "₦",
                  //                     style: TextStyle(
                  //                         fontSize: 41.5,
                  //                         fontFamily: 'Roboto',
                  //                         color: Colors.white),
                  //                   ),
                  //                   const Text(
                  //                     "Asset: ",
                  //                     style: TextStyle(
                  //                         fontSize: 20,
                  //                         fontFamily: 'Roboto',
                  //                         color: Colors.white),
                  //                   ),
                  //                   snapshot.data == 'null'
                  //                       ? Text(
                  //                           "0",
                  //                           style: summaryHead,
                  //                         )
                  //                       : Text(
                  //                           formatCurrency.format(
                  //                               int.parse(snapshot.data!)),
                  //                           style: summaryHead,
                  //                         ),
                  //                 ],
                  //               ),
                  //             );
                  //     }),
                ],
              ),
              SizedBox(
                  width: size.width * 0.95,
                  // height: size.height * 0.65,
                  child: Row(
                    children: [
                      FutureBuilder<List<Inventory>>(
                        future: InventoryDBHelper.instance.getInventories(),
                        builder: (BuildContext context,
                            AsyncSnapshot<List<Inventory>> snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          return snapshot.data!.isEmpty
                              ? const Center(child: Text('No products yet.'))
                              : SizedBox(
                                  height: size.height * 0.7,
                                  width: size.width * 0.475,
                                  child: InventoryChart(
                                    data: snapshot.data!,
                                  ),
                                );
                        },
                      ),
                      FutureBuilder<List<DisbursementRecord>>(
                        future: DisbursementDBHelper.instance
                            .getDisbursementsByMonth(),
                        builder: (BuildContext context,
                            AsyncSnapshot<List<DisbursementRecord>> snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          return snapshot.data!.isEmpty
                              ? const Center(child: Text('No products yet.'))
                              : SizedBox(
                                  height: size.height * 0.7,
                                  width: size.width * 0.475,
                                  child: SalesChart(
                                    data: snapshot.data!,
                                  ),
                                );
                        },
                      ),
                    ],
                  )),
            ],
          ),
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
