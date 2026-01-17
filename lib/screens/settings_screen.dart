
// lib/screens/settings_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          final settings = settingsProvider.settings;

          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Theme Customization',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('Background Color'),
                trailing: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(settings.backgroundColor),
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onTap: () => _showColorPicker(context, settingsProvider),
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Background Image'),
                subtitle: settings.backgroundImagePath != null
                    ? const Text('Tap to change or remove')
                    : const Text('No image set'),
                trailing: settings.backgroundImagePath != null
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    settingsProvider.updateBackgroundImage(null);
                  },
                )
                    : null,
                onTap: () => _pickBackgroundImage(context, settingsProvider),
              ),
              if (settings.backgroundImagePath != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(settings.backgroundImagePath!),
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'About',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('DataStock'),
                subtitle: Text('Version 1.0.0\nSecure Key-Value Storage'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showColorPicker(BuildContext context, SettingsProvider provider) {
    final colors = [
      Colors.white,
      Colors.grey[100]!,
      Colors.blue[50]!,
      Colors.green[50]!,
      Colors.purple[50]!,
      Colors.orange[50]!,
      Colors.pink[50]!,
      Colors.teal[50]!,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Background Color'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  provider.updateBackgroundColor(colors[index]);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: colors[index],
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickBackgroundImage(
      BuildContext context,
      SettingsProvider provider,
      ) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      provider.updateBackgroundImage(image.path);
    }
  }
}