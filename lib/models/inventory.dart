class Inventory {
  final int? id;
  final String code;
  final String brand;
  final String variety;
  final String colour;
  final String quantity;
  final String dateAdded;
  final String imageUrl;
  final String? imagePath;

  // --- NEW FIELDS ---
  final String? type; // Main type: 'Computer', 'Mouse', etc.
  final String? computerType; // Sub-type for computer: 'laptop' or 'desktop'
  final String? caseModel;
  final String? laptopSn; // Laptop Serial Number

  Inventory({
    this.id,
    required this.code,
    required this.brand,
    required this.variety,
    required this.colour,
    required this.quantity,
    required this.dateAdded,
    required this.imageUrl,
    this.imagePath,
    // --- Add new fields to constructor ---
    this.type,
    this.computerType,
    this.caseModel,
    this.laptopSn,
  });

  factory Inventory.fromMap(Map<String, dynamic> json) => Inventory(
        id: json['id'],
        code: json['code'],
        brand: json['brand'],
        variety: json['variety'],
        colour: json['colour'],
        quantity: json['quantity'].toString(),
        dateAdded: json['date_added'],
        imageUrl: json['image_url'],
        imagePath: json['image_path'],
        // --- Read new fields from map ---
        type: json['type'],
        computerType: json['computer_type'],
        caseModel: json['case_model'],
        laptopSn: json['laptop_sn'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'code': code,
        'brand': brand,
        'variety': variety,
        'colour': colour,
        'quantity': quantity,
        'date_added': dateAdded,
        'image_url': imageUrl,
        if (imagePath != null) 'image_path': imagePath,
        // --- Add new fields to map if they exist ---
        if (type != null) 'type': type,
        if (computerType != null) 'computer_type': computerType,
        if (caseModel != null) 'case_model': caseModel,
        if (laptopSn != null) 'laptop_sn': laptopSn,
      };
}
