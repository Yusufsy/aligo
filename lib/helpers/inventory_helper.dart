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
}
