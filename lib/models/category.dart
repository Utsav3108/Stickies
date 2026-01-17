import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 0)
class KVCategory extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  bool isHidden;

  @HiveField(3)
  int order;

  KVCategory({
    required this.id,
    required this.name,
    this.isHidden = false,
    this.order = 0,
  });
}