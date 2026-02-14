import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Service for managing persistent user UUID
/// This UUID is generated once on first app launch and persists forever
class UuidService {
  static const String _kUserUuidKey = 'user_uuid_v1';
  static const Uuid _uuidGenerator = Uuid();

  String? _cachedUuid;

  /// Get or create user UUID
  /// Returns cached value if available, otherwise loads from storage
  Future<String> getUserUuid() async {
    if (_cachedUuid != null) {
      return _cachedUuid!;
    }

    final prefs = await SharedPreferences.getInstance();
    String? uuid = prefs.getString(_kUserUuidKey);

    if (uuid == null || uuid.isEmpty) {
      // First time user - generate new UUID
      uuid = _uuidGenerator.v4();
      await prefs.setString(_kUserUuidKey, uuid);
      print('🆔 New user UUID generated: $uuid');
    } else {
      print('🆔 Existing user UUID loaded: $uuid');
    }

    _cachedUuid = uuid;
    return uuid;
  }

  /// Get cached UUID synchronously (must call getUserUuid() first)
  String? getCachedUuid() => _cachedUuid;

  /// Clear UUID (for testing/debugging only)
  Future<void> clearUuid() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserUuidKey);
    _cachedUuid = null;
    print('🗑️ User UUID cleared');
  }
}
