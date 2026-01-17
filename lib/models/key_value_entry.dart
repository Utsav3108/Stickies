// lib/models/key_value_entry.dart
import 'package:hive/hive.dart';
import 'value_type.dart';

part 'key_value_entry.g.dart';

@HiveType(typeId: 2)
class KeyValueEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String key;

  @HiveField(2)
  String value; // Text content or file path

  @HiveField(3)
  ValueType valueType;

  @HiveField(4)
  String categoryId;

  @HiveField(5)
  bool isHidden;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  String? duration; // For audio/video

  KeyValueEntry({
    required this.id,
    required this.key,
    required this.value,
    required this.valueType,
    required this.categoryId,
    this.isHidden = false,
    required this.createdAt,
    this.duration,
  });
}

