// lib/models/value_type.dart
import 'package:hive/hive.dart';

part 'value_type.g.dart';

@HiveType(typeId: 1)
enum ValueType {
  @HiveField(0)
  text,

  @HiveField(1)
  image,

  @HiveField(2)
  audio,

  @HiveField(3)
  video,
}
