import 'dart:convert';
import 'dart:typed_data';

import 'package:aligo/components/aligo_appbar.dart';
import 'package:aligo/components/aligo_drawer.dart';
import 'package:aligo/screens/custody/custody_list_screen.dart'; // CustodyRecordRead
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';

class AddCustodyScreen extends StatefulWidget {
  /// If provided, will prefill fields and perform an update.
  final CustodyRecordRead? initialRecord;

  const AddCustodyScreen({Key? key, this.initialRecord}) : super(key: key);

  @override
  State<AddCustodyScreen> createState() => _AddCustodyScreenState();
}

class _AddCustodyScreenState extends State<AddCustodyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  // Employees
  List<Map<String, dynamic>> employees = [];
  bool _loadingEmployees = true;
  String? _selectedEmployeeName;
  final TextEditingController _nameCtrl = TextEditingController();

  // ======= MULTI-SELECT FIELDS =======
  // Computer types (multi-select)
  static const List<String> _computerTypeOptions = [
    'laptop',
    'desktop',
    'all-in-one',
  ];
  final Set<String> _computerTypes = {};

  bool get _hasLaptop => _computerTypes.contains('laptop');

  // Laptop SN input (shown only if laptop selected)
  final _laptopSnCtrl = TextEditingController();

  // Case Model
  static const List<String> _caseModelOptions = [
    'Mini Tower',
    'Mid Tower',
    'Full Tower',
    'SFF',
    'USFF',
    'Rackmount',
    'All-in-one',
  ];
  final Set<String> _caseModels = {};

  // Keyboard
  static const List<String> _keyboardOptions = [
    'Wired',
    'Wireless',
    'Arabic',
    'English',
    'Backlit',
    'Mechanical',
    'Ergonomic',
  ];
  final Set<String> _keyboard = {};

  // Mouse
  static const List<String> _mouseOptions = [
    'Wired',
    'Wireless',
    'Optical',
    'Laser',
    'Trackball',
  ];
  final Set<String> _mouse = {};

  // Monitor
  static const List<String> _monitorOptions = [
    '19"',
    '21"',
    '22"',
    '24"',
    '27"',
    'HD',
    'FHD',
    'QHD',
    '4K',
  ];
  final Set<String> _monitor = {};

  // Printer
  static const List<String> _printerOptions = [
    'Laser',
    'Inkjet',
    'Color',
    'B/W',
    'All-in-one',
  ];
  final Set<String> _printer = {};

  // UPS
  static const List<String> _upsOptions = [
    '600VA',
    '850VA',
    '1000VA',
    '1500VA',
    'Online',
    'Line-interactive',
  ];
  final Set<String> _ups = {};

  // Scanner
  static const List<String> _scannerOptions = [
    'Flatbed',
    'ADF',
    'Handheld',
  ];
  final Set<String> _scanner = {};

  // Department
  static const List<String> _departmentOptions = [
    'HR',
    'Finance',
    'IT',
    'Admin',
    'Sales',
    'Marketing',
    'Operations',
    'Support',
  ];
  final Set<String> _department = {};

  // Level
  static const List<String> _levelOptions = [
    'Intern',
    'Level 1',
    'Level 2',
    'Level 3',
    'Manager',
    'Director',
  ];
  final Set<String> _level = {};

  // CPU
  static const List<String> _cpuOptions = [
    'Core i3',
    'Core i5',
    'Core i7',
    'Core i9',
    'Ryzen 3',
    'Ryzen 5',
    'Ryzen 7',
    'Ryzen 9',
  ];
  final Set<String> _cpu = {};

  // ======= Inputs that stay as text (SENSITIVE/LOCKED) =======
  final _hashMarksCtrl = TextEditingController(); // "#serial number"
  final _ip1Ctrl = TextEditingController(); // IP_1
  final _ip2Ctrl = TextEditingController(); // IP_2
  final _notesCtrl = TextEditingController(); // Notes

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

  @override
  void initState() {
    super.initState();
    _loadLoginInfo();
    _loadEmployees().then((_) {
      if (_isEdit) _populateFromInitial();
    });
  }

  Future<void> _loadLoginInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _currentStaffId = prefs.getString('currentStaffId');
        _currentStaffName = prefs.getString('currentStaffName');
      });
    } catch (_) {
      // ignore
    }
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
        title: Text(_isEdit ? 'تحديث التوقيع' : 'إضافة التوقيع'),
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
  }

  // ======= Generic Multi-select Picker =======
  Future<void> _openMultiPicker({
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
          title: Text(title),
          content: StatefulBuilder(
            builder: (context, setLocal) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (allowCustom) ...[
                      TextField(
                        controller: customCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Add custom',
                          isDense: true,
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
                        title: Text(opt),
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
                    // Show any custom items (not in options)
                    ...temp
                        .where((e) => !options.contains(e))
                        .map((custom) => CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(custom),
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
              child: const Text('Clear'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  selected
                    ..clear()
                    ..addAll(temp);
                  if (title.startsWith('Computer')) {
                    _syncLaptopSNVisibility();
                  }
                });
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Widget _multiSelectField({
    required String label,
    required Set<String> selected,
    required List<String> options,
    bool allowCustom = true,
  }) {
    final summary = selected.isEmpty ? 'Select...' : selected.join(', ');
    return InkWell(
      onTap: () => _openMultiPicker(
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
        title: const Text('Unlock Advanced Fields'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_currentStaffName != null || _currentStaffId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'User: ${_currentStaffName ?? ''} ${_currentStaffId != null ? "(${_currentStaffId})" : ""}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            if (_currentStaffId == null)
              TextField(
                controller: staffIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Staff ID',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
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
                  const SnackBar(content: Text('Enter staff ID and password')),
                );
                return;
              }

              try {
                final doc =
                    await _firestore.collection('users').doc(staffId).get();
                if (!doc.exists) {
                  throw 'User not found';
                }
                final data = doc.data() as Map<String, dynamic>;
                if (data['password'] != pwd) {
                  throw 'Incorrect password';
                }
                unlocked = true;

                // If we didn’t have them stored, store now for later sessions
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
            child: const Text('Unlock'),
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
        const SnackBar(content: Text('Name is required.')),
      );
      return;
    }

    if (_signatureBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signature is required.')),
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
      'cpu': _joinOrNull(_cpu),

      // Sensitive
      'hashMarks': _hashMarksCtrl.text.trim().isEmpty
          ? null
          : _hashMarksCtrl.text.trim(),
      'ip_1': _ip1Ctrl.text.trim().isEmpty ? null : _ip1Ctrl.text.trim(),
      'ip_2': _ip2Ctrl.text.trim().isEmpty ? null : _ip2Ctrl.text.trim(),
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    };

    try {
      if (_isEdit) {
        // UPDATE: who did it + when
        data['updatedAt'] = FieldValue.serverTimestamp();
        data['updated_by_name'] = _currentStaffName ?? 'Unknown';
        data['updated_by_id'] = _currentStaffId;

        await _firestore
            .collection('custody')
            .doc(widget.initialRecord!.id)
            .update(data);

        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Record updated')));
        }
      } else {
        // CREATE: who added it + when
        data['createdAt'] = FieldValue.serverTimestamp();
        data['added_by_name'] = _currentStaffName ?? 'Unknown';
        data['added_by_id'] = _currentStaffId;

        await _firestore.collection('custody').add(data);

        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Record saved')));
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
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

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
                              decoration: const InputDecoration(
                                labelText: 'الاسم *',
                                border: OutlineInputBorder(),
                              ),
                              textInputAction: TextInputAction.done,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
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

                        // Multi-select: Computer Type(s)
                        _multiSelectField(
                          label: 'Computer Type(s)',
                          selected: _computerTypes,
                          options: _computerTypeOptions,
                        ),
                        const SizedBox(height: 12),

                        if (_hasLaptop) ...[
                          TextFormField(
                            controller: _laptopSnCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Laptop SN',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Multi-select: Case Model
                        _multiSelectField(
                          label: 'Case Model',
                          selected: _caseModels,
                          options: _caseModelOptions,
                        ),
                        const SizedBox(height: 12),

                        // Multi-select: Keyboard
                        _multiSelectField(
                          label: 'Keyboard',
                          selected: _keyboard,
                          options: _keyboardOptions,
                        ),
                        const SizedBox(height: 12),

                        // Multi-select: Mouse
                        _multiSelectField(
                          label: 'Mouse',
                          selected: _mouse,
                          options: _mouseOptions,
                        ),
                        const SizedBox(height: 12),

                        // Multi-select: Monitor
                        _multiSelectField(
                          label: 'Monitor',
                          selected: _monitor,
                          options: _monitorOptions,
                        ),
                        const SizedBox(height: 12),

                        // Multi-select: Printer
                        _multiSelectField(
                          label: 'Printer',
                          selected: _printer,
                          options: _printerOptions,
                        ),
                        const SizedBox(height: 12),

                        // Multi-select: UPS
                        _multiSelectField(
                          label: 'UPS',
                          selected: _ups,
                          options: _upsOptions,
                        ),
                        const SizedBox(height: 12),

                        // Multi-select: Scanner
                        _multiSelectField(
                          label: 'Scanner',
                          selected: _scanner,
                          options: _scannerOptions,
                        ),
                        const SizedBox(height: 12),

                        // Multi-select: Department
                        _multiSelectField(
                          label: 'Department',
                          selected: _department,
                          options: _departmentOptions,
                        ),
                        const SizedBox(height: 12),

                        // Multi-select: Level
                        _multiSelectField(
                          label: 'Level',
                          selected: _level,
                          options: _levelOptions,
                        ),
                        const SizedBox(height: 12),

                        // Multi-select: CPU
                        _multiSelectField(
                          label: 'CPU',
                          selected: _cpu,
                          options: _cpuOptions,
                        ),
                        const SizedBox(height: 16),

                        // ====== SENSITIVE (LOCKED) SECTION ======
                        if (!_sensitiveUnlocked)
                          Card(
                            elevation: 1,
                            child: ListTile(
                              leading: const Icon(Icons.lock_outline),
                              title: const Text('Advanced Fields'),
                              subtitle: Text(
                                _currentStaffName != null ||
                                        _currentStaffId != null
                                    ? 'Locked — ${_currentStaffName ?? ''}${_currentStaffId != null ? " (${_currentStaffId})" : ""}'
                                    : 'Locked — tap Unlock',
                              ),
                              trailing: ElevatedButton.icon(
                                icon: const Icon(Icons.lock_open),
                                label: const Text('Unlock'),
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
                                    children: const [
                                      Icon(Icons.lock_open, size: 18),
                                      SizedBox(width: 6),
                                      Text(
                                        'Advanced Fields (Unlocked)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _hashMarksCtrl,
                                    decoration: const InputDecoration(
                                      labelText: '#serial number',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _ip1Ctrl,
                                    decoration: const InputDecoration(
                                      labelText: 'IP_1',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _ip2Ctrl,
                                    decoration: const InputDecoration(
                                      labelText: 'IP_2',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _notesCtrl,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                      labelText: 'Notes',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Signature
                        Text('Signature *', style: tema.textTheme.titleMedium),
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
                                ? const Text('Tap to add signature',
                                    style: TextStyle(color: Colors.black54))
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
                          label:
                              Text(_isEdit ? 'Update Custody' : 'Save Custody'),
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
