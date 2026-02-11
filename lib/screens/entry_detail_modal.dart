// lib/screens/entry_detail_modal.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../Theme/app_colors.dart';
import '../Theme/app_theme.dart';
import '../models/key_value_entry.dart';
import '../models/value_type.dart';
import '../providers/entry_provider.dart';
import '../providers/category_provider.dart';
import 'add_entry_screen.dart';

class EntryDetailModal extends StatelessWidget {
  final KeyValueEntry entry;

  const EntryDetailModal({super.key, required this.entry});

  Color _getColorForValueType(ValueType type) {
    switch (type) {
      case ValueType.text:
        return const Color(0xFFD8DD56);
      case ValueType.image:
        return const Color(0xFF7C74F5);
      case ValueType.video:
        return const Color(0xFFF5AA74);
      case ValueType.audio:
        return const Color(0xFF74D4F5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorForValueType(entry.valueType);
    final categoryProvider = context.watch<CategoryProvider>();
    final category = categoryProvider.getCategoryById(entry.categoryId);

    // Determine which actions to show based on content type
    final showCopy = entry.valueType == ValueType.text || entry.valueType == ValueType.image;
    final showShare = entry.valueType == ValueType.text || entry.valueType == ValueType.image;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              if (category != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      label: Text(category.name, style: TextStyle(color: Colors.white),),
                      backgroundColor: Colors.black12,
                      labelStyle: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: entry.isHidden
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock, size: 64, color: Colors.black38),
                        const SizedBox(height: 16),
                        Text(
                          'This note is hidden',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                      : _buildContent(),
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (showCopy)
                      _buildActionButton(
                        icon: Icons.copy,
                        label: 'Copy',
                        onTap: () => _copyToClipboard(context),
                      ),
                    if (showShare)
                      _buildActionButton(
                        icon: Icons.share,
                        label: 'Share',
                        onTap: () => _shareContent(context),
                      ),
                    _buildActionButton(
                      icon: entry.isHidden ? Icons.visibility : Icons.visibility_off,
                      label: entry.isHidden ? 'Show' : 'Hide',
                      onTap: () {
                        context.read<EntryProvider>().toggleEntryVisibility(entry);
                        Navigator.pop(context);
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.edit,
                      label: 'Edit',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EntryFormScreen(entry: entry), // Changed
                          ),
                        );
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.delete,
                      label: 'Delete',
                      color: Colors.red,
                      onTap: () {
                        _showDeleteConfirmation(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    try {
      if (entry.valueType == ValueType.text) {
        // Copy text content
        await Clipboard.setData(ClipboardData(text: entry.value));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Text copied to clipboard'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (entry.valueType == ValueType.image) {
        // For images, copy the file path (you can enhance this to copy actual image data)
        await Clipboard.setData(ClipboardData(text: 'Image: ${entry.key}'));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image info copied to clipboard'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareContent(BuildContext context) async {
    try {
      if (entry.valueType == ValueType.text) {
        // Share text content
        await Share.share(
          entry.value,
          subject: entry.key,
        );
      } else if (entry.valueType == ValueType.image) {
        // Share image file
        if (entry.value.isNotEmpty && File(entry.value).existsSync()) {
          await Share.shareXFiles(
            [XFile(entry.value)],
            text: entry.key,
          );
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image file not found'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildContent() {
    switch (entry.valueType) {
      case ValueType.text:
        return SelectableText(
          entry.value,
          style: AppTheme.bodyStyle(size: 18),
        );
      case ValueType.image:
        if (entry.value.isNotEmpty && File(entry.value).existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(entry.value),
              fit: BoxFit.contain,
            ),
          );
        }
        return const Center(
          child: Icon(Icons.broken_image, size: 64, color: Colors.black38),
        );
      case ValueType.video:
        if (entry.value.isNotEmpty && File(entry.value).existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 300,
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(Icons.videocam, size: 64, color: Colors.white70),
                  ),
                ),
                const Icon(
                  Icons.play_circle_outline,
                  size: 80,
                  color: Colors.white,
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entry.duration ?? 'Video',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const Center(
          child: Icon(Icons.broken_image, size: 64, color: Colors.black38),
        );
      case ValueType.audio:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.audiotrack, size: 64, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              if (entry.duration != null)
                Text(
                  entry.duration!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                entry.value.split('/').last,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: color ?? Colors.black87, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color ?? Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text(
          'Delete Note',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this note? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              context.read<EntryProvider>().deleteEntry(entry.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close modal
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}