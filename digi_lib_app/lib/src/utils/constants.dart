import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Application constants for the Digital Library App
class AppConstants {
  // App Information
  static const String appName = 'Digital Library';
  static const String appVersion = '1.0.0';

  // API Configuration
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:9090';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:9090';
    } else if (Platform.isIOS) {
      return 'http://localhost:9090';
    } else {
      return 'http://localhost:9090';
    }
  }

  static const String apiVersion = 'v1';

  // Database Configuration
  static const String databaseName = 'digital_library.db';
  static const int databaseVersion = 1;

  // Cache Configuration
  static const int maxCacheSizeMB = 500;
  static const int maxCacheAgeHours = 24 * 7; // 1 week

  // Pagination
  static const int defaultPageSize = 50;
  static const int maxPageSize = 100;

  // File Types
  static const List<String> supportedFileTypes = ['pdf', 'epub', 'docx'];

  // Rendering Configuration
  static const int defaultDPI = 150;
  static const String defaultImageFormat = 'webp';

  // Sync Configuration
  static const Duration syncInterval = Duration(minutes: 15);
  static const int maxRetryAttempts = 3;

  // Security
  static const String secureStorageKey = 'digi_lib_secure_storage';

  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double defaultBorderRadius = 8.0;
  static const double defaultPadding = 16.0;
}

/// Error messages
class ErrorMessages {
  static const String networkError =
      'Network connection error. Please check your internet connection.';
  static const String authenticationError =
      'Authentication failed. Please sign in again.';
  static const String fileNotFound = 'File not found or cannot be accessed.';
  static const String unsupportedFileType = 'Unsupported file type.';
  static const String syncError =
      'Synchronization failed. Changes will be synced when connection is restored.';
  static const String storageError =
      'Storage error. Please check available disk space.';
  static const String unknownError =
      'An unexpected error occurred. Please try again.';
}

/// Storage keys for SharedPreferences and SecureStorage
class StorageKeys {
  // Secure Storage Keys
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';

  // SharedPreferences Keys
  static const String userId = 'user_id';
  static const String lastSyncTime = 'last_sync_time';
  static const String cacheSize = 'cache_size';
  static const String appTheme = 'app_theme';
  static const String readingSettings = 'reading_settings';
  static const String notificationSettings = 'notification_settings';
}

/// Centralized logger utility for the DigiLib application.
///
/// Provides structured logging with different levels (debug, info, warning, error)
/// and consistent formatting across the application.
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// Log debug information - used for development debugging
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log informational messages - general application flow
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning messages - potential issues that don't break functionality
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error messages - actual errors that need attention
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal errors - critical errors that may crash the app
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}
