// lib/screens/home_screen.dart
import 'dart:io';
import 'package:datastock/models/key_value_entry.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../Theme/app_theme.dart';
import '../providers/category_provider.dart';
import '../providers/entry_provider.dart';
import '../providers/settings_provider.dart';
import '../models/category.dart';
import '../models/value_type.dart';
import 'add_entry_screen.dart';
import 'entry_detail_modal.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategoryId = 'all';
  bool _isSearching = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getColorForValueType(ValueType type) {
    switch (type) {
      case ValueType.text:
        return const Color(0xFFD8DD56); // Yellow
      case ValueType.image:
        return const Color(0xFF7C74F5); // Purple
      case ValueType.video:
        return const Color(0xFFF5AA74); // Orange
      case ValueType.audio:
        return const Color(0xFF74D4F5); // Light Blue
    }
  }

  void _showEntryDetail(BuildContext context, entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EntryDetailModal(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<CategoryProvider, EntryProvider, SettingsProvider>(
      builder:
          (context, categoryProvider, entryProvider, settingsProvider, child) {
        final settings = settingsProvider.settings;
        final categories = categoryProvider.categories;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Search notes...',
                      hintStyle: TextStyle(color: Colors.white60),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      entryProvider.setSearchQuery(value);
                    },
                  )
                : const Text(
                    'Stickies',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isSearching ? Icons.close : Icons.search,
                  color: Colors.white,
                ),
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
            ],
          ),
          drawer: _buildDrawer(categoryProvider, entryProvider),
          body: _buildStickyNotesGrid(entryProvider),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EntryFormScreen(), // Changed
                ),
              );
              if (mounted) setState(() {});
            },
            backgroundColor: const Color(0xFFA4F291),
            child: const Icon(Icons.add, color: Colors.black, size: 32),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(
      CategoryProvider categoryProvider, EntryProvider entryProvider) {
    final categories = categoryProvider.visibleCategories;

    return Drawer(
      backgroundColor: const Color(0xFF1C1C1E),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8DD56),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.sticky_note_2, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Categories',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.inbox, color: Colors.white70),
              title: const Text(
                'All Notes',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${entryProvider.getCategoryCount('all')}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              selected: _selectedCategoryId == 'all',
              selectedTileColor: Colors.white12,
              onTap: () {
                setState(() {
                  _selectedCategoryId = 'all';
                });
                Navigator.pop(context);
              },
            ),
            const Divider(color: Colors.white24),
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final count = entryProvider.getCategoryCount(category.id);

                  return ListTile(
                    leading: const Icon(Icons.label, color: Colors.white70),
                    title: Text(
                      category.name,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    selected: _selectedCategoryId == category.id,
                    selectedTileColor: Colors.white12,
                    onTap: () {
                      setState(() {
                        _selectedCategoryId = category.id;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.add_circle_outline,
                  color: Color(0xFFA4F291)),
              title: const Text(
                'New Category',
                style: TextStyle(color: Color(0xFFA4F291), fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                _showAddCategoryDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyNotesGrid(EntryProvider entryProvider) {
    final entries = _selectedCategoryId == 'all'
        ? entryProvider.entries
        : entryProvider.getEntriesByCategory(_selectedCategoryId!);

    final filteredEntries = _searchController.text.isEmpty
        ? entries
        : entryProvider.getEntriesByCategory(_selectedCategoryId ?? 'all');

    if (filteredEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sticky_note_2_outlined,
              size: 80,
              color: Colors.grey[800],
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching ? 'No notes found' : 'No notes yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to create your first note',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: filteredEntries.length,
      itemBuilder: (context, index) {
        final entry = filteredEntries[index];
        final color = _getColorForValueType(entry.valueType);

        return GestureDetector(
          onTap: () => _showEntryDetail(context, entry),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.isHidden)
                      const Icon(Icons.visibility_off,
                          size: 16, color: Colors.black54),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: entry.isHidden
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock,
                                  size: 32, color: Colors.black38),
                              const SizedBox(height: 4),
                              Text(
                                'Hidden',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildNoteContent(entry),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoteContent(KeyValueEntry entry) {
    switch (entry.valueType) {
      case ValueType.text:
        return Text(
          entry.value,
          style: AppTheme.bodyStyle(),
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        );
      case ValueType.image:
        if (entry.value.isNotEmpty && File(entry.value).existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(entry.value),
              fit: BoxFit.cover,
            ),
          );
        }
        return const Center(
          child: Icon(Icons.image, size: 48, color: Colors.black38),
        );
      case ValueType.video:
        if (entry.value.isNotEmpty && File(entry.value).existsSync()) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(Icons.videocam, size: 48, color: Colors.white),
                  ),
                ),
              ),
              const Positioned.fill(
                child: Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        }
        return const Center(
          child: Icon(Icons.videocam, size: 48, color: Colors.black38),
        );
      case ValueType.audio:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.audiotrack, size: 48, color: Colors.black87),
              if (entry.duration != null) ...[
                const SizedBox(height: 8),
                Text(
                  entry.duration!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ],
            ],
          ),
        );
    }
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text(
          'New Category',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Category Name',
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFA4F291)),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<CategoryProvider>().addCategory(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Add',
              style: TextStyle(color: Color(0xFFA4F291)),
            ),
          ),
        ],
      ),
    );
  }
}
