
// lib/providers/settings_provider.dart
import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = AppSettings();

  SettingsProvider() {
    loadSettings();
  }

  AppSettings get settings => _settings;

  void loadSettings() {
    _settings = StorageService.getSettings();
    notifyListeners();
  }

  Future<void> updateBackgroundColor(Color color) async {
    _settings.backgroundColor = color.value;
    await StorageService.updateSettings(_settings);
    notifyListeners();
  }

  Future<void> updateBackgroundImage(String? path) async {
    _settings.backgroundImagePath = path;
    await StorageService.updateSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _settings.isDarkMode = !_settings.isDarkMode;
    await StorageService.updateSettings(_settings);
    notifyListeners();
  }
}