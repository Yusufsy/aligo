import 'dart:typed_data';

class Disbursement {
  final int? id;

  /// Prefer storing a string staff ID (Firestore doc id) if not guaranteed numeric.
  final String
      employeeRefId; // Firestore employee doc id or unique staff code (string)
  final String? employeeNumber; // Optional numeric staff number if you have it
  final String productId;
  final String quantity;
  final String dateOfDisbursement;
  final String signatureBase64; // NEW

  Disbursement({
    this.id,
    required this.employeeRefId,
    this.employeeNumber,
    required this.productId,
    required this.quantity,
    required this.dateOfDisbursement,
    required this.signatureBase64,
  });

  factory Disbursement.fromMap(Map<String, dynamic> json) => Disbursement(
        id: json['id'],
        employeeRefId: json['employeeRefId'],
        employeeNumber: json['employeeNumber'],
        productId: json['productId'].toString(),
        quantity: json['quantity'].toString(),
        dateOfDisbursement: json['dateOfDisbursement'],
        signatureBase64: json['signature'] ?? '',
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeRefId': employeeRefId,
      'employeeNumber': employeeNumber,
      'productId': productId,
      'quantity': quantity,
      'dateOfDisbursement': dateOfDisbursement,
      'signature': signatureBase64,
    };
  }
}

class DisbursementRecord {
  final int? id;
  final String employeeRefId;
  final String? employeeNumber;
  final String productId;
  final Uint8List image;
  final String brand;
  final String variety;
  final String quantity;
  final String dateOfDisbursement;
  final String signatureBase64;

  DisbursementRecord({
    this.id,
    required this.employeeRefId,
    this.employeeNumber,
    required this.productId,
    required this.image,
    required this.brand,
    required this.variety,
    required this.quantity,
    required this.dateOfDisbursement,
    required this.signatureBase64,
  });

  factory DisbursementRecord.fromMap(Map<String, dynamic> json) =>
      DisbursementRecord(
        id: json['id'],
        image: json['image'],
        brand: json['brand'],
        variety: json['variety'],
        employeeRefId: json['employeeRefId'],
        employeeNumber: json['employeeNumber'],
        productId: json['productId'].toString(),
        quantity: json['quantity'].toString(),
        dateOfDisbursement: json['dateOfDisbursement'],
        signatureBase64: json['signature'] ?? '',
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeRefId': employeeRefId,
      'employeeNumber': employeeNumber,
      'productId': productId,
      'image': image,
      'brand': brand,
      'variety': variety,
      'quantity': quantity,
      'dateOfDisbursement': dateOfDisbursement,
      'signature': signatureBase64,
    };
  }
}
