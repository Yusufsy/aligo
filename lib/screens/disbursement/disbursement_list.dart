import 'dart:typed_data';

import 'package:aligo/components/aligo_appbar.dart';
import 'package:aligo/components/aligo_drawer.dart';
import 'package:aligo/helpers/disbursement_helper.dart';
import 'package:aligo/models/disbursement.dart';
import 'package:aligo/screens/disbursement/add_disbursement.dart';
import 'package:aligo/screens/disbursement/disbursement_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DisbursementList extends StatefulWidget {
  const DisbursementList({Key? key}) : super(key: key);

  @override
  State<DisbursementList> createState() => _DisbursementListState();
}

class _DisbursementListState extends State<DisbursementList> {
  TextStyle tableHead =
      const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600);
  TextStyle summaryHead = const TextStyle(
      fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white);

  final formatCurrency = NumberFormat.currency(symbol: "");

  String? _filter;
  var year = DateFormat('yyyy').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    ButtonStyle selectBtn =
        ButtonStyle(foregroundColor: MaterialStateProperty.all(Colors.red));
    ButtonStyle defaultBtn = const ButtonStyle();
    return Scaffold(
      appBar: const AligoAppbar(title: 'Disbursements'),
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
                    future: _filter == null
                        ? DisbursementDBHelper.instance.numDisbursements(null)
                        : (_filter == 'day'
                            ? DisbursementDBHelper.instance
                                .numDisbursements('day')
                            : (_filter == 'month'
                                ? DisbursementDBHelper.instance
                                    .numDisbursements('month')
                                : DisbursementDBHelper.instance
                                    .numDisbursements('year'))),
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
                                    Icons.list_alt,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  const Text(
                                    "Disbursements: ",
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
                    future: _filter == null
                        ? DisbursementDBHelper.instance.sumQty(null)
                        : (_filter == 'day'
                            ? DisbursementDBHelper.instance.sumQty('day')
                            : (_filter == 'month'
                                ? DisbursementDBHelper.instance.sumQty('month')
                                : DisbursementDBHelper.instance
                                    .sumQty('year'))),
                    builder:
                        (BuildContext context, AsyncSnapshot<String> snapshot) {
                      return snapshot.data == null
                          ? const SizedBox()
                          : Container(
                              padding: const EdgeInsets.all(10),
                              color: Colors.green,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.numbers,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  const Text(
                                    "Items: ",
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
                  //   future: _filter == null
                  //       ? SaleDBHelper.instance.sumAmount(null)
                  //       : (_filter == 'day'
                  //           ? SaleDBHelper.instance.sumAmount('day')
                  //           : (_filter == 'month' ? SaleDBHelper.instance.sumAmount('month') : SaleDBHelper.instance.sumAmount('year'))),
                  //   builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                  //     // if (!snapshot.hasData) {
                  //     //   return const Center(child: CircularProgressIndicator());
                  //     // }
                  //     return snapshot.data == null
                  //         ? const SizedBox()
                  //         : Container(
                  //             padding: const EdgeInsets.all(10),
                  //             color: Colors.blueGrey,
                  //             child: Row(
                  //               children: [
                  //                 const Text(
                  //                   "Revenue: ",
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
                  // FutureBuilder(
                  //   future: _filter == null
                  //       ? SaleDBHelper.instance.getProfit(null)
                  //       : (_filter == 'day'
                  //           ? SaleDBHelper.instance.getProfit('day')
                  //           : (_filter == 'month' ? SaleDBHelper.instance.getProfit('month') : SaleDBHelper.instance.getProfit('year'))),
                  //   builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                  //     // if (!snapshot.hasData) {
                  //     //   return const Center(child: CircularProgressIndicator());
                  //     // }
                  //     return snapshot.data == null
                  //         ? const SizedBox()
                  //         : Container(
                  //             padding: const EdgeInsets.all(10),
                  //             color: Colors.deepOrange,
                  //             child: Row(
                  //               children: [
                  //                 const Text(
                  //                   "Profit: ",
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
            Row(
              children: [
                const Icon(
                  Icons.filter_alt,
                  color: Colors.blueAccent,
                  size: 50,
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filter = null;
                    });
                  },
                  style: _filter == null ? selectBtn : defaultBtn,
                  child: const Text("All"),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filter = "annual";
                    });
                  },
                  style: _filter != null && _filter == 'annual'
                      ? selectBtn
                      : defaultBtn,
                  child: const Text("Annual"),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filter = "month";
                    });
                  },
                  style: _filter != null && _filter == 'month'
                      ? selectBtn
                      : defaultBtn,
                  child: const Text("30 days"),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filter = "day";
                    });
                  },
                  style: _filter != null && _filter == 'day'
                      ? selectBtn
                      : defaultBtn,
                  child: const Text("Today"),
                ),
              ],
            ),
            FutureBuilder<List<DisbursementRecord>>(
              future: _filter == null
                  ? DisbursementDBHelper.instance.getDisbursements()
                  : (_filter == 'day'
                      ? DisbursementDBHelper.instance.getDisbursementsByDay()
                      : (_filter == 'month'
                          ? DisbursementDBHelper.instance
                              .getDisbursementsByMonth()
                          : DisbursementDBHelper.instance
                              .getDisbursementByYear())),
              builder: (BuildContext context,
                  AsyncSnapshot<List<DisbursementRecord>> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                print(snapshot.data);
                List<DataRow> rows = snapshot.data!.isEmpty
                    ? []
                    : snapshot.data!.map((sale) {
                        return DataRow(
                          cells: <DataCell>[
                            DataCell(
                              Text('${sale.id}'),
                            ),
                            DataCell(
                              GestureDetector(
                                onTap: () {
                                  expandImageDialog(context, sale.image);
                                },
                                child: Image.memory(sale.image),
                              ),
                            ),
                            DataCell(
                              Text(
                                  '${sale.brand} ${sale.variety} x${sale.quantity}'),
                            ),
                            // DataCell(
                            //   Text(formatCurrency.format(int.parse(sale.price))),
                            // ),
                            DataCell(Text('${sale.employeeId}')),
                          ],
                          onSelectChanged: (selected) {
                            showDialog(
                              context: context,
                              builder: (context) => DisbursementDialog(
                                saleRecord: sale,
                              ),
                            );
                          },
                          onLongPress: () {
                            showAlertDialog(context, sale.id!);
                          },
                        );
                      }).toList();
                return snapshot.data!.isEmpty
                    ? const Center(
                        child: Text(
                          'No disbursements yet.',
                          style: TextStyle(fontSize: 20),
                        ),
                      )
                    : DataTable(
                        showCheckboxColumn: false,
                        columns: <DataColumn>[
                          DataColumn(label: Text('ID', style: tableHead)),
                          DataColumn(label: Text('Image', style: tableHead)),
                          DataColumn(label: Text('Product', style: tableHead)),
                          // DataColumn(label: Text('Price', style: tableHead)),
                          DataColumn(label: Text('EmpID', style: tableHead)),
                        ],
                        rows: rows,
                      );
                // ListView(
                //         children: snapshot.data!.map(
                //           (sale) {
                //             return Center(
                //               child: ListTile(
                //                 title: Table(
                //                   defaultColumnWidth: const IntrinsicColumnWidth(),
                //                   children: <TableRow>[
                //                     TableRow(children: <Widget>[
                //                       TableCell(
                //                         verticalAlignment: TableCellVerticalAlignment.middle,
                //                         child: Text(sale.id.toString()),
                //                       ),
                //                       TableCell(
                //                         verticalAlignment: TableCellVerticalAlignment.middle,
                //                         child: GestureDetector(
                //                           onTap: () {
                //                             expandImageDialog(context, sale.image);
                //                           },
                //                           child: Column(
                //                             children: [
                //                               Image.memory(sale.image, height: 100),
                //                               Text(sale.brand),
                //                               Text(sale.variety),
                //                               Text(sale.quantity),
                //                             ],
                //                           ),
                //                         ),
                //                       ),
                //                       // TableCell(
                //                       //   verticalAlignment: TableCellVerticalAlignment.middle,
                //                       //   child: Text(sale.productId),),
                //                       // TableCell(
                //                       //     verticalAlignment: TableCellVerticalAlignment.middle,
                //                       //     child: Text(inventory.variety),),
                //                       TableCell(
                //                         verticalAlignment: TableCellVerticalAlignment.middle,
                //                         child: Column(
                //                           children: [
                //                             Text(
                //                               formatCurrency.format(int.parse(sale.price)),
                //                             ),
                //                             // Text("Cost: ${formatCurrency.format(int.parse(sale.cost))}"),
                //                           ],
                //                         ),
                //                       ),
                //                       // TableCell(verticalAlignment: TableCellVerticalAlignment.middle, child: Center(child: Text(sale.quantity))),
                //                       TableCell(
                //                         verticalAlignment: TableCellVerticalAlignment.middle,
                //                         child: Column(
                //                           children: [
                //                             Text(
                //                               formatCurrency.format(int.parse(sale.amount)),
                //                             ),
                //                             // Text(
                //                             //     "Profit: ${formatCurrency.format((int.parse(sale.price) - int.parse(sale.cost)) * int.parse(sale.quantity))}"),
                //                           ],
                //                         ),
                //                       ),
                //                       // TableCell(
                //                       //   verticalAlignment: TableCellVerticalAlignment.middle,
                //                       //   child: Text(sale.dateOfDisbursement),
                //                       // ),
                //                       // TableCell(
                //                       //     verticalAlignment: TableCellVerticalAlignment.middle,
                //                       //     child: Row(
                //                       //       children: [
                //                       //         IconButton(
                //                       //           onPressed: () {
                //                       //             showAlertDialog(context, sale.id!);
                //                       //           },
                //                       //           color: Colors.red,
                //                       //           icon: const Icon(Icons.delete_forever),
                //                       //           tooltip: "Delete",
                //                       //         ),
                //                       //       ],
                //                       //     )),
                //                     ])
                //                   ],
                //                 ),
                //                 onTap: () {},
                //               ),
                //             );
                //           },
                //         ).toList(),
                //       );
              },
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AddDisbursement()),
          );
        },
        child: const Icon(Icons.post_add_sharp, size: 30),
      ),
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
        await DisbursementDBHelper.instance.remove(id).then((value) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Disbursement deleted')));
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
