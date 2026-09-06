/// Product model — mirrors shared `products`, `product_identifiers`
/// and `product_categories` tables. Product identity/normalisation is a
/// backend (Member 4) responsibility; Flutter only carries identifiers.
library;

import 'business.dart' show BusinessType;
class Product {
  const Product({
    required this.id,
    required this.name,
    this.brand,
    this.category,
    this.manufacturer,
    this.packSize,
    this.gtin,
  });

  final String id;
  final String name;
  final String? brand;
  final String? category;
  final String? manufacturer;
  final String? packSize;

  /// Global Trade Item Number / barcode if known.
  final String? gtin;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        brand: json['brand'] as String?,
        category: json['category'] as String?,
        manufacturer: json['manufacturer'] as String?,
        packSize: json['packSize'] as String?,
        gtin: json['gtin'] as String?,
      );
}

/// Supply-chain supplier record — mirrors shared `suppliers` table.
/// Relationships are created by the backend; Flutter submits declarations.
class Supplier {
  const Supplier({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    this.gstin,
    this.lastPurchaseDate,
  });

  final String id;
  final String name;
  final BusinessType type;
  final String location;
  final String? gstin;
  final DateTime? lastPurchaseDate;
}
