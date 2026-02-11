
// lib/screens/entry_form_screen.dart
import 'dart:io';
import 'package:datastock/Theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../Theme/app_colors.dart';
import '../models/value_type.dart';
import '../models/key_value_entry.dart';
import '../providers/entry_provider.dart';
import '../providers/category_provider.dart';
import 'category_selection.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

class EntryFormScreen extends StatefulWidget {
  final KeyValueEntry? entry; // null for add, non-null for edit

  const EntryFormScreen({super.key, this.entry});

  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  late ValueType _activeType;
  String? _filePath;
  bool _titleManuallyEdited = false;
  String? _selectedCategoryId;
  String _selectedCategoryName = 'General';

  bool get isEditMode => widget.entry != null;

  @override
  void initState() {
    super.initState();

    if (isEditMode) {
      // Initialize with existing entry data
      _titleController.text = widget.entry!.key;
      _activeType = widget.entry!.valueType;
      _selectedCategoryId = widget.entry!.categoryId;
      _titleManuallyEdited = true; // Don't auto-generate in edit mode

      if (_activeType == ValueType.text) {
        _textController.text = widget.entry!.value;
      } else {
        _filePath = widget.entry!.value;
      }

      // Get category name
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final categoryProvider = context.read<CategoryProvider>();
        final category = categoryProvider.getCategoryById(_selectedCategoryId!);
        if (category != null) {
          setState(() {
            _selectedCategoryName = category.name;
          });
        }
      });
    } else {
      // New entry mode
      _activeType = ValueType.text;

      // Auto-open keyboard for new entries
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }

    // Listen to text changes to auto-generate title (only for new entries)
    _textController.addListener(_onTextChanged);

    // Listen to title changes to detect manual editing
    _titleController.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Auto-generate title from first 3 words (only for new text entries)
  void _onTextChanged() {
    if (isEditMode || _titleManuallyEdited || _activeType != ValueType.text) return;

    final text = _textController.text.trim();
    if (text.isEmpty) {
      _titleController.clear();
      return;
    }

    final words = text.split(RegExp(r'\s+'));
    final firstThreeWords = words.take(3).join(' ');

    if (_titleController.text != firstThreeWords) {
      _titleController.text = firstThreeWords;
    }
  }

  void _onTitleChanged() {
    if (_titleController.text.isNotEmpty) {
      _titleManuallyEdited = true;
    }
  }

  // ================= SAVE ENTRY =================

  Future<void> _saveEntry() async {
    final entryProvider = context.read<EntryProvider>();
    final categoryProvider = context.read<CategoryProvider>();

    String title = _titleController.text.trim();

    // Auto-generate title if empty
    if (title.isEmpty) {
      if (_activeType == ValueType.text) {
        final text = _textController.text.trim();
        if (text.isEmpty) {
          _showSnack('Please write something');
          return;
        }
        final words = text.split(RegExp(r'\s+'));
        title = words.take(3).join(' ');
      } else {
        title = '${_activeType.name.toUpperCase()} ${DateTime.now().toString().substring(0, 16)}';
      }
    }

    String value;
    if (_activeType == ValueType.text) {
      value = _textController.text.trim();
      if (value.isEmpty) {
        _showSnack('Please write something');
        return;
      }
    } else {
      value = _filePath ?? '';
      if (value.isEmpty) {
        _showSnack('Please select a file');
        return;
      }
    }

    // Handle category selection
    String categoryId;
    if (_selectedCategoryId != null) {
      categoryId = _selectedCategoryId!;
    } else {
      if (categoryProvider.categories.isEmpty) {
        await categoryProvider.addCategory('General');
        await Future.delayed(const Duration(milliseconds: 100));
        categoryProvider.loadCategories();
      }

      final generalCategory = categoryProvider.categories.firstWhere(
            (cat) => cat.name.toLowerCase() == 'general',
        orElse: () => categoryProvider.categories.first,
      );
      categoryId = generalCategory.id;
    }

    if (isEditMode) {
      // Update existing entry
      widget.entry!.key = title;
      widget.entry!.value = value;
      widget.entry!.categoryId = categoryId;
      await entryProvider.updateEntry(widget.entry!);
    } else {
      // Create new entry
      await entryProvider.addEntry(
        key: title,
        value: value,
        valueType: _activeType,
        categoryId: categoryId,
      );
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  // ================= CATEGORY SELECTION MODAL =================

  Future<void> _showCategoryPicker() async {
    final categoryProvider = context.read<CategoryProvider>();

    if (categoryProvider.categories.isEmpty) {
      await categoryProvider.addCategory('General');
      categoryProvider.loadCategories();
    }

    final generalExists = categoryProvider.categories.any(
          (cat) => cat.name.toLowerCase() == 'general',
    );
    if (!generalExists) {
      await categoryProvider.addCategory('General');
      categoryProvider.loadCategories();
    }

    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CategoryPickerModal(),
    );

    if (result != null) {
      setState(() {
        _selectedCategoryId = result['id'];
        _selectedCategoryName = result['name']!;
      });
    }
  }

  void _showSnack(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.textHint,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  // ================= CHIP HANDLER =================

  void _onChipTap(ValueType type) async {
    //In edit mode, don't allow changing media types
    if (isEditMode && type != _activeType) {
      _showSnack('Cannot change type when editing');
      return;
    }

    setState(() {
      _activeType = type;
      _filePath = null;
      if (!isEditMode) {
        _titleManuallyEdited = false;
      }
    });

    if (type == ValueType.text) {
      _focusNode.requestFocus();
      return;
    }

    await _openPicker(type);
  }

  // ================= PICKER =================

  Future<void> _openPicker(ValueType type) async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Camera', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo, color: Colors.white),
              title: const Text('Gallery', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source == null) return;

    if (type == ValueType.image) {
      final img = await picker.pickImage(source: source);
      if (img != null) {
        setState(() => _filePath = img.path);
        if (!isEditMode && !_titleManuallyEdited) {
          _titleController.text = 'Photo ${DateTime.now().toString().substring(11, 16)}';
        }
      }
    } else if (type == ValueType.video) {
      final vid = await picker.pickVideo(source: source);
      if (vid != null) {
        setState(() => _filePath = vid.path);
        if (!isEditMode && !_titleManuallyEdited) {
          _titleController.text = 'Video ${DateTime.now().toString().substring(11, 16)}';
        }
      }
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _titleController,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          decoration: const InputDecoration(
            hintText: 'Title',
            hintStyle: TextStyle(color: AppColors.textHint),
            border: InputBorder.none,
          ),
          onTap: () {
            _titleManuallyEdited = true;
          },
        ),
        actions: [
          TextButton(
            onPressed: _saveEntry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.saveButton,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isEditMode ? 'Update' : 'Save',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChips(),
                const SizedBox(height: 20),
                Expanded(child: _buildContent()),
                const SizedBox(height: 70), // Space for category button
              ],
            ),
          ),
          // Category selector button at bottom-left
          Positioned(
            left: 16,
            bottom: 16,
            child: GestureDetector(
              onTap: _showCategoryPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white24, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.label, size: 18, color: Colors.white70),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        _selectedCategoryName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_drop_down, size: 20, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= CHIPS =================

  Widget _buildChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(
            label: 'Text',
            type: ValueType.text,
            color: AppColors.textChip,
            icon: Icons.chat_bubble_outline,
          ),
          const SizedBox(width: 12),
          _chip(
            label: 'Photo',
            type: ValueType.image,
            color: AppColors.photoChip,
            icon: Icons.image_outlined,
          ),
          const SizedBox(width: 12),
          _chip(
            label: 'Video',
            type: ValueType.video,
            color: AppColors.videoChip,
            icon: Icons.play_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required ValueType type,
    required Color color,
    required IconData icon,
  }) {
    final isActive = _activeType == type;
    final isDisabled = isEditMode && type != _activeType;

    return GestureDetector(
      onTap: () => _onChipTap(type),
      child: Opacity(
        opacity: isDisabled
            ? 0.3
            : (isActive ? AppColors.activeOpacity : AppColors.inactiveOpacity),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.black),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= CONTENT =================

  Widget _buildContent() {
    if (_activeType == ValueType.text) {
      return TextField(
        controller: _textController,
        focusNode: _focusNode,
        maxLines: null,
        style: AppTheme.bodyStyle(size: 18, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Write your stickies...',
          hintStyle: GoogleFonts.nunito(
            color: AppColors.textHint,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          )
          ,
          border: InputBorder.none,
        ),
      );
    }

    if (_filePath == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _activeType == ValueType.image
                  ? Icons.add_photo_alternate_outlined
                  : Icons.video_library_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              isEditMode
                  ? 'No file available'
                  : 'Tap chip again to select ${_activeType.name}',
              style: const TextStyle(color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    if (_activeType == ValueType.image) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              File(_filePath!),
              fit: BoxFit.contain,
              width: double.infinity,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                if (isEditMode)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                    onPressed: () => _openPicker(_activeType),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                  onPressed: () {
                    setState(() {
                      _filePath = null;
                      if (!isEditMode) {
                        _titleController.clear();
                        _titleManuallyEdited = false;
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.play_circle_fill,
            size: 72,
            color: AppColors.videoChip,
          ),
          const SizedBox(height: 16),
          Text(
            _filePath!.split('/').last,
            style: const TextStyle(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (isEditMode)
            ElevatedButton.icon(
              onPressed: () => _openPicker(_activeType),
              icon: const Icon(Icons.edit),
              label: const Text('Change Video'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.saveButton,
                foregroundColor: Colors.black,
              ),
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _filePath = null;
                if (!isEditMode) {
                  _titleController.clear();
                  _titleManuallyEdited = false;
                }
              });
            },
            icon: const Icon(Icons.close),
            label: const Text('Remove Video'),
          ),
        ],
      ),
    );
  }
}
