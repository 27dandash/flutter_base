part of '../imports/products_imports.dart';

/// Single-product details screen. The cubit is constructed fresh for each
/// details screen (see the `@injectable` factory binding) so two products
/// opened in sequence never share state.
@injectable
class ProductDetailsCubit extends AsyncCubit<ProductEntity> {
  ProductDetailsCubit(this._getProduct);

  final GetProductDetailsUseCase _getProduct;

  Future<void> fetchDetails(int id) {
    return execute(() => _getProduct(id));
  }
}
