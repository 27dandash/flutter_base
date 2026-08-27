import 'package:hive_ce/hive.dart';

part 'queued_operation.g.dart';

@HiveType(typeId: 10)
class QueuedOperation extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String endpoint;

  @HiveField(2)
  final String method; // POST | PUT | PATCH | DELETE

  @HiveField(3)
  final Map<String, dynamic>? body;

  @HiveField(4)
  final Map<String, dynamic>? headers;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  int retryCount;

  @HiveField(7)
  final String? localId;

  /// Opaque stable account scope (prefer a one-way hash of the backend user
  /// id). It is authenticated as AES-GCM AAD and checked before replay.
  final String ownerScope;

  QueuedOperation({
    required this.id,
    required this.endpoint,
    required this.method,
    this.body,
    this.headers,
    required this.createdAt,
    this.retryCount = 0,
    this.localId,
    this.ownerScope = 'legacy',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'endpoint': endpoint,
    'method': method,
    'body': body,
    'headers': headers,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'retryCount': retryCount,
    'localId': localId,
    'ownerScope': ownerScope,
  };

  factory QueuedOperation.fromJson(Map<String, dynamic> json) =>
      QueuedOperation(
        id: json['id']! as String,
        endpoint: json['endpoint']! as String,
        method: json['method']! as String,
        body: (json['body'] as Map?)?.cast<String, dynamic>(),
        headers: (json['headers'] as Map?)?.cast<String, dynamic>(),
        createdAt: DateTime.parse(json['createdAt']! as String),
        retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
        localId: json['localId'] as String?,
        ownerScope: json['ownerScope']! as String,
      );
}
