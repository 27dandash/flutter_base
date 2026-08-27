/// Safe accessors for `Map<String, dynamic>` payloads coming back from
/// the API. Each getter returns a sensible fallback instead of throwing
/// when the key is missing, the value is null, or the type doesn't match
/// — so a single malformed field never crashes an entire screen.
///
/// Pair them with `ProductModel.fromJson(json)` style factories:
///
/// ```dart
/// factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
///   id:          json.getInt('id'),
///   name:        json.getString('name'),
///   price:       json.getDouble('price'),
///   isAvailable: json.getBool('available'),
///   imageUrl:    json.getStringOrNull('image_url'),
///   tags:        json.getList<String>('tags'),
///   author:      json.getObject('author', AuthorModel.fromJson),
///   reviews:     json.getObjectList('reviews', ReviewModel.fromJson),
/// );
/// ```
extension JsonGetters on Map<String, dynamic> {
  // ── Strings ───────────────────────────────────────────────────────

  String getString(String key, {String fallback = ''}) {
    final raw = this[key];
    if (raw == null) return fallback;
    return raw.toString();
  }

  String? getStringOrNull(String key) {
    final raw = this[key];
    if (raw == null) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }

  // ── Numbers ───────────────────────────────────────────────────────

  int getInt(String key, {int fallback = 0}) {
    final raw = this[key];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? fallback;
  }

  int? getIntOrNull(String key) {
    final raw = this[key];
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }

  double getDouble(String key, {double fallback = 0.0}) {
    final raw = this[key];
    if (raw is double) return raw;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? fallback;
  }

  double? getDoubleOrNull(String key) {
    final raw = this[key];
    if (raw == null) return null;
    if (raw is double) return raw;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }

  // ── Bool ─────────────────────────────────────────────────────────

  bool getBool(String key, {bool fallback = false}) {
    final raw = this[key];
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final lower = raw.toLowerCase().trim();
      if (lower == 'true' || lower == '1' || lower == 'yes') return true;
      if (lower == 'false' || lower == '0' || lower == 'no') return false;
    }
    return fallback;
  }

  // ── DateTime ─────────────────────────────────────────────────────

  /// Parses ISO 8601 strings (`"2024-01-31T10:00:00Z"`) and bare dates
  /// (`"2024-01-31"`). Returns `null` for anything unparseable so callers
  /// can fall back to whatever placeholder they prefer.
  DateTime? getDateTime(String key) {
    final raw = this[key];
    if (raw is DateTime) return raw;
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  // ── Collections ──────────────────────────────────────────────────

  /// `getList<String>('tags')` — filters non-matching types out silently.
  List<T> getList<T>(String key) {
    final raw = this[key];
    if (raw is! List) return const [];
    return raw.whereType<T>().toList();
  }

  Map<String, dynamic> getMap(String key) {
    final raw = this[key];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  Map<String, dynamic>? getMapOrNull(String key) {
    final raw = this[key];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  /// Safely extract a nested object via its `fromJson` factory.
  ///
  /// ```dart
  /// author: json.getObject('author', AuthorModel.fromJson),
  /// ```
  T? getObject<T>(String key, T Function(Map<String, dynamic> json) fromJson) {
    final raw = this[key];
    if (raw is Map<String, dynamic>) return fromJson(raw);
    if (raw is Map) return fromJson(Map<String, dynamic>.from(raw));
    return null;
  }

  /// Array of objects via factory:
  /// `json.getObjectList('reviews', ReviewModel.fromJson)`
  List<T> getObjectList<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final raw = this[key];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  }
}
