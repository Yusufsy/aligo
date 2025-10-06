import 'dart:convert';
import 'dart:typed_data';

import 'package:aligo/components/aligo_appbar.dart';
import 'package:aligo/components/aligo_drawer.dart';
import 'package:aligo/screens/custody/add_custody_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Read-only model for displaying Firestore documents.
class CustodyRecordRead {
  final String id;
  final String name;
  final String signatureBase64;
  final String? computerType;
  final String? laptopSn;
  final String? caseModel;
  final String? keyboard;
  final String? mouse;
  final String? monitor;
  final String? printer;
  final String? ups;
  final String? scanner;
  final String? department;
  final String? level;
  final String? cpu;
  final String? hashMarks;
  final String? ip1;
  final String? ip2;
  final String? notes;
  final DateTime? createdAt;

  CustodyRecordRead({
    required this.id,
    required this.name,
    required this.signatureBase64,
    this.computerType,
    this.laptopSn,
    this.caseModel,
    this.keyboard,
    this.mouse,
    this.monitor,
    this.printer,
    this.ups,
    this.scanner,
    this.department,
    this.level,
    this.cpu,
    this.hashMarks,
    this.ip1,
    this.ip2,
    this.notes,
    this.createdAt,
  });

  factory CustodyRecordRead.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? {};
    return CustodyRecordRead(
      id: snap.id,
      name: (d['name'] ?? '') as String,
      signatureBase64: (d['signature'] ?? '') as String,
      computerType: d['computerType'] as String?,
      laptopSn: d['laptopSN'] as String?,
      caseModel: d['caseModel'] as String?,
      keyboard: d['keyboard'] as String?,
      mouse: d['mouse'] as String?,
      monitor: d['monitor'] as String?,
      printer: d['printer'] as String?,
      ups: d['ups'] as String?,
      scanner: d['scanner'] as String?,
      department: d['department'] as String?,
      level: d['level'] as String?,
      cpu: d['cpu'] as String?,
      hashMarks: d['hashMarks'] as String?,
      ip1: d['ip_1'] as String?,
      ip2: d['ip_2'] as String?,
      notes: d['notes'] as String?,
      createdAt: d['createdAt'] is Timestamp
          ? (d['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}

class CustodyListScreen extends StatefulWidget {
  const CustodyListScreen({Key? key}) : super(key: key);

  @override
  State<CustodyListScreen> createState() => _CustodyListScreenState();
}

class _CustodyListScreenState extends State<CustodyListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  List<CustodyRecordRead> _latestFiltered = [];

  bool get _isDesktopOrWeb {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return true;
      default:
        return false;
    }
  }

  Stream<List<CustodyRecordRead>> _recordsStream() {
    return FirebaseFirestore.instance
        .collection('custody')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((q) => q.docs
            .map((d) => CustodyRecordRead.fromSnapshot(
                d as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  bool _matchesQuery(CustodyRecordRead r, String q) {
    if (q.isEmpty) return true;
    final lq = q.toLowerCase();
    bool part(String? v) => v != null && v.toLowerCase().contains(lq);
    return part(r.name) ||
        part(r.computerType) ||
        part(r.laptopSn) ||
        part(r.caseModel) ||
        part(r.department) ||
        part(r.notes) ||
        part(r.ip1) ||
        part(r.ip2);
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final next = _searchCtrl.text.trim();
      if (next != _query) {
        setState(() => _query = next);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AligoAppbar(title: 'جرد'),
      endDrawer: const AligoDrawer(),
      body: StreamBuilder<List<CustodyRecordRead>>(
        stream: _recordsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final all = snap.data ?? [];
          final filtered = all.where((r) => _matchesQuery(r, _query)).toList();
          _latestFiltered = filtered;

          return Column(
            children: [
              _buildSearchBar(
                context,
                total: all.length,
                filtered: filtered.length,
                canExport: filtered.isNotEmpty,
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          _query.isEmpty
                              ? 'لا توجد سجلات جرد حتى الآن.'
                              : 'No matches for "$_query".',
                        ),
                      )
                    : _isDesktopOrWeb
                        ? _FullTable(
                            records: filtered,
                            totalCount: all.length,
                            filteredCount: filtered.length,
                            onRowTap: (r) => _goToEdit(context, r),
                          )
                        : (_query.isEmpty
                            ? _GroupedMobileList(
                                records: filtered,
                                onGroupTap: (name, list) =>
                                    _showGroupedDialog(context, name, list),
                              )
                            : _FilteredMobileList(
                                records: filtered,
                                onTapRecord: (r) {
                                  // Show the same grouped preview dialog used elsewhere,
                                  // but scoped to the tapped person's name.
                                  final group = (snap.data ?? [])
                                      .where((x) => x.name == r.name)
                                      .toList();
                                  _showGroupedDialog(context, r.name, group);
                                },
                              )),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'إضافة سجل جرد',
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddCustodyScreen(),
            ),
          ).then((updated) {
            if (updated == true && mounted) setState(() {});
          });
        },
      ),
    );
  }

  // ---------- Navigation to edit ----------
  Future<void> _goToEdit(BuildContext rootContext, CustodyRecordRead r) async {
    final updated = await Navigator.push(
      rootContext,
      MaterialPageRoute(builder: (_) => AddCustodyScreen(initialRecord: r)),
    );
    if (updated == true && mounted) setState(() {});
  }

  // ---------- Search Bar ----------
  Widget _buildSearchBar(
    BuildContext context, {
    required int total,
    required int filtered,
    required bool canExport,
  }) {
    return Material(
      elevation: 1,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText:
                      'البحث حسب الاسم، النوع، الرقم التسلسلي، القسم، عنوان IP، الملاحظات...',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          onPressed: () => _searchCtrl.clear(),
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: canExport ? _exportExcel : null,
              icon: const Icon(Icons.download),
              label: const Text('تصدير ملف EXCEL'),
            ),
            if (_isDesktopOrWeb) ...[
              const SizedBox(width: 12),
              Text(
                _query.isEmpty
                    ? 'All ($total)'
                    : 'Filter: $_query  ($filtered / $total)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------- Grouped Dialog (Name → list of records, tap → EDIT) ----------
  void _showGroupedDialog(
    BuildContext rootContext,
    String name,
    List<CustodyRecordRead> group,
  ) {
    showDialog(
      context: rootContext,
      builder: (dialogCtx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 620, maxWidth: 520),
          child: Column(
            children: [
              AppBar(
                title: Text('$name (${group.length})'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(dialogCtx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 12, left: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'اضغط على البطاقة للتعديل مباشرة',
                    style: Theme.of(rootContext).textTheme.bodySmall,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: group.length,
                  separatorBuilder: (_, __) => const Divider(height: 30),
                  itemBuilder: (_, i) {
                    final rec = group[i];
                    return InkWell(
                      onTap: () async {
                        // Close dialog first, then navigate to edit
                        Navigator.of(dialogCtx).pop();
                        await _goToEdit(rootContext, rec);
                      },
                      child: _RecordDetailsCard(record: rec, dense: true),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- CSV Export ----------
  // Future<void> _exportCsv() async {
  //   if (_latestFiltered.isEmpty) return;
  //
  //   final buffer = StringBuffer();
  //   buffer.writeln([
  //     'Name',
  //     'ComputerType',
  //     'LaptopSN',
  //     'CaseModel',
  //     'Keyboard',
  //     'Mouse',
  //     'Monitor',
  //     'Printer',
  //     'UPS',
  //     'Scanner',
  //     'Department',
  //     'Level',
  //     'CPU',
  //     'HashMarks',
  //     'IP_1',
  //     'IP_2',
  //     'Notes',
  //     'CreatedAt',
  //   ].map(_csvEscape).join(','));
  //
  //   for (final r in _latestFiltered) {
  //     buffer.writeln([
  //       r.name,
  //       r.computerType,
  //       r.laptopSn,
  //       r.caseModel,
  //       r.keyboard,
  //       r.mouse,
  //       r.monitor,
  //       r.printer,
  //       r.ups,
  //       r.scanner,
  //       r.department,
  //       r.level,
  //       r.cpu,
  //       r.hashMarks,
  //       r.ip1,
  //       r.ip2,
  //       r.notes,
  //       r.createdAt?.toIso8601String(),
  //     ].map(_csvEscape).join(','));
  //   }
  //
  //   final csv = buffer.toString();
  //   final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  //   final filename = 'custody_export_$ts.csv';
  //
  //   try {
  //     final csvBytes = Uint8List.fromList(utf8.encode(csv));
  //
  //     final savePath = await FilePicker.platform.saveFile(
  //       dialogTitle: 'Save CSV',
  //       fileName: filename,
  //       type: FileType.custom,
  //       allowedExtensions: ['csv'],
  //       bytes: csvBytes,
  //       // required on Android/iOS
  //       lockParentWindow: true,
  //     );
  //
  //     if (savePath == null) {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Export cancelled')),
  //         );
  //       }
  //       return;
  //     }
  //
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Saved: $savePath')),
  //       );
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('File save failed: $e')),
  //       );
  //     }
  //   }
  // }

  // ... (replace _exportCsv and _csvEscape)

// ---------- Excel (.xlsx) Export ----------
  Future<void> _exportExcel() async {
    if (_latestFiltered.isEmpty) return;

    // Create workbook & sheet
    final wb = xlsio.Workbook();
    final sheet = wb.worksheets[0];
    sheet.name = 'Custody Records';

    // Headers
    final headers = [
      'Name',
      'ComputerType',
      'LaptopSN',
      'CaseModel',
      'Keyboard',
      'Mouse',
      'Monitor',
      'Printer',
      'UPS',
      'Scanner',
      'Department',
      'Level',
      'CPU',
      'HashMarks',
      'IP_1',
      'IP_2',
      'Notes',
      'CreatedAt',
      'Signature',
    ];

    // Write headers (row 1)
    for (int c = 0; c < headers.length; c++) {
      final cell = sheet.getRangeByIndex(1, c + 1);
      cell.setText(headers[c]);
      cell.cellStyle.bold = true;
    }

    // Helper: clean + decode base64 (handles data URLs)
    Uint8List? _decodeBase64Image(String b64) {
      try {
        final cleaned = b64.split(',').last.trim();
        return Uint8List.fromList(base64Decode(cleaned));
      } catch (_) {
        return null;
      }
    }

    // Write rows starting at row 2
    int row = 2;
    for (final r in _latestFiltered) {
      sheet.getRangeByIndex(row, 1).setText(r.name);
      sheet.getRangeByIndex(row, 2).setText(r.computerType ?? '');
      sheet.getRangeByIndex(row, 3).setText(r.laptopSn ?? '');
      sheet.getRangeByIndex(row, 4).setText(r.caseModel ?? '');
      sheet.getRangeByIndex(row, 5).setText(r.keyboard ?? '');
      sheet.getRangeByIndex(row, 6).setText(r.mouse ?? '');
      sheet.getRangeByIndex(row, 7).setText(r.monitor ?? '');
      sheet.getRangeByIndex(row, 8).setText(r.printer ?? '');
      sheet.getRangeByIndex(row, 9).setText(r.ups ?? '');
      sheet.getRangeByIndex(row, 10).setText(r.scanner ?? '');
      sheet.getRangeByIndex(row, 11).setText(r.department ?? '');
      sheet.getRangeByIndex(row, 12).setText(r.level ?? '');
      sheet.getRangeByIndex(row, 13).setText(r.cpu ?? '');
      sheet.getRangeByIndex(row, 14).setText(r.hashMarks ?? '');
      sheet.getRangeByIndex(row, 15).setText(r.ip1 ?? '');
      sheet.getRangeByIndex(row, 16).setText(r.ip2 ?? '');
      sheet.getRangeByIndex(row, 17).setText(r.notes ?? '');
      sheet.getRangeByIndex(row, 18).setText(r.createdAt != null
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(r.createdAt!)
          : '');

      // Put signature image in column 19 (Signature)
      final img = _decodeBase64Image(r.signatureBase64);
      if (img != null && img.isNotEmpty) {
        // Anchor picture to the signature cell’s top-left
        final pic = sheet.pictures.addStream(row, 19, img);
        // Size & row height so it’s visible
        pic.height = 60; // points
        pic.width = 150;
        sheet.getRangeByIndex(row, 1).rowHeight = 48; // adjust row height
      } else {
        sheet.getRangeByIndex(row, 19).setText('—');
      }

      row++;
    }

    // Auto-fit columns
    for (int c = 1; c <= headers.length; c++) {
      sheet.autoFitColumn(c);
    }

    // Save workbook to bytes
    final bytes = Uint8List.fromList(wb.saveAsStream());
    wb.dispose();

    // Save via FilePicker (works on mobile/desktop/web)
    final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'custody_export_$ts.xlsx';

    try {
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Excel',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: bytes,
        lockParentWindow: true,
      );

      if (savePath == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export cancelled')),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved: $savePath')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  String _csvEscape(Object? raw) {
    if (raw == null) return '';
    final s = raw.toString();
    final needsQuoting = s.contains(',') ||
        s.contains('"') ||
        s.contains('\n') ||
        s.contains('\r');
    if (!needsQuoting) return s;
    return '"${s.replaceAll('"', '""')}"';
  }
}

// ---------- MOBILE grouped list ----------
class _GroupedMobileList extends StatelessWidget {
  final List<CustodyRecordRead> records;
  final void Function(String name, List<CustodyRecordRead> group) onGroupTap;

  const _GroupedMobileList({
    Key? key,
    required this.records,
    required this.onGroupTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<String, List<CustodyRecordRead>> grouped = {};
    for (final r in records) {
      grouped.putIfAbsent(r.name, () => []).add(r);
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final e = entries[i];
        final count = e.value.length;
        return ListTile(
          title: Text(e.key),
          subtitle: Text('$count device${count == 1 ? '' : 's'}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onGroupTap(e.key, e.value),
        );
      },
    );
  }
}

// ---------- MOBILE flat filtered list ----------
class _FilteredMobileList extends StatelessWidget {
  final List<CustodyRecordRead> records;
  final void Function(CustodyRecordRead) onTapRecord;

  const _FilteredMobileList({
    Key? key,
    required this.records,
    required this.onTapRecord,
  }) : super(key: key);

  String _subtitle(CustodyRecordRead r) {
    final parts = [
      r.computerType,
      r.laptopSn,
      r.caseModel,
      r.department,
      r.ip1,
      r.ip2,
    ].where((e) => e != null && e!.trim().isNotEmpty).map((e) => e!.trim());
    final joined = parts.take(3).join(' • ');
    return joined.isEmpty ? 'Details' : joined;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: records.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final r = records[i];
        return ListTile(
          title: Text(r.name),
          subtitle: Text(_subtitle(r)),
          trailing: const Icon(Icons.edit),
          onTap: () => onTapRecord(r),
        );
      },
    );
  }
}

// ---------- DESKTOP / WEB full table ----------
class _FullTable extends StatelessWidget {
  final List<CustodyRecordRead> records;
  final int totalCount;
  final int filteredCount;
  final void Function(CustodyRecordRead) onRowTap;

  const _FullTable({
    Key? key,
    required this.records,
    required this.totalCount,
    required this.filteredCount,
    required this.onRowTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 16, 4),
            child: Text(
              '$filteredCount / $totalCount shown',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                showCheckboxColumn: false,
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Computer Type')),
                  DataColumn(label: Text('Laptop SN')),
                  DataColumn(label: Text('Case Model')),
                  DataColumn(label: Text('Keyboard')),
                  DataColumn(label: Text('Mouse')),
                  DataColumn(label: Text('Monitor')),
                  DataColumn(label: Text('Printer')),
                  DataColumn(label: Text('UPS')),
                  DataColumn(label: Text('Scanner')),
                  DataColumn(label: Text('Department')),
                  DataColumn(label: Text('Level')),
                  DataColumn(label: Text('CPU')),
                  DataColumn(label: Text('##')),
                  DataColumn(label: Text('IP_1')),
                  DataColumn(label: Text('IP_2')),
                  DataColumn(label: Text('Notes')),
                  DataColumn(label: Text('Date')),
                ],
                rows: records.map((r) {
                  final dateStr = r.createdAt == null
                      ? ''
                      : r.createdAt!
                          .toLocal()
                          .toString()
                          .replaceFirst(RegExp(r'\.\d+$'), '');
                  return DataRow(
                    cells: [
                      DataCell(Text(r.name)),
                      DataCell(Text(r.computerType ?? '')),
                      DataCell(Text(r.laptopSn ?? '')),
                      DataCell(Text(r.caseModel ?? '')),
                      DataCell(Text(r.keyboard ?? '')),
                      DataCell(Text(r.mouse ?? '')),
                      DataCell(Text(r.monitor ?? '')),
                      DataCell(Text(r.printer ?? '')),
                      DataCell(Text(r.ups ?? '')),
                      DataCell(Text(r.scanner ?? '')),
                      DataCell(Text(r.department ?? '')),
                      DataCell(Text(r.level ?? '')),
                      DataCell(Text(r.cpu ?? '')),
                      DataCell(Text(r.hashMarks ?? '')),
                      DataCell(Text(r.ip1 ?? '')),
                      DataCell(Text(r.ip2 ?? '')),
                      DataCell(Text(r.notes ?? '')),
                      DataCell(Text(dateStr)),
                    ],
                    onSelectChanged: (_) => onRowTap(r),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------- Record details card ----------
class _RecordDetailsCard extends StatelessWidget {
  final CustodyRecordRead record;
  final bool dense;

  const _RecordDetailsCard({Key? key, required this.record, this.dense = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final createdStr = record.createdAt == null
        ? '—'
        : record.createdAt!
            .toLocal()
            .toString()
            .replaceFirst(RegExp(r'\.\d+$'), '');

    Widget signature() {
      if (record.signatureBase64.isEmpty) return const Text('No signature');
      try {
        final bytes = base64Decode(record.signatureBase64);
        return Image.memory(
          bytes,
          height: 90,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        );
      } catch (_) {
        return const Text('Invalid signature data');
      }
    }

    final fieldList = <_Field>[
      _Field('Name', record.name),
      _Field('Computer Type', record.computerType),
      // _Field('Laptop SN', record.laptopSn),
      _Field('Case Model', record.caseModel),
      _Field('Keyboard', record.keyboard),
      _Field('Mouse', record.mouse),
      _Field('Monitor', record.monitor),
      _Field('Printer', record.printer),
      _Field('UPS', record.ups),
      _Field('Scanner', record.scanner),
      _Field('Department', record.department),
      _Field('Level', record.level),
      _Field('CPU', record.cpu),
      // _Field('##', record.hashMarks),
      // _Field('IP_1', record.ip1),
      // _Field('IP_2', record.ip2),
      _Field('Notes', record.notes),
      _Field('Date', createdStr),
    ].where((f) => f.value != null && f.value!.trim().isNotEmpty).toList();

    return Card(
      elevation: dense ? 1 : 2,
      margin: EdgeInsets.symmetric(vertical: dense ? 4 : 8),
      child: Padding(
        padding: EdgeInsets.all(dense ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!dense)
              Text(record.name, style: Theme.of(context).textTheme.titleMedium),
            if (!dense) const Divider(),
            ...fieldList.map((f) => _InfoRow(label: f.label, value: f.value!)),
            const SizedBox(height: 12),
            Text(
              'Signature',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            signature(),
          ],
        ),
      ),
    );
  }
}

// ---------- Helpers ----------
class _Field {
  final String label;
  final String? value;

  _Field(this.label, this.value);
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({Key? key, required this.label, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
