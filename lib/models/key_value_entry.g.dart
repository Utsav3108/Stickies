// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'key_value_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KeyValueEntryAdapter extends TypeAdapter<KeyValueEntry> {
  @override
  final int typeId = 2;

  @override
  KeyValueEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KeyValueEntry(
      id: fields[0] as String,
      key: fields[1] as String,
      value: fields[2] as String,
      valueType: fields[3] as ValueType,
      categoryId: fields[4] as String,
      isHidden: fields[5] as bool,
      createdAt: fields[6] as DateTime,
      duration: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, KeyValueEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.key)
      ..writeByte(2)
      ..write(obj.value)
      ..writeByte(3)
      ..write(obj.valueType)
      ..writeByte(4)
      ..write(obj.categoryId)
      ..writeByte(5)
      ..write(obj.isHidden)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.duration);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeyValueEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
