import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../models/analytics_event.dart';
import '../models/value_type.dart';
import 'uuid_service.dart';

/// Centralized analytics service for tracking user behavior
///
/// This service wraps Firebase Analytics and provides:
/// - Type-safe event logging
/// - Automatic user UUID association
/// - Event throttling to avoid spam
/// - Crashlytics integration
///
/// Usage:
/// ```dart
/// await analyticsService.logStickyCreated(
///   type: ValueType.text,
///   categoryId: 'cat_123',
/// );
/// ```
class AnalyticsService {
  final FirebaseAnalytics _analytics;
  final UuidService _uuidService;

  // Throttling: prevent logging duplicate events within this window
  static const Duration _throttleDuration = Duration(seconds: 2);
  final Map<String, DateTime> _lastEventTimes = {};

  AnalyticsService({
    required FirebaseAnalytics analytics,
    required UuidService uuidService,
  })  : _analytics = analytics,
        _uuidService = uuidService;

  /// Initialize analytics with user UUID
  Future<void> initialize() async {
    try {
      final uuid = await _uuidService.getUserUuid();

      // Set user ID for all future events
      await _analytics.setUserId(id: uuid);

      // Set custom user property
      await _analytics.setUserProperty(
        name: 'user_uuid',
        value: uuid,
      );

      // Configure Crashlytics user identifier
      FirebaseCrashlytics.instance.setUserIdentifier(uuid);

      print('✅ Analytics initialized for user: $uuid');
    } catch (e, stackTrace) {
      print('❌ Failed to initialize analytics: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace);
    }
  }

  /// Check if event should be throttled
  bool _shouldThrottle(String eventKey) {
    final lastTime = _lastEventTimes[eventKey];
    if (lastTime == null) return false;

    final timeSince = DateTime.now().difference(lastTime);
    return timeSince < _throttleDuration;
  }

  /// Log event with automatic UUID and timestamp
  Future<void> _logEvent(
    AnalyticsEvent event,
    Map<String, dynamic> parameters,
  ) async {
    try {
      // Check throttling
      final eventKey =
          '${event.eventName}_${parameters[AnalyticsParams.stickyId] ?? ''}';
      if (_shouldThrottle(eventKey)) {
        print('⏸️ Event throttled: ${event.eventName}');
        return;
      }
      _lastEventTimes[eventKey] = DateTime.now();

      // Add common parameters
      final enrichedParams = {
        ...parameters,
        AnalyticsParams.userId: _uuidService.getCachedUuid() ?? 'unknown',
        AnalyticsParams.timestamp: DateTime.now().millisecondsSinceEpoch,
      };

      await _analytics.logEvent(
        name: event.eventName,
        parameters: enrichedParams,
      );

      print('📊 Event logged: ${event.eventName}');
    } catch (e, stackTrace) {
      print('❌ Failed to log event ${event.eventName}: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace);
    }
  }

  // ==================== STICKY CREATION ====================

  /// Log sticky creation
  Future<void> logStickyCreated({
    required ValueType type,
    required String categoryId,
    String? categoryName,
    int? contentLength,
  }) async {
    AnalyticsEvent event;
    switch (type) {
      case ValueType.text:
        event = AnalyticsEvent.createTextSticky;
        break;
      case ValueType.image:
        event = AnalyticsEvent.createPhotoSticky;
        break;
      case ValueType.video:
        event = AnalyticsEvent.createVideoSticky;
        break;
      case ValueType.audio:
        event = AnalyticsEvent.createTextSticky; // Fallback
        break;
    }

    await _logEvent(event, {
      AnalyticsParams.stickyType: type.name,
      AnalyticsParams.categoryId: categoryId,
      if (categoryName != null) AnalyticsParams.categoryName: categoryName,
      if (contentLength != null) AnalyticsParams.contentLength: contentLength,
    });
  }

  /// Log sticky update
  Future<void> logStickyUpdated({
    required String stickyId,
    required ValueType type,
    required String categoryId,
  }) async {
    await _logEvent(AnalyticsEvent.updateSticky, {
      AnalyticsParams.stickyId: stickyId,
      AnalyticsParams.stickyType: type.name,
      AnalyticsParams.categoryId: categoryId,
    });
  }

  // ==================== STICKY ACTIONS ====================

  /// Log sticky copy action
  Future<void> logStickyCopy({
    required String stickyId,
    required ValueType type,
  }) async {
    await _logEvent(AnalyticsEvent.stickyCopy, {
      AnalyticsParams.stickyId: stickyId,
      AnalyticsParams.stickyType: type.name,
    });
  }

  /// Log sticky share action
  Future<void> logStickyShare({
    required String stickyId,
    required ValueType type,
  }) async {
    await _logEvent(AnalyticsEvent.stickyShare, {
      AnalyticsParams.stickyId: stickyId,
      AnalyticsParams.stickyType: type.name,
    });
  }

  /// Log sticky hide/show toggle
  Future<void> logStickyVisibilityToggle({
    required String stickyId,
    required bool isNowHidden,
  }) async {
    await _logEvent(
      isNowHidden ? AnalyticsEvent.stickyHide : AnalyticsEvent.stickyShow,
      {
        AnalyticsParams.stickyId: stickyId,
      },
    );
  }

  /// Log sticky edit initiated
  Future<void> logStickyEdit({
    required String stickyId,
    required ValueType type,
  }) async {
    await _logEvent(AnalyticsEvent.stickyEdit, {
      AnalyticsParams.stickyId: stickyId,
      AnalyticsParams.stickyType: type.name,
    });
  }

  /// Log sticky deletion
  Future<void> logStickyDelete({
    required String stickyId,
    required ValueType type,
  }) async {
    await _logEvent(AnalyticsEvent.stickyDelete, {
      AnalyticsParams.stickyId: stickyId,
      AnalyticsParams.stickyType: type.name,
    });
  }

  // ==================== CATEGORY EVENTS ====================

  /// Log category creation
  Future<void> logCategoryCreated({
    required String categoryId,
    required String categoryName,
    required int totalCategories,
  }) async {
    await _logEvent(AnalyticsEvent.createCategory, {
      AnalyticsParams.categoryId: categoryId,
      AnalyticsParams.categoryName: categoryName,
      AnalyticsParams.categoryCount: totalCategories,
    });
  }

  /// Log category deletion
  Future<void> logCategoryDeleted({
    required String categoryId,
    required int remainingCategories,
  }) async {
    await _logEvent(AnalyticsEvent.deleteCategory, {
      AnalyticsParams.categoryId: categoryId,
      AnalyticsParams.categoryCount: remainingCategories,
    });
  }

  // ==================== SCREEN TRACKING ====================

  /// Log screen view
  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenName,
      );
      print('📱 Screen view: $screenName');
    } catch (e) {
      print('❌ Failed to log screen view: $e');
    }
  }

  /// Log sticky detail view
  Future<void> logStickyDetailView({
    required String stickyId,
    required ValueType type,
  }) async {
    await _logEvent(AnalyticsEvent.viewStickyDetail, {
      AnalyticsParams.stickyId: stickyId,
      AnalyticsParams.stickyType: type.name,
    });
  }

  // ==================== APP LIFECYCLE ====================

  /// Log app opened
  Future<void> logAppOpened() async {
    await _logEvent(AnalyticsEvent.appOpened, {});
  }

  /// Log aggregated stats (call periodically or on app close)
  Future<void> logUserStats({
    required int totalStickies,
    required int textCount,
    required int photoCount,
    required int videoCount,
    required int categoryCount,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'user_stats_snapshot',
        parameters: {
          AnalyticsParams.userId: _uuidService.getCachedUuid() ?? 'unknown',
          AnalyticsParams.totalStickies: totalStickies,
          AnalyticsParams.textStickiesCount: textCount,
          AnalyticsParams.photoStickiesCount: photoCount,
          AnalyticsParams.videoStickiesCount: videoCount,
          AnalyticsParams.categoryCount: categoryCount,
          AnalyticsParams.timestamp: DateTime.now().millisecondsSinceEpoch,
        },
      );
      print('📈 User stats logged');
    } catch (e) {
      print('❌ Failed to log user stats: $e');
    }
  }
}
