import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/inventory.dart';

class InventoryDBHelper {
  InventoryDBHelper._();

  static final InventoryDBHelper instance = InventoryDBHelper._();
  final _col = FirebaseFirestore.instance.collection('inventory');

  Future<List<Inventory>> getInventories() async {
    final snap = await _col.orderBy('id', descending: true).get();
    return snap.docs.map((d) {
      final data = d.data();
      return Inventory.fromMap(data);
    }).toList();
  }

  /// Get single inventory item by its `code`
  Future<Inventory?> getInventoryByCode(String code) async {
    final snap = await _col.where('code', isEqualTo: code).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return Inventory.fromMap(snap.docs.first.data());
  }

  Future<void> add(Inventory item) async {
    await _col.doc(item.code).set(item.toMap());
  }

  Future<void> update(Inventory item) async {
    await _col.doc(item.code).update(item.toMap());
  }

  Future<void> remove(String code) async {
    await _col.doc(code).delete();
  }

  /// Sum of all quantities in inventory
  Future<int> sumQty() async {
    final list = await getInventories();
    return list.fold<int>(
      0,
      (int sum, item) => sum + int.parse(item.quantity),
    );
  }

  Future<int> numProducts() async {
    final list = await getInventories();
    return list.length;
  }

  /// Aggregate quantities per product label for the dashboard horizontal summary.
  ///
  /// By default each item is labeled as "<brand> <variety>" (e.g., "Canon 6030").
  /// You can override the label with [labelBuilder] if you prefer grouping by another field,
  /// e.g. (inv) => inv.code or "${inv.brand} ${inv.colour}".
  Future<List<Map<String, dynamic>>> fetchQtyPerProduct({
    String Function(Inventory inv)? labelBuilder,
  }) async {
    final items = await getInventories();

    // Group totals by chosen label
    final Map<String, int> totals = {};
    for (final inv in items) {
      // Default label: "Brand Variety"
      final String label =
          (labelBuilder != null) ? labelBuilder(inv) : _defaultLabel(inv);

      final int q = int.tryParse(inv.quantity) ?? 0;
      if (label.trim().isEmpty) continue; // skip unlabeled entries safely
      totals.update(label, (old) => old + q, ifAbsent: () => q);
    }

    // Convert to List<Map> and sort by name (RTL-friendly too)
    final rows = totals.entries
        .map((e) => <String, dynamic>{'name': e.key, 'qty': e.value})
        .toList()
      ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

    return rows;
  }

  // Helper used by fetchQtyPerProduct
  String _defaultLabel(Inventory inv) {
    final parts = <String>[
      (inv.brand).toString().trim(),
      (inv.variety).toString().trim(),
    ].where((s) => s.isNotEmpty).toList();

    // Fallback to code if both brand & variety are empty
    if (parts.isEmpty) {
      final code = (inv.code).toString().trim();
      return code.isNotEmpty ? code : 'بدون اسم';
    }
    return parts.join(' ');
  }
}
