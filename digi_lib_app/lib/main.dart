import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:menu_bar/menu_bar.dart';
import 'src/utils/constants.dart';
import 'src/utils/network_test.dart';
import 'src/screens/auth/auth_wrapper.dart';
import 'src/widgets/session_timeout_handler.dart';
import 'src/widgets/global_error_handler.dart';
import 'src/widgets/offline_mode_banner.dart';
import 'src/widgets/user_feedback_system.dart';
import 'src/services/token_refresh_service.dart';
import 'src/services/desktop/desktop_integration_service.dart';
import 'src/services/desktop/desktop_ui_service.dart';
import 'src/services/desktop/desktop_window_service.dart';
import 'src/services/mobile/mobile_integration_service.dart';
import 'src/services/mobile/mobile_ui_service.dart';
import 'src/services/mobile/notification_service.dart';
import 'src/services/desktop/menu_bar_service.dart';

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
  
  // Initialize platform-specific services
  if (DesktopUIService.isDesktop) {
    await _initializeDesktopServices();
  } else if (MobileUIService.isMobile) {
    await _initializeMobileServices();
  }
  
  runApp(
    const ProviderScope(
      child: DigitalLibraryApp(),
    ),
  );
}

Future<void> _initializeDesktopServices() async {
  try {
    await DesktopIntegrationService.initialize(
      onNewLibrary: () {
        // TODO: Navigate to add library screen
        print('New Library requested');
      },
      onOpenFile: () {
        // TODO: Open file picker
        print('Open File requested');
      },
      onSearch: () {
        // TODO: Navigate to search screen
        print('Search requested');
      },
      onSettings: () {
        // TODO: Navigate to settings screen
        print('Settings requested');
      },
      onAbout: () {
        // TODO: Show about dialog
        print('About requested');
      },
      onQuit: () {
        // TODO: Handle app quit
        print('Quit requested');
      },
      onRefresh: () {
        // TODO: Refresh current view
        print('Refresh requested');
      },
      onToggleFullscreen: () async {
        await DesktopWindowService.toggleFullscreen();
      },
      onZoomIn: () {
        // TODO: Increase zoom level
        print('Zoom In requested');
      },
      onZoomOut: () {
        // TODO: Decrease zoom level
        print('Zoom Out requested');
      },
      onZoomReset: () {
        // TODO: Reset zoom level
        print('Zoom Reset requested');
      },
      onGoBack: () {
        // TODO: Navigate back
        print('Go Back requested');
      },
      onGoForward: () {
        // TODO: Navigate forward
        print('Go Forward requested');
      },
      updateUrl: 'https://api.example.com/updates', // TODO: Replace with actual update URL
      enableAutoUpdates: true,
    );
  } catch (e) {
    print('Failed to initialize desktop services: $e');
  }
}

Future<void> _initializeMobileServices() async {
  try {
    await MobileIntegrationService.initialize(
      notificationConfig: const NotificationConfig(
        enableSyncNotifications: true,
        enableDownloadNotifications: true,
        enableErrorNotifications: true,
        enableReadingReminders: false,
      ),
      enableBackgroundSync: true,
      enableGestureOptimizations: true,
    );
  } catch (e) {
    print('Failed to initialize mobile services: $e');
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
      theme: DesktopUIService.isDesktop 
          ? DesktopUIService.getDesktopTheme(isDark: false)
          : MobileUIService.isMobile
              ? MobileUIService.getMobileTheme(isDark: false)
              : ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                ),
                filled: true,
              ),
            ),
      darkTheme: DesktopUIService.isDesktop 
          ? DesktopUIService.getDesktopTheme(isDark: true)
          : MobileUIService.isMobile
              ? MobileUIService.getMobileTheme(isDark: true)
              : ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                ),
                filled: true,
              ),
            ),
      scrollBehavior: DesktopUIService.isDesktop 
          ? DesktopUIService.getDesktopScrollBehavior()
          : null,
      home: const GlobalErrorHandler(
        child: FeedbackPromptWidget(
          child: OfflineModeBanner(
            child: SessionTimeoutHandler(
              child: AuthWrapper(),
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
    
    // Wrap with MenuBarWidget for desktop platforms
    if (DesktopUIService.isDesktop) {
      return MenuBarWidget(
        barButtons: MenuBarService.menuButtons,
        child: app,
      );
    }
    
    return app;
  }
}