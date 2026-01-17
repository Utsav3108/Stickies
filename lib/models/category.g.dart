// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KVCategoryAdapter extends TypeAdapter<KVCategory> {
  @override
  final int typeId = 0;

  @override
  KVCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KVCategory(
      id: fields[0] as String,
      name: fields[1] as String,
      isHidden: fields[2] as bool,
      order: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, KVCategory obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.isHidden)
      ..writeByte(3)
      ..write(obj.order);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KVCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
