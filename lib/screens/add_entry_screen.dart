// lib/screens/add_entry_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/value_type.dart';
import '../providers/entry_provider.dart';
import '../providers/category_provider.dart';

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();
  final _newCategoryController = TextEditingController();

  ValueType _selectedType = ValueType.text;
  String? _selectedCategoryId;
  String? _filePath;
  bool _showNewCategory = false;

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      if (_selectedType == ValueType.image) {
        final picker = ImagePicker();
        final image = await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          setState(() {
            _filePath = image.path;
          });
        }
      } else {
        FileType fileType;
        if (_selectedType == ValueType.audio) {
          fileType = FileType.audio;
        } else {
          fileType = FileType.video;
        }

        final result = await FilePicker.platform.pickFiles(type: fileType);
        if (result != null && result.files.single.path != null) {
          setState(() {
            _filePath = result.files.single.path;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    final categoryProvider = context.read<CategoryProvider>();
    final entryProvider = context.read<EntryProvider>();

    String categoryId;
    if (_showNewCategory && _newCategoryController.text.isNotEmpty) {
      await categoryProvider.addCategory(_newCategoryController.text);
      categoryProvider.loadCategories();
      categoryId = categoryProvider.categories
          .firstWhere((c) => c.name == _newCategoryController.text)
          .id;
    } else if (_selectedCategoryId != null) {
      categoryId = _selectedCategoryId!;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    String value = _selectedType == ValueType.text
        ? _valueController.text
        : (_filePath ?? '');

    if (_selectedType != ValueType.text && value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file')),
      );
      return;
    }

    await entryProvider.addEntry(
      key: _keyController.text,
      value: value,
      valueType: _selectedType,
      categoryId: categoryId,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Entry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveEntry,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _keyController,
              decoration: const InputDecoration(
                labelText: 'Key *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a key';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ValueType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Value Type',
                border: OutlineInputBorder(),
              ),
              items: ValueType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                  _filePath = null;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_selectedType == ValueType.text)
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: 'Value *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a value';
                  }
                  return null;
                },
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: Text('Select ${_selectedType.name.toUpperCase()}'),
                  ),
                  if (_filePath != null) ...[
                    const SizedBox(height: 8),
                    if (_selectedType == ValueType.image)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_filePath!),
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _filePath!.split('/').last,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            const SizedBox(height: 16),
            Consumer<CategoryProvider>(
              builder: (context, categoryProvider, child) {
                final categories = categoryProvider.categories;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_showNewCategory) ...[
                      DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat.id,
                            child: Text(cat.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showNewCategory = true;
                            _selectedCategoryId = null;
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create New Category'),
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _newCategoryController,
                        decoration: const InputDecoration(
                          labelText: 'New Category Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a category name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showNewCategory = false;
                            _newCategoryController.clear();
                          });
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Select Existing Category'),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}