import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/error/failures.dart';
import '../entities/product_entity.dart';
import '../repositories/products_repository.dart';

@injectable
class GetProductDetailsUseCase {
  const GetProductDetailsUseCase(this._repo);

  final ProductsRepository _repo;

  Future<Either<Failure, ProductEntity>> call(int id) =>
      _repo.getProductById(id);
}
