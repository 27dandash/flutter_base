part of '../imports/products_imports.dart';

/// Lists products with optional search + handles create/update/delete.
///
/// Pattern recap (from `core/state/async_cubit.dart`)
///   - `execute(() => useCase(...))`  → emits Loading → Success/Failure
///                                     by folding the `Either<Failure,T>`.
///   - `setData(newList)`             → push a local mutation without
///                                     re-fetching (CRUD optimism).
///   - `setFailure(SomeFailure(...))` → force an error state.
///   - `state` is a sealed `AsyncState<T>` → exhaustive in the UI.
///
/// The cubit holds **list state only**. Selected filters / search text
/// live in [ProductsViewController] (bloc owns server data, controller
/// owns ephemeral UI state).
@injectable
class ProductsCubit extends AsyncCubit<List<ProductEntity>> {
  ProductsCubit(this._getProducts, this._createProduct, this._deleteProduct);

  final GetProductsUseCase _getProducts;
  final CreateProductUseCase _createProduct;
  final DeleteProductUseCase _deleteProduct;

  // ── Initial / refresh fetch ───────────────────────────────────────

  Future<void> fetchProducts({String? search}) {
    return execute(() => _getProducts(search: search));
  }

  // ── Create — optimistic insert + server confirmation ──────────────

  /// Optimistic flow:
  ///   1. Show a temporary product on top of the list immediately.
  ///   2. Fire POST in the background.
  ///   3. On success: replace the temp with the server-confirmed entity.
  ///   4. On failure: roll back (remove the temp) and surface the failure.
  Future<Either<Failure, ProductEntity>> create({
    required String name,
    required String description,
    required double price,
  }) async {
    final temp = ProductEntity(
      id: -DateTime.now().millisecondsSinceEpoch, // negative = temp id
      name: name,
      description: description,
      price: price,
      status: ProductStatus.draft,
    );
    final current = lastData ?? const <ProductEntity>[];
    setData([temp, ...current]);

    final result = await _createProduct(
      name: name,
      description: description,
      price: price,
    );

    return result.fold(
      (failure) {
        // Roll back.
        setData(current);
        return Left(failure);
      },
      (saved) {
        // Replace temp with server-confirmed product.
        final updated = (lastData ?? const <ProductEntity>[])
            .map((p) => p.id == temp.id ? saved : p)
            .toList();
        setData(updated);
        return Right(saved);
      },
    );
  }

  // ── Local edit (e.g. when an edit screen returns) ────────────────

  void updateProduct(ProductEntity updated) {
    final current = lastData ?? const <ProductEntity>[];
    setData(current.map((p) => p.id == updated.id ? updated : p).toList());
  }

  // ── Delete — optimistic remove + rollback on server failure ──────

  Future<Either<Failure, Unit>> delete(int id) async {
    final current = lastData ?? const <ProductEntity>[];
    setData(current.where((p) => p.id != id).toList());

    final result = await _deleteProduct(id);
    return result.fold((failure) {
      setData(current); // restore
      return Left(failure);
    }, Right.new);
  }
}
