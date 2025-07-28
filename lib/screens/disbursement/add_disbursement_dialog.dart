import 'dart:convert';
import 'package:aligo/helpers/disbursement_helper.dart';
import 'package:aligo/models/disbursement.dart';
import 'package:aligo/models/inventory.dart';
import 'package:aligo/screens/disbursement/disbursement_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';

class AddDisbursementDialog extends StatefulWidget {
  final Inventory inventory;

  const AddDisbursementDialog({super.key, required this.inventory});

  @override
  State<AddDisbursementDialog> createState() => _AddDisbursementDialogState();
}

class _AddDisbursementDialogState extends State<AddDisbursementDialog> {
  int qty = 1;

  // ─── Employee state ─────────────────────────────────────────
  String? _selectedEmployeeDocId;
  String? _selectedEmployeeNumber;
  List<Map<String, dynamic>> employees = [];
  bool _loadingEmployees = true;

  // ─── Signature ───────────────────────────────────────────────
  final SignatureController _sigController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  String? _signatureBase64;

  bool _saving = false;

  int get _maxAvailable =>
      int.tryParse(widget.inventory.quantity) ?? 0; // safeguard

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    setState(() => _loadingEmployees = true);
    try {
      final snap =
          await FirebaseFirestore.instance.collection('employees').get();
      employees = snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return {
          'id': d.id,
          'name': data['name'] as String,
          'number': data.containsKey('number') ? data['number'] : null,
        };
      }).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load employees: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingEmployees = false);
    }
  }

  /// If user enters a new name, add it to employees collection.
  Future<void> _addEmployee(String name) async {
    final doc = await FirebaseFirestore.instance
        .collection('employees')
        .add({'name': name});
    await _fetchEmployees();
    setState(() => _selectedEmployeeDocId = doc.id);
  }

  Future<void> _openSignatureDialog() async {
    _sigController.clear();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة التوقيع'),
        content: SizedBox(
          width: 340,
          height: 260,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    color: Colors.white,
                  ),
                  child: Signature(
                    controller: _sigController,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _sigController.clear(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('واضح'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (_sigController.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('الرجاء رسم التوقيع أولا')),
                        );
                        return;
                      }
                      final bytes = await _sigController.toPngBytes();
                      if (bytes != null) {
                        setState(() => _signatureBase64 = base64Encode(bytes));
                        Navigator.of(ctx).pop();
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('يحفظ'),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  bool get _canSubmit =>
      !_saving &&
      _signatureBase64 != null &&
      _selectedEmployeeDocId != null &&
      qty > 0 &&
      qty <= _maxAvailable;

  Future<void> _addDisbursement() async {
    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill required fields & signature')),
      );
      return;
    }
    setState(() => _saving = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final disb = Disbursement(
        employeeRefId: _selectedEmployeeDocId!,
        employeeNumber: _selectedEmployeeNumber,
        productId: widget.inventory.code.toString(),
        quantity: qty.toString(),
        dateOfDisbursement: dateStr,
        signatureBase64: _signatureBase64!,
      );

      // Assumes helper handles dedup and stock decrement
      await DisbursementDBHelper.instance.addDisbursement(
        disbursement: disb,
        deduplicate: false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disbursement recorded')),
      );

      // close and refresh
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DisbursementList()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _sigController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("عملية الصرف"),
      content: SizedBox(
        width: 500,
        child: _loadingEmployees
            ? const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              )
            : AbsorbPointer(
                absorbing: _saving,
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ── Product Preview ─────────────────────
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              widget.inventory.imageUrl,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.image_not_supported,
                                  size: 80),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(widget.inventory.brand,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          Text(widget.inventory.variety),
                          Text("Colour: ${widget.inventory.colour}",
                              style: const TextStyle(color: Colors.grey)),
                          Text("$_maxAvailable in stock",
                              style: TextStyle(
                                  color: _maxAvailable > 0
                                      ? Colors.grey
                                      : Colors.red,
                                  fontSize: 12)),
                          const SizedBox(height: 12),

                          // ── Employee Autocomplete ───────────────
                          Autocomplete<String>(
                            optionsBuilder: (txt) {
                              final q = txt.text.toLowerCase();
                              return employees
                                  .map((e) => e['name'] as String)
                                  .where(
                                      (name) => name.toLowerCase().contains(q))
                                  .toList();
                            },
                            onSelected: (name) {
                              final match = employees
                                  .firstWhere((e) => e['name'] == name);
                              setState(() {
                                _selectedEmployeeDocId = match['id'];
                                _selectedEmployeeNumber =
                                    match['number']?.toString();
                              });
                            },
                            fieldViewBuilder:
                                (ctx, textCtrl, focusNode, onFieldSubmitted) {
                              textCtrl.text = _selectedEmployeeDocId == null
                                  ? ''
                                  : employees.firstWhere((e) =>
                                      e['id'] ==
                                      _selectedEmployeeDocId)['name'] as String;
                              return TextFormField(
                                controller: textCtrl,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.person_outline),
                                  labelText: "Employee *",
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                textInputAction: TextInputAction.done,
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Required' : null,
                                onFieldSubmitted: (value) async {
                                  final trimmed = value.trim();
                                  if (trimmed.isEmpty) return;
                                  final matches = employees
                                      .where((e) =>
                                          (e['name'] as String).toLowerCase() ==
                                          trimmed.toLowerCase())
                                      .toList();
                                  if (matches.isEmpty) {
                                    await _addEmployee(trimmed);
                                  } else {
                                    final m = matches.first;
                                    setState(() {
                                      _selectedEmployeeDocId =
                                          m['id'] as String;
                                      _selectedEmployeeNumber =
                                          m['number']?.toString();
                                    });
                                  }
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 14),

                          // ── Quantity Selector ──────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Quantity: "),
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: qty > 1 && !_saving
                                    ? () => setState(() => qty -= 1)
                                    : null,
                                visualDensity: VisualDensity.compact,
                              ),
                              Text(qty.toString(),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: qty < _maxAvailable && !_saving
                                    ? () => setState(() => qty += 1)
                                    : null,
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          if (qty > _maxAvailable)
                            const Text(
                              'Cannot exceed stock.',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          const SizedBox(height: 16),

                          // ── Signature ─────────────────────────
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Signature *',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: _openSignatureDialog,
                            child: Container(
                              height: 110,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _signatureBase64 == null
                                      ? Colors.redAccent
                                      : Colors.grey.shade400,
                                ),
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: _signatureBase64 == null
                                  ? const Text(
                                      'Tap to add signature',
                                      style: TextStyle(color: Colors.black54),
                                    )
                                  : const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle,
                                            color: Colors.green),
                                        SizedBox(height: 4),
                                        Text(
                                          'Signature captured',
                                          style:
                                              TextStyle(color: Colors.black87),
                                        )
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Actions ──────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: _saving
                                    ? null
                                    : () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 40,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _canSubmit ? _addDisbursement : null,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14),
                                    minimumSize: const Size(110, 40),
                                  ),
                                  icon: _saving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.save,
                                          size: 18,
                                        ),
                                  label: Text(_saving ? 'توفير...' : 'سِجِلّ'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_saving)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.08),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
