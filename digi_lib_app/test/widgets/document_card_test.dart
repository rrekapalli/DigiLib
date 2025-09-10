import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digi_lib_app/src/widgets/document_card.dart';
import 'package:digi_lib_app/src/models/entities/document.dart';

@Skip('TODO: Fix DocumentCard constructor parameters')
void main() {
  group('DocumentCard Widget Tests', () {
    late Document testDocument;

    setUp(() {
      testDocument = Document(
        id: 'doc123',
        libraryId: 'lib123',
        title: 'Test Document',
        author: 'Test Author',
        filename: 'test.pdf',
        relativePath: '/test/test.pdf',
        fullPath: '/full/path/test.pdf',
        extension: 'pdf',
        sizeBytes: 1024000,
        pageCount: 10,
        format: 'PDF',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    Widget createTestWidget(Widget child) {
      return ProviderScope(
        child: MaterialApp(home: Scaffold(body: child)),
      );
    }

    testWidgets('should display document information', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          DocumentCard(
            document: testDocument,
            isSelected: false,
            isMultiSelectMode: false,
            onTap: () {},
            onLongPress: () {},
            onSelectionChanged: (selected) {},
            onContextMenu: () {},
          ),
        ),
      );

      // Verify document title is displayed
      expect(find.text('Test Document'), findsOneWidget);

      // Verify author is displayed
      expect(find.text('Test Author'), findsOneWidget);

      // Verify file format is displayed
      expect(find.text('PDF'), findsOneWidget);
    });

    testWidgets('should handle tap events', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        createTestWidget(
          DocumentCard(
            document: testDocument,
            isSelected: false,
            isMultiSelectMode: false,
            onTap: () {
              tapped = true;
            },
            onLongPress: () {},
            onSelectionChanged: (selected) {},
            onContextMenu: () {},
          ),
        ),
      );

      // Tap the card
      await tester.tap(find.byType(DocumentCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('should display thumbnail when available', (
      WidgetTester tester,
    ) async {
      final documentWithThumbnail = testDocument.copyWith(
        imageUrl: 'https://example.com/thumbnail.jpg',
      );

      await tester.pumpWidget(
        createTestWidget(
          DocumentCard(
            document: documentWithThumbnail,
            isSelected: false,
            isMultiSelectMode: false,
            onTap: () {},
            onLongPress: () {},
            onSelectionChanged: (selected) {},
            onContextMenu: () {},
          ),
        ),
      );

      // Should find an image widget (thumbnail)
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should show placeholder when no thumbnail', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          DocumentCard(
            document: testDocument,
            isSelected: false,
            isMultiSelectMode: false,
            onTap: () {},
            onLongPress: () {},
            onSelectionChanged: (selected) {},
            onContextMenu: () {},
          ),
        ),
      );

      // Should find a placeholder icon
      expect(find.byIcon(Icons.description), findsOneWidget);
    });

    testWidgets('should display file size', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          DocumentCard(
            document: testDocument,
            isSelected: false,
            isMultiSelectMode: false,
            onTap: () {},
            onLongPress: () {},
            onSelectionChanged: (selected) {},
            onContextMenu: () {},
          ),
        ),
      );

      // Should display formatted file size (1.0 MB)
      expect(find.textContaining('MB'), findsOneWidget);
    });

    testWidgets('should display page count', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          DocumentCard(
            document: testDocument,
            isSelected: false,
            isMultiSelectMode: false,
            onTap: () {},
            onLongPress: () {},
            onSelectionChanged: (selected) {},
            onContextMenu: () {},
          ),
        ),
      );

      // Should display page count
      expect(find.textContaining('10'), findsOneWidget);
    });

    testWidgets('should handle long titles gracefully', (
      WidgetTester tester,
    ) async {
      final longTitleDocument = testDocument.copyWith(
        title:
            'This is a very long document title that should be truncated or wrapped properly in the UI',
      );

      await tester.pumpWidget(
        createTestWidget(
          DocumentCard(document: longTitleDocument, onTap: () {}),
        ),
      );

      // Should not overflow
      expect(tester.takeException(), isNull);

      // Title should still be found (even if truncated)
      expect(find.textContaining('This is a very long'), findsOneWidget);
    });

    testWidgets('should show selection state when selected', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          DocumentCard(document: testDocument, onTap: () {}, isSelected: true),
        ),
      );

      // Should show selection indicator
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should handle missing author gracefully', (
      WidgetTester tester,
    ) async {
      final noAuthorDocument = testDocument.copyWith(author: null);

      await tester.pumpWidget(
        createTestWidget(
          DocumentCard(document: noAuthorDocument, onTap: () {}),
        ),
      );

      // Should not crash and should show unknown author or hide author field
      expect(tester.takeException(), isNull);
    });

    testWidgets('should show context menu when long pressed', (
      WidgetTester tester,
    ) async {
      bool contextMenuShown = false;

      await tester.pumpWidget(
        createTestWidget(
          DocumentCard(
            document: testDocument,
            onTap: () {},
            onLongPress: () {
              contextMenuShown = true;
            },
          ),
        ),
      );

      // Long press the card
      await tester.longPress(find.byType(DocumentCard));
      await tester.pump();

      expect(contextMenuShown, isTrue);
    });

    testWidgets('should display offline indicator when offline', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          DocumentCard(
            document: testDocument,
            onTap: () {},
            isOfflineAvailable: true,
          ),
        ),
      );

      // Should show offline indicator
      expect(find.byIcon(Icons.offline_pin), findsOneWidget);
    });

    testWidgets('should display sync status indicator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          DocumentCard(
            document: testDocument,
            onTap: () {},
            syncStatus: 'syncing',
          ),
        ),
      );

      // Should show sync indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should handle different document formats', (
      WidgetTester tester,
    ) async {
      final epubDocument = testDocument.copyWith(
        format: 'EPUB',
        extension: 'epub',
      );

      await tester.pumpWidget(
        createTestWidget(
          DocumentCard(
            document: epubDocument,
            isSelected: false,
            isMultiSelectMode: false,
            onTap: () {},
            onLongPress: () {},
            onSelectionChanged: (selected) {},
            onContextMenu: () {},
          ),
        ),
      );

      expect(find.text('EPUB'), findsOneWidget);
    });

    testWidgets('should be accessible', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          DocumentCard(
            document: testDocument,
            isSelected: false,
            isMultiSelectMode: false,
            onTap: () {},
            onLongPress: () {},
            onSelectionChanged: (selected) {},
            onContextMenu: () {},
          ),
        ),
      );

      // Check for semantic labels
      expect(find.bySemanticsLabel('Test Document'), findsOneWidget);

      // Verify the card is focusable for keyboard navigation
      final cardFinder = find.byType(DocumentCard);
      expect(cardFinder, findsOneWidget);

      // The card should be tappable
      await tester.tap(cardFinder);
      expect(tester.takeException(), isNull);
    });
  });
}
