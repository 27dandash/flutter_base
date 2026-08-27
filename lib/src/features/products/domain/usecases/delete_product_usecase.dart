import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/error/failures.dart';
import '../repositories/products_repository.dart';

@injectable
class DeleteProductUseCase {
  const DeleteProductUseCase(this._repo);

  final ProductsRepository _repo;

  Future<Either<Failure, Unit>> call(int id) => _repo.deleteProduct(id);
}
