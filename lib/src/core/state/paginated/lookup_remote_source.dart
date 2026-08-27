import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../config/res/config_imports.dart';
import '../../network/base/base_remote_source.dart';
import '../../network/error/failures.dart';
import '../../network/http_method.dart';
import 'paginated_data.dart';
import 'pagination_meta.dart';

/// Generic HTTP source for paginated lookup / dropdown endpoints.
///
/// A single injectable singleton shared by every [PaginatedLookupCubit]
/// subclass — keeps Dio wiring out of individual cubits.
///
/// Each call to [fetchPage] is self-contained: the caller supplies the
/// endpoint URL, page number, an optional extra-params map, and a parser
/// function that turns the raw `data` node into a typed list.
@lazySingleton
class LookupRemoteSource extends BaseRemoteSource {
  /// Fetch one page of items for a paginated lookup endpoint.
  ///
  /// Pagination query params (`page`, `paginate`) come from
  /// [ConstantManager.paginateJson]. Extra filters can be merged via
  /// [extraParams] (e.g. `{'country_id': 3}`).
  ///
  /// The response is expected to follow the project standard:
  /// ```json
  /// { "data": [...], "pagination": { ... } }
  /// ```
  /// Both `pagination` and `meta` keys are accepted.
  Future<Either<Failure, PaginatedData<T>>> fetchPage<T>({
    required String endpoint,
    required int page,
    required List<T> Function(dynamic) itemsFromRoot,
    Map<String, dynamic> extraParams = const {},
  }) => request<PaginatedData<T>>(
    method: HttpMethod.get,
    endpoint: endpoint,
    queryParameters: {...ConstantManager.paginateJson(page)!, ...extraParams},
    fromJson: (json) {
      if (json is! Map<String, dynamic>) return PaginatedData<T>.initial();
      final rawData = json['data'];
      final items = itemsFromRoot(
        rawData is List ? rawData : (rawData ?? json),
      );
      final pJson = json['pagination'] ?? json['meta'];
      final meta = pJson is Map<String, dynamic>
          ? PaginationMeta.fromJson(pJson)
          : const PaginationMeta.empty();
      return PaginatedData<T>(items: items, meta: meta);
    },
  );
}
