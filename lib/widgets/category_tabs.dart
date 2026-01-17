// lib/widgets/category_tabs.dart
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../providers/entry_provider.dart';

class CategoryTabs extends StatelessWidget {
  final TabController tabController;
  final List<KVCategory> categories;
  final EntryProvider entryProvider;
  final VoidCallback onMoreTapped;

  const CategoryTabs({
    super.key,
    required this.tabController,
    required this.categories,
    required this.entryProvider,
    required this.onMoreTapped,
  });

  @override
  Widget build(BuildContext context) {
    final showMore = categories.length > 5;

    return TabBar(
      controller: tabController,
      isScrollable: true,
      tabs: [
        Tab(
          child: Row(
            children: [
              const Text('All'),
              const SizedBox(width: 4),
              _buildCountBadge(entryProvider.getCategoryCount('all')),
            ],
          ),
        ),
        ...categories.take(showMore ? 5 : categories.length).map((cat) {
          return Tab(
            child: Row(
              children: [
                Text(cat.name),
                const SizedBox(width: 4),
                _buildCountBadge(entryProvider.getCategoryCount(cat.id)),
              ],
            ),
          );
        }),
        if (showMore)
          Tab(
            child: GestureDetector(
              onTap: onMoreTapped,
              child: const Row(
                children: [
                  Icon(Icons.more_horiz, size: 20),
                  SizedBox(width: 4),
                  Text('More'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
