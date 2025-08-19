import 'dart:typed_data';

import 'package:aligo/components/aligo_appbar.dart';
import 'package:aligo/components/aligo_drawer.dart';
import 'package:aligo/helpers/inventory_helper.dart';
import 'package:aligo/helpers/storage_helper.dart';
import 'package:aligo/models/inventory.dart';
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

  // --- EXISTING CONTROLLERS ---
  final TextEditingController _codeCntrl = TextEditingController();
  final TextEditingController _brandCntrl = TextEditingController();
  final TextEditingController _varietyCntrl = TextEditingController();
  final TextEditingController _colourCntrl = TextEditingController();
  final TextEditingController _quantityCntrl = TextEditingController();

  // --- NEW STATE VARIABLES AND CONTROLLERS ---
  final TextEditingController _caseModelCntrl = TextEditingController();
  final TextEditingController _laptopSnCntrl = TextEditingController();

  String? _selectedType;
  String? _selectedComputerType;

  final List<String> _itemTypes = [
    'Computer',
    'Keyboard',
    'Mouse',
    'Monitor',
    'Printer',
    'UPS',
    'Scanner'
  ];
  final List<String> _computerTypes = ['laptop', 'desktop'];

  bool _isLoading = false;

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    _codeCntrl.dispose();
    _brandCntrl.dispose();
    _varietyCntrl.dispose();
    _colourCntrl.dispose();
    _quantityCntrl.dispose();
    _caseModelCntrl.dispose();
    _laptopSnCntrl.dispose();
    super.dispose();
  }

  Future<void> _addInventory() async {
    try {
      if (_imageMemo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار الصورة')),
        );
        return;
      }

      final f = DateFormat('yyyy-MM-dd');
      final date = f.format(DateTime.now());

      final (url, path) = await StorageHelper.instance.uploadInventoryImage(
        data: _imageMemo!,
        code: _codeCntrl.text.trim(),
      );

      // --- UPDATE INVENTORY OBJECT CREATION ---
      final inv = Inventory(
        code: _codeCntrl.text.trim(),
        brand: _brandCntrl.text.trim(),
        variety: _varietyCntrl.text.trim(),
        colour: _colourCntrl.text.trim(),
        quantity: _quantityCntrl.text.trim(),
        dateAdded: date,
        imageUrl: url,
        imagePath: path,
        // Add new fields
        type: _selectedType,
        computerType: _selectedComputerType,
        caseModel:
            _selectedType == 'Computer' ? _caseModelCntrl.text.trim() : null,
        laptopSn: _selectedComputerType == 'laptop'
            ? _laptopSnCntrl.text.trim()
            : null,
      );

      await InventoryDBHelper.instance.add(inv);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إضافة المنتج'),
            backgroundColor: Colors.green,
          ),
        );
        // You could clear the form here if desired
        _formKey.currentState?.reset();
        setState(() {
          _imageMemo = null;
          _selectedType = null;
          _selectedComputerType = null;
          _caseModelCntrl.clear();
          _laptopSnCntrl.clear();
        });
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding product: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: const AligoAppbar(title: 'إضافة المخزون'),
      endDrawer: const AligoDrawer(),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 10),
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
                    ? const Icon(Icons.add_a_photo, size: 200)
                    : Image.memory(_imageMemo!, width: 200),
              ),
              const SizedBox(height: 5),
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
                        validator: (v) => v == null || v.isEmpty
                            ? 'Please enter some text'
                            : null,
                      ),
                      const SizedBox(height: 30),

                      // --- ADD THE NEW DROPDOWN AND CONDITIONAL FIELDS ---

                      // 1. Main Item Type Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.category),
                          hintText: 'حدد نوع العنصر',
                        ),
                        items: _itemTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedType = newValue;
                            // Reset conditional fields when main type changes
                            _selectedComputerType = null;
                            _caseModelCntrl.clear();
                            _laptopSnCntrl.clear();
                          });
                        },
                        validator: (v) =>
                            v == null ? 'Please select a type' : null,
                      ),
                      const SizedBox(height: 30),

                      // 2. Conditional Fields for "Computer"
                      if (_selectedType == 'Computer') ...[
                        // Computer Type Dropdown (Laptop/Desktop)
                        DropdownButtonFormField<String>(
                          value: _selectedComputerType,
                          decoration: const InputDecoration(
                            icon: Icon(Icons.devices),
                            hintText: 'حدد نوع الكمبيوتر',
                          ),
                          items: _computerTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedComputerType = newValue;
                              // Reset laptop SN if type is not laptop
                              if (newValue != 'laptop') {
                                _laptopSnCntrl.clear();
                              }
                            });
                          },
                          validator: (v) => v == null
                              ? 'Please select a computer type'
                              : null,
                        ),
                        const SizedBox(height: 30),

                        // Case Model TextField
                        TextFormField(
                          controller: _caseModelCntrl,
                          decoration: const InputDecoration(
                            icon: Icon(Icons.computer),
                            hintText: "Case Model",
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Please enter a case model'
                              : null,
                        ),
                        const SizedBox(height: 30),

                        // Conditional Field for "Laptop"
                        if (_selectedComputerType == 'laptop') ...[
                          TextFormField(
                            controller: _laptopSnCntrl,
                            decoration: const InputDecoration(
                              icon: Icon(Icons.pin),
                              hintText: "Laptop SN",
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Please enter the laptop SN'
                                : null,
                          ),
                          const SizedBox(height: 30),
                        ],
                      ],

                      if (_selectedType != 'Computer') ...[
                        TextFormField(
                          controller: _brandCntrl,
                          decoration: const InputDecoration(
                            icon: Icon(Icons.store_mall_directory_outlined),
                            hintText: "Brand name",
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Please enter some text'
                              : null,
                        ),
                        const SizedBox(height: 30),
                      ],

                      // ... (Rest of your existing TextFormFields: variety, colour, quantity)

                      TextFormField(
                        controller: _varietyCntrl,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.account_tree_outlined),
                          hintText: "Variety",
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => v == null || v.isEmpty
                            ? 'Please enter some text'
                            : null,
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _colourCntrl,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.account_tree),
                          hintText: "Colour",
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Please enter colour variant'
                            : null,
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _quantityCntrl,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.numbers),
                          hintText: "Quantity",
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Please enter a quantity';
                          if (num.tryParse(v) == null)
                            return 'Please enter a valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),

                      // --- SUBMIT BUTTON (No changes needed here) ---
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    if (_imageMemo == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Please Upload a product image!')),
                                      );
                                      return;
                                    }
                                    setState(() => _isLoading = true);
                                    await _addInventory();
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
                                  }
                                },
                          style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all(Colors.green)),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(Icons.add, color: Colors.white),
                                    Text('Add',
                                        style: TextStyle(color: Colors.white)),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 30),
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
