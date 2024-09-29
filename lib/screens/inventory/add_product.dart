import 'dart:typed_data';

import 'package:aligo/components/aligo_appbar.dart';
import 'package:aligo/components/aligo_drawer.dart';
import 'package:aligo/helpers/inventory_helper.dart';
import 'package:aligo/models/inventory.dart';
import 'package:aligo/screens/home.dart';
import 'package:aligo/screens/inventory/inventory_list.dart';
import 'package:aligo/screens/login.dart';
import 'package:aligo/screens/disbursement/disbursement_list.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({Key? key}) : super(key: key);

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageMemo;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeCntrl = TextEditingController();
  final TextEditingController _brandCntrl = TextEditingController();
  final TextEditingController _varietyCntrl = TextEditingController();
  final TextEditingController _colourCntrl = TextEditingController();
  final TextEditingController _quantityCntrl = TextEditingController();

  // final TextEditingController _costCntrl = TextEditingController();
  // final TextEditingController _priceCntrl = TextEditingController();

  _addInventory() async {
    try {
      final f = DateFormat('yyyy-MM-dd');
      var date = f.format(DateTime.now());
      await InventoryDBHelper.instance
          .add(Inventory(
              code: _codeCntrl.text,
              brand: _brandCntrl.text,
              variety: _varietyCntrl.text,
              colour: _colourCntrl.text,
              quantity: _quantityCntrl.text,
              // cost: _costCntrl.text,
              // price: _priceCntrl.text,
              dateAdded: date,
              image: _imageMemo!))
          .then((value) => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Product Added'),
                  backgroundColor: Colors.green,
                ),
              ));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error occurred.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: const AligoAppbar(title: 'Add Inventory'),
      drawer: const AligoDrawer(),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(
                height: 10,
              ),
              InkWell(
                onTap: () async {
                  XFile? result =
                      await _picker.pickImage(source: ImageSource.gallery);

                  if (result != null) {
                    Uint8List fileBytes = await result.readAsBytes();
                    setState(() => _imageMemo = fileBytes);
                  }
                },
                child: _imageMemo == null
                    ? const Icon(
                        Icons.add_a_photo,
                        size: 200,
                      )
                    : Image.memory(
                        _imageMemo!,
                        width: 200,
                      ),
              ),
              const SizedBox(
                height: 5,
              ),
              SizedBox(
                width: size.width * 0.7,
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
                        width: 100,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              // if (int.parse(_costCntrl.text) <
                              //     int.parse(_priceCntrl.text)) {
                              if (_imageMemo != null) {
                                _addInventory();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Adding Product...')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Please Upload a product image!')),
                                );
                              }
                              // } else {
                              //   ScaffoldMessenger.of(context).showSnackBar(
                              //     const SnackBar(
                              //       content: Text(
                              //           'Cost amount cannot be greater than selling price'),
                              //       backgroundColor: Colors.red,
                              //     ),
                              //   );
                              // }
                            }
                          },
                          style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all(Colors.green)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.add, color: Colors.white),
                              Text('Add',
                                  style: TextStyle(color: Colors.white)),
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
}
