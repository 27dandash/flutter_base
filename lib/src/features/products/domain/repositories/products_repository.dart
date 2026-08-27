import 'package:dartz/dartz.dart';

import '../../../../core/network/error/failures.dart';
import '../entities/product_entity.dart';

/// Abstract repository — the use-case-facing surface of the feature.
///
/// Use-cases depend on this, not on the data source directly, so we can
/// add cross-cutting concerns (caching, retry policy, logging) inside
/// `ProductsRepositoryImpl` without touching anyone's code.
abstract interface class ProductsRepository {
  // Reads
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    int page = 1,
    String? search,
  });

  Future<Either<Failure, ProductEntity>> getProductById(int id);

  // Writes
  Future<Either<Failure, ProductEntity>> createProduct({
    required String name,
    required String description,
    required double price,
  });

  Future<Either<Failure, ProductEntity>> updateProduct({
    required int id,
    required String name,
    required String description,
    required double price,
  });

  Future<Either<Failure, Unit>> deleteProduct(int id);
}
