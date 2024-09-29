import 'package:aligo/components/aligo_appbar.dart';
import 'package:aligo/components/aligo_drawer.dart';
import 'package:aligo/helpers/inventory_helper.dart';
import 'package:aligo/screens/disbursement/add_disbursement_dialog.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class Scan extends StatefulWidget {
  const Scan({super.key});

  @override
  State<Scan> createState() => _ScanState();
}

class _ScanState extends State<Scan> {
  final MobileScannerController _controller = MobileScannerController();
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AligoAppbar(title: 'Barcode Scanner'),
      drawer: const AligoDrawer(),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: MobileScanner(
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              debugPrint('Barcode found! ${barcodes[0].rawValue}');
              final code = barcodes[0].rawValue;
              if (context.mounted) {
                fetchProduct(context, code);
              }
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          XFile? result = await _picker.pickImage(source: ImageSource.gallery);

          if (result != null) {
            final BarcodeCapture? barcodes =
                await _controller.analyzeImage(result.path);
            final code = barcodes?.barcodes[0].rawValue;
            debugPrint(barcodes?.barcodes[0].rawValue);
            if (context.mounted) {
              fetchProduct(context, code);
            }
          }
        },
        child: const Icon(Icons.photo_library_sharp),
      ),
    );
  }

  void fetchProduct(BuildContext context, String? code) async {
    final inventories =
        await InventoryDBHelper.instance.getInventoryByCode(code ?? 'none');
    if (context.mounted) {
      if (inventories.isNotEmpty) {
        await showDialog(
          context: context,
          builder: (context) {
            return StatefulBuilder(builder: (context, setState) {
              return AddDisbursementDialog(inventory: inventories[0]);
            });
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No product found'),
          ),
        );
      }
    }
  }
}
