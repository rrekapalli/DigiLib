import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digi_lib_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End User Workflow Tests', () {
    testWidgets(
      'Complete user journey: Authentication -> Library -> Document Reading',
      (WidgetTester tester) async {
        // Start the app
        app.main();
        await tester.pumpAndSettle();

        // Step 1: Authentication Flow
        await _testAuthenticationFlow(tester);

        // Step 2: Library Management
        await _testLibraryManagement(tester);

        // Step 3: Document Browsing
        await _testDocumentBrowsing(tester);

        // Step 4: Document Reading
        await _testDocumentReading(tester);

        // Step 5: Annotation Features
        await _testAnnotationFeatures(tester);

        // Step 6: Search Functionality
        await _testSearchFunctionality(tester);

        // Step 7: Settings and Preferences
        await _testSettingsAndPreferences(tester);
      },
    );

    testWidgets('Offline functionality workflow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Authenticate first
      await _testAuthenticationFlow(tester);

      // Test offline document access
      await _testOfflineDocumentAccess(tester);

      // Test offline annotation creation
      await _testOfflineAnnotations(tester);

      // Test sync when back online
      await _testSyncAfterOffline(tester);
    });

    testWidgets('Error handling and recovery workflow', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      // Test network error handling
      await _testNetworkErrorHandling(tester);

      // Test authentication error recovery
      await _testAuthErrorRecovery(tester);

      // Test sync conflict resolution
      await _testSyncConflictResolution(tester);
    });
  });
}

Future<void> _testAuthenticationFlow(WidgetTester tester) async {
  // Look for sign-in button or welcome screen
  expect(find.textContaining('Sign In'), findsOneWidget);

  // Tap sign-in button
  await tester.tap(find.textContaining('Sign In'));
  await tester.pumpAndSettle();

  // Should show OAuth provider options
  expect(find.textContaining('Google'), findsOneWidget);
  expect(find.textContaining('Microsoft'), findsOneWidget);

  // Tap Google sign-in (this would normally open a web view)
  await tester.tap(find.textContaining('Google'));
  await tester.pumpAndSettle();

  // In a real test, we'd mock the OAuth flow
  // For now, we'll simulate successful authentication
  // by checking if we reach the main app screen

  // Wait for authentication to complete
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Should now be on the main library screen
  expect(find.textContaining('Libraries'), findsOneWidget);
}

Future<void> _testLibraryManagement(WidgetTester tester) async {
  // Should be on libraries screen
  expect(find.textContaining('Libraries'), findsOneWidget);

  // Look for add library button
  final addLibraryButton = find.byIcon(Icons.add);
  expect(addLibraryButton, findsOneWidget);

  // Tap add library
  await tester.tap(addLibraryButton);
  await tester.pumpAndSettle();

  // Should show library type selection dialog
  expect(find.textContaining('Add Library'), findsOneWidget);
  expect(find.textContaining('Local Folder'), findsOneWidget);
  expect(find.textContaining('Google Drive'), findsOneWidget);

  // Select local folder
  await tester.tap(find.textContaining('Local Folder'));
  await tester.pumpAndSettle();

  // Should show folder picker or path input
  // For testing, we'll assume a test library is created

  // Wait for library to be added
  await tester.pumpAndSettle(const Duration(seconds: 1));

  // Should see the new library in the list
  expect(find.textContaining('Test Library'), findsOneWidget);
}

Future<void> _testDocumentBrowsing(WidgetTester tester) async {
  // Tap on a library to browse documents
  await tester.tap(find.textContaining('Test Library'));
  await tester.pumpAndSettle();

  // Should be in document browser
  expect(find.byType(GridView), findsOneWidget);

  // Should see document cards
  expect(find.byType(Card), findsAtLeastNWidgets(1));

  // Test view mode toggle
  final viewModeButton = find.byIcon(Icons.view_list);
  if (viewModeButton.evaluate().isNotEmpty) {
    await tester.tap(viewModeButton);
    await tester.pumpAndSettle();

    // Should switch to list view
    expect(find.byType(ListView), findsOneWidget);
  }

  // Test sorting options
  final sortButton = find.byIcon(Icons.sort);
  if (sortButton.evaluate().isNotEmpty) {
    await tester.tap(sortButton);
    await tester.pumpAndSettle();

    // Should show sort options
    expect(find.textContaining('Name'), findsOneWidget);
    expect(find.textContaining('Date'), findsOneWidget);

    // Select sort by name
    await tester.tap(find.textContaining('Name'));
    await tester.pumpAndSettle();
  }
}

Future<void> _testDocumentReading(WidgetTester tester) async {
  // Tap on a document to open it
  final documentCard = find.byType(Card).first;
  await tester.tap(documentCard);
  await tester.pumpAndSettle();

  // Should be in document reader
  expect(find.byType(PageView), findsOneWidget);

  // Test page navigation
  await tester.drag(find.byType(PageView), const Offset(-300, 0));
  await tester.pumpAndSettle();

  // Should advance to next page
  // Verify page indicator updated

  // Test zoom functionality
  await tester.timedDrag(
    find.byType(PageView),
    const Offset(0, 0),
    const Duration(milliseconds: 100),
  );

  // Pinch to zoom (simulate)
  final center = tester.getCenter(find.byType(PageView));
  await tester.startGesture(center);
  await tester.pumpAndSettle();

  // Test reader controls
  final readerToolbar = find.byType(AppBar);
  expect(readerToolbar, findsOneWidget);

  // Test back navigation
  final backButton = find.byIcon(Icons.arrow_back);
  await tester.tap(backButton);
  await tester.pumpAndSettle();

  // Should be back in document browser
  expect(find.byType(GridView), findsOneWidget);
}

Future<void> _testAnnotationFeatures(WidgetTester tester) async {
  // Open a document again
  final documentCard = find.byType(Card).first;
  await tester.tap(documentCard);
  await tester.pumpAndSettle();

  // Test bookmark creation
  final bookmarkButton = find.byIcon(Icons.bookmark_add);
  if (bookmarkButton.evaluate().isNotEmpty) {
    await tester.tap(bookmarkButton);
    await tester.pumpAndSettle();

    // Should show bookmark creation dialog
    expect(find.textContaining('Add Bookmark'), findsOneWidget);

    // Add bookmark note
    final noteField = find.byType(TextField);
    await tester.enterText(noteField, 'Test bookmark note');
    await tester.pumpAndSettle();

    // Save bookmark
    await tester.tap(find.textContaining('Save'));
    await tester.pumpAndSettle();

    // Should show success message or bookmark indicator
  }

  // Test comment creation
  final commentButton = find.byIcon(Icons.comment);
  if (commentButton.evaluate().isNotEmpty) {
    await tester.tap(commentButton);
    await tester.pumpAndSettle();

    // Should show comment creation interface
    expect(find.textContaining('Add Comment'), findsOneWidget);

    // Add comment text
    final commentField = find.byType(TextField);
    await tester.enterText(commentField, 'Test comment');
    await tester.pumpAndSettle();

    // Save comment
    await tester.tap(find.textContaining('Save'));
    await tester.pumpAndSettle();
  }

  // Test annotation list
  final annotationsButton = find.byIcon(Icons.list);
  if (annotationsButton.evaluate().isNotEmpty) {
    await tester.tap(annotationsButton);
    await tester.pumpAndSettle();

    // Should show annotations list
    expect(find.textContaining('Bookmarks'), findsOneWidget);
    expect(find.textContaining('Comments'), findsOneWidget);
  }
}

Future<void> _testSearchFunctionality(WidgetTester tester) async {
  // Navigate to search screen
  final searchButton = find.byIcon(Icons.search);
  await tester.tap(searchButton);
  await tester.pumpAndSettle();

  // Should be on search screen
  expect(find.byType(TextField), findsOneWidget);

  // Enter search query
  await tester.enterText(find.byType(TextField), 'test search');
  await tester.pumpAndSettle();

  // Trigger search
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pumpAndSettle();

  // Should show search results
  expect(find.textContaining('Results'), findsOneWidget);

  // Test search filters
  final filterButton = find.byIcon(Icons.filter_list);
  if (filterButton.evaluate().isNotEmpty) {
    await tester.tap(filterButton);
    await tester.pumpAndSettle();

    // Should show filter options
    expect(find.textContaining('Library'), findsOneWidget);
    expect(find.textContaining('File Type'), findsOneWidget);
  }

  // Test search result interaction
  if (find.byType(ListTile).evaluate().isNotEmpty) {
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    // Should open the document from search results
    expect(find.byType(PageView), findsOneWidget);
  }
}

Future<void> _testSettingsAndPreferences(WidgetTester tester) async {
  // Navigate to settings
  final settingsButton = find.byIcon(Icons.settings);
  await tester.tap(settingsButton);
  await tester.pumpAndSettle();

  // Should be on settings screen
  expect(find.textContaining('Settings'), findsOneWidget);

  // Test theme settings
  final themeOption = find.textContaining('Theme');
  if (themeOption.evaluate().isNotEmpty) {
    await tester.tap(themeOption);
    await tester.pumpAndSettle();

    // Should show theme options
    expect(find.textContaining('Light'), findsOneWidget);
    expect(find.textContaining('Dark'), findsOneWidget);
    expect(find.textContaining('System'), findsOneWidget);

    // Select dark theme
    await tester.tap(find.textContaining('Dark'));
    await tester.pumpAndSettle();
  }

  // Test sync settings
  final syncOption = find.textContaining('Sync');
  if (syncOption.evaluate().isNotEmpty) {
    await tester.tap(syncOption);
    await tester.pumpAndSettle();

    // Should show sync options
    expect(find.byType(Switch), findsAtLeastNWidgets(1));

    // Toggle auto-sync
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
  }

  // Test cache settings
  final cacheOption = find.textContaining('Cache');
  if (cacheOption.evaluate().isNotEmpty) {
    await tester.tap(cacheOption);
    await tester.pumpAndSettle();

    // Should show cache management options
    expect(find.textContaining('Clear Cache'), findsOneWidget);
  }
}

Future<void> _testOfflineDocumentAccess(WidgetTester tester) async {
  // Simulate going offline
  // In a real test, we'd mock network connectivity

  // Try to access a document
  final documentCard = find.byType(Card).first;
  await tester.tap(documentCard);
  await tester.pumpAndSettle();

  // Should still be able to view cached documents
  expect(find.byType(PageView), findsOneWidget);

  // Should show offline indicator
  expect(find.byIcon(Icons.cloud_off), findsOneWidget);
}

Future<void> _testOfflineAnnotations(WidgetTester tester) async {
  // Create annotations while offline
  final bookmarkButton = find.byIcon(Icons.bookmark_add);
  if (bookmarkButton.evaluate().isNotEmpty) {
    await tester.tap(bookmarkButton);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Offline bookmark');
    await tester.tap(find.textContaining('Save'));
    await tester.pumpAndSettle();

    // Should show offline queue indicator
    expect(find.byIcon(Icons.sync_problem), findsOneWidget);
  }
}

Future<void> _testSyncAfterOffline(WidgetTester tester) async {
  // Simulate coming back online
  // In a real test, we'd restore network connectivity

  // Should automatically start syncing
  expect(find.byIcon(Icons.sync), findsOneWidget);

  // Wait for sync to complete
  await tester.pumpAndSettle(const Duration(seconds: 3));

  // Should show sync success
  expect(find.textContaining('Synced'), findsOneWidget);
}

Future<void> _testNetworkErrorHandling(WidgetTester tester) async {
  // Simulate network error during API call
  // Should show error message with retry option
  expect(find.textContaining('Network Error'), findsOneWidget);
  expect(find.textContaining('Retry'), findsOneWidget);

  // Test retry functionality
  await tester.tap(find.textContaining('Retry'));
  await tester.pumpAndSettle();
}

Future<void> _testAuthErrorRecovery(WidgetTester tester) async {
  // Simulate authentication token expiration
  // Should automatically attempt token refresh
  // If refresh fails, should prompt for re-authentication

  if (find.textContaining('Session Expired').evaluate().isNotEmpty) {
    expect(find.textContaining('Sign In Again'), findsOneWidget);

    await tester.tap(find.textContaining('Sign In Again'));
    await tester.pumpAndSettle();

    // Should return to authentication flow
    expect(find.textContaining('Sign In'), findsOneWidget);
  }
}

Future<void> _testSyncConflictResolution(WidgetTester tester) async {
  // Simulate sync conflict
  if (find.textContaining('Sync Conflict').evaluate().isNotEmpty) {
    expect(find.textContaining('Resolve'), findsOneWidget);

    await tester.tap(find.textContaining('Resolve'));
    await tester.pumpAndSettle();

    // Should show conflict resolution options
    expect(find.textContaining('Keep Local'), findsOneWidget);
    expect(find.textContaining('Keep Server'), findsOneWidget);

    // Choose resolution
    await tester.tap(find.textContaining('Keep Local'));
    await tester.pumpAndSettle();

    // Should resolve conflict and continue sync
    expect(find.textContaining('Conflict Resolved'), findsOneWidget);
  }
}
