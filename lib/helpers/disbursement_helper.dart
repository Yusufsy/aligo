import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aligo/models/disbursement.dart';

class DisbursementDBHelper {
  DisbursementDBHelper._();

  static final DisbursementDBHelper instance = DisbursementDBHelper._();

  final CollectionReference _col =
      FirebaseFirestore.instance.collection('disbursements');
  final CollectionReference _inventoryCol =
      FirebaseFirestore.instance.collection('inventory');

  /// Create a deterministic document id to avoid duplicates
  /// (employeeRefId + productId + calendar day).
  /// Adjust the granularity (e.g. include hour/minute) if you want finer uniqueness.
  String buildDeterministicId({
    required String employeeRefId,
    required String productId,
    required DateTime date,
  }) {
    final day = DateTime(date.year, date.month, date.day);
    final dayStr = "${day.year.toString().padLeft(4, '0')}"
        "${day.month.toString().padLeft(2, '0')}"
        "${day.day.toString().padLeft(2, '0')}";
    return "${employeeRefId}_${productId}_$dayStr";
  }

  /// Add a disbursement, optionally deduplicating (merging quantity)
  /// and always atomically decrementing inventory.
  ///
  /// Throws an Exception if insufficient stock or doc conflict issues.
  Future<void> addDisbursement({
    required Disbursement disbursement,
    bool deduplicate = true,
  }) async {
    final now = DateTime.now();
    final productId = disbursement.productId;
    final employeeRef = disbursement.employeeRefId;
    final quantityToDisburse = int.parse(disbursement.quantity);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      // 1. Inventory doc
      final invRef = _inventoryCol.doc(productId);
      final invSnap = await tx.get(invRef);
      if (!invSnap.exists) {
        throw Exception("Inventory item '$productId' not found.");
      }

      final invData = invSnap.data() as Map<String, dynamic>;
      // Accept quantity stored as string or int
      final rawQty = invData['quantity'];
      int currentQty;
      if (rawQty is int) {
        currentQty = rawQty;
      } else if (rawQty is String) {
        currentQty = int.tryParse(rawQty) ?? 0;
      } else {
        currentQty = 0;
      }

      if (currentQty < quantityToDisburse) {
        throw Exception(
            "Insufficient stock. Available: $currentQty, requested: $quantityToDisburse");
      }

      // 2. Prepare disbursement doc reference
      DocumentReference disbRef;
      if (deduplicate) {
        final deterministicId = buildDeterministicId(
          employeeRefId: employeeRef,
          productId: productId,
          date: now,
        );
        disbRef = _col.doc(deterministicId);

        final existingSnap = await tx.get(disbRef);
        if (existingSnap.exists) {
          // Merge / increment existing quantity
          final existing = existingSnap.data() as Map<String, dynamic>;
          final existingQtyRaw = existing['quantity'];
          int existingQty;
          if (existingQtyRaw is int) {
            existingQty = existingQtyRaw;
          } else if (existingQtyRaw is String) {
            existingQty = int.tryParse(existingQtyRaw) ?? 0;
          } else {
            existingQty = 0;
          }
          final newQty = existingQty + quantityToDisburse;

          tx.update(disbRef, {
            'quantity': newQty.toString(),
            'updatedAt': FieldValue.serverTimestamp(),
            // Optionally update signature only if you want latest:
            'signature': disbursement.signatureBase64,
          });
        } else {
          tx.set(disbRef, {
            ...disbursement.toMap(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // Let Firestore generate ID
        disbRef = _col.doc();
        tx.set(disbRef, {
          ...disbursement.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 3. Decrement inventory
      final newInventoryQty = currentQty - quantityToDisburse;
      tx.update(invRef, {'quantity': newInventoryQty.toString()});
    });
  }

  /// Update an existing disbursement (does NOT adjust inventory).
  /// Provide the document id you want to update.
  Future<void> update(String disbursementDocId, Map<String, dynamic> update) {
    return _col.doc(disbursementDocId).update({
      ...update,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a disbursement; optionally re-stock inventory (pass restock=true).
  /// NOTE: Only restock if that business rule applies (normally disbursements are final).
  Future<void> delete(String disbursementDocId, {bool restock = false}) async {
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final ref = _col.doc(disbursementDocId);
      final snap = await tx.get(ref);
      if (!snap.exists) {
        return;
      }
      final data = snap.data() as Map<String, dynamic>;
      final productId = data['productId']?.toString();
      final quantityRaw = data['quantity'];
      int qty;
      if (quantityRaw is int) {
        qty = quantityRaw;
      } else if (quantityRaw is String) {
        qty = int.tryParse(quantityRaw) ?? 0;
      } else {
        qty = 0;
      }

      tx.delete(ref);

      if (restock && productId != null) {
        final invRef = _inventoryCol.doc(productId);
        final invSnap = await tx.get(invRef);
        if (invSnap.exists) {
          final invData = invSnap.data() as Map<String, dynamic>;
          final invQtyRaw = invData['quantity'];
          int invQty;
          if (invQtyRaw is int) {
            invQty = invQtyRaw;
          } else if (invQtyRaw is String) {
            invQty = int.tryParse(invQtyRaw) ?? 0;
          } else {
            invQty = 0;
          }
          tx.update(invRef, {'quantity': (invQty + qty).toString()});
        }
      }
    });
  }

  // ---------------- Queries / Aggregations ----------------

  /// Generic date filter helper
  Query _applyDateFilter(Query base, String? filter) {
    if (filter == null) return base;
    final now = DateTime.now();
    DateTime start;
    if (filter == 'day') {
      start = DateTime(now.year, now.month, now.day);
    } else if (filter == 'month') {
      start = now.subtract(const Duration(days: 30));
    } else if (filter == 'year') {
      start = DateTime(now.year);
    } else {
      return base;
    }
    // Assuming stored dateOfDisbursement is a YYYY-MM-DD string or ISO.
    return base.where('dateOfDisbursement',
        isGreaterThanOrEqualTo: start.toIso8601String().substring(0, 10));
  }

  Future<List<Disbursement>> getDisbursements({String? filter}) async {
    Query q = _col.orderBy('createdAt', descending: true);
    q = _applyDateFilter(q, filter);
    final snap = await q.get();
    return snap.docs
        .map((d) => Disbursement.fromMap(d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<Disbursement>> getDisbursementsByMonth() =>
      getDisbursements(filter: 'month');

  Future<int> sumQty(String? filter) async {
    final list = await getDisbursements(filter: filter);
    return list.fold<int>(
        0, (sum, d) => sum + int.tryParse(d.quantity)!.toInt());
  }

  Future<int> numDisbursements(String? filter) async {
    final list = await getDisbursements(filter: filter);
    return list.length;
  }

  Future<List<Disbursement>> getByStaff({
    required String employeeRefId,
    String? dateFilter,
  }) async {
    Query q = _col
        .where('employeeRefId', isEqualTo: employeeRefId)
        .orderBy('createdAt', descending: true);
    q = _applyDateFilter(q, dateFilter);
    final snap = await q.get();
    return snap.docs
        .map((d) => Disbursement.fromMap(d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<int> numByStaff(String employeeRefId, String? filter) async {
    final list =
        await getByStaff(employeeRefId: employeeRefId, dateFilter: filter);
    return list.length;
  }

  Future<int> qtyByStaff(String employeeRefId, String? filter) async {
    final list =
        await getByStaff(employeeRefId: employeeRefId, dateFilter: filter);
    return list.fold<int>(
      0,
      (sum, d) => sum + int.tryParse(d.quantity)!,
    );
  }
}
