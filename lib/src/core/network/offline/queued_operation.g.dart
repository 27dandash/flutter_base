// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queued_operation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QueuedOperationAdapter extends TypeAdapter<QueuedOperation> {
  @override
  final typeId = 10;

  @override
  QueuedOperation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QueuedOperation(
      id: fields[0] as String,
      endpoint: fields[1] as String,
      method: fields[2] as String,
      body: (fields[3] as Map?)?.cast<String, dynamic>(),
      headers: (fields[4] as Map?)?.cast<String, dynamic>(),
      createdAt: fields[5] as DateTime,
      retryCount: fields[6] == null ? 0 : (fields[6] as num).toInt(),
      localId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, QueuedOperation obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.endpoint)
      ..writeByte(2)
      ..write(obj.method)
      ..writeByte(3)
      ..write(obj.body)
      ..writeByte(4)
      ..write(obj.headers)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.retryCount)
      ..writeByte(7)
      ..write(obj.localId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueuedOperationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
