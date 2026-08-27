import '../../domain/entities/product_entity.dart';
import '../../domain/enums/product_status.dart';
import '../models/product_model.dart';

/// Maps between the data-layer `ProductModel` (wire shape) and the
/// domain-layer `ProductEntity` (clean shape).
///
/// Architectural note
///   The mapper lives in the **data** layer because it knows both the
///   `Model` (data) and the `Entity` (domain). Domain code never imports
///   it — the data-source uses `.toEntity()` before returning, and the
///   data-source uses `.toModel()` before writing.
///
/// Usage
///   ```dart
///   final entity = productModel.toEntity();
///   final model  = productEntity.toModel();
///   ```
extension ProductModelMapper on ProductModel {
  ProductEntity toEntity() => ProductEntity(
    id: id,
    name: name,
    description: description,
    price: price,
    imageUrl: imageUrl,
    status: ProductStatus.fromRaw(statusRaw),
  );
}

extension ProductEntityMapper on ProductEntity {
  ProductModel toModel() => ProductModel(
    id: id,
    name: name,
    description: description,
    price: price,
    imageUrl: imageUrl,
    statusRaw: status.raw,
  );
}
