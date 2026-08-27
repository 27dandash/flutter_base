import '../../../../core/shared/extensions/json_extensions.dart';

/// DTO mirroring the JSON shape returned by the API.
///
/// Notes
///   - We use `JsonGetters` extension to read every field — never throws,
///     always gives back a sensible fallback when a key is missing or
///     mistyped.
///   - Status is kept as a raw string here. The `ProductMapper` extension
///     in `data/mappers/` is responsible for turning it into the
///     `ProductStatus` enum.
class ProductModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;

  /// Raw status string from the wire — kept here so the data layer never
  /// has to know about domain enums.
  final String? statusRaw;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.statusRaw,
    this.imageUrl,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id: json.getInt('id'),
    name: json.getString('name'),
    description: json.getString('description'),
    price: json.getDouble('price'),
    imageUrl: json.getStringOrNull('image_url'),
    statusRaw: json.getStringOrNull('status'),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'image_url': imageUrl,
    'status': statusRaw,
  };
}
