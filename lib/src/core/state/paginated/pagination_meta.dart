import 'package:equatable/equatable.dart';

/// Pagination metadata returned by the API alongside a page of items.
///
/// `fromJson` is **defensive on purpose**: it parses every numeric field
/// safely (`int.tryParse` + fallbacks) and accepts the two common
/// backend naming conventions in one place:
///
///   - Laravel-style (`per_page`, `last_page`, `current_page`,
///     `next_page_url`, `prev_page_url`).
///   - Custom-style (`total_items`, `total`, `count_items`,
///     `total_pages`, `perv_page_url` — yes, with the typo some PHP
///     APIs ship).
///
/// A malformed payload never throws — it falls back to sensible defaults
/// so the UI keeps working.
class PaginationMeta extends Equatable {
  final int totalItems;
  final int countItems;
  final int perPage;
  final int totalPages;
  final int currentPage;
  final String? nextPageUrl;
  final String? prevPageUrl;

  const PaginationMeta({
    required this.totalItems,
    required this.countItems,
    required this.perPage,
    required this.totalPages,
    required this.currentPage,
    this.nextPageUrl,
    this.prevPageUrl,
  });

  /// Sensible empty value used by [PaginatedData.initial].
  const PaginationMeta.empty()
    : totalItems = 0,
      countItems = 0,
      perPage = 10,
      totalPages = 1,
      currentPage = 1,
      nextPageUrl = null,
      prevPageUrl = null;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    final totalItems = _pInt(json['total_items'] ?? json['total']);
    final perPage = _pInt(json['per_page'], 30);
    final totalPages = _pInt(json['total_pages'] ?? json['last_page'], 1);
    final currentPage = _pInt(json['current_page'], 1);
    final countItems = _pInt(
      json['count_items'] ?? json['to'] ?? json['per_page'],
      perPage,
    );

    return PaginationMeta(
      totalItems: totalItems,
      countItems: countItems,
      perPage: perPage == 0 ? 30 : perPage,
      totalPages: totalPages <= 0 ? 1 : totalPages,
      currentPage: currentPage <= 0 ? 1 : currentPage,
      nextPageUrl: json['next_page_url']?.toString(),
      // Some PHP APIs ship the typo 'perv_page_url' — accept both.
      prevPageUrl:
          json['prev_page_url']?.toString() ??
          json['perv_page_url']?.toString(),
    );
  }

  // ── Sugar ─────────────────────────────────────────────────────────

  bool get hasNextPage => nextPageUrl != null && nextPageUrl!.isNotEmpty;
  bool get hasPrevPage => prevPageUrl != null && prevPageUrl!.isNotEmpty;
  bool get isLastPage => currentPage >= totalPages;
  bool get isFirstPage => currentPage == 1;

  @override
  List<Object?> get props => [
    totalItems,
    countItems,
    perPage,
    totalPages,
    currentPage,
    nextPageUrl,
    prevPageUrl,
  ];

  // ── Helpers ───────────────────────────────────────────────────────

  static int _pInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }
}
