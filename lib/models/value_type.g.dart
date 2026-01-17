// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'value_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ValueTypeAdapter extends TypeAdapter<ValueType> {
  @override
  final int typeId = 1;

  @override
  ValueType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ValueType.text;
      case 1:
        return ValueType.image;
      case 2:
        return ValueType.audio;
      case 3:
        return ValueType.video;
      default:
        return ValueType.text;
    }
  }

  @override
  void write(BinaryWriter writer, ValueType obj) {
    switch (obj) {
      case ValueType.text:
        writer.writeByte(0);
        break;
      case ValueType.image:
        writer.writeByte(1);
        break;
      case ValueType.audio:
        writer.writeByte(2);
        break;
      case ValueType.video:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValueTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
