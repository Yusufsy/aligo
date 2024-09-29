import 'dart:typed_data';

class Disbursement {
  final int? id;
  final int employeeId;
  final String productId;
  final String quantity;

  // final String amount;
  final String dateOfDisbursement;

  Disbursement({
    this.id,
    required this.employeeId,
    required this.productId,
    required this.quantity,
    // required this.amount,
    required this.dateOfDisbursement,
  });

  factory Disbursement.fromMap(Map<String, dynamic> json) => Disbursement(
      id: json['id'],
      employeeId: json['employeeId'],
      productId: json['productId'].toString(),
      quantity: json['quantity'].toString(),
      // amount: json['amount'].toString(),
      dateOfDisbursement: json['dateOfDisbursement']);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'productId': productId,
      'quantity': quantity,
      // 'amount': amount,
      'dateOfDisbursement': dateOfDisbursement
    };
  }
}

class DisbursementRecord {
  final int? id;
  final int employeeId;
  final String productId;
  final Uint8List image;
  final String brand;
  final String variety;
  final String quantity;

  // final String cost;
  // final String price;
  // final String amount;
  final String dateOfDisbursement;

  DisbursementRecord({
    this.id,
    required this.employeeId,
    required this.productId,
    required this.image,
    required this.brand,
    required this.variety,
    required this.quantity,
    // required this.cost,
    // required this.price,
    // required this.amount,
    required this.dateOfDisbursement,
  });

  factory DisbursementRecord.fromMap(Map<String, dynamic> json) =>
      DisbursementRecord(
          id: json['id'],
          image: json['image'],
          brand: json['brand'],
          variety: json['variety'],
          employeeId: json['employeeId'],
          productId: json['productId'].toString(),
          quantity: json['quantity'].toString(),
          // cost: json['cost'].toString(),
          // price: json['price'].toString(),
          // amount: json['amount'].toString(),
          dateOfDisbursement: json['dateOfDisbursement']);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'productId': productId,
      'image': image,
      'brand': brand,
      'variety': brand,
      'quantity': quantity,
      // 'cost': cost,
      // 'price': price,
      // 'amount': amount,
      'dateOfDisbursement': dateOfDisbursement
    };
  }
}
