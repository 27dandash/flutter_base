import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_base/src/features/products/domain/enums/product_status.dart';
import 'package:flutter_base/src/features/products/presentation/imports/products_imports.dart';

void main() {
  test('clear result removes the committed filter', () {
    final controller = ProductsViewController(onSearch: (_) {});
    controller.setStatusFilter(ProductStatus.available);

    controller.applyFilterSheetResult(const ProductsStatusFilterCleared());

    expect(controller.statusFilter.value, isNull);
    controller.dispose();
  });

  test('dismissed result leaves the committed filter unchanged', () {
    final controller = ProductsViewController(onSearch: (_) {});
    controller.setStatusFilter(ProductStatus.draft);

    controller.applyFilterSheetResult(const ProductsStatusFilterDismissed());
    controller.applyFilterSheetResult(null);

    expect(controller.statusFilter.value, ProductStatus.draft);
    controller.dispose();
  });

  test('selected result commits the chosen status', () {
    final controller = ProductsViewController(onSearch: (_) {});

    controller.applyFilterSheetResult(
      const ProductsStatusFilterSelected(ProductStatus.available),
    );

    expect(controller.statusFilter.value, ProductStatus.available);
    controller.dispose();
  });
}
