import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/error/failures.dart';
import '../../domain/datasources/products_remote_data_source.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/products_repository.dart';

/// Concrete repository.
///
/// Right now it's a thin pass-through — the remote data source already
/// returns `Either<Failure, T>`. The moment we add a second data source
/// (e.g. a Hive cache, an in-memory mirror) this class is where the
/// "try cache then remote" logic lives — without anyone upstream caring.
@LazySingleton(as: ProductsRepository)
class ProductsRepositoryImpl implements ProductsRepository {
  const ProductsRepositoryImpl(this._remote);

  final ProductsRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    int page = 1,
    String? search,
  }) => _remote.getProducts(page: page, search: search);

  @override
  Future<Either<Failure, ProductEntity>> getProductById(int id) =>
      _remote.getProductById(id);

  @override
  Future<Either<Failure, ProductEntity>> createProduct({
    required String name,
    required String description,
    required double price,
  }) =>
      _remote.createProduct(name: name, description: description, price: price);

  @override
  Future<Either<Failure, ProductEntity>> updateProduct({
    required int id,
    required String name,
    required String description,
    required double price,
  }) => _remote.updateProduct(
    id: id,
    name: name,
    description: description,
    price: price,
  );

  @override
  Future<Either<Failure, Unit>> deleteProduct(int id) =>
      _remote.deleteProduct(id);
}
