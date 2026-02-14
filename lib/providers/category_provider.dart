import 'package:flutter/foundation.dart';
import '../models/category.dart';
import '../services/storage_service.dart';
import '../services/analytics_service.dart';

class CategoryProvider with ChangeNotifier {
  List<KVCategory> _categories = [];
  AnalyticsService? _analyticsService;

  CategoryProvider() {
    loadCategories();
  }

  List<KVCategory> get categories => _categories;

  List<KVCategory> get visibleCategories =>
      _categories.where((c) => !c.isHidden).toList();

  // Setter to inject analytics service after provider creation
  void setAnalyticsService(AnalyticsService service) {
    _analyticsService = service;
  }

  KVCategory? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> loadCategories() async {
    _categories = StorageService.getAllCategories();
    notifyListeners();
  }

  Future<void> addCategory(String name) async {
    final category = KVCategory(
        id: DateTime.now().millisecondsSinceEpoch.toString(), name: name);

    await StorageService.addCategory(category);
    _categories.add(category);
    notifyListeners();

    // Log analytics
    if (_analyticsService != null) {
      await _analyticsService!.logCategoryCreated(
        categoryId: category.id,
        categoryName: name,
        totalCategories: _categories.length,
      );
    }
  }

  Future<void> updateCategory(KVCategory category) async {
    await StorageService.updateCategory(category);
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    await StorageService.deleteCategory(id);
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();

    // Log analytics
    if (_analyticsService != null) {
      await _analyticsService!.logCategoryDeleted(
        categoryId: id,
        remainingCategories: _categories.length,
      );
    }
  }

  // Helper to check if a category name already exists
  bool categoryNameExists(String name) {
    return _categories.any(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
    );
  }

  Future<void> toggleCategoryVisibility(KVCategory category) async {
    category.isHidden = !category.isHidden;
    await StorageService.updateCategory(category);
    loadCategories();
  }
}
