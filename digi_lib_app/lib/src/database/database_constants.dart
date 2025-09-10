/// Database constants and table/column definitions
class DatabaseConstants {
  // Database configuration
  static const String databaseName = 'digi_lib.db';
  static const int currentVersion = 1;
  
  // Table names
  static const String usersTable = 'users';
  static const String librariesTable = 'libraries';
  static const String documentsTable = 'documents';
  static const String pagesTable = 'pages';
  static const String tagsTable = 'tags';
  static const String documentTagsTable = 'document_tags';
  static const String bookmarksTable = 'bookmarks';
  static const String commentsTable = 'comments';
  static const String sharesTable = 'shares';
  static const String readingProgressTable = 'reading_progress';
  static const String jobsQueueTable = 'jobs_queue';
  static const String cacheMetadataTable = 'cache_metadata';
  static const String documentsFtsTable = 'documents_fts';
  
  // Common column names
  static const String idColumn = 'id';
  static const String createdAtColumn = 'created_at';
  static const String updatedAtColumn = 'updated_at';
  static const String syncedColumn = 'synced';
  static const String syncedAtColumn = 'synced_at';
  
  // Users table columns
  static const String userEmailColumn = 'email';
  static const String userNameColumn = 'name';
  static const String userProviderColumn = 'provider';
  static const String userProviderIdColumn = 'provider_id';
  
  // Libraries table columns
  static const String libraryOwnerIdColumn = 'owner_id';
  static const String libraryNameColumn = 'name';
  static const String libraryTypeColumn = 'type';
  static const String libraryConfigColumn = 'config';
  
  // Documents table columns
  static const String documentLibraryIdColumn = 'library_id';
  static const String documentTitleColumn = 'title';
  static const String documentAuthorColumn = 'author';
  static const String documentFilenameColumn = 'filename';
  static const String documentRelativePathColumn = 'relative_path';
  static const String documentFullPathColumn = 'full_path';
  static const String documentExtensionColumn = 'extension';
  static const String documentRenamedNameColumn = 'renamed_name';
  static const String documentIsbnColumn = 'isbn';
  static const String documentYearPublishedColumn = 'year_published';
  static const String documentStatusColumn = 'status';
  static const String documentCloudIdColumn = 'cloud_id';
  static const String documentSha256Column = 'sha256';
  static const String documentSizeBytesColumn = 'size_bytes';
  static const String documentPageCountColumn = 'page_count';
  static const String documentFormatColumn = 'format';
  static const String documentImageUrlColumn = 'image_url';
  static const String documentAmazonUrlColumn = 'amazon_url';
  static const String documentReviewUrlColumn = 'review_url';
  static const String documentMetadataJsonColumn = 'metadata_json';
  
  // Pages table columns
  static const String pageDocIdColumn = 'doc_id';
  static const String pageNumberColumn = 'page_number';
  static const String pageTextContentColumn = 'text_content';
  static const String pageThumbnailUrlColumn = 'thumbnail_url';
  
  // Tags table columns
  static const String tagOwnerIdColumn = 'owner_id';
  static const String tagNameColumn = 'name';
  
  // Document tags table columns
  static const String documentTagDocIdColumn = 'doc_id';
  static const String documentTagTagIdColumn = 'tag_id';
  
  // Bookmarks table columns
  static const String bookmarkUserIdColumn = 'user_id';
  static const String bookmarkDocIdColumn = 'doc_id';
  static const String bookmarkPageNumberColumn = 'page_number';
  static const String bookmarkNoteColumn = 'note';
  
  // Comments table columns
  static const String commentDocIdColumn = 'doc_id';
  static const String commentUserIdColumn = 'user_id';
  static const String commentPageNumberColumn = 'page_number';
  static const String commentAnchorColumn = 'anchor';
  static const String commentContentColumn = 'content';
  
  // Shares table columns
  static const String shareSubjectIdColumn = 'subject_id';
  static const String shareSubjectTypeColumn = 'subject_type';
  static const String shareOwnerIdColumn = 'owner_id';
  static const String shareGranteeEmailColumn = 'grantee_email';
  static const String sharePermissionColumn = 'permission';
  
  // Reading progress table columns
  static const String readingProgressUserIdColumn = 'user_id';
  static const String readingProgressDocIdColumn = 'doc_id';
  static const String readingProgressLastPageColumn = 'last_page';
  
  // Jobs queue table columns
  static const String jobTypeColumn = 'type';
  static const String jobPayloadColumn = 'payload';
  static const String jobStatusColumn = 'status';
  static const String jobAttemptsColumn = 'attempts';
  static const String jobLastErrorColumn = 'last_error';
  static const String jobScheduledAtColumn = 'scheduled_at';
  
  // Cache metadata table columns
  static const String cacheKeyColumn = 'key';
  static const String cacheSizeBytesColumn = 'size_bytes';
  static const String cacheLastAccessedColumn = 'last_accessed';
  
  // Enum values
  static const List<String> libraryTypes = ['local', 'gdrive', 'onedrive', 's3'];
  static const List<String> shareSubjectTypes = ['document', 'folder'];
  static const List<String> sharePermissions = ['view', 'comment', 'full'];
  static const List<String> jobStatuses = ['pending', 'running', 'completed', 'failed'];
  
  // SQL query limits
  static const int defaultPageSize = 50;
  static const int maxPageSize = 200;
  static const int defaultCacheLimit = 1000;
  
  // Cache settings
  static const int defaultCacheSizeMB = 500;
  static const int maxCacheSizeMB = 2000;
  static const Duration cacheExpiryDuration = Duration(days: 30);
}

/// Database utility functions
class DatabaseUtils {
  /// Convert DateTime to Unix timestamp (milliseconds)
  static int dateTimeToTimestamp(DateTime dateTime) {
    return dateTime.millisecondsSinceEpoch;
  }
  
  /// Convert Unix timestamp to DateTime
  static DateTime timestampToDateTime(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }
  
  /// Get current timestamp
  static int getCurrentTimestamp() {
    return DateTime.now().millisecondsSinceEpoch;
  }
  
  /// Convert boolean to integer for SQLite storage
  static int boolToInt(bool value) {
    return value ? 1 : 0;
  }
  
  /// Convert integer to boolean from SQLite storage
  static bool intToBool(int value) {
    return value == 1;
  }
  
  /// Escape SQL string for safe queries
  static String escapeSqlString(String input) {
    return input.replaceAll("'", "''");
  }
  
  /// Build WHERE clause from map of conditions
  static String buildWhereClause(Map<String, dynamic> conditions) {
    if (conditions.isEmpty) return '';
    
    final clauses = conditions.entries.map((entry) {
      final key = entry.key;
      final value = entry.value;
      
      if (value == null) {
        return '$key IS NULL';
      } else if (value is List) {
        final placeholders = List.filled(value.length, '?').join(', ');
        return '$key IN ($placeholders)';
      } else {
        return '$key = ?';
      }
    }).toList();
    
    return 'WHERE ${clauses.join(' AND ')}';
  }
  
  /// Build ORDER BY clause
  static String buildOrderByClause(String column, {bool ascending = true}) {
    return 'ORDER BY $column ${ascending ? 'ASC' : 'DESC'}';
  }
  
  /// Build LIMIT clause with optional offset
  static String buildLimitClause(int limit, {int? offset}) {
    if (offset != null && offset > 0) {
      return 'LIMIT $limit OFFSET $offset';
    }
    return 'LIMIT $limit';
  }
  
  /// Validate table name to prevent SQL injection
  static bool isValidTableName(String tableName) {
    final validPattern = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');
    return validPattern.hasMatch(tableName);
  }
  
  /// Validate column name to prevent SQL injection
  static bool isValidColumnName(String columnName) {
    final validPattern = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');
    return validPattern.hasMatch(columnName);
  }
}