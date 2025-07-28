import 'dart:typed_data';

import 'package:aligo/helpers/disbursement_helper.dart';
import 'package:aligo/models/disbursement.dart';
import 'package:aligo/screens/disbursement/disbursement_list.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DisbursementDialog extends StatefulWidget {
  final DisbursementRecord saleRecord;

  const DisbursementDialog({Key? key, required this.saleRecord})
      : super(key: key);

  @override
  State<DisbursementDialog> createState() => _DisbursementDialogState();
}

class _DisbursementDialogState extends State<DisbursementDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _empCntrl =
      TextEditingController(text: widget.saleRecord.employeeRefId.toString());
  late final TextEditingController _brandCntrl =
      TextEditingController(text: widget.saleRecord.brand);
  late final TextEditingController _varietyCntrl =
      TextEditingController(text: widget.saleRecord.variety);

  // late final TextEditingController _colourCntrl = TextEditingController(text: widget.saleRecord.colour);
  late final TextEditingController _quantityCntrl =
      TextEditingController(text: widget.saleRecord.quantity);

  // late final TextEditingController _costCntrl = TextEditingController(text: widget.saleRecord.cost);
  // late final TextEditingController _priceCntrl = TextEditingController(text: widget.saleRecord.price);

  Uint8List? _imageMemo;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("تفاصيل الصرف"),
      content: SizedBox(
        // height: MediaQuery.of(context).size.height * 0.18,
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              InkWell(
                onTap: () async {
                  FilePickerResult? result = await FilePicker.platform
                      .pickFiles(type: FileType.image, withData: true);

                  if (result != null) {
                    PlatformFile file = result.files.first;
                    file.readStream;
                    Uint8List fileBytes = file.bytes!;
                    _imageMemo = fileBytes;
                    setState(() {});
                  } else {
                    // User canceled the picker
                  }
                },
                child: _imageMemo == null
                    ? Image.memory(
                        widget.saleRecord.image,
                        width: 200,
                      )
                    : Image.memory(
                        _imageMemo!,
                        width: 200,
                      ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        controller: _empCntrl,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.person_outline),
                          hintText: "Employee ID",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter some text';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _brandCntrl,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.store_mall_directory_outlined),
                          hintText: "Brand name",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter some text';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _varietyCntrl,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.account_tree_outlined),
                          hintText: "Variety",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter some text';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      TextFormField(
                        controller: _quantityCntrl,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.numbers),
                          hintText: "Quantity",
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a quantity amount';
                          }
                          final n = num.tryParse(value);
                          if (n == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      // TextFormField(
                      //   controller: _costCntrl,
                      //   decoration: const InputDecoration(
                      //     icon: Icon(Icons.numbers),
                      //     hintText: "Cost per unit",
                      //   ),
                      //   keyboardType: TextInputType.number,
                      //   validator: (value) {
                      //     if (value == null || value.isEmpty) {
                      //       return 'Please enter a price amount';
                      //     }
                      //     final n = num.tryParse(value);
                      //     if (n == null) {
                      //       return 'Please enter a valid number';
                      //     }
                      //     return null;
                      //   },
                      // ),
                      // const SizedBox(
                      //   height: 30,
                      // ),
                      // TextFormField(
                      //   controller: _priceCntrl,
                      //   decoration: const InputDecoration(
                      //     icon: Icon(Icons.numbers),
                      //     hintText: "Price per unit",
                      //   ),
                      //   keyboardType: TextInputType.number,
                      //   validator: (value) {
                      //     if (value == null || value.isEmpty) {
                      //       return 'Please enter a price amount';
                      //     }
                      //     final n = num.tryParse(value);
                      //     if (n == null) {
                      //       return 'Please enter a valid number';
                      //     }
                      //     return null;
                      //   },
                      // ),
                      // const SizedBox(
                      //   height: 30,
                      // ),
                      SizedBox(
                        width: 125,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              // if (int.parse(_costCntrl.text) < int.parse(_priceCntrl.text)) {
                              // if (_imageMemo != null) {
                              _updateDisbursementRecord();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Updating Product...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                              // } else {
                              //   ScaffoldMessenger.of(context).showSnackBar(
                              //     const SnackBar(content: Text(
                              //         'Please Upload a product image!')),
                              //   );
                              // }
                              // } else {
                              //   ScaffoldMessenger.of(context).showSnackBar(
                              //     const SnackBar(
                              //       content: Text('Cost amount cannot be greater than selling price'),
                              //       backgroundColor: Colors.red,
                              //     ),
                              //   );
                              // }
                            }
                          },
                          style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all(Colors.blue)),
                          child: const Row(
                            children: <Widget>[
                              Icon(Icons.edit),
                              Text('Update'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  _updateDisbursementRecord() async {
    try {
      final f = DateFormat('yyyy-MM-dd');
      var date = f.format(DateTime.now());

      // Prepare the data to update
      final Map<String, dynamic> updateData = {
        'employeeRefId': _empCntrl.text,
        'quantity': _quantityCntrl.text,
        'dateOfDisbursement': date,
        // Only include image if it was changed
        if (_imageMemo != null) 'image': _imageMemo,
        // Add other fields you want to update from the dialog
        'brand': _brandCntrl.text,
        // Assuming you want to update brand and variety
        'variety': _varietyCntrl.text,
      };

      await DisbursementDBHelper.instance
          .update(widget.saleRecord.id.toString(),
              updateData) // Pass document ID and map
          .then((value) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disbursement updated'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const DisbursementList()));
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error occurred: $e'), // Show the actual error
            backgroundColor: Colors.red, // Change color for error
          ),
        );
      }
    }
  }
}
