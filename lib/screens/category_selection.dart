import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Theme/app_colors.dart';
import '../providers/entry_provider.dart';
import '../providers/category_provider.dart';

class CategoryPickerModal extends StatefulWidget {
  const CategoryPickerModal({super.key});

  @override
  State<CategoryPickerModal> createState() => _CategoryPickerModalState();
}

class _CategoryPickerModalState extends State<CategoryPickerModal> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _newCategoryController = TextEditingController();
  String _searchQuery = '';
  bool _showCreateField = false;

  @override
  void dispose() {
    _searchController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Select Category',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search categories...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white38),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // Categories list
          Expanded(
            child: Consumer<CategoryProvider>(
              builder: (context, categoryProvider, child) {
                final allCategories = categoryProvider.categories;
                final filteredCategories = _searchQuery.isEmpty
                    ? allCategories
                    : allCategories
                    .where((cat) =>
                    cat.name.toLowerCase().contains(_searchQuery))
                    .toList();

                if (filteredCategories.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.white24),
                        const SizedBox(height: 16),
                        const Text(
                          'No categories found',
                          style: TextStyle(color: Colors.white38, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final name = _searchQuery.trim();
                            if (name.isEmpty) return;

                            final categoryProvider = context.read<CategoryProvider>();
                            await categoryProvider.addCategory(name);
                            categoryProvider.loadCategories();

                            // Get the newly created category
                            final newCategory = categoryProvider.categories
                                .firstWhere((cat) => cat.name.toLowerCase() == name.toLowerCase());

                            if (context.mounted) {
                              Navigator.pop(context, {
                                'id': newCategory.id,
                                'name': newCategory.name,
                              });
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: Text('Create "$_searchQuery"'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.saveButton,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filteredCategories.length,
                  itemBuilder: (context, index) {
                    final category = filteredCategories[index];
                    final entryProvider = context.read<EntryProvider>();
                    final count = entryProvider.getCategoryCount(category.id);

                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.label, color: Colors.white70, size: 20),
                      ),
                      title: Text(
                        category.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context, {
                          'id': category.id,
                          'name': category.name,
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}