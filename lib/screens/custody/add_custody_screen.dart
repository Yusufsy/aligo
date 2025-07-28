import 'dart:convert';
import 'dart:typed_data';

import 'package:aligo/components/aligo_appbar.dart';
import 'package:aligo/components/aligo_drawer.dart';
import 'package:aligo/models/custody_record.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class AddCustodyScreen extends StatefulWidget {
  const AddCustodyScreen({Key? key}) : super(key: key);

  @override
  State<AddCustodyScreen> createState() => _AddCustodyScreenState();
}

class _AddCustodyScreenState extends State<AddCustodyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  // Employees dropdown
  List<Map<String, dynamic>> employees = [];
  bool _loadingEmployees = true;
  String? _selectedEmployeeName;

  // Computer Type
  String? _selectedComputerType;
  final List<String> _computerTypes = ['laptop', 'desktop'];

  // Optional fields
  final _laptopSnCtrl = TextEditingController();
  final _caseModelCtrl = TextEditingController();
  final _keyboardCtrl = TextEditingController();
  final _mouseCtrl = TextEditingController();
  final _monitorCtrl = TextEditingController();
  final _printerCtrl = TextEditingController();
  final _upsCtrl = TextEditingController();
  final _scannerCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _levelCtrl = TextEditingController();
  final _cpuCtrl = TextEditingController();
  final _hashMarksCtrl = TextEditingController();
  final _ip1Ctrl = TextEditingController();
  final _ip2Ctrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Signature
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  String? _signatureBase64;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    setState(() => _loadingEmployees = true);
    try {
      final snapshot = await _firestore.collection('employees').get();
      employees = snapshot.docs.map((doc) {
        return {'id': doc.id, 'name': doc['name'] as String};
      }).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load employees: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingEmployees = false);
    }
  }

  /// Called when user submits a name that isn't in the list
  Future<void> _addEmployee(String name) async {
    final doc = await _firestore.collection('employees').add({'name': name});
    // refresh local list
    await fetchEmployees();
    // select the newly added name
    setState(() => _selectedEmployeeName = name);
  }

  Future<void> _openSignatureDialog() async {
    _signatureController.clear();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة التوقيع'),
        content: SizedBox(
          width: 340,
          height: 250,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    color: Colors.white,
                  ),
                  child: Signature(
                    controller: _signatureController,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _signatureController.clear(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('واضح'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (_signatureController.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('من فضلك ارسم التوقيع أولا.')),
                        );
                        return;
                      }
                      final Uint8List? data =
                          await _signatureController.toPngBytes();
                      if (data != null) {
                        setState(() => _signatureBase64 = base64Encode(data));
                        if (mounted) Navigator.of(ctx).pop();
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('يحفظ'),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_signatureBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signature is required.')),
      );
      return;
    }
    setState(() => _saving = true);

    final record = CustodyRecord(
      name: _selectedEmployeeName!,
      signatureBase64: _signatureBase64!,
      computerType: _selectedComputerType,
      laptopSn: _selectedComputerType == 'laptop'
          ? _emptyToNull(_laptopSnCtrl.text)
          : null,
      caseModel: _emptyToNull(_caseModelCtrl.text),
      keyboard: _emptyToNull(_keyboardCtrl.text),
      mouse: _emptyToNull(_mouseCtrl.text),
      monitor: _emptyToNull(_monitorCtrl.text),
      printer: _emptyToNull(_printerCtrl.text),
      ups: _emptyToNull(_upsCtrl.text),
      scanner: _emptyToNull(_scannerCtrl.text),
      department: _emptyToNull(_departmentCtrl.text),
      level: _emptyToNull(_levelCtrl.text),
      cpu: _emptyToNull(_cpuCtrl.text),
      hashMarks: _emptyToNull(_hashMarksCtrl.text),
      ip1: _emptyToNull(_ip1Ctrl.text),
      ip2: _emptyToNull(_ip2Ctrl.text),
      notes: _emptyToNull(_notesCtrl.text),
    );

    try {
      await _firestore.collection('custody').add(record.toMap());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Custody record saved.')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving record: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _emptyToNull(String? v) {
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  @override
  void dispose() {
    _laptopSnCtrl.dispose();
    _caseModelCtrl.dispose();
    _keyboardCtrl.dispose();
    _mouseCtrl.dispose();
    _monitorCtrl.dispose();
    _printerCtrl.dispose();
    _upsCtrl.dispose();
    _scannerCtrl.dispose();
    _departmentCtrl.dispose();
    _levelCtrl.dispose();
    _cpuCtrl.dispose();
    _hashMarksCtrl.dispose();
    _ip1Ctrl.dispose();
    _ip2Ctrl.dispose();
    _notesCtrl.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      maxLines: maxLines,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: const AligoAppbar(title: 'إضافة الحضانة'),
      drawer: const AligoDrawer(),
      body: _loadingEmployees
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: AbsorbPointer(
                absorbing: _saving,
                child: Stack(
                  children: [
                    ListView(padding: const EdgeInsets.all(16), children: [
                      // ─────── Name with Autocomplete ───────
                      Autocomplete<String>(
                        optionsBuilder: (textEditingValue) {
                          final q = textEditingValue.text.toLowerCase();
                          return employees
                              .map((e) => e['name'] as String)
                              .where((name) => name.toLowerCase().contains(q))
                              .toList();
                        },
                        onSelected: (sel) =>
                            setState(() => _selectedEmployeeName = sel),
                        fieldViewBuilder: (
                          context,
                          textController,
                          focusNode,
                          onFieldSubmitted,
                        ) {
                          // Initialize with selected if any
                          textController.text = _selectedEmployeeName ?? '';
                          return TextFormField(
                            controller: textController,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'الاسم *',
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.done,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Required' : null,
                            onFieldSubmitted: (value) async {
                              final trimmed = value.trim();
                              if (trimmed.isEmpty) return;
                              if (!employees.any((e) =>
                                  (e['name'] as String).toLowerCase() ==
                                  trimmed.toLowerCase())) {
                                // add new employee
                                await _addEmployee(trimmed);
                              } else {
                                setState(() => _selectedEmployeeName = trimmed);
                              }
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 12),
                      // ─────── Computer Type Dropdown ───────
                      DropdownButtonFormField<String>(
                        value: _selectedComputerType,
                        decoration: const InputDecoration(
                          labelText: 'Computer Type',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: _computerTypes
                            .map((t) =>
                                DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedComputerType = v;
                            if (v != 'laptop') _laptopSnCtrl.clear();
                          });
                        },
                      ),

                      const SizedBox(height: 12),
                      if (_selectedComputerType == 'laptop') ...[
                        _buildTextField('Laptop SN', _laptopSnCtrl),
                        const SizedBox(height: 12),
                      ],

                      _buildTextField('Case Model', _caseModelCtrl),
                      const SizedBox(height: 12),
                      _buildTextField('Keyboard', _keyboardCtrl),
                      const SizedBox(height: 12),
                      _buildTextField('Mouse', _mouseCtrl),
                      const SizedBox(height: 12),
                      _buildTextField('Monitor', _monitorCtrl),
                      const SizedBox(height: 12),
                      _buildTextField('Printer', _printerCtrl),
                      const SizedBox(height: 12),
                      _buildTextField('UPS', _upsCtrl),
                      const SizedBox(height: 12),
                      _buildTextField('Scanner', _scannerCtrl),
                      const SizedBox(height: 12),
                      _buildTextField('Department', _departmentCtrl),
                      const SizedBox(height: 12),
                      _buildTextField('Level', _levelCtrl),
                      const SizedBox(height: 12),
                      _buildTextField('CPU', _cpuCtrl),
                      const SizedBox(height: 12),
                      _buildTextField('##', _hashMarksCtrl),
                      const SizedBox(height: 12),
                      _buildTextField('IP_1', _ip1Ctrl),
                      const SizedBox(height: 12),
                      _buildTextField('IP_2', _ip2Ctrl),
                      const SizedBox(height: 12),
                      _buildTextField('Notes', _notesCtrl, maxLines: 3),
                      const SizedBox(height: 20),

                      // Signature
                      Text('Signature *', style: tema.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _openSignatureDialog,
                        child: Container(
                          height: 140,
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.green),
                                    SizedBox(height: 6),
                                    Text('Signature captured'),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Custody Record'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ]),
                    if (_saving)
                      Container(
                        color: Colors.black.withOpacity(0.15),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
