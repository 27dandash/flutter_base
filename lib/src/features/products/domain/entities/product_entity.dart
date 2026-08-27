import 'package:equatable/equatable.dart';

import '../enums/product_status.dart';

/// Pure domain object — no `fromJson`, no Dio, no Flutter widgets.
/// Used by use-cases, cubits, and UI.
///
/// Serialization is handled by `ProductModel` in `data/models/` and the
/// `ProductMapper` extension in `domain/mappers/`.
class ProductEntity extends Equatable {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final ProductStatus status;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.status,
    this.imageUrl,
  });

  /// Placeholder used by Skeletonizer / shimmer loading states so the UI
  /// can lay out cards before the real data arrives.
  factory ProductEntity.initial() => const ProductEntity(
    id: 0,
    name: '',
    description: '',
    price: 0,
    status: ProductStatus.unknown,
  );

  ProductEntity copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    ProductStatus? status,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [id, name, description, price, imageUrl, status];
}
