import 'dart:async';

import 'package:flutter_base/src/core/network/error/failures.dart';
import 'package:flutter_base/src/core/state/async/async.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Cubit extends AsyncCubit<String> {
  Future<void> run(Future<Either<Failure, String>> Function() call) =>
      execute(call);
}

Widget _host(_Cubit cubit) => MaterialApp(
  home: BlocProvider<_Cubit>.value(
    value: cubit,
    child: Scaffold(
      body: AsyncBlocBuilder<_Cubit, String>(
        initialBuilder: (_) => const Text('initial'),
        loadingBuilder: (_) => const Text('loading'),
        errorBuilder: (_, _) => const Text('safe error'),
        builder: (_, value) => Text('data:$value'),
      ),
    ),
  ),
);

void main() {
  testWidgets('renders initial, loading, success and safe failure branches', (
    tester,
  ) async {
    final cubit = _Cubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(_host(cubit));
    expect(find.text('initial'), findsOneWidget);

    final pending = Completer<Either<Failure, String>>();
    final run = cubit.run(() => pending.future);
    await tester.pumpAndSettle();
    expect(find.text('loading'), findsOneWidget);
    pending.complete(const Right('done'));
    await run;
    await tester.pumpAndSettle();
    expect(find.text('data:done'), findsOneWidget);

    cubit.setFailure(const NetworkFailure(technical: 'private host'));
    await tester.pump();
    expect(find.text('data:done'), findsOneWidget);
    expect(find.textContaining('private host'), findsNothing);
  });
}
