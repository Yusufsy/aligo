import 'package:aligo/components/aligo_appbar.dart';
import 'package:aligo/components/aligo_drawer.dart';
import 'package:aligo/helpers/inventory_helper.dart';
import 'package:aligo/models/inventory.dart';
import 'package:aligo/models/product_summary.dart';
import 'package:aligo/screens/custody/custody_list_screen.dart';
import 'package:aligo/screens/disbursement/disbursement_list.dart';
import 'package:aligo/screens/inventory/inventory_list.dart';
import 'package:aligo/screens/scan.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  /// Compose a readable product name: brand + variety + colour (skip empties).
  String _productDisplayName(Inventory inv) {
    final parts = <String>[
      inv.brand.trim(),
      inv.variety.trim(),
      inv.colour.trim(),
    ].where((p) => p.isNotEmpty).toList();
    return parts.isEmpty ? inv.code : parts.join(' ');
  }

  Widget _buildTile(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<ProductSummary>> _loadPerProduct() async {
    final rows = await InventoryDBHelper.instance.fetchQtyPerProduct();
    return rows
        .map<ProductSummary>((r) => ProductSummary(
              name: (r['name'] ?? '').toString(),
              qty: (r['qty'] as num?)?.toInt() ?? 0,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AligoAppbar(
        title: 'لوحة التحكم',
        showLogout: true,
      ),
      endDrawer: const AligoDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ─── Per-Product Horizontal Summary ─────────────────────────
            const Text(
              'المخزون حسب المنتج',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            PerProductHorizontalSummary(summariesFuture: _loadPerProduct()),
            const SizedBox(height: 16),
            // FutureBuilder<List<Inventory>>(
            //   future: InventoryDBHelper.instance.getInventories(),
            //   builder: (ctx, snap) {
            //     if (snap.connectionState == ConnectionState.waiting) {
            //       return Container(
            //         width: double.infinity,
            //         height: 120,
            //         decoration: BoxDecoration(
            //           color: Colors.grey[600],
            //           borderRadius: BorderRadius.circular(12),
            //         ),
            //         child: const Center(
            //           child: SizedBox(
            //             width: 32,
            //             height: 32,
            //             child: CircularProgressIndicator(color: Colors.white),
            //           ),
            //         ),
            //       );
            //     }
            //     if (snap.hasError) {
            //       return Container(
            //         width: double.infinity,
            //         padding: const EdgeInsets.all(16),
            //         decoration: BoxDecoration(
            //           color: Colors.red[400],
            //           borderRadius: BorderRadius.circular(12),
            //         ),
            //         child: Text(
            //           'خطأ في تحميل المخزون: ${snap.error}',
            //           style: const TextStyle(color: Colors.white),
            //         ),
            //       );
            //     }
            //
            //     final list = snap.data ?? [];
            //     if (list.isEmpty) {
            //       return Container(
            //         width: double.infinity,
            //         padding: const EdgeInsets.all(16),
            //         decoration: BoxDecoration(
            //           color: Colors.grey[600],
            //           borderRadius: BorderRadius.circular(12),
            //         ),
            //         child: const Text(
            //           'لا يوجد مخزون',
            //           style: TextStyle(color: Colors.white, fontSize: 16),
            //         ),
            //       );
            //     }
            //
            //     // Sort ascending by qty so lowest appear first
            //     list.sort((a, b) {
            //       final aq = int.tryParse(a.quantity) ?? 0;
            //       final bq = int.tryParse(b.quantity) ?? 0;
            //       return aq.compareTo(bq);
            //     });
            //
            //     return Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         const Align(
            //           alignment: Alignment.centerRight,
            //           child: Padding(
            //             padding: EdgeInsets.only(bottom: 6),
            //             child: Text(
            //               'المخزون حسب المنتج',
            //               style: TextStyle(
            //                 color: Colors.black54,
            //                 fontSize: 14,
            //                 fontWeight: FontWeight.w600,
            //               ),
            //             ),
            //           ),
            //         ),
            //         Container(
            //           height: 120,
            //           decoration: BoxDecoration(
            //             color: Colors.grey[200],
            //             borderRadius: BorderRadius.circular(12),
            //           ),
            //           child: SingleChildScrollView(
            //             scrollDirection: Axis.horizontal,
            //             padding: const EdgeInsets.symmetric(
            //                 horizontal: 10, vertical: 8),
            //             child: Row(
            //               children: list.map((inv) {
            //                 final qty = int.tryParse(inv.quantity) ?? 0;
            //                 Color bg;
            //                 Color txt = Colors.white;
            //                 if (qty <= 5) {
            //                   bg = Colors.red.shade600;
            //                 } else if (qty <= 10) {
            //                   bg = Colors.amber.shade700;
            //                   txt = Colors.black;
            //                 } else {
            //                   bg = Colors.blueGrey.shade700;
            //                 }
            //
            //                 return Container(
            //                   width: 170,
            //                   margin: const EdgeInsets.symmetric(horizontal: 6),
            //                   padding: const EdgeInsets.all(10),
            //                   decoration: BoxDecoration(
            //                     color: bg,
            //                     borderRadius: BorderRadius.circular(10),
            //                     boxShadow: [
            //                       BoxShadow(
            //                         color: Colors.black.withOpacity(0.15),
            //                         blurRadius: 4,
            //                         offset: const Offset(0, 2),
            //                       )
            //                     ],
            //                   ),
            //                   child: Column(
            //                     crossAxisAlignment: CrossAxisAlignment.start,
            //                     children: [
            //                       Expanded(
            //                         child: Text(
            //                           _productDisplayName(inv),
            //                           maxLines: 2,
            //                           overflow: TextOverflow.ellipsis,
            //                           textDirection: TextDirection.rtl,
            //                           style: TextStyle(
            //                             color: txt,
            //                             fontSize: 14,
            //                             fontWeight: FontWeight.w600,
            //                             height: 1.25,
            //                           ),
            //                         ),
            //                       ),
            //                       const SizedBox(height: 6),
            //                       Row(
            //                         children: [
            //                           Icon(Icons.inventory_2,
            //                               size: 18,
            //                               color: txt.withOpacity(0.9)),
            //                           const SizedBox(width: 4),
            //                           Text(
            //                             qty.toString(),
            //                             style: TextStyle(
            //                               color: txt,
            //                               fontSize: 18,
            //                               fontWeight: FontWeight.bold,
            //                             ),
            //                           ),
            //                         ],
            //                       ),
            //                       // NEW: warning line when qty < 5
            //                       if (qty < 5)
            //                         Padding(
            //                           padding: const EdgeInsets.only(top: 4),
            //                           child: Text(
            //                             'تحذير الكمية قليله جدا',
            //                             textDirection: TextDirection.rtl,
            //                             style: TextStyle(
            //                               color: txt,
            //                               fontSize: 11,
            //                               fontWeight: FontWeight.w600,
            //                             ),
            //                             maxLines: 1,
            //                             overflow: TextOverflow.ellipsis,
            //                           ),
            //                         ),
            //                     ],
            //                   ),
            //                 );
            //               }).toList(),
            //             ),
            //           ),
            //         ),
            //       ],
            //     );
            //   },
            // ),

            const SizedBox(height: 16),

            // ─── Grid of Navigation Tiles ───────────────────────────────
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildTile(
                    Icons.barcode_reader,
                    'ماسح ضوئي',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Scan()),
                    ),
                  ),
                  _buildTile(
                    Icons.all_inbox,
                    'المخزون',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InventoryList()),
                    ),
                  ),
                  _buildTile(
                    Icons.nature_people,
                    'تسليم مواد',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DisbursementList()),
                    ),
                  ),
                  _buildTile(
                    Icons.people,
                    'جرد',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CustodyListScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
