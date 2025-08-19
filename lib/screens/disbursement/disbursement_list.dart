import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show File; // safe - guarded by kIsWeb logic

import 'package:aligo/components/aligo_appbar.dart';
import 'package:aligo/components/aligo_drawer.dart';
import 'package:aligo/helpers/disbursement_helper.dart';
import 'package:aligo/models/disbursement.dart';
import 'package:aligo/screens/disbursement/add_disbursement.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// If you add a web helper for CSV downloading, re-enable:
// import 'csv_web_download_stub.dart' if (dart.library.html) 'csv_web_download.dart';

class DisbursementList extends StatefulWidget {
  const DisbursementList({Key? key}) : super(key: key);

  @override
  State<DisbursementList> createState() => _DisbursementListState();
}

class _DisbursementListState extends State<DisbursementList> {
  final TextStyle tableHead =
      const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600);
  final TextEditingController staffSearchCtrl = TextEditingController();

  String? _dateFilter; // 'day' | 'month' | 'year' | null
  bool _loading = true;
  bool _exporting = false;

  List<Disbursement> _allDisbursements = [];
  Map<String, String> _employeeNameById = {}; // employeeRefId -> name
  Map<String, String> _productNameById = {}; // productId -> composed name

  // Filtered view
  List<Disbursement> _filtered = [];

  int get _totalCount => _allDisbursements.length;

  int get _filteredCount => _filtered.length;

  int get _filteredQty =>
      _filtered.fold<int>(0, (s, d) => s + int.tryParse(d.quantity)!.toInt());

  @override
  void initState() {
    super.initState();
    _loadData();
    staffSearchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    staffSearchCtrl.removeListener(_applyFilter);
    staffSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Parallel fetch: disbursements + employees
      final disbFuture =
          DisbursementDBHelper.instance.getDisbursements(filter: _dateFilter);
      final employeesFuture =
          FirebaseFirestore.instance.collection('employees').get();

      final results = await Future.wait([disbFuture, employeesFuture]);
      final disbursements = results[0] as List<Disbursement>;
      final empSnap = results[1] as QuerySnapshot;

      // Build employee map
      final empMap = <String, String>{};
      for (final doc in empSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['name'] ?? '').toString();
        empMap[doc.id] = name;
      }

      _allDisbursements = disbursements;
      _employeeNameById = empMap;

      // Fetch product names
      await _loadProductsFor(disbursements);

      _applyFilter();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Load error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Compose product name from inventory fields
  String _composeProductName(Map<String, dynamic> data) {
    final brand = (data['brand'] ?? '').toString().trim();
    final variety = (data['variety'] ?? '').toString().trim();
    final colour = (data['colour'] ?? '').toString().trim();
    final parts = [brand, variety, colour].where((p) => p.isNotEmpty).toList();
    return parts.isEmpty ? '—' : parts.join(' ');
  }

  /// Batch load distinct products referenced in disbursements.
  Future<void> _loadProductsFor(List<Disbursement> disbursements) async {
    final ids = {
      for (final d in disbursements) d.productId,
    };
    // Firestore whereIn limit of 10 per query; batch if > 10
    final List<String> allIds = ids.toList();
    final Map<String, String> resultMap = {};
    const batchSize = 10;

    for (var i = 0; i < allIds.length; i += batchSize) {
      final chunk = allIds.sublist(
        i,
        (i + batchSize > allIds.length) ? allIds.length : i + batchSize,
      );
      try {
        final snap = await FirebaseFirestore.instance
            .collection('inventory')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in snap.docs) {
          final data = doc.data() as Map<String, dynamic>;
          resultMap[doc.id] = _composeProductName(data);
        }
      } catch (_) {
        // If a chunk fails (e.g., some IDs missing), we continue
      }
    }

    // Fallback names for any not found
    for (final id in allIds) {
      resultMap.putIfAbsent(id, () => id); // just show id if missing
    }

    _productNameById = resultMap;
  }

  void _applyFilter() {
    final q = staffSearchCtrl.text.trim().toLowerCase();
    bool nameContains(String? name) =>
        q.isEmpty || (name != null && name.toLowerCase().contains(q));

    _filtered = _allDisbursements.where((d) {
      final empName = _employeeNameById[d.employeeRefId];
      return nameContains(empName);
    }).toList()
      ..sort((a, b) {
        // Sort by date desc then employee name
        final ad = a.dateOfDisbursement;
        final bd = b.dateOfDisbursement;
        final cmpDate = bd.compareTo(ad);
        if (cmpDate != 0) return cmpDate;
        final an = _employeeNameById[a.employeeRefId] ?? '';
        final bn = _employeeNameById[b.employeeRefId] ?? '';
        return an.toLowerCase().compareTo(bn.toLowerCase());
      });

    if (mounted) setState(() {});
  }

  Future<void> _refresh() async => _loadData();

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

  // ------------------- CSV Export -------------------
  Future<void> _exportCsv() async {
    if (_filtered.isEmpty || _exporting) return;
    setState(() => _exporting = true);
    try {
      final buffer = StringBuffer();
      buffer.writeln([
        'EmployeeName',
        'EmployeeRefId',
        'ProductId',
        'ProductName',
        'Quantity',
        'DateOfDisbursement',
        'SignaturePresent',
      ].join(','));

      for (final d in _filtered) {
        final empName = _employeeNameById[d.employeeRefId] ?? '';
        final productName = _productNameById[d.productId] ?? d.productId;
        final hasSig = (d.signatureBase64.isNotEmpty).toString();
        buffer.writeln([
          _csvEscape(empName),
          _csvEscape(d.employeeRefId),
          _csvEscape(d.productId),
          _csvEscape(productName),
          _csvEscape(d.quantity),
          _csvEscape(d.dateOfDisbursement),
          _csvEscape(hasSig),
        ].join(','));
      }

      final csv = buffer.toString();
      final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'disbursements_export_$ts.csv';

      if (kIsWeb) {
        // saveCsvWeb(filename, csv); // uncomment if you add the helper
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('CSV generated (web): $filename')),
          );
        }
      } else {
        final bytes = Uint8List.fromList(utf8.encode(csv));
        final savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Disbursements CSV',
          fileName: filename,
          type: FileType.custom,
          allowedExtensions: ['csv'],
          bytes: bytes,
          lockParentWindow: true,
        );

        if (savePath == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Export cancelled')),
            );
          }
          return;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved: $savePath')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _csvEscape(String? v) {
    if (v == null) return '';
    final s = v;
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  // ------------------- UI -------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AligoAppbar(title: 'تسليم مواد', showLogout: true),
      endDrawer: const AligoDrawer(),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchAndExportBar(),
            _buildSummaryBar(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? Center(
                          child: Text(
                            staffSearchCtrl.text.isEmpty
                                ? 'لم يتم صرف أي مبالغ حتى الآن.'
                                : 'No matches for "${staffSearchCtrl.text}".',
                            style: const TextStyle(fontSize: 16),
                          ),
                        )
                      : _buildTable(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AddDisbursement()),
          );
        },
        child: const Icon(Icons.post_add_sharp, size: 30),
      ),
    );
  }

  Widget _buildSearchAndExportBar() {
    return Material(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: staffSearchCtrl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'البحث حسب اسم الموظف...',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: staffSearchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            staffSearchCtrl.clear();
                            _applyFilter();
                          },
                        ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed:
                  (_filtered.isNotEmpty && !_exporting) ? _exportCsv : null,
              icon: _exporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.download),
              label: Text(_exporting ? 'جاري التصدير...' : 'تصدير ملف CSV'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.grey.shade100,
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _chip(
            label: 'تسليم مواد',
            value: '$_filteredCount / $_totalCount',
            color: Colors.blueAccent,
          ),
          _chip(
            label: 'أغراض',
            value: '$_filteredQty',
            color: Colors.green,
          ),
          // Uncomment if you want quick date filters still:
          // _filterButton('All', null),
          // _filterButton('Today', 'day'),
          // _filterButton('30 days', 'month'),
          // _filterButton('Annual', 'year'),
        ],
      ),
    );
  }

  Widget _filterButton(String text, String? value) {
    final selected = _dateFilter == value;
    return ChoiceChip(
      label: Text(text),
      selected: selected,
      onSelected: (v) {
        setState(() => _dateFilter = value);
        _loadData();
      },
    );
  }

  Widget _chip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          )
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: <DataColumn>[
            DataColumn(label: Text('Employee', style: tableHead)),
            DataColumn(label: Text('Product ID', style: tableHead)),
            DataColumn(label: Text('Product Name', style: tableHead)),
            DataColumn(label: Text('Quantity', style: tableHead)),
            DataColumn(label: Text('Date', style: tableHead)),
          ],
          rows: _filtered.map((d) {
            final empName =
                _employeeNameById[d.employeeRefId] ?? d.employeeRefId;
            final productName = _productNameById[d.productId] ?? d.productId;
            return DataRow(
              cells: <DataCell>[
                DataCell(Text(empName)),
                DataCell(Text(d.productId)),
                DataCell(Text(productName)),
                DataCell(Text(d.quantity)),
                DataCell(Text(d.dateOfDisbursement)),
              ],
              onSelectChanged: (_) =>
                  _showDetailsDialog(d, empName, productName),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDetailsDialog(
      Disbursement d, String employeeName, String productName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Disbursement Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Employee', employeeName),
              _detailRow('Employee Ref ID', d.employeeRefId),
              _detailRow('Product ID', d.productId),
              _detailRow('Product Name', productName),
              _detailRow('Quantity', d.quantity),
              _detailRow('Date', d.dateOfDisbursement),
              const SizedBox(height: 12),
              const Text('Signature',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              if (d.signatureBase64.isNotEmpty)
                Image.memory(
                  base64Decode(d.signatureBase64),
                  height: 160,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Text('Signature decode error'),
                )
              else
                const Text('No signature'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
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
