// lib/screens/home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../providers/entry_provider.dart';
import '../providers/settings_provider.dart';
import '../models/category.dart';
import '../widgets/category_tabs.dart';
import '../widgets/entry_list_item.dart';
import 'add_entry_screen.dart';
import 'category_management_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  TabController? _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  int _previousCategoryCount = 0;

  @override
  void initState() {
    super.initState();
    // Don't initialize here - do it in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final categoryProvider = context.read<CategoryProvider>();
    final visibleCategories = categoryProvider.visibleCategories;
    final newCount = visibleCategories.length + 1;

    // Only create/recreate controller if count changed or controller is null
    if (_tabController == null || _previousCategoryCount != newCount) {
      _tabController?.dispose();
      _tabController = TabController(
        length: newCount,
        vsync: this,
      );
      _previousCategoryCount = newCount;
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _rebuildTabControllerIfNeeded(int newLength) {
    if (_tabController == null || _tabController!.length != newLength) {
      // Save current index
      final currentIndex = _tabController?.index ?? 0;

      // Dispose old controller
      _tabController?.dispose();

      // Create new controller
      _tabController = TabController(
        length: newLength,
        vsync: this,
        initialIndex: currentIndex < newLength ? currentIndex : 0,
      );
      _previousCategoryCount = newLength;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<CategoryProvider, EntryProvider, SettingsProvider>(
      builder: (context, categoryProvider, entryProvider, settingsProvider, child) {
        final visibleCategories = categoryProvider.visibleCategories;
        final newLength = visibleCategories.length + 1;

        // Rebuild tab controller if needed
        _rebuildTabControllerIfNeeded(newLength);

        // Sort categories by count
        final sortedCategories = List<KVCategory>.from(visibleCategories)
          ..sort((a, b) {
            final countA = entryProvider.getCategoryCount(a.id);
            final countB = entryProvider.getCategoryCount(b.id);
            return countB.compareTo(countA);
          });

        final settings = settingsProvider.settings;

        // Guard against null controller
        if (_tabController == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: _isSearching
                ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search keys, values...',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                entryProvider.setSearchQuery(value);
              },
            )
                : const Text('DataStock'),
            actions: [
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      entryProvider.setSearchQuery('');
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: CategoryTabs(
                tabController: _tabController!,
                categories: sortedCategories,
                entryProvider: entryProvider,
                onMoreTapped: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoryManagementScreen(),
                    ),
                  );
                },
              ),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              color: settings.backgroundImagePath == null
                  ? Color(settings.backgroundColor)
                  : null,
              image: settings.backgroundImagePath != null
                  ? DecorationImage(
                image: FileImage(File(settings.backgroundImagePath!)),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEntryList('all', entryProvider),
                ...sortedCategories.map(
                      (cat) => _buildEntryList(cat.id, entryProvider), // Fixed: removed unnecessary ?.
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEntryScreen(),
                ),
              );
              // Refresh state after returning from add screen
              if (mounted) {
                setState(() {});
              }
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildEntryList(String categoryId, EntryProvider entryProvider) {
    final entries = entryProvider.getEntriesByCategory(categoryId);

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching ? 'No results found' : 'No entries yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        return EntryListItem(entry: entries[index]);
      },
    );
  }
}