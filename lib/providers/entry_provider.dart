
// lib/providers/entry_provider.dart
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/key_value_entry.dart';
import '../models/value_type.dart';
import '../services/storage_service.dart';

class EntryProvider extends ChangeNotifier {
  List<KeyValueEntry> _entries = [];
  final _uuid = const Uuid();
  String _searchQuery = '';

  EntryProvider() {
    loadEntries();
  }

  List<KeyValueEntry> get entries => _entries;
  String get searchQuery => _searchQuery;

  void loadEntries() {
    _entries = StorageService.getAllEntries();
    notifyListeners();
  }

  List<KeyValueEntry> getEntriesByCategory(String categoryId) {
    var filtered = categoryId == 'all'
        ? _entries
        : _entries.where((e) => e.categoryId == categoryId).toList();

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((e) {
        final keyMatch = e.key.toLowerCase().contains(_searchQuery.toLowerCase());
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
      id: _uuid.v4(),
      key: key,
      value: value,
      valueType: valueType,
      categoryId: categoryId,
      createdAt: DateTime.now(),
      duration: duration,
    );
    await StorageService.addEntry(entry);
    loadEntries();
  }

  Future<void> updateEntry(KeyValueEntry entry) async {
    await StorageService.updateEntry(entry);
    loadEntries();
  }

  Future<void> deleteEntry(String id) async {
    await StorageService.deleteEntry(id);
    loadEntries();
  }

  Future<void> toggleEntryVisibility(KeyValueEntry entry) async {
    entry.isHidden = !entry.isHidden;
    await StorageService.updateEntry(entry);
    loadEntries();
  }
}