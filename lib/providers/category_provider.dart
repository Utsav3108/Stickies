// lib/providers/category_provider.dart
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../services/storage_service.dart';

class CategoryProvider extends ChangeNotifier {
  List<KVCategory> _categories = [];
  final _uuid = const Uuid();

  CategoryProvider() {
    loadCategories();
  }

  List<KVCategory> get categories => _categories;

  List<KVCategory> get visibleCategories =>
      _categories.where((c) => !c.isHidden).toList();

  void loadCategories() {
    _categories = StorageService.getAllCategories();
    notifyListeners();
  }

  Future<void> addCategory(String name) async {
    final category = KVCategory(
      id: _uuid.v4(),
      name: name,
      order: _categories.length,
    );
    await StorageService.addCategory(category);
    loadCategories();
  }

  Future<void> updateCategory(KVCategory category) async {
    await StorageService.updateCategory(category);
    loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await StorageService.deleteCategory(id);
    loadCategories();
  }

  Future<void> toggleCategoryVisibility(KVCategory category) async {
    category.isHidden = !category.isHidden;
    await StorageService.updateCategory(category);
    loadCategories();
  }

  KVCategory? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}
