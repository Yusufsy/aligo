import 'dart:typed_data';
import 'package:aligo/helpers/inventory_helper.dart';
import 'package:aligo/models/inventory.dart';
import 'package:aligo/screens/inventory/inventory_list.dart';
import 'package:aligo/helpers/storage_helper.dart'; // <-- make sure path is correct
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

  Uint8List? _newImageBytes; // picked new bytes (not yet uploaded)
  String? _previewLocalTag; // rebuild trigger after picking
  bool _saving = false;

  @override
  void dispose() {
    _codeCntrl.dispose();
    _brandCntrl.dispose();
    _varietyCntrl.dispose();
    _colourCntrl.dispose();
    _quantityCntrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        setState(() {
          _newImageBytes = file.bytes!;
          _previewLocalTag = DateTime.now().millisecondsSinceEpoch.toString();
        });
      }
    }
  }

  Future<void> _updateInventory() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final nowStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      String imageUrl = widget.inventory.imageUrl;
      String? imagePath = widget.inventory.imagePath;

      // If user selected a new image: upload, then delete old
      if (_newImageBytes != null) {
        // Upload new
        final (newUrl, newPath) =
            await StorageHelper.instance.uploadInventoryImage(
          data: _newImageBytes!,
          code: _codeCntrl.text.trim(),
        );

        // Delete old (ignore errors)
        await StorageHelper.instance.deleteIfExists(imagePath);

        imageUrl = newUrl;
        imagePath = newPath;
      }

      final updated = Inventory(
        id: widget.inventory.id,
        code: _codeCntrl.text.trim(),
        brand: _brandCntrl.text.trim(),
        variety: _varietyCntrl.text.trim(),
        colour: _colourCntrl.text.trim(),
        quantity: _quantityCntrl.text.trim(),
        dateAdded: nowStr,
        // if you want to keep original, use widget.inventory.dateAdded
        imageUrl: imageUrl,
        imagePath: imagePath,
      );

      await InventoryDBHelper.instance.update(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث المنتج'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // close dialog
      // Refresh list page (replace):
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const InventoryList()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$eفشل التحديث: '),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 200,
        height: 160,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade100,
        ),
        alignment: Alignment.center,
        child: _newImageBytes != null
            ? Image.memory(_newImageBytes!, fit: BoxFit.cover)
            : Image.network(
                widget.inventory.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, size: 64),
              ),
      ),
    );

    return Stack(
      children: [
        AlertDialog(
          title: const Text('تحديث المنتج'),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    imageWidget,
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _codeCntrl,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.qr_code),
                        labelText: 'Code / Barcode',
                      ),
                      readOnly: true,
                      // keep code immutable; remove if you need to allow changes
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _brandCntrl,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.store_mall_directory_outlined),
                        labelText: 'Brand',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _varietyCntrl,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.category_outlined),
                        labelText: 'Variety',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _colourCntrl,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.palette_outlined),
                        labelText: 'Colour',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _quantityCntrl,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.numbers),
                        labelText: 'Quantity',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Required';
                        }
                        if (num.tryParse(v) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 160,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                        onPressed: _saving ? null : _updateInventory,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
        if (_saving)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.25),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }
}
