#!/usr/bin/env bash
#
# Generates a clean-architecture feature scaffold that compiles out of the box
# and follows the project rules (see lib/src/features/products/ for the
# reference implementation).
#
# Usage:
#   ./scripts/new_feature.sh <feature_snake> [entity_snake]
#
# Examples:
#   ./scripts/new_feature.sh orders            # entity defaults to "order"
#   ./scripts/new_feature.sh blog_posts post   # plural feature, singular entity
#
# After running:
#   1) dart run build_runner build --delete-conflicting-outputs   (wire DI)
#   2) Add the endpoint to lib/src/core/network/api_endpoints.dart
#   3) flutter analyze
#
set -euo pipefail

FEATURE="${1:-}"
if [[ -z "$FEATURE" ]]; then
  echo "Usage: $0 <feature_snake> [entity_snake]" >&2
  exit 1
fi

# Default entity = feature with a trailing 's' stripped.
ENTITY="${2:-${FEATURE%s}}"

# ── name helpers ──────────────────────────────────────────────────────
to_pascal() { echo "$1" | awk -F'_' '{for(i=1;i<=NF;i++)printf "%s",toupper(substr($i,1,1)) substr($i,2)}'; }
to_camel()  { local p; p="$(to_pascal "$1")"; echo "$(echo "${p:0:1}" | tr '[:upper:]' '[:lower:]')${p:1}"; }

FEATURE_PASCAL="$(to_pascal "$FEATURE")"   # e.g. Orders
ENTITY_PASCAL="$(to_pascal "$ENTITY")"     # e.g. Order
ENTITY_CAMEL="$(to_camel "$ENTITY")"       # e.g. order

ROOT="lib/src/features/${FEATURE}"
if [[ -e "$ROOT" ]]; then
  echo "✗ $ROOT already exists — aborting." >&2
  exit 1
fi

echo "→ Scaffolding feature '$FEATURE' (entity: $ENTITY_PASCAL) at $ROOT"

mkdir -p \
  "$ROOT/data/datasources" "$ROOT/data/models" "$ROOT/data/mappers" "$ROOT/data/repositories" \
  "$ROOT/domain/datasources" "$ROOT/domain/entities" "$ROOT/domain/repositories" "$ROOT/domain/usecases" \
  "$ROOT/presentation/imports" "$ROOT/presentation/cubits" "$ROOT/presentation/controllers" \
  "$ROOT/presentation/view" "$ROOT/presentation/widgets"

# ── domain/entities ───────────────────────────────────────────────────
cat > "$ROOT/domain/entities/${ENTITY}_entity.dart" <<EOF
import 'package:equatable/equatable.dart';

/// Pure domain object — no fromJson, no Dio, no Flutter.
class ${ENTITY_PASCAL}Entity extends Equatable {
  final int id;
  final String name;

  const ${ENTITY_PASCAL}Entity({required this.id, required this.name});

  /// Safe placeholder for skeleton/loading states.
  factory ${ENTITY_PASCAL}Entity.initial() =>
      const ${ENTITY_PASCAL}Entity(id: 0, name: '');

  @override
  List<Object?> get props => [id, name];
}
EOF

# ── data/models ───────────────────────────────────────────────────────
cat > "$ROOT/data/models/${ENTITY}_model.dart" <<EOF
/// Wire DTO. Null-safe parsing with type coercion (entity-safety rule).
class ${ENTITY_PASCAL}Model {
  final int id;
  final String name;

  const ${ENTITY_PASCAL}Model({required this.id, required this.name});

  factory ${ENTITY_PASCAL}Model.fromJson(Map<String, dynamic> json) =>
      ${ENTITY_PASCAL}Model(
        id: int.tryParse('\${json['id'] ?? ''}') ?? 0,
        name: (json['name'] ?? '').toString(),
      );
}
EOF

# ── data/mappers ──────────────────────────────────────────────────────
cat > "$ROOT/data/mappers/${ENTITY}_mapper.dart" <<EOF
import '../../domain/entities/${ENTITY}_entity.dart';
import '../models/${ENTITY}_model.dart';

/// Model → Entity mapping kept out of both classes so each stays focused.
extension ${ENTITY_PASCAL}MapperX on ${ENTITY_PASCAL}Model {
  ${ENTITY_PASCAL}Entity toEntity() =>
      ${ENTITY_PASCAL}Entity(id: id, name: name);
}
EOF

# ── domain/datasources (abstract) ─────────────────────────────────────
cat > "$ROOT/domain/datasources/${FEATURE}_remote_data_source.dart" <<EOF
import 'package:dartz/dartz.dart';

import '../../../../core/network/error/failures.dart';
import '../entities/${ENTITY}_entity.dart';

abstract interface class ${FEATURE_PASCAL}RemoteDataSource {
  Future<Either<Failure, List<${ENTITY_PASCAL}Entity>>> get${FEATURE_PASCAL}({
    int page,
  });
}
EOF

# ── data/datasources (impl) ───────────────────────────────────────────
cat > "$ROOT/data/datasources/${FEATURE}_remote_data_source_impl.dart" <<EOF
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/base/base_remote_source.dart';
import '../../../../core/network/error/failures.dart';
import '../../../../core/network/http_method.dart';
import '../../domain/datasources/${FEATURE}_remote_data_source.dart';
import '../../domain/entities/${ENTITY}_entity.dart';
import '../mappers/${ENTITY}_mapper.dart';
import '../models/${ENTITY}_model.dart';

@LazySingleton(as: ${FEATURE_PASCAL}RemoteDataSource)
class ${FEATURE_PASCAL}RemoteDataSourceImpl extends BaseRemoteSource
    implements ${FEATURE_PASCAL}RemoteDataSource {
  ${FEATURE_PASCAL}RemoteDataSourceImpl();

  // TODO: move this literal into ApiEndpoints once the route is final.
  static const String _endpoint = '${FEATURE}';

  @override
  Future<Either<Failure, List<${ENTITY_PASCAL}Entity>>> get${FEATURE_PASCAL}({
    int page = 1,
  }) {
    return request<List<${ENTITY_PASCAL}Entity>>(
      method: HttpMethod.get,
      endpoint: _endpoint,
      queryParameters: {'page': page},
      fromJson: _parseList,
    );
  }

  List<${ENTITY_PASCAL}Entity> _parseList(dynamic json) {
    final data = json is Map<String, dynamic> ? json['data'] : json;
    final list = data is List ? data : const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => ${ENTITY_PASCAL}Model.fromJson(e).toEntity())
        .toList();
  }
}
EOF

# ── domain/repositories (abstract) ────────────────────────────────────
cat > "$ROOT/domain/repositories/${FEATURE}_repository.dart" <<EOF
import 'package:dartz/dartz.dart';

import '../../../../core/network/error/failures.dart';
import '../entities/${ENTITY}_entity.dart';

abstract interface class ${FEATURE_PASCAL}Repository {
  Future<Either<Failure, List<${ENTITY_PASCAL}Entity>>> get${FEATURE_PASCAL}({
    int page,
  });
}
EOF

# ── data/repositories (impl) ──────────────────────────────────────────
cat > "$ROOT/data/repositories/${FEATURE}_repository_impl.dart" <<EOF
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/error/failures.dart';
import '../../domain/datasources/${FEATURE}_remote_data_source.dart';
import '../../domain/entities/${ENTITY}_entity.dart';
import '../../domain/repositories/${FEATURE}_repository.dart';

@LazySingleton(as: ${FEATURE_PASCAL}Repository)
class ${FEATURE_PASCAL}RepositoryImpl implements ${FEATURE_PASCAL}Repository {
  const ${FEATURE_PASCAL}RepositoryImpl(this._remote);

  final ${FEATURE_PASCAL}RemoteDataSource _remote;

  @override
  Future<Either<Failure, List<${ENTITY_PASCAL}Entity>>> get${FEATURE_PASCAL}({
    int page = 1,
  }) =>
      _remote.get${FEATURE_PASCAL}(page: page);
}
EOF

# ── domain/usecases ───────────────────────────────────────────────────
cat > "$ROOT/domain/usecases/get_${FEATURE}_usecase.dart" <<EOF
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/error/failures.dart';
import '../entities/${ENTITY}_entity.dart';
import '../repositories/${FEATURE}_repository.dart';

@injectable
class Get${FEATURE_PASCAL}UseCase {
  const Get${FEATURE_PASCAL}UseCase(this._repo);

  final ${FEATURE_PASCAL}Repository _repo;

  Future<Either<Failure, List<${ENTITY_PASCAL}Entity>>> call({int page = 1}) =>
      _repo.get${FEATURE_PASCAL}(page: page);
}
EOF

# ── presentation/imports (part hub) ───────────────────────────────────
cat > "$ROOT/presentation/imports/${FEATURE}_imports.dart" <<EOF
/// part / part of hub for the ${FEATURE_PASCAL} feature presentation layer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../config/res/config_imports.dart';
import '../../../../core/state/async/async.dart';
import '../../../../core/widgets/scaffolds/default_scaffold.dart';
import '../../domain/entities/${ENTITY}_entity.dart';
import '../../domain/usecases/get_${FEATURE}_usecase.dart';

part '../cubits/${FEATURE}_cubit.dart';
part '../view/${FEATURE}_screen.dart';
part '../widgets/${FEATURE}_body.dart';
EOF

# ── presentation/cubits ───────────────────────────────────────────────
cat > "$ROOT/presentation/cubits/${FEATURE}_cubit.dart" <<EOF
part of '../imports/${FEATURE}_imports.dart';

@injectable
class ${FEATURE_PASCAL}Cubit extends AsyncCubit<List<${ENTITY_PASCAL}Entity>> {
  ${FEATURE_PASCAL}Cubit(this._get${FEATURE_PASCAL});

  final Get${FEATURE_PASCAL}UseCase _get${FEATURE_PASCAL};

  Future<void> fetch${FEATURE_PASCAL}() =>
      execute(() => _get${FEATURE_PASCAL}());
}
EOF

# ── presentation/view ─────────────────────────────────────────────────
cat > "$ROOT/presentation/view/${FEATURE}_screen.dart" <<EOF
part of '../imports/${FEATURE}_imports.dart';

/// Public entry point — wire navigators to \`const ${FEATURE_PASCAL}Screen()\`.
class ${FEATURE_PASCAL}Screen extends StatefulWidget {
  const ${FEATURE_PASCAL}Screen({super.key});

  @override
  State<${FEATURE_PASCAL}Screen> createState() => _${FEATURE_PASCAL}ScreenState();
}

class _${FEATURE_PASCAL}ScreenState extends State<${FEATURE_PASCAL}Screen> {
  late final ${FEATURE_PASCAL}Cubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = injector<${FEATURE_PASCAL}Cubit>()..fetch${FEATURE_PASCAL}();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<${FEATURE_PASCAL}Cubit>.value(
      value: _cubit,
      child: DefaultScaffold(
        // TODO: replace with a feature-specific LocaleKeys.* title.
        title: ConstantManager.appName,
        body: const _${FEATURE_PASCAL}Body(),
      ),
    );
  }
}
EOF

# ── presentation/widgets ──────────────────────────────────────────────
cat > "$ROOT/presentation/widgets/${FEATURE}_body.dart" <<EOF
part of '../imports/${FEATURE}_imports.dart';

class _${FEATURE_PASCAL}Body extends StatelessWidget {
  const _${FEATURE_PASCAL}Body();

  @override
  Widget build(BuildContext context) {
    return AsyncBlocBuilder<${FEATURE_PASCAL}Cubit, List<${ENTITY_PASCAL}Entity>>(
      onRetry: () => context.read<${FEATURE_PASCAL}Cubit>().fetch${FEATURE_PASCAL}(),
      builder: (context, items) {
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) => ListTile(title: Text(items[i].name)),
        );
      },
    );
  }
}
EOF

echo "✓ Created \$(find "$ROOT" -name '*.dart' | wc -l | tr -d ' ') Dart files."
echo
echo "Next steps:"
echo "  1) dart run build_runner build --delete-conflicting-outputs"
echo "  2) Add the real endpoint to lib/src/core/network/api_endpoints.dart"
echo "  3) flutter analyze"
