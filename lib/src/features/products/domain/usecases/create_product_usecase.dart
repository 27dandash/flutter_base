import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/error/failures.dart';
import '../entities/product_entity.dart';
import '../repositories/products_repository.dart';

/// Creates a product on the server.
///
/// Business rule example
///   - Price must be strictly positive — we short-circuit with a
///     `ValidationFailure` before any network call.
@injectable
class CreateProductUseCase {
  const CreateProductUseCase(this._repo);

  final ProductsRepository _repo;

  Future<Either<Failure, ProductEntity>> call({
    required String name,
    required String description,
    required double price,
  }) {
    if (price <= 0) {
      return Future.value(
        const Left(
          ValidationFailure(
            // Falls back to LocaleKeys.failureValidation when omitted —
            // here we surface a field-level message instead.
            fields: {
              'price': ['Price must be > 0'],
            },
          ),
        ),
      );
    }
    return _repo.createProduct(
      name: name.trim(),
      description: description.trim(),
      price: price,
    );
  }
}
