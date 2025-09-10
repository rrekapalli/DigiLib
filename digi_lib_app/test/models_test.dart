import 'package:flutter_test/flutter_test.dart';
import 'package:digi_lib_app/src/models/models.dart';

void main() {
  group('Data Models Tests', () {
    test('User model serialization', () {
      final user = User(
        id: 'test-id',
        email: 'test@example.com',
        name: 'Test User',
        provider: 'google',
        providerId: 'google-123',
        createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
      );

      final json = user.toJson();
      final userFromJson = User.fromJson(json);

      expect(userFromJson.id, equals(user.id));
      expect(userFromJson.email, equals(user.email));
      expect(userFromJson.name, equals(user.name));
      expect(userFromJson.provider, equals(user.provider));
      expect(userFromJson.providerId, equals(user.providerId));
      expect(userFromJson.createdAt, equals(user.createdAt));
    });

    test('Library model serialization', () {
      final library = Library(
        id: 'lib-id',
        ownerId: 'owner-id',
        name: 'Test Library',
        type: LibraryType.local,
        config: {'path': '/test/path'},
        createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
      );

      final json = library.toJson();
      final libraryFromJson = Library.fromJson(json);

      expect(libraryFromJson.id, equals(library.id));
      expect(libraryFromJson.ownerId, equals(library.ownerId));
      expect(libraryFromJson.name, equals(library.name));
      expect(libraryFromJson.type, equals(library.type));
      expect(libraryFromJson.config, equals(library.config));
      expect(libraryFromJson.createdAt, equals(library.createdAt));
    });

    test('Document model serialization', () {
      final document = Document(
        id: 'doc-id',
        libraryId: 'lib-id',
        title: 'Test Document',
        author: 'Test Author',
        filename: 'test.pdf',
        relativePath: 'folder/test.pdf',
        fullPath: '/full/path/folder/test.pdf',
        extension: 'pdf',
        renamedName: null,
        isbn: '978-0123456789',
        yearPublished: 2024,
        status: 'active',
        cloudId: null,
        sha256: 'abc123',
        sizeBytes: 1024000,
        pageCount: 100,
        format: 'pdf',
        imageUrl: null,
        amazonUrl: null,
        reviewUrl: null,
        metadataJson: {'custom': 'data'},
        createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2024-01-01T00:00:00Z'),
      );

      final json = document.toJson();
      final documentFromJson = Document.fromJson(json);

      expect(documentFromJson.id, equals(document.id));
      expect(documentFromJson.libraryId, equals(document.libraryId));
      expect(documentFromJson.title, equals(document.title));
      expect(documentFromJson.author, equals(document.author));
      expect(documentFromJson.filename, equals(document.filename));
      expect(documentFromJson.isbn, equals(document.isbn));
      expect(documentFromJson.yearPublished, equals(document.yearPublished));
      expect(documentFromJson.sizeBytes, equals(document.sizeBytes));
      expect(documentFromJson.pageCount, equals(document.pageCount));
      expect(documentFromJson.metadataJson, equals(document.metadataJson));
    });

    test('AuthResult model serialization', () {
      final authResult = AuthResult(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        expiresIn: 3600,
        tokenType: 'Bearer',
      );

      final json = authResult.toJson();
      final authResultFromJson = AuthResult.fromJson(json);

      expect(authResultFromJson.accessToken, equals(authResult.accessToken));
      expect(authResultFromJson.refreshToken, equals(authResult.refreshToken));
      expect(authResultFromJson.expiresIn, equals(authResult.expiresIn));
      expect(authResultFromJson.tokenType, equals(authResult.tokenType));
    });

    test('SyncChange model serialization', () {
      final syncChange = SyncChange(
        entityType: 'document',
        entityId: 'doc-id',
        operation: 'update',
        data: {'title': 'Updated Title'},
        timestamp: DateTime.parse('2024-01-01T00:00:00Z'),
      );

      final json = syncChange.toJson();
      final syncChangeFromJson = SyncChange.fromJson(json);

      expect(syncChangeFromJson.entityType, equals(syncChange.entityType));
      expect(syncChangeFromJson.entityId, equals(syncChange.entityId));
      expect(syncChangeFromJson.operation, equals(syncChange.operation));
      expect(syncChangeFromJson.data, equals(syncChange.data));
      expect(syncChangeFromJson.timestamp, equals(syncChange.timestamp));
    });

    test('CreateLibraryRequest model serialization', () {
      final request = CreateLibraryRequest(
        name: 'Test Library',
        type: LibraryType.gdrive,
        config: {'clientId': 'test-client-id'},
      );

      final json = request.toJson();
      final requestFromJson = CreateLibraryRequest.fromJson(json);

      expect(requestFromJson.name, equals(request.name));
      expect(requestFromJson.type, equals(request.type));
      expect(requestFromJson.config, equals(request.config));
    });
  });
}