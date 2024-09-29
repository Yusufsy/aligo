import 'dart:typed_data';

import 'package:aligo/helpers/inventory_helper.dart';
import 'package:aligo/models/inventory.dart';
import 'package:aligo/screens/inventory/inventory_list.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UpdateProduct extends StatefulWidget {
  final Inventory inventory;

  const UpdateProduct({Key? key, required this.inventory}) : super(key: key);

  @override
  State<UpdateProduct> createState() => _UpdateProductState();
}

class _UpdateProductState extends State<UpdateProduct> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeCntrl =
      TextEditingController(text: widget.inventory.code);
  late final TextEditingController _brandCntrl =
      TextEditingController(text: widget.inventory.brand);
  late final TextEditingController _varietyCntrl =
      TextEditingController(text: widget.inventory.variety);
  late final TextEditingController _colourCntrl =
      TextEditingController(text: widget.inventory.colour);
  late final TextEditingController _quantityCntrl =
      TextEditingController(text: widget.inventory.quantity);

  // late final TextEditingController _costCntrl = TextEditingController(text: widget.inventory.cost);
  // late final TextEditingController _priceCntrl = TextEditingController(text: widget.inventory.price);

  Uint8List? _imageMemo;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Update product"),
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
                        widget.inventory.image,
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
                        controller: _codeCntrl,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.barcode_reader),
                          hintText: "Barcode",
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
                      const SizedBox(
                        height: 30,
                      ),
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
                        controller: _colourCntrl,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.account_tree),
                          hintText: "Colour",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter colour variant';
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
                      //     hintText: "Cost per unit / yard",
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
                              _updateInventory();
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

  _updateInventory() async {
    try {
      final f = DateFormat('yyyy-MM-dd');
      var date = f.format(DateTime.now());
      await InventoryDBHelper.instance
          .update(Inventory(
              id: widget.inventory.id,
              code: _codeCntrl.text,
              brand: _brandCntrl.text,
              variety: _varietyCntrl.text,
              colour: _colourCntrl.text,
              quantity: _quantityCntrl.text,
              // cost: _costCntrl.text,
              // price: _priceCntrl.text,
              dateAdded: date,
              image: _imageMemo == null ? widget.inventory.image : _imageMemo!))
          .then((value) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product updated'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const InventoryList()));
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error occurred.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
