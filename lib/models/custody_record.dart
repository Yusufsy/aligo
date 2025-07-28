import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model (all optional except name + signature)
class CustodyRecord {
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
  final String? hashMarks; // For the field labeled "##"
  final String? ip1;
  final String? ip2;
  final String? notes;
  final DateTime createdAt;

  CustodyRecord({
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
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'name': name,
        'signature': signatureBase64,
        'computerType': computerType,
        'laptopSN': laptopSn,
        'caseModel': caseModel,
        'keyboard': keyboard,
        'mouse': mouse,
        'monitor': monitor,
        'printer': printer,
        'ups': ups,
        'scanner': scanner,
        'department': department,
        'level': level,
        'cpu': cpu,
        'hashMarks': hashMarks,
        'ip_1': ip1,
        'ip_2': ip2,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
