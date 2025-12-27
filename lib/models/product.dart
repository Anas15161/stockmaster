import 'dart:convert';

class Product {
  final int? id;
  final String name;
  final String sku;
  final String category;
  final int quantity;
  final double costPrice;
  final double sellingPrice;
  final String? supplier;
  final List<String> images;

  Product({
    this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.quantity,
    required this.costPrice,
    required this.sellingPrice,
    this.supplier,
    this.images = const [],
  });

  // Conversion en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'category': category,
      'quantity': quantity,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'supplier': supplier,
      'images': jsonEncode(images),
    };
  }

  // Création depuis SQLite
  factory Product.fromMap(Map<String, dynamic> map) {
    List<String> parsedImages = [];
    if (map['images'] != null) {
      try {
        final dynamic decoded = jsonDecode(map['images']);
        if (decoded is List) {
          parsedImages = List<String>.from(decoded);
        }
      } catch (e) {
        // Fallback or log error if needed
        parsedImages = [];
      }
    }

    return Product(
      id: map['id'],
      name: map['name'],
      sku: map['sku'],
      category: map['category'],
      quantity: map['quantity'],
      costPrice: map['costPrice'],
      sellingPrice: map['sellingPrice'],
      supplier: map['supplier'],
      images: parsedImages,
    );
  }
}