import 'dart:typed_data';

class Inventory {
  final int? id;
  final String code;
  final String brand;
  final String variety;
  final String colour;
  final String quantity;

  // final String cost;
  // final String price;
  final String dateAdded;
  final Uint8List image;

  Inventory(
      {this.id,
      required this.code,
      required this.brand,
      required this.variety,
      required this.colour,
      required this.quantity,
      // required this.cost,
      // required this.price,
      required this.dateAdded,
      required this.image});

  factory Inventory.fromMap(Map<String, dynamic> json) => Inventory(
      id: json['id'],
      code: json['code'],
      brand: json['brand'],
      variety: json['variety'],
      colour: json['colour'],
      quantity: json['quantity'].toString(),
      // cost: json['cost'].toString(),
      // price: json['price'].toString(),
      dateAdded: json['date_added'],
      image: json['image']);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'brand': brand,
      'variety': variety,
      'colour': colour,
      'quantity': quantity,
      // 'cost': cost,
      // 'price': price,
      'date_added': dateAdded,
      'image': image
    };
  }
}
