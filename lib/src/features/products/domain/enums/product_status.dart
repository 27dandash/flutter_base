/// Domain-level enum for a product's lifecycle state.
///
/// The wire value coming from the API is a raw string (e.g. "available",
/// "sold_out"). We map it here so the rest of the app only deals with a
/// type-safe enum.
enum ProductStatus {
  available('available'),
  outOfStock('out_of_stock'),
  draft('draft'),
  archived('archived'),
  unknown('unknown');

  /// String the backend sends/expects on the wire.
  final String raw;
  const ProductStatus(this.raw);

  /// Safe parser — never throws. Unknown values become [unknown] so the UI
  /// can render a fallback state instead of crashing.
  factory ProductStatus.fromRaw(String? value) {
    if (value == null || value.isEmpty) return ProductStatus.unknown;
    for (final s in ProductStatus.values) {
      if (s.raw == value) return s;
    }
    return ProductStatus.unknown;
  }

  bool get isAvailable => this == ProductStatus.available;
  bool get isOutOfStock => this == ProductStatus.outOfStock;
}
