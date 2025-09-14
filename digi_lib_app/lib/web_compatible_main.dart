import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/utils/constants.dart';
import 'src/utils/network_test.dart';
import 'src/screens/auth/auth_wrapper.dart';
import 'src/widgets/session_timeout_handler.dart';
import 'src/widgets/global_error_handler.dart';
import 'src/widgets/offline_mode_banner.dart';
import 'src/widgets/user_feedback_system.dart';
import 'src/services/token_refresh_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Test network connectivity for debugging
  if (kDebugMode) {
    try {
      await NetworkTest.testPlatformInfo();
      await NetworkTest.testApiConnectivity();
    } catch (e) {
      debugPrint('Network test failed: $e');
    }
  }

  // Initialize platform-specific services only if not on web
  if (!kIsWeb) {
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      await _initializeDesktopServices();
    } else {
      await _initializeMobileServices();
    }
  }

  runApp(const ProviderScope(child: DigitalLibraryApp()));
}

Future<void> _initializeDesktopServices() async {
  // Only initialize desktop services if not on web
  if (kIsWeb) return;

  try {
    // Desktop initialization code here
    // This will be skipped on web
    debugPrint('Desktop services initialized');
  } catch (e) {
    debugPrint('Failed to initialize desktop services: $e');
  }
}

Future<void> _initializeMobileServices() async {
  // Only initialize mobile services if not on web
  if (kIsWeb) return;

  try {
    // Mobile initialization code here
    debugPrint('Mobile services initialized');
  } catch (e) {
    debugPrint('Failed to initialize mobile services: $e');
  }
}

class DigitalLibraryApp extends ConsumerWidget {
  const DigitalLibraryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize token refresh service
    ref.watch(tokenRefreshServiceProvider);

    final app = MaterialApp(
      title: AppConstants.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.defaultBorderRadius,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.defaultBorderRadius,
            ),
          ),
          filled: true,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.defaultBorderRadius,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.defaultBorderRadius,
            ),
          ),
          filled: true,
        ),
      ),
      home: const GlobalErrorHandler(
        child: FeedbackPromptWidget(
          child: OfflineModeBanner(
            child: SessionTimeoutHandler(child: AuthWrapper()),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );

    // Don't wrap with MenuBarWidget for web
    return app;
  }
}
