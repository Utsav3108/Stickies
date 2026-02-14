import 'package:flutter/foundation.dart';
import '../models/key_value_entry.dart';
import '../models/value_type.dart';
import '../services/storage_service.dart';
import '../services/analytics_service.dart';

class EntryProvider with ChangeNotifier {
  final AnalyticsService analyticsService;
  List<KeyValueEntry> _entries = [];
  String _searchQuery = '';

  EntryProvider({required this.analyticsService}) {
    loadEntries();
  }

  List<KeyValueEntry> get entries => _entries;

  String get searchQuery => _searchQuery;

  List<KeyValueEntry> get visibleEntries =>
      _entries.where((e) => !e.isHidden).toList();

  // List<KeyValueEntry> getEntriesByCategory(String categoryId) {
  //   return _entries.where((e) => e.categoryId == categoryId).toList();
  // }

  List<KeyValueEntry> getEntriesByType(ValueType type) {
    return _entries.where((e) => e.valueType == type).toList();
  }

  Future<void> loadEntries() async {
    _entries = StorageService.getAllEntries();
    notifyListeners();
  }

  List<KeyValueEntry> getEntriesByCategory(String categoryId) {
    var filtered = categoryId == 'all'
        ? _entries
        : _entries.where((e) => e.categoryId == categoryId).toList();

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((e) {
        final keyMatch =
            e.key.toLowerCase().contains(_searchQuery.toLowerCase());
        final valueMatch = e.valueType == ValueType.text &&
            e.value.toLowerCase().contains(_searchQuery.toLowerCase());
        return keyMatch || valueMatch;
      }).toList();
    }

    return filtered;
  }

  int getCategoryCount(String categoryId) {
    if (categoryId == 'all') return _entries.length;
    return _entries.where((e) => e.categoryId == categoryId).length;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> addEntry({
    required String key,
    required String value,
    required ValueType valueType,
    required String categoryId,
    String? duration,
  }) async {
    final entry = KeyValueEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      key: key,
      value: value,
      valueType: valueType,
      categoryId: categoryId,
      createdAt: DateTime.now(),
      duration: duration,
    );

    await StorageService.addEntry(entry);
    _entries.add(entry);
    notifyListeners();

    // Log analytics
    await analyticsService.logStickyCreated(
      type: valueType,
      categoryId: categoryId,
      contentLength: valueType == ValueType.text ? value.length : null,
    );
  }

  Future<void> updateEntry(KeyValueEntry entry) async {
    await StorageService.updateEntry(entry);
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _entries[index] = entry;
      notifyListeners();
    }

    // Log analytics
    await analyticsService.logStickyUpdated(
      stickyId: entry.id,
      type: entry.valueType,
      categoryId: entry.categoryId,
    );
  }

  Future<void> deleteEntry(String id) async {
    final entry = _entries.firstWhere((e) => e.id == id);

    await StorageService.deleteEntry(id);
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();

    // Log analytics
    await analyticsService.logStickyDelete(
      stickyId: id,
      type: entry.valueType,
    );
  }

  Future<void> toggleEntryVisibility(KeyValueEntry entry) async {
    entry.isHidden = !entry.isHidden;
    await StorageService.updateEntry(entry);
    notifyListeners();

    // Log analytics
    await analyticsService.logStickyVisibilityToggle(
      stickyId: entry.id,
      isNowHidden: entry.isHidden,
    );
  }

  // Method to log aggregated stats
  Future<void> logCurrentStats(int categoryCount) async {
    await analyticsService.logUserStats(
      totalStickies: _entries.length,
      textCount: getEntriesByType(ValueType.text).length,
      photoCount: getEntriesByType(ValueType.image).length,
      videoCount: getEntriesByType(ValueType.video).length,
      categoryCount: categoryCount,
    );
  }

  // Bulk operations with optimized analytics
  Future<void> deleteMultipleEntries(List<String> ids) async {
    final entriesToDelete = _entries.where((e) => ids.contains(e.id)).toList();

    for (final id in ids) {
      await StorageService.deleteEntry(id);
    }

    _entries.removeWhere((e) => ids.contains(e.id));
    notifyListeners();

    // Log bulk delete analytics
    if (entriesToDelete.isNotEmpty) {
      final typeBreakdown = <String, int>{};
      for (final entry in entriesToDelete) {
        typeBreakdown[entry.valueType.name] =
            (typeBreakdown[entry.valueType.name] ?? 0) + 1;
      }

      // Log as custom event (can add to AnalyticsService if needed)
      print(
          '📊 Bulk delete: ${entriesToDelete.length} stickies - $typeBreakdown');
    }
  }
}
