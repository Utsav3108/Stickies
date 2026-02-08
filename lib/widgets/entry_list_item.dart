
// lib/widgets/entry_list_item.dart
import 'dart:io';
import 'package:datastock/screens/add_entry_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/key_value_entry.dart';
import '../models/value_type.dart';
import '../providers/entry_provider.dart';
import '../providers/category_provider.dart';

class EntryListItem extends StatelessWidget {
  final KeyValueEntry entry;

  const EntryListItem({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final entryProvider = context.read<EntryProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final category = categoryProvider.getCategoryById(entry.categoryId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: _buildLeadingIcon(),
        title: Text(
          entry.key,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            entry.isHidden
                ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '••••••••',
                style: TextStyle(letterSpacing: 2),
              ),
            )
                : _buildValuePreview(),
            const SizedBox(height: 4),
            if (category != null)
              Chip(
                label: Text(category.name),
                labelStyle: const TextStyle(fontSize: 11),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Row(
                children: [
                  Icon(entry.isHidden ? Icons.visibility : Icons.visibility_off),
                  const SizedBox(width: 8),
                  Text(entry.isHidden ? 'Show' : 'Hide'),
                ],
              ),
              onTap: () {
                entryProvider.toggleEntryVisibility(entry);
              },
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
              onTap: () {
                Future.delayed(Duration.zero, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EntryFormScreen(entry: entry),
                    ),
                  );
                });
              },
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
              onTap: () {
                entryProvider.deleteEntry(entry.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingIcon() {
    switch (entry.valueType) {
      case ValueType.text:
        return const Icon(Icons.text_fields, size: 32);
      case ValueType.image:
        return entry.value.isNotEmpty && File(entry.value).existsSync()
            ? ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.file(
            File(entry.value),
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
        )
            : const Icon(Icons.image, size: 32);
      case ValueType.audio:
        return const Icon(Icons.audiotrack, size: 32);
      case ValueType.video:
        return entry.value.isNotEmpty && File(entry.value).existsSync()
            ? Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 50,
                height: 50,
                color: Colors.black12,
              ),
            ),
            const Icon(Icons.play_circle_outline, color: Colors.white),
          ],
        )
            : const Icon(Icons.videocam, size: 32);
    }
  }

  Widget _buildValuePreview() {
    switch (entry.valueType) {
      case ValueType.text:
        return Text(
          entry.value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey[700]),
        );
      case ValueType.audio:
        return Text(
          'Audio ${entry.duration ?? ""}',
          style: TextStyle(color: Colors.grey[700]),
        );
      case ValueType.video:
        return Text(
          'Video ${entry.duration ?? ""}',
          style: TextStyle(color: Colors.grey[700]),
        );
      case ValueType.image:
        return Text(
          'Image',
          style: TextStyle(color: Colors.grey[700]),
        );
    }
  }
}