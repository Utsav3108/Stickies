// lib/models/app_settings.dart
import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 3)
class AppSettings extends HiveObject {
  @HiveField(0)
  int backgroundColor;

  @HiveField(1)
  String? backgroundImagePath;

  @HiveField(2)
  bool isDarkMode;

  AppSettings({
    this.backgroundColor = 0xFFFFFFFF,
    this.backgroundImagePath,
    this.isDarkMode = false,
  });
}