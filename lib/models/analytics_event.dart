/// Analytics event types for the Stickies app
enum AnalyticsEvent {
  // Sticky creation events
  createTextSticky('create_text_sticky'),
  createPhotoSticky('create_photo_sticky'),
  createVideoSticky('create_video_sticky'),

  // Sticky update event
  updateSticky('update_sticky'),

  // Sticky action events
  stickyCopy('sticky_copy'),
  stickyShare('sticky_share'),
  stickyHide('sticky_hide'),
  stickyShow('sticky_show'),
  stickyEdit('sticky_edit'),
  stickyDelete('sticky_delete'),

  // Category events
  createCategory('create_category'),
  deleteCategory('delete_category'),

  // Screen views
  viewStickyDetail('view_sticky_detail'),
  viewHome('view_home'),

  // App lifecycle
  appOpened('app_opened'),
  appClosed('app_closed');

  final String eventName;

  const AnalyticsEvent(this.eventName);
}

/// Common parameter keys for analytics events
class AnalyticsParams {
  static const String userId = 'user_uuid';
  static const String stickyType = 'sticky_type';
  static const String stickyId = 'sticky_id';
  static const String categoryId = 'category_id';
  static const String categoryName = 'category_name';
  static const String categoryCount = 'category_count';
  static const String totalStickies = 'total_stickies';
  static const String textStickiesCount = 'text_stickies_count';
  static const String photoStickiesCount = 'photo_stickies_count';
  static const String videoStickiesCount = 'video_stickies_count';
  static const String hasContent = 'has_content';
  static const String contentLength = 'content_length';
  static const String isEditMode = 'is_edit_mode';
  static const String timestamp = 'timestamp';
}
