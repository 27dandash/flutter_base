import 'package:dartz/dartz.dart';

import '../../../../core/network/error/failures.dart';
import '../entities/product_entity.dart';

/// Abstract contract for fetching/mutating products on a remote source.
///
/// Concrete implementation in `data/datasources/` extends `BaseRemoteSource`
/// (Dio + cancellation). Keeping the abstract here means use-cases and
/// tests can swap fakes in without touching the data layer.
abstract interface class ProductsRemoteDataSource {
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
