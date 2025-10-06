import 'dart:convert';
import 'dart:typed_data';

import 'package:aligo/components/aligo_appbar.dart';
import 'package:aligo/components/aligo_drawer.dart';
import 'package:aligo/screens/custody/custody_list_screen.dart'; // CustodyRecordRead
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' as excl;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';

class AddCustodyScreen extends StatefulWidget {
  final CustodyRecordRead? initialRecord;

  const AddCustodyScreen({Key? key, this.initialRecord}) : super(key: key);

  @override
  State<AddCustodyScreen> createState() => _AddCustodyScreenState();
}

class _AddCustodyScreenState extends State<AddCustodyScreen> {
  // ---------- Excel config ----------
  static const String kExcelAsset = 'assets/latest2.xlsx';
  static const List<String> kPreferredSheets = ['Sheet1'];

  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  // Employees
  List<Map<String, dynamic>> employees = [];
  bool _loadingEmployees = true;
  String? _selectedEmployeeName;
  final TextEditingController _nameCtrl = TextEditingController();

  // ======= Dynamic MULTI-SELECT options (from Excel) =======
  List<String> _computerTypeOptions = [];
  final Set<String> _computerTypes = {};

  // Desktop case-model options
  List<String> _caseModelOptions = [];

  // Laptop model options (from "لابتوب"/Laptop Model)
  List<String> _caseModelLaptopOptions = [];
  final Set<String> _caseModels = {};

  List<String> _keyboardOptions = [];
  final Set<String> _keyboard = {};

  List<String> _mouseOptions = [];
  final Set<String> _mouse = {};

  List<String> _monitorOptions = [];
  final Set<String> _monitor = {};

  List<String> _printerOptions = [];
  final Set<String> _printer = {};

  List<String> _upsOptions = [];
  final Set<String> _ups = {};

  List<String> _scannerOptions = [];
  final Set<String> _scanner = {};

  List<String> _departmentOptions = [];
  final Set<String> _department = {};

  List<String> _levelOptions = [];
  final Set<String> _level = {};

  // PC-SN options (we keep using Set _cpu to preserve Firestore field name)
  List<String> _pcSnOptions = [];
  final Set<String> _cpu = {}; // <-- will hold PC-SN values; saved as 'cpu'

  // Laptop SN input (shown only if a laptop-like type is selected)
  final _laptopSnCtrl = TextEditingController();

  // ======= Hidden (SENSITIVE/LOCKED) text inputs =======
  final _hashMarksCtrl = TextEditingController(); // "#serial number"
  final _ip1Ctrl = TextEditingController(); // IP_1
  final _ip2Ctrl = TextEditingController(); // IP_2
  final _notesCtrl = TextEditingController(); // Notes
  final _biosSnCtrl = TextEditingController(); // BIOS S/N
  final _uuidCtrl = TextEditingController(); // UUID

  // Signature
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  String? _signatureBase64;

  bool _saving = false;

  bool get _isEdit => widget.initialRecord != null;

  // ======= Login info (SharedPreferences) for unlock =======
  String? _currentStaffId;
  String? _currentStaffName;
  bool _sensitiveUnlocked = false;

  // ======= Arabic labels (from Excel if available) =======
  // key -> Arabic label
  final Map<String, String> _arLabel = {};

  // Fallback Arabic labels
  final Map<String, String> _arFallback = const {
    'name': 'الاسم',
    'computerType': 'نوع الحاسوب',
    'laptopSN': 'لابتوب سيريل نمبر',
    'caseModel': 'موديل الكيس',
    'laptopModel': 'موديل اللابتوب',
    'keyboard': 'لوحة مفاتيح',
    'mouse': 'فأرة',
    'monitor': 'شاشة',
    'printer': 'طابعة',
    'ups': 'مزود طاقة (UPS)',
    'scanner': 'ماسح ضوئي',
    'department': 'القسم',
    'level': 'المستوى',
    'pcSN': 'PC-SN',
    'hashMarks': 'الرقم التسلسلي',
    'ip_1': 'عنوان IP 1',
    'ip_2': 'عنوان IP 2',
    'biosSN': 'BIOS S/N',
    'uuid': 'UUID',
    'notes': 'ملاحظات',
    'signature': 'التوقيع',
    'advanced': 'حقول متقدمة',
    'unlock': 'فتح',
    'locked': 'مقفلة — اضغط فتح',
    'unlocked': 'حقول متقدمة (تم فتحها)',
    'addCustom': 'أضف قيمة مخصصة',
    'clear': 'مسح',
    'done': 'تم',
  };

  String _label(String key) => _arLabel[key] ?? _arFallback[key] ?? key;

  // Detect if an option means "laptop" (Arabic/English)
  bool _isLaptopValue(String v) {
    final s = v.toLowerCase();
    return s.contains('laptop') ||
        s.contains('lap top') ||
        s.contains('notebook') ||
        v.contains('لاب') ||
        v.contains('لابتوب') ||
        v.contains('حاسوب محمول') ||
        v.contains('نوت بوك');
  }

  bool get _hasLaptop => _computerTypes.any(_isLaptopValue);

  @override
  void initState() {
    super.initState();
    _loadLoginInfo();
    _loadEmployees().then((_) {
      if (_isEdit) _populateFromInitial();
    });
    _loadOptionsFromExcel(); // Build labels & option lists
    // _maybeImportFromExcel(); // One-time importer with new mappings
  }

  // ================= Excel: read headers & options =================
  Future<void> _loadOptionsFromExcel() async {
    try {
      final bd = await rootBundle.load(kExcelAsset);
      final excel = excl.Excel.decodeBytes(bd.buffer.asUint8List());

      // Prefer "2025" then "Sheet1", else first sheet
      excl.Sheet? sheet;
      for (final name in kPreferredSheets) {
        sheet = excel.tables[name];
        if (sheet != null) break;
      }
      sheet ??=
          excel.tables.values.isNotEmpty ? excel.tables.values.first : null;

      if (sheet == null || sheet.rows.isEmpty) return;

      // Map header -> column index (using AR/EN synonyms)
      final headerRow = sheet.rows.first;
      final headerMap = _buildHeaderMap(headerRow);

      // Use header text as Arabic label if present
      void setLabelFromHeader(String key) {
        final col = headerMap[key];
        if (col != null && col >= 0 && col < headerRow.length) {
          final raw = (headerRow[col]?.value ?? '').toString().trim();
          if (raw.isNotEmpty) _arLabel[key] = raw;
        }
      }

      for (final k in [
        'name',
        'computerType',
        'laptopSN',
        'caseModel',
        'laptopModel',
        'keyboard',
        'mouse',
        'monitor',
        'printer',
        'ups',
        'scanner',
        'department',
        'level',
        'pcSN', // PC-SN (will be stored under Firestore field 'cpu')
        'hashMarks',
        'ip_1',
        'ip_2',
        'biosSN',
        'uuid',
        'notes',
      ]) {
        setLabelFromHeader(k);
      }

      // Collect unique options per column (split by comma/; /)
      Set<String> collect(String key) {
        final col = headerMap[key];
        final set = <String>{};
        if (col == null) return set;
        for (var r = 1; r < sheet!.rows.length; r++) {
          final raw = _cell(sheet.rows[r], col);
          final csv = _normalizeCsv(raw);
          if (csv == null) continue;
          for (final part in csv.split(',')) {
            final v = part.trim();
            if (v.isNotEmpty) set.add(v);
          }
        }
        return set;
      }

      _computerTypeOptions = collect('computerType').toList()..sort(_localeCmp);
      _caseModelOptions = collect('caseModel').toList()..sort(_localeCmp);
      _caseModelLaptopOptions = collect('laptopModel').toList()
        ..sort(_localeCmp);

      _keyboardOptions = collect('keyboard').toList()..sort(_localeCmp);
      _mouseOptions = collect('mouse').toList()..sort(_localeCmp);
      _monitorOptions = collect('monitor').toList()..sort(_localeCmp);
      _printerOptions = collect('printer').toList()..sort(_localeCmp);
      _upsOptions = collect('ups').toList()..sort(_localeCmp);
      _scannerOptions = collect('scanner').toList()..sort(_localeCmp);
      _departmentOptions = collect('department').toList()..sort(_localeCmp);
      _levelOptions = collect('level').toList()..sort(_localeCmp);

      // PC-SN options (saved into 'cpu' field)
      _pcSnOptions = collect('pcSN').toList()..sort(_localeCmp);

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر قراءة ملف الإكسل: $e')),
        );
      }
    }
  }

  int _localeCmp(String a, String b) =>
      a.toLowerCase().compareTo(b.toLowerCase());

  /// Build a map of normalized header key -> column index from the first row.
  Map<String, int> _buildHeaderMap(List<excl.Data?> headerRow) {
    final Map<String, int> map = {};

    // Arabic/English synonyms per field
    final Map<String, List<String>> synonyms = {
      'name': ['name', 'employee', 'emp', 'الاسم'],
      'computerType': [
        'computer type',
        'computer types',
        'type',
        'device',
        'النوع',
        'computer',
        'نوع الجهاز',
        'نوع الحاسوب',
        'نوع الحاسبة',
        'نوع الكمبيوتر'
      ],
      'laptopSN': [
        'laptop sn',
        'serial',
        'sn',
        'serial number',
        'laptop serial',
        'laptop serial number',
        'سيريال',
        'سيريال اللابتوب',
        'الرقم التسلسلي للابتوب',
        'لابتوب سيريل نمبر',
        'سيريال لابتوب'
      ],
      'caseModel': [
        'case model',
        'case',
        'موديل الكيس',
        'موديل الجهاز',
        'موديل الحاسوب',
        'الكيس'
      ],
      'laptopModel': [
        'laptop model',
        'laptop',
        'موديل اللابتوب',
        'نوع اللابتوب',
        'لابتوب'
      ],
      'keyboard': ['keyboard', 'كيبورد', 'لوحة مفاتيح'],
      'mouse': ['mouse', 'ماوس', 'فأرة'],
      'monitor': ['monitor', 'screen', 'شاشة'],
      'printer': ['printer', 'طابعة'],
      'ups': ['ups', 'يو بي اس', 'مزود طاقة'],
      'scanner': ['scanner', 'سكانر', 'ماسح ضوئي'],
      'department': ['department', 'قسم', 'القسم'],
      'level': ['level', 'المستوى', 'الطابق'],
      // PC-SN (we will store in Firestore field 'cpu')
      'pcSN': [
        'pc-sn',
        'pc sn',
        'pc serial',
        'pc serial number',
        'pcsn',
        'سيريال الجهاز',
        'سيريال الحاسوب',
        'سيريال الكمبيوتر',
        'رقم جهاز',
        'رقم الحاسوب'
      ],
      'hashMarks': [
        '#',
        'hashmarks',
        'serial #',
        '#serial number',
        'الرقم التسلسلي'
      ],
      'ip_1': ['ip_1', 'ip1', 'ip 1', 'اي بي 1', 'عنوان ip 1', 'عنوان ip1'],
      'ip_2': ['ip_2', 'ip2', 'ip 2', 'اي بي 2', 'عنوان ip 2', 'عنوان ip2'],
      'biosSN': [
        'bios s/n',
        'bios sn',
        'bios serial',
        'bios',
        'بايوس',
        'سيريال البايوس'
      ],
      'uuid': ['uuid', 'يو يو آي دي', 'معرّف uuid'],
      'notes': ['notes', 'ملاحظات'],
    };

    String _norm(String s) =>
        s.toLowerCase().replaceAll('\n', ' ').replaceAll('\r', ' ').trim();

    for (int c = 0; c < headerRow.length; c++) {
      final cell = headerRow[c];
      final raw = (cell?.value ?? '').toString();
      if (raw.trim().isEmpty) continue;

      final hdr = _norm(raw);
      for (final entry in synonyms.entries) {
        for (final syn in entry.value) {
          if (hdr.contains(_norm(syn))) {
            map.putIfAbsent(entry.key, () => c);
          }
        }
      }
    }
    return map;
  }

  /// Get cell text from a row, given a (possibly-null) column index.
  String? _cell(List<excl.Data?> row, int? colIndex) {
    if (colIndex == null) return null;
    if (colIndex < 0 || colIndex >= row.length) return null;
    final v = row[colIndex]?.value;
    if (v == null) return null;
    return v.toString();
  }

  /// Normalize any delimited value into a comma-separated string ("A,B,C").
  String? _normalizeCsv(String? raw) {
    if (raw == null) return null;
    final t = raw.trim();
    if (t.isEmpty) return null;
    final parts = t
        .split(RegExp(r'[,/;]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    if (parts.isEmpty) return null;
    return parts.join(',');
  }

  // ================= One-time importer (updated mappings) =================
  Future<void> _maybeImportFromExcel() async {
    if (_isEdit) return; // Only on add screen
    try {
      final prefs = await SharedPreferences.getInstance();
      const flagKey = 'custody_import_2025_v2_done';
      if (prefs.getBool(flagKey) == true) return;

      final bd = await rootBundle.load(kExcelAsset);
      final excel = excl.Excel.decodeBytes(bd.buffer.asUint8List());

      // Choose sheet
      excl.Sheet? sheet;
      for (final name in kPreferredSheets) {
        sheet = excel.tables[name];
        if (sheet != null) break;
      }
      sheet ??=
          excel.tables.values.isNotEmpty ? excel.tables.values.first : null;

      if (sheet == null || sheet.rows.isEmpty) {
        _snack('لم يتم العثور على ورقة بيانات صالحة داخل ملف الإكسل.');
        return;
      }

      // Build header map
      final headerRow = sheet.rows.first;
      final headerMap = _buildHeaderMap(headerRow);

      if (!headerMap.containsKey('name')) {
        _snack('لا يوجد عمود للاسم في الصف الأول.');
        return;
      }

      final addedByName = _currentStaffName ?? 'Unknown';
      final addedById = _currentStaffId;

      WriteBatch batch = _firestore.batch();
      int inBatch = 0, totalAdded = 0;

      Future<void> commitIfNeeded() async {
        if (inBatch > 0) {
          await batch.commit();
          batch = _firestore.batch();
          inBatch = 0;
        }
      }

      for (int r = 1; r < sheet.rows.length; r++) {
        final row = sheet.rows[r];
        final name = _cell(row, headerMap['name'])?.trim();
        if (name == null || name.isEmpty) continue;

        String? csv(String key) => _normalizeCsv(_cell(row, headerMap[key]));
        String? txt(String key) => _cell(row, headerMap[key])?.trim();

        final computerTypeCsv = csv('computerType');
        final hasLaptop = (computerTypeCsv ?? '')
            .split(',')
            .any((v) => _isLaptopValue(v.trim()));

        // pick case model depending on laptop presence
        final caseModelCsv = hasLaptop
            ? csv('laptopModel') ?? csv('caseModel')
            : csv('caseModel');

        final data = <String, dynamic>{
          'name': name,
          'signature': '',
          // no signature in import
          'computerType': computerTypeCsv,
          'laptopSN': hasLaptop ? txt('laptopSN') : null,
          'caseModel': caseModelCsv,
          'keyboard': csv('keyboard'),
          'mouse': csv('mouse'),
          'monitor': csv('monitor'),
          'printer': csv('printer'),
          'ups': csv('ups'),
          'scanner': csv('scanner'),
          'department': csv('department'),
          'level': csv('level'),

          // repurposed: store PC-SN under 'cpu' for compatibility with list screen
          'cpu': csv('pcSN'),

          // Sensitive / hidden
          'hashMarks': txt('hashMarks'),
          'ip_1': txt('ip_1'),
          'ip_2': txt('ip_2'),
          'bios_sn': txt('biosSN'),
          'uuid': txt('uuid'),
          'notes': txt('notes'),

          'createdAt': FieldValue.serverTimestamp(),
          'added_by_name': addedByName,
          'added_by_id': addedById,
        };

        // normalize empty strings to null
        data.updateAll((k, v) => (v is String && v.trim().isEmpty) ? null : v);

        final docRef = _firestore.collection('custody').doc();
        batch.set(docRef, data);
        inBatch++;
        totalAdded++;

        if (inBatch >= 450) await commitIfNeeded();
      }

      await commitIfNeeded();
      await prefs.setBool(flagKey, true);
      _snack('تم استيراد $totalAdded سجلاً من الإكسل.');
    } catch (e) {
      _snack('فشل الاستيراد: $e');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= End Excel / Import helpers =================

  Future<void> _loadLoginInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _currentStaffId = prefs.getString('currentStaffId');
        _currentStaffName = prefs.getString('currentStaffName');
      });
    } catch (_) {}
  }

  Future<void> _loadEmployees() async {
    setState(() => _loadingEmployees = true);
    try {
      final snap = await _firestore.collection('employees').get();
      employees = snap.docs
          .map((d) => {'id': d.id, 'name': d['name'] as String})
          .toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load employees: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingEmployees = false);
    }
  }

  Set<String> _splitCSV(String? s) {
    if (s == null || s.trim().isEmpty) return {};
    return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
  }

  String? _joinOrNull(Set<String> s) => s.isEmpty ? null : s.join(',');

  void _populateFromInitial() {
    final r = widget.initialRecord!;
    _selectedEmployeeName = r.name;
    _nameCtrl.text = r.name;
    _signatureBase64 = r.signatureBase64;

    _computerTypes
      ..clear()
      ..addAll(_splitCSV(r.computerType));
    _laptopSnCtrl.text = r.laptopSn ?? '';

    _caseModels
      ..clear()
      ..addAll(_splitCSV(r.caseModel));
    _keyboard
      ..clear()
      ..addAll(_splitCSV(r.keyboard));
    _mouse
      ..clear()
      ..addAll(_splitCSV(r.mouse));
    _monitor
      ..clear()
      ..addAll(_splitCSV(r.monitor));
    _printer
      ..clear()
      ..addAll(_splitCSV(r.printer));
    _ups
      ..clear()
      ..addAll(_splitCSV(r.ups));
    _scanner
      ..clear()
      ..addAll(_splitCSV(r.scanner));
    _department
      ..clear()
      ..addAll(_splitCSV(r.department));
    _level
      ..clear()
      ..addAll(_splitCSV(r.level));

    // 'cpu' now represents PC-SN
    _cpu
      ..clear()
      ..addAll(_splitCSV(r.cpu));

    _hashMarksCtrl.text = r.hashMarks ?? '';
    _ip1Ctrl.text = r.ip1 ?? '';
    _ip2Ctrl.text = r.ip2 ?? '';
    _notesCtrl.text = r.notes ?? '';

    _syncLaptopSNVisibility();
    setState(() {});
  }

  Future<void> _addEmployee(String name) async {
    await _firestore.collection('employees').add({'name': name});
    await _loadEmployees();
    _selectedEmployeeName = name;
    _nameCtrl.text = name;
    setState(() {});
  }

  Future<void> _openSignatureDialog() async {
    _signatureController.clear();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isEdit
            ? 'تحديث ${_label('signature')}'
            : 'إضافة ${_label('signature')}'),
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
              Row(children: [
                TextButton.icon(
                  onPressed: () => _signatureController.clear(),
                  icon: const Icon(Icons.refresh),
                  label: Text(_arFallback['clear']!),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_signatureController.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'من فضلك أدخل ${_label('signature')} أولاً.')),
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
                  label: Text(_arFallback['done']!),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _syncLaptopSNVisibility() {
    if (!_hasLaptop) _laptopSnCtrl.clear();
    // When toggling laptop presence, it's safer to clear case model picks
    _caseModels.clear();
  }

  // ======= Generic Multi-select Picker (with field key) =======
  Future<void> _openMultiPicker({
    required String fieldKey, // <— 'computerType', 'caseModel', 'pcSN'...
    required String title,
    required List<String> options,
    required Set<String> selected,
    bool allowCustom = true,
  }) async {
    final temp = Set<String>.from(selected);
    final customCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title, textDirection: TextDirection.rtl),
          content: StatefulBuilder(
            builder: (context, setLocal) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (allowCustom) ...[
                      TextField(
                        controller: customCtrl,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          labelText: _arFallback['addCustom'],
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: (v) {
                          final t = v.trim();
                          if (t.isEmpty) return;
                          setLocal(() {
                            temp.add(t);
                          });
                          customCtrl.clear();
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    ...options.map((opt) {
                      final checked = temp.contains(opt);
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(opt, textDirection: TextDirection.rtl),
                        value: checked,
                        onChanged: (v) => setLocal(() {
                          if (v == true) {
                            temp.add(opt);
                          } else {
                            temp.remove(opt);
                          }
                        }),
                      );
                    }),
                    ...temp.where((e) => !options.contains(e)).map((custom) =>
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(custom, textDirection: TextDirection.rtl),
                          value: true,
                          onChanged: (v) {
                            if (v != true) {
                              setLocal(() {
                                temp.remove(custom);
                              });
                            }
                          },
                        )),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                temp.clear();
                Navigator.pop(ctx);
              },
              child: Text(_arFallback['clear']!),
            ),
            ElevatedButton(
              onPressed: () {
                final wasLaptop = _hasLaptop;
                Navigator.pop(ctx);
                setState(() {
                  selected
                    ..clear()
                    ..addAll(temp);

                  if (fieldKey == 'computerType') {
                    final nowLaptop = _computerTypes.any(_isLaptopValue);
                    if (wasLaptop != nowLaptop) {
                      _syncLaptopSNVisibility();
                    }
                  }
                });
              },
              child: Text(_arFallback['done']!),
            ),
          ],
        );
      },
    );
  }

  Widget _multiSelectField({
    required String fieldKey,
    required String label,
    required Set<String> selected,
    required List<String> options,
    bool allowCustom = true,
  }) {
    final summary = selected.isEmpty ? '...' : selected.join(', ');
    return InkWell(
      onTap: () => _openMultiPicker(
        fieldKey: fieldKey,
        title: label,
        options: options,
        selected: selected,
        allowCustom: allowCustom,
      ),
      borderRadius: BorderRadius.circular(6),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                summary,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: selected.isEmpty ? Colors.black54 : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  // ======= Sensitive section lock/unlock =======
  Future<void> _promptUnlockSensitive() async {
    final staffIdCtrl = TextEditingController(text: _currentStaffId ?? '');
    final passCtrl = TextEditingController();
    bool unlocked = false;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_label('advanced'), textDirection: TextDirection.rtl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_currentStaffName != null || _currentStaffId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'المستخدم: ${_currentStaffName ?? ''} ${_currentStaffId != null ? "(${_currentStaffId})" : ""}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  textDirection: TextDirection.rtl,
                ),
              ),
            if (_currentStaffId == null)
              TextField(
                controller: staffIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'رقم الموظف',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                textDirection: TextDirection.rtl,
              ),
            const SizedBox(height: 10),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final staffId =
                  (staffIdCtrl.text.isEmpty && _currentStaffId != null)
                      ? _currentStaffId!
                      : staffIdCtrl.text.trim();
              final pwd = passCtrl.text.trim();
              if (staffId.isEmpty || pwd.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('الرجاء إدخال رقم الموظف وكلمة المرور')),
                );
                return;
              }

              try {
                final doc =
                    await _firestore.collection('users').doc(staffId).get();
                if (!doc.exists) {
                  throw 'المستخدم غير موجود';
                }
                final data = doc.data() as Map<String, dynamic>;
                if (data['password'] != pwd) {
                  throw 'كلمة المرور غير صحيحة';
                }
                unlocked = true;

                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('currentStaffId', staffId);
                if (data['name'] is String) {
                  await prefs.setString('currentStaffName', data['name']);
                }

                Navigator.pop(ctx);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: Text(_label('unlock')),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (unlocked) {
      setState(() => _sensitiveUnlocked = true);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = (_selectedEmployeeName ?? _nameCtrl.text).trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_label('name')} مطلوب')),
      );
      return;
    }

    if (_signatureBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_label('signature')} مطلوب')),
      );
      return;
    }

    setState(() => _saving = true);

    final data = <String, dynamic>{
      'name': name,
      'signature': _signatureBase64,
      'computerType': _joinOrNull(_computerTypes),
      'laptopSN': _hasLaptop
          ? (_laptopSnCtrl.text.trim().isEmpty
              ? null
              : _laptopSnCtrl.text.trim())
          : null,
      'caseModel': _joinOrNull(_caseModels),
      'keyboard': _joinOrNull(_keyboard),
      'mouse': _joinOrNull(_mouse),
      'monitor': _joinOrNull(_monitor),
      'printer': _joinOrNull(_printer),
      'ups': _joinOrNull(_ups),
      'scanner': _joinOrNull(_scanner),
      'department': _joinOrNull(_department),
      'level': _joinOrNull(_level),

      // NOTE: 'cpu' now stores PC-SN (for compatibility with the list screen)
      'cpu': _joinOrNull(_cpu),

      // Hidden / sensitive
      'hashMarks': _hashMarksCtrl.text.trim().isEmpty
          ? null
          : _hashMarksCtrl.text.trim(),
      'ip_1': _ip1Ctrl.text.trim().isEmpty ? null : _ip1Ctrl.text.trim(),
      'ip_2': _ip2Ctrl.text.trim().isEmpty ? null : _ip2Ctrl.text.trim(),
      'bios_sn':
          _biosSnCtrl.text.trim().isEmpty ? null : _biosSnCtrl.text.trim(),
      'uuid': _uuidCtrl.text.trim().isEmpty ? null : _uuidCtrl.text.trim(),
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    };

    try {
      if (_isEdit) {
        data['updatedAt'] = FieldValue.serverTimestamp();
        data['updated_by_name'] = _currentStaffName ?? 'Unknown';
        data['updated_by_id'] = _currentStaffId;

        await _firestore
            .collection('custody')
            .doc(widget.initialRecord!.id)
            .update(data);

        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('تم تحديث السجل')));
        }
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        data['added_by_name'] = _currentStaffName ?? 'Unknown';
        data['added_by_id'] = _currentStaffId;

        await _firestore.collection('custody').add(data);

        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('تم حفظ السجل')));
        }
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _laptopSnCtrl.dispose();
    _hashMarksCtrl.dispose();
    _ip1Ctrl.dispose();
    _ip2Ctrl.dispose();
    _notesCtrl.dispose();
    _biosSnCtrl.dispose();
    _uuidCtrl.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    // Case model label/options based on laptop selection
    final caseModelLabel = _hasLaptop
        ? (_arLabel['laptopModel'] ?? _arFallback['laptopModel']!)
        : _label('caseModel');
    final caseModelOptions =
        _hasLaptop ? _caseModelLaptopOptions : _caseModelOptions;

    return Scaffold(
      appBar: AligoAppbar(title: _isEdit ? 'تحديث الحضانة' : 'إضافة الحضانة'),
      endDrawer: const AligoDrawer(),
      body: _loadingEmployees
          ? const Center(child: CircularProgressIndicator())
          : AbsorbPointer(
              absorbing: _saving,
              child: Stack(
                children: [
                  Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Name with autocomplete + add-on-enter
                        Autocomplete<String>(
                          optionsBuilder: (txt) {
                            final q = txt.text.toLowerCase();
                            return employees
                                .map((e) => e['name'] as String)
                                .where((n) => n.toLowerCase().contains(q))
                                .toList();
                          },
                          onSelected: (sel) {
                            _selectedEmployeeName = sel;
                            _nameCtrl.text = sel;
                            setState(() {});
                          },
                          fieldViewBuilder: (ctx, _ignoredCtrl, fn, onSub) {
                            return TextFormField(
                              controller: _nameCtrl,
                              focusNode: fn,
                              decoration: InputDecoration(
                                labelText: '${_label('name')} *',
                                border: const OutlineInputBorder(),
                              ),
                              textDirection: TextDirection.rtl,
                              textInputAction: TextInputAction.done,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'مطلوب'
                                  : null,
                              onChanged: (v) =>
                                  _selectedEmployeeName = v.trim(),
                              onFieldSubmitted: (value) async {
                                final t = value.trim();
                                if (t.isEmpty) return;
                                final exists = employees.any((e) =>
                                    (e['name'] as String).toLowerCase() ==
                                    t.toLowerCase());
                                if (!exists) {
                                  await _addEmployee(t);
                                } else {
                                  setState(() => _selectedEmployeeName = t);
                                }
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        // Computer Type (نوع الحاسوب)
                        _multiSelectField(
                          fieldKey: 'computerType',
                          label: _label('computerType'),
                          selected: _computerTypes,
                          options: _computerTypeOptions,
                        ),
                        const SizedBox(height: 12),

                        if (_hasLaptop) ...[
                          TextFormField(
                            controller: _laptopSnCtrl,
                            decoration: InputDecoration(
                              labelText: _label('laptopSN'),
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Case Model — dependent
                        _multiSelectField(
                          fieldKey: 'caseModel',
                          label: caseModelLabel,
                          selected: _caseModels,
                          options: caseModelOptions,
                        ),
                        const SizedBox(height: 12),

                        _multiSelectField(
                          fieldKey: 'keyboard',
                          label: _label('keyboard'),
                          selected: _keyboard,
                          options: _keyboardOptions,
                        ),
                        const SizedBox(height: 12),

                        _multiSelectField(
                          fieldKey: 'mouse',
                          label: _label('mouse'),
                          selected: _mouse,
                          options: _mouseOptions,
                        ),
                        const SizedBox(height: 12),

                        _multiSelectField(
                          fieldKey: 'monitor',
                          label: _label('monitor'),
                          selected: _monitor,
                          options: _monitorOptions,
                        ),
                        const SizedBox(height: 12),

                        _multiSelectField(
                          fieldKey: 'printer',
                          label: _label('printer'),
                          selected: _printer,
                          options: _printerOptions,
                        ),
                        const SizedBox(height: 12),

                        _multiSelectField(
                          fieldKey: 'ups',
                          label: _label('ups'),
                          selected: _ups,
                          options: _upsOptions,
                        ),
                        const SizedBox(height: 12),

                        _multiSelectField(
                          fieldKey: 'scanner',
                          label: _label('scanner'),
                          selected: _scanner,
                          options: _scannerOptions,
                        ),
                        const SizedBox(height: 12),

                        _multiSelectField(
                          fieldKey: 'department',
                          label: _label('department'),
                          selected: _department,
                          options: _departmentOptions,
                        ),
                        const SizedBox(height: 12),

                        _multiSelectField(
                          fieldKey: 'level',
                          label: _label('level'),
                          selected: _level,
                          options: _levelOptions,
                        ),
                        const SizedBox(height: 16),

                        // ====== SENSITIVE (LOCKED) SECTION ======
                        if (!_sensitiveUnlocked)
                          Card(
                            elevation: 1,
                            child: ListTile(
                              leading: const Icon(Icons.lock_outline),
                              title: Text(_label('advanced')),
                              subtitle: Text(
                                (_currentStaffName != null ||
                                        _currentStaffId != null)
                                    ? 'مقفلة — ${_currentStaffName ?? ''}${_currentStaffId != null ? " (${_currentStaffId})" : ""}'
                                    : _label('locked'),
                              ),
                              trailing: ElevatedButton.icon(
                                icon: const Icon(Icons.lock_open),
                                label: Text(_label('unlock')),
                                onPressed: _promptUnlockSensitive,
                              ),
                            ),
                          )
                        else
                          Card(
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.lock_open, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        _label('unlocked'),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // PC-SN (saved as 'cpu') — using options from Excel
                                  _multiSelectField(
                                    fieldKey: 'pcSN',
                                    label: _label('pcSN'),
                                    selected: _cpu,
                                    options: _pcSnOptions,
                                  ),
                                  const SizedBox(height: 12),

                                  TextFormField(
                                    controller: _biosSnCtrl,
                                    decoration: InputDecoration(
                                      labelText: _label('biosSN'),
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                  const SizedBox(height: 12),

                                  TextFormField(
                                    controller: _uuidCtrl,
                                    decoration: InputDecoration(
                                      labelText: _label('uuid'),
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                  const SizedBox(height: 12),

                                  TextFormField(
                                    controller: _hashMarksCtrl,
                                    decoration: InputDecoration(
                                      labelText: _label('hashMarks'),
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                  const SizedBox(height: 12),

                                  TextFormField(
                                    controller: _ip1Ctrl,
                                    decoration: InputDecoration(
                                      labelText: _label('ip_1'),
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                  const SizedBox(height: 12),

                                  TextFormField(
                                    controller: _ip2Ctrl,
                                    decoration: InputDecoration(
                                      labelText: _label('ip_2'),
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                  const SizedBox(height: 12),

                                  TextFormField(
                                    controller: _notesCtrl,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      labelText: _label('notes'),
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Signature
                        Text('${_label('signature')} *',
                            style: tema.textTheme.titleMedium,
                            textDirection: TextDirection.rtl),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _openSignatureDialog,
                          child: Container(
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              border: Border.all(
                                color: _signatureBase64 == null
                                    ? Colors.redAccent
                                    : Colors.grey.shade400,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: _signatureBase64 == null
                                ? Text('اضغط لإضافة ${_label('signature')}',
                                    style:
                                        const TextStyle(color: Colors.black54))
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: Colors.green),
                                      SizedBox(height: 6),
                                      Text('تم التقاط التوقيع'),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        ElevatedButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: const Icon(Icons.save),
                          label: Text(_isEdit ? 'تحديث السجل' : 'حفظ السجل'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                  if (_saving)
                    Container(
                      color: Colors.black.withOpacity(0.15),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
    );
  }
}
