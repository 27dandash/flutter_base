import 'package:dartz/dartz.dart';

import '../../network/error/failures.dart';
import 'lookup_remote_source.dart';
import 'paginated_async_cubit.dart';
import 'paginated_data.dart';

/// Abstract base for every paginated lookup / dropdown cubit.
///
/// Subclasses implement only two methods:
///   • [apiEndpoint] — the endpoint URL (use [key] for dependent dropdowns)
///   • [itemsFromRoot] — maps raw `data` to a typed `List<T>`
///
/// Pagination query params (`page`, `paginate`) are injected automatically
/// via [LookupRemoteSource]. The cubit inherits the full
/// [PaginatedAsyncCubit] API: `fetchInitialData`, `loadMore`, `refresh`,
/// and optimistic local mutations.
///
/// ### Independent lookup example
/// ```dart
/// @injectable
/// class CountriesCubit extends PaginatedLookupCubit<CountryEntity> {
///   CountriesCubit(super.source);
///
///   @override
///   String apiEndpoint({String? key}) => ApiEndpoints.countries;
///
///   @override
///   List<CountryEntity> itemsFromRoot(dynamic data) =>
///       (data as List? ?? [])
///           .whereType<Map<String, dynamic>>()
///           .map(CountryEntity.fromJson)
///           .toList();
/// }
/// ```
///
/// ### Dependent lookup example (cities depend on country)
/// ```dart
/// @injectable
/// class CitiesCubit extends PaginatedLookupCubit<CityEntity> {
///   CitiesCubit(super.source) {
///     // Pre-populate with empty data so the dropdown starts disabled.
///     setSuccess(data: PaginatedData.initial());
///   }
///
///   @override
///   String apiEndpoint({String? key}) =>
///       ApiEndpoints.citiesByCountry(key ?? '0');
///
///   @override
///   List<CityEntity> itemsFromRoot(dynamic data) =>
///       (data as List? ?? [])
///           .whereType<Map<String, dynamic>>()
///           .map(CityEntity.fromJson)
///           .toList();
///
///   Future<void> fetchForCountry(int countryId) async {
///     if (countryId <= 0) {
///       setSuccess(data: PaginatedData.initial());
///       return;
///     }
///     await fetchInitialData(filterKey: '$countryId');
///   }
/// }
/// ```
///
/// ### Screen usage
/// ```dart
/// AppDropdown<CountryEntity>(
///   paginatedCubit: context.read<CountriesCubit>(),
///   itemAsString: (c) => c.name,
///   onChanged: (c) => vc.country.value = c,
/// )
/// ```
abstract class PaginatedLookupCubit<T> extends PaginatedAsyncCubit<T> {
  PaginatedLookupCubit(this._source);
  final LookupRemoteSource _source;

  /// Return the API endpoint path.
  ///
  /// [key] is the `filterKey` forwarded from [fetchInitialData] — use it
  /// to build dependent endpoints (e.g. `/cities/{key}`).
  String apiEndpoint({String? key});

  /// Extract the typed item list from the raw `data` node.
  List<T> itemsFromRoot(dynamic data);

  /// Override to merge additional query params (e.g. extra filters).
  Map<String, dynamic> extraQueryParams({String? key}) => {};

  /// Convenience alias — preserves `fetch({key})` call-sites.
  Future<void> fetch({String? key}) => fetchInitialData(filterKey: key);

  @override
  Future<Either<Failure, PaginatedData<T>>> fetchPage(
    int page, {
    String? filterKey,
  }) => _source.fetchPage<T>(
    endpoint: apiEndpoint(key: filterKey),
    page: page,
    extraParams: extraQueryParams(key: filterKey),
    itemsFromRoot: itemsFromRoot,
  );
}
