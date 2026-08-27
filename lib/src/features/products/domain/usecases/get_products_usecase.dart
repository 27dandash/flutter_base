import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/error/failures.dart';
import '../entities/product_entity.dart';
import '../repositories/products_repository.dart';

/// Thin use-case wrapping a single repository call.
///
/// Why use-cases exist:
///   - Cubits stay tiny — they only know which use-case to run.
///   - Business rules (e.g. "search needs at least 2 chars") live here,
///     not in the cubit or the data source.
///   - Easy to unit-test: feed a fake repo, assert the use-case behaviour.
///
/// Returns `Either<Failure, ...>` — the cubit `.fold`s on it.
@injectable
class GetProductsUseCase {
  const GetProductsUseCase(this._repo);

  final ProductsRepository _repo;

  /// Callable syntax: `useCase(search: 'shoe')`.
  Future<Either<Failure, List<ProductEntity>>> call({
    int page = 1,
    String? search,
  }) {
    // Business rule example — trim & drop tiny search terms so we don't
    // hammer the backend on the very first keystroke.
    final trimmed = search?.trim();
    final cleaned = (trimmed != null && trimmed.length < 2) ? null : trimmed;

    return _repo.getProducts(page: page, search: cleaned);
  }
}
