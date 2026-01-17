// lib/services/storage_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/category.dart';
import '../models/key_value_entry.dart';
import '../models/app_settings.dart';
import '../models/value_type.dart';

class StorageService {
  static const String categoriesBox = 'categories';
  static const String entriesBox = 'entries';
  static const String settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(KVCategoryAdapter());
    Hive.registerAdapter(KeyValueEntryAdapter());
    Hive.registerAdapter(AppSettingsAdapter());
    Hive.registerAdapter(ValueTypeAdapter());

    // Open boxes
    await Hive.openBox<KVCategory>(categoriesBox);
    await Hive.openBox<KeyValueEntry>(entriesBox);
    await Hive.openBox<AppSettings>(settingsBox);
  }

  // Category operations
  static Box<KVCategory> getCategoriesBox() => Hive.box<KVCategory>(categoriesBox);

  static Future<void> addCategory(KVCategory category) async {
    final box = getCategoriesBox();
    await box.put(category.id, category);
  }

  static Future<void> updateCategory(KVCategory category) async {
    await category.save();
  }

  static Future<void> deleteCategory(String id) async {
    final box = getCategoriesBox();
    await box.delete(id);
  }

  static List<KVCategory> getAllCategories() {
    return getCategoriesBox().values.toList();
  }

  // Entry operations
  static Box<KeyValueEntry> getEntriesBox() => Hive.box<KeyValueEntry>(entriesBox);

  static Future<void> addEntry(KeyValueEntry entry) async {
    final box = getEntriesBox();
    await box.put(entry.id, entry);
  }

  static Future<void> updateEntry(KeyValueEntry entry) async {
    await entry.save();
  }

  static Future<void> deleteEntry(String id) async {
    final box = getEntriesBox();
    await box.delete(id);
  }

  static List<KeyValueEntry> getAllEntries() {
    return getEntriesBox().values.toList();
  }

  static List<KeyValueEntry> getEntriesByCategory(String categoryId) {
    return getEntriesBox()
        .values
        .where((e) => e.categoryId == categoryId)
        .toList();
  }

  // Settings operations
  static Box<AppSettings> getSettingsBox() => Hive.box<AppSettings>(settingsBox);

  static AppSettings getSettings() {
    final box = getSettingsBox();
    if (box.isEmpty) {
      final settings = AppSettings();
      box.put('settings', settings);
      return settings;
    }
    return box.get('settings')!;
  }

  static Future<void> updateSettings(AppSettings settings) async {
    await settings.save();
  }
}