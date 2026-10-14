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
  ///   4. On failure: remove **only that temp** and surface the failure.
  ///
  /// Each step edits the list as it is *now* instead of restoring a snapshot,
  /// so overlapping creates/deletes (or a refresh that landed meanwhile) are
  /// never undone by the outcome of an unrelated request.
  Future<Either<Failure, ProductEntity>> create({
    required String name,
    required String description,
    required double price,
  }) async {
    final temp = ProductEntity(
      id: -_nextTempId++, // negative = temp id, unique per call
      name: name,
      description: description,
      price: price,
      status: ProductStatus.draft,
    );
    setData([temp, ...?lastData]);

    final result = await _createProduct(
      name: name,
      description: description,
      price: price,
    );

    return result.fold(
      (failure) {
        setData([...?lastData].where((p) => p.id != temp.id).toList());
        return Left(failure);
      },
      (saved) {
        final items = [...?lastData];
        final index = items.indexWhere((p) => p.id == temp.id);
        if (index >= 0) {
          items[index] = saved;
        } else if (!items.any((p) => p.id == saved.id)) {
          // The temp row vanished (a refresh replaced the list); the created
          // product must still show up.
          items.insert(0, saved);
        }
        setData(items);
        return Right(saved);
      },
    );
  }

  int _nextTempId = DateTime.now().millisecondsSinceEpoch;

  // ── Local edit (e.g. when an edit screen returns) ────────────────

  void updateProduct(ProductEntity updated) {
    final current = lastData ?? const <ProductEntity>[];
    setData(current.map((p) => p.id == updated.id ? updated : p).toList());
  }

  // ── Delete — optimistic remove + rollback on server failure ──────

  /// Removes the row immediately and puts back **that row** (at its old
  /// position) if the server refuses. Other changes made meanwhile stay.
  Future<Either<Failure, Unit>> delete(int id) async {
    final before = lastData ?? const <ProductEntity>[];
    final index = before.indexWhere((p) => p.id == id);
    final removed = index >= 0 ? before[index] : null;
    setData(before.where((p) => p.id != id).toList());

    final result = await _deleteProduct(id);
    return result.fold((failure) {
      if (removed != null) {
        final items = [...?lastData];
        if (!items.any((p) => p.id == id)) {
          items.insert(index.clamp(0, items.length), removed);
          setData(items);
        }
      }
      return Left(failure);
    }, Right.new);
  }
}
