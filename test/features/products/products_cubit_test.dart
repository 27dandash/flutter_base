import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_base/src/core/network/error/failures.dart';
import 'package:flutter_base/src/features/products/domain/entities/product_entity.dart';
import 'package:flutter_base/src/features/products/domain/enums/product_status.dart';
import 'package:flutter_base/src/features/products/domain/repositories/products_repository.dart';
import 'package:flutter_base/src/features/products/domain/usecases/create_product_usecase.dart';
import 'package:flutter_base/src/features/products/domain/usecases/delete_product_usecase.dart';
import 'package:flutter_base/src/features/products/domain/usecases/get_products_usecase.dart';
import 'package:flutter_base/src/features/products/presentation/imports/products_imports.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements ProductsRepository {}

ProductEntity _p(int id, [String name = 'p']) => ProductEntity(
  id: id,
  name: '$name$id',
  description: '',
  price: 10,
  status: ProductStatus.draft,
);

void main() {
  late _Repo repo;
  late ProductsCubit cubit;

  setUp(() {
    repo = _Repo();
    cubit = ProductsCubit(
      GetProductsUseCase(repo),
      CreateProductUseCase(repo),
      DeleteProductUseCase(repo),
    )..setData([_p(1), _p(2), _p(3)]);
  });

  tearDown(() => cubit.close());

  List<int> ids() => cubit.lastData!.map((p) => p.id).toList();

  group('create', () {
    test('replaces the temp row with the saved product', () async {
      when(
        () => repo.createProduct(
          name: any(named: 'name'),
          description: any(named: 'description'),
          price: any(named: 'price'),
        ),
      ).thenAnswer((_) async => Right(_p(99)));

      await cubit.create(name: 'n', description: 'd', price: 5);

      expect(ids(), [99, 1, 2, 3]);
    });

    test('a failure removes only its own temp row', () async {
      final first = Completer<Either<Failure, ProductEntity>>();
      final second = Completer<Either<Failure, ProductEntity>>();
      final queue = [first, second];
      when(
        () => repo.createProduct(
          name: any(named: 'name'),
          description: any(named: 'description'),
          price: any(named: 'price'),
        ),
      ).thenAnswer((_) => queue.removeAt(0).future);

      final a = cubit.create(name: 'a', description: '', price: 1);
      final b = cubit.create(name: 'b', description: '', price: 1);
      expect(cubit.lastData!.length, 5, reason: 'both temps visible');

      first.complete(const Left(NetworkFailure()));
      expect((await a).isLeft(), isTrue);
      expect(
        cubit.lastData!.length,
        4,
        reason: 'the other create is still pending and must stay',
      );

      second.complete(Right(_p(50)));
      await b;
      expect(ids(), [50, 1, 2, 3]);
    });

    test('a saved product survives a refresh that dropped the temp', () async {
      final pending = Completer<Either<Failure, ProductEntity>>();
      when(
        () => repo.createProduct(
          name: any(named: 'name'),
          description: any(named: 'description'),
          price: any(named: 'price'),
        ),
      ).thenAnswer((_) => pending.future);

      final run = cubit.create(name: 'n', description: '', price: 1);
      cubit.setData([_p(1), _p(2)]); // a refresh replaced the whole list
      pending.complete(Right(_p(77)));
      await run;

      expect(ids(), [77, 1, 2]);
    });

    test('temp ids are unique even within one millisecond', () async {
      final pending = Completer<Either<Failure, ProductEntity>>();
      when(
        () => repo.createProduct(
          name: any(named: 'name'),
          description: any(named: 'description'),
          price: any(named: 'price'),
        ),
      ).thenAnswer((_) => pending.future);

      unawaited(cubit.create(name: 'a', description: '', price: 1));
      unawaited(cubit.create(name: 'b', description: '', price: 1));

      final temps = cubit.lastData!.where((p) => p.id < 0).map((p) => p.id);
      expect(temps.toSet().length, 2);
      pending.complete(Right(_p(1)));
    });
  });

  group('delete', () {
    test('a failure restores the row at its old position', () async {
      when(() => repo.deleteProduct(2))
          .thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await cubit.delete(2);

      expect(result.isLeft(), isTrue);
      expect(ids(), [1, 2, 3]);
    });

    test(
      'a rollback keeps changes made while the request was in flight',
      () async {
        final pending = Completer<Either<Failure, Unit>>();
        when(() => repo.deleteProduct(2)).thenAnswer((_) => pending.future);

        final run = cubit.delete(2);
        expect(ids(), [1, 3]);
        cubit.updateProduct(_p(3, 'renamed'));
        cubit.setData([...cubit.lastData!, _p(4)]); // something added meanwhile
        pending.complete(const Left(NetworkFailure()));
        await run;

        expect(ids(), [1, 2, 3, 4]);
        expect(cubit.lastData!.firstWhere((p) => p.id == 3).name, 'renamed3');
      },
    );

    test('success leaves the row removed', () async {
      when(() => repo.deleteProduct(2))
          .thenAnswer((_) async => const Right(unit));

      await cubit.delete(2);

      expect(ids(), [1, 3]);
    });
  });
}
