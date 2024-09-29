import 'package:aligo/helpers/disbursement_helper.dart';
import 'package:aligo/models/disbursement.dart';
import 'package:aligo/models/inventory.dart';
import 'package:aligo/screens/disbursement/disbursement_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddDisbursementDialog extends StatefulWidget {
  final Inventory inventory;

  const AddDisbursementDialog({super.key, required this.inventory});

  @override
  State<AddDisbursementDialog> createState() => _AddDisbursementDialogState();
}

class _AddDisbursementDialogState extends State<AddDisbursementDialog> {
  int qty = 1;
  String? employeeID;
  List<Map<String, dynamic>> employees = [];

  @override
  void initState() {
    super.initState();
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    final firestoreInstance = FirebaseFirestore.instance;
    QuerySnapshot querySnapshot =
        await firestoreInstance.collection('employees').get();

    setState(() {
      employees = querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                'number': doc['number'],
                'name': doc['name'],
              })
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Process Disbursement"),
      content: SingleChildScrollView(
        child: SizedBox(
          // height: MediaQuery.of(context).size.height * 0.7,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(child: Image.memory(widget.inventory.image)),
                Text(widget.inventory.code),
                Text(widget.inventory.brand),
                Text(widget.inventory.variety),
                Text(
                  "Colour: ${widget.inventory.colour}",
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                Text(
                  "${widget.inventory.quantity} in stock",
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    icon: Icon(Icons.person_outline),
                    hintText: "Select Employee",
                  ),
                  value: employeeID,
                  items: employees.map((employee) {
                    return DropdownMenuItem<String>(
                      value: employee['number'],
                      child:
                          Text("${employee['number']} - ${employee['name']}"),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      employeeID = value;
                    });
                  },
                ),
                // TextFormField(
                //   decoration: const InputDecoration(
                //     icon: Icon(Icons.person_outline),
                //     hintText: "Employee ID",
                //   ),
                //   keyboardType: TextInputType.number,
                //   onChanged: (value) {
                //     setState(() => employeeID = value);
                //   },
                // ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Quantity"),
                    IconButton(
                        onPressed: () {
                          setState(() {
                            if (qty > 1) {
                              qty -= 1;
                              // amount = int.parse(price) * qty;
                            }
                          });
                        },
                        icon: const Icon(Icons.remove)),
                    Text(qty.toString()),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          qty += 1;
                          // amount = int.parse(price) * qty;
                        });
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _addDisbursement(
                      employeeID ?? '',
                      widget.inventory.id.toString(),
                      qty.toString(),
                      // amount.toString(),
                    );
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.shopping_bag),
                      Spacer(),
                      Text("Record"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _addDisbursement(
    String employeeId,
    String productId,
    String quantity,
    // String amount
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Processing...'),
        duration: Duration(seconds: 2),
      ),
    );
    try {
      final f = DateFormat('yyyy-MM-dd');
      var date = f.format(DateTime.now());
      await DisbursementDBHelper.instance.add(Disbursement(
        employeeId: int.parse(employeeId),
        productId: productId,
        quantity: quantity,
        dateOfDisbursement: date,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disbursement recorded')),
        );
        setState(() {});
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DisbursementList()),
        );
      }
    } catch (e) {
      print(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error occurred.')),
        );
      }
    }
  }
}
