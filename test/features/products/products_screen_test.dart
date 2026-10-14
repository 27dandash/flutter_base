import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_base/src/config/res/config_imports.dart';
import 'package:flutter_base/src/features/products/domain/repositories/products_repository.dart';
import 'package:flutter_base/src/features/products/domain/usecases/create_product_usecase.dart';
import 'package:flutter_base/src/features/products/domain/usecases/delete_product_usecase.dart';
import 'package:flutter_base/src/features/products/domain/usecases/get_products_usecase.dart';
import 'package:flutter_base/src/features/products/presentation/imports/products_imports.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements ProductsRepository {}

Widget _host() => ScreenUtilInit(
  designSize: const Size(375, 812),
  builder: (_, _) => const MaterialApp(home: ProductsScreen()),
);

void main() {
  late _Repo repo;

  setUp(() {
    repo = _Repo();
    when(
      () => repo.getProducts(
        page: any(named: 'page'),
        search: any(named: 'search'),
      ),
    ).thenAnswer((_) async => const Right([]));
    injector.registerFactory<ProductsCubit>(
      () => ProductsCubit(
        GetProductsUseCase(repo),
        CreateProductUseCase(repo),
        DeleteProductUseCase(repo),
      ),
    );
  });

  tearDown(() => injector.reset());

  testWidgets('opening the screen fetches the list exactly once', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.pump(const Duration(milliseconds: 50));
    // Longer than the 350ms search debounce: the seeded empty query used to
    // fire a second, identical request here.
    await tester.pump(const Duration(milliseconds: 600));

    verify(
      () => repo.getProducts(
        page: any(named: 'page'),
        search: any(named: 'search'),
      ),
    ).called(1);
  });

  testWidgets('typing a search term fetches once after the debounce', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 600));
    clearInteractions(repo);

    await tester.enterText(find.byType(TextField).first, 'shoe');
    await tester.pump(const Duration(milliseconds: 100));
    verifyNever(
      () => repo.getProducts(
        page: any(named: 'page'),
        search: any(named: 'search'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    verify(() => repo.getProducts(page: 1, search: 'shoe')).called(1);
  });
}
