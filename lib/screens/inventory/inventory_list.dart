import 'package:aligo/components/aligo_appbar.dart';
import 'package:aligo/components/aligo_drawer.dart';
import 'package:aligo/helpers/inventory_helper.dart';
import 'package:aligo/models/inventory.dart';
import 'package:aligo/screens/inventory/add_product.dart';
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
      appBar: const AligoAppbar(title: 'المخزون'),
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
                  FutureBuilder<int>(
                    future: InventoryDBHelper.instance.numProducts(),
                    builder:
                        (BuildContext context, AsyncSnapshot<int> snapshot) {
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
                                    "منتجات:",
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.white),
                                  ),
                                  Text(
                                    snapshot.data!.toString(),
                                    style: summaryHead,
                                  ),
                                ],
                              ),
                            );
                    },
                  ),
                  FutureBuilder<int>(
                    future: InventoryDBHelper.instance.sumQty(),
                    builder:
                        (BuildContext context, AsyncSnapshot<int> snapshot) {
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
                                    "كمية:",
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
                                          snapshot.data!.toString(),
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
                            // DataCell(
                            //   GestureDetector(
                            //       onTap: () {
                            //         expandImageDialog(
                            //             context, inventory.imageUrl);
                            //       },
                            //       child: Image.network(inventory.imageUrl)),
                            // ),
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
                            showAlertDialog(context, inventory.code);
                          },
                        );
                      }).toList();
                return snapshot.data!.isEmpty
                    ? const Center(child: Text('لا يوجد منتجات حتى الآن.'))
                    : DataTable(
                        showCheckboxColumn: false,
                        columns: <DataColumn>[
                          // DataColumn(label: Text('Image', style: tableHead)),
                          DataColumn(label: Text('اسم', style: tableHead)),
                          DataColumn(label: Text('الكمية', style: tableHead)),
                          // DataColumn(label: Text('Price', style: tableHead)),
                          DataColumn(label: Text('تاريخ', style: tableHead)),
                        ],
                        rows: rows,
                      );
              },
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to AddProduct and wait for result
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddProduct()),
          );

          // If an item was added (AddProduct returned true), refresh list
          if (added == true && mounted) {
            setState(
                () {}); // Triggers FutureBuilders (getInventories / counts)
          }
        },
        child: const Icon(Icons.post_add_sharp, size: 30),
      ),
    );
  }

  showAlertDialog(BuildContext context, String id) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: const Text("يلغي"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = TextButton(
      child: const Text(
        "يمسح",
        style: TextStyle(color: Colors.red),
      ),
      onPressed: () async {
        await InventoryDBHelper.instance.remove(id).then((value) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('تم حذف المنتج')));
        });
        setState(() {});
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("تأكيد الحذف"),
      content: SizedBox(
        height: MediaQuery.of(context).size.height * 0.18,
        child: const Column(
          children: <Widget>[
            Icon(
              Icons.warning_amber_outlined,
              size: 100,
              color: Colors.orange,
            ),
            Text("هل أنت متأكد أنك تريد الحذف؟"),
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

  expandImageDialog(BuildContext context, String imageUrl) {
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("صورة المنتج"),
      content: SizedBox(
          // height: MediaQuery.of(context).size.height * 0.18,
          child: Image.network(imageUrl)),
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
