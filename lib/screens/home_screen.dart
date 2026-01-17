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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initTabController();
  }

  void _initTabController() {
    final categoryProvider = context.read<CategoryProvider>();
    final visibleCategories = categoryProvider.visibleCategories;
    _tabController = TabController(
      length: visibleCategories.length + 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<CategoryProvider, EntryProvider, SettingsProvider>(
      builder: (context, categoryProvider, entryProvider, settingsProvider, child) {
        final visibleCategories = categoryProvider.visibleCategories;

        // Rebuild tab controller if categories changed
        if (_tabController.length != visibleCategories.length + 1) {
          _tabController.dispose();
          _tabController = TabController(
            length: visibleCategories.length + 1,
            vsync: this,
          );
        }

        // Sort categories by count
        final sortedCategories = List<KVCategory>.from(visibleCategories)
          ..sort((a, b) {
            final countA = entryProvider.getCategoryCount(a.id);
            final countB = entryProvider.getCategoryCount(b.id);
            return countB.compareTo(countA);
          });

        final settings = settingsProvider.settings;

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
                tabController: _tabController,
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
                      (cat) => _buildEntryList(cat?.id ?? "", entryProvider),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEntryScreen(),
                ),
              );
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