import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_base/src/core/network/error/failures.dart';
import 'package:flutter_base/src/core/state/async/async.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class _CounterCubit extends AsyncCubit<int> {}

void main() {
  group('AsyncCubit', () {
    test('starts in AsyncInitial', () {
      expect(_CounterCubit().state, isA<AsyncInitial<int>>());
    });

    blocTest<_CounterCubit, AsyncState<int>>(
      'execute success emits Loading -> Success',
      build: _CounterCubit.new,
      act: (c) => c.execute(() async => const Right(5)),
      expect: () => [const AsyncLoading<int>(), const AsyncSuccess<int>(5)],
    );

    blocTest<_CounterCubit, AsyncState<int>>(
      'execute failure emits Loading -> Failure',
      build: _CounterCubit.new,
      act: (c) => c.execute(() async => const Left(NetworkFailure())),
      expect: () => [
        const AsyncLoading<int>(),
        const AsyncFailure<int>(NetworkFailure()),
      ],
    );

    blocTest<_CounterCubit, AsyncState<int>>(
      'CancelledFailure restores initial instead of leaving loading stuck',
      build: _CounterCubit.new,
      act: (c) => c.execute(() async => const Left(CancelledFailure())),
      expect: () => [const AsyncLoading<int>(), const AsyncInitial<int>()],
    );

    blocTest<_CounterCubit, AsyncState<int>>(
      'setData emits Success without re-fetch',
      build: _CounterCubit.new,
      act: (c) => c.setData(9),
      expect: () => [const AsyncSuccess<int>(9)],
    );

    blocTest<_CounterCubit, AsyncState<int>>(
      'setFailure emits Failure',
      build: _CounterCubit.new,
      act: (c) => c.setFailure(const ServerFailure()),
      expect: () => [const AsyncFailure<int>(ServerFailure())],
    );

    blocTest<_CounterCubit, AsyncState<int>>(
      'keeps last data as previous after a later failure',
      build: _CounterCubit.new,
      act: (c) async {
        await c.execute(() async => const Right(7));
        await c.execute(() async => const Left(NetworkFailure()));
      },
      expect: () => [
        const AsyncLoading<int>(),
        const AsyncSuccess<int>(7),
        const AsyncLoading<int>(previous: 7),
        const AsyncFailure<int>(NetworkFailure(), previous: 7),
      ],
    );

    blocTest<_CounterCubit, AsyncState<int>>(
      'maps an unexpected throw to a typed failure',
      build: _CounterCubit.new,
      act: (c) => c.execute(() async => throw StateError('sensitive value')),
      expect: () => [
        const AsyncLoading<int>(),
        isA<AsyncFailure<int>>().having(
          (state) => state.failure,
          'failure',
          isA<UnknownFailure>().having(
            (failure) => failure.technical,
            'redacted technical message',
            'Unexpected StateError',
          ),
        ),
      ],
    );

    test('latest concurrent execution wins', () async {
      final first = Completer<Either<Failure, int>>();
      final second = Completer<Either<Failure, int>>();
      final cubit = _CounterCubit();
      final states = <AsyncState<int>>[];
      final subscription = cubit.stream.listen(states.add);

      final firstRun = cubit.execute(() => first.future);
      final secondRun = cubit.execute(() => second.future);
      second.complete(const Right(2));
      await secondRun;
      first.complete(const Right(1));
      await firstRun;

      expect(cubit.state, const AsyncSuccess<int>(2));
      expect(states.whereType<AsyncSuccess<int>>(), [const AsyncSuccess(2)]);
      await subscription.cancel();
      await cubit.close();
    });

    test('completion after close is ignored', () async {
      final result = Completer<Either<Failure, int>>();
      final cubit = _CounterCubit();
      final run = cubit.execute(() => result.future);
      await cubit.close();
      result.complete(const Right(1));
      await run;
      expect(cubit.isClosed, isTrue);
    });
  });
}
