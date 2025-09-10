import 'package:test/test.dart';
import 'package:digi_lib_app/src/models/entities/user.dart';
import 'package:digi_lib_app/src/models/entities/library.dart';
import 'package:digi_lib_app/src/models/entities/document.dart';
import 'package:digi_lib_app/src/models/api/auth_result.dart';
import 'package:digi_lib_app/src/models/api/sync_models.dart';
import 'package:digi_lib_app/src/models/api/create_library_request.dart';

void main() {
  group('Data Models Unit Tests', () {
    group('User Model', () {
      test('should create User instance correctly', () {
        final user = User(
          id: 'test-id',
          email: 'test@example.com',
          name: 'Test User',
          provider: 'google',
          providerId: 'google-123',
          createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
        );

        expect(user.id, equals('test-id'));
        expect(user.email, equals('test@example.com'));
        expect(user.name, equals('Test User'));
        expect(user.provider, equals('google'));
        expect(user.providerId, equals('google-123'));
        expect(user.createdAt, equals(DateTime.parse('2024-01-01T00:00:00Z')));
      });

      test('should serialize User to JSON correctly', () {
        final user = User(
          id: 'test-id',
          email: 'test@example.com',
          name: 'Test User',
          provider: 'google',
          providerId: 'google-123',
          createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
        );

        final json = user.toJson();
        expect(json['id'], equals('test-id'));
        expect(json['email'], equals('test@example.com'));
        expect(json['name'], equals('Test User'));
        expect(json['provider'], equals('google'));
        expect(json['provider_id'], equals('google-123'));
        expect(json['created_at'], equals('2024-01-01T00:00:00.000Z'));
      });

      test('should deserialize User from JSON correctly', () {
        final json = {
          'id': 'test-id',
          'email': 'test@example.com',
          'name': 'Test User',
          'provider': 'google',
          'provider_id': 'google-123',
          'created_at': '2024-01-01T00:00:00.000Z',
        };

        final user = User.fromJson(json);
        expect(user.id, equals('test-id'));
        expect(user.email, equals('test@example.com'));
        expect(user.name, equals('Test User'));
        expect(user.provider, equals('google'));
        expect(user.providerId, equals('google-123'));
        expect(user.createdAt, equals(DateTime.parse('2024-01-01T00:00:00Z')));
      });

      test('should support copyWith method', () {
        final user = User(
          id: 'test-id',
          email: 'test@example.com',
          name: 'Test User',
          provider: 'google',
          providerId: 'google-123',
          createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
        );

        final updatedUser = user.copyWith(name: 'Updated Name');
        expect(updatedUser.name, equals('Updated Name'));
        expect(updatedUser.id, equals(user.id));
        expect(updatedUser.email, equals(user.email));
      });

      test('should support equality comparison', () {
        final user1 = User(
          id: 'test-id',
          email: 'test@example.com',
          name: 'Test User',
          provider: 'google',
          providerId: 'google-123',
          createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
        );

        final user2 = User(
          id: 'test-id',
          email: 'test@example.com',
          name: 'Test User',
          provider: 'google',
          providerId: 'google-123',
          createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
        );

        expect(user1, equals(user2));
        expect(user1.hashCode, equals(user2.hashCode));
      });
    });

    group('Library Model', () {
      test('should create Library instance correctly', () {
        final library = Library(
          id: 'lib-id',
          ownerId: 'owner-id',
          name: 'Test Library',
          type: LibraryType.local,
          config: {'path': '/test/path'},
          createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
        );

        expect(library.id, equals('lib-id'));
        expect(library.ownerId, equals('owner-id'));
        expect(library.name, equals('Test Library'));
        expect(library.type, equals(LibraryType.local));
        expect(library.config, equals({'path': '/test/path'}));
        expect(library.createdAt, equals(DateTime.parse('2024-01-01T00:00:00Z')));
      });

      test('should serialize Library to JSON correctly', () {
        final library = Library(
          id: 'lib-id',
          ownerId: 'owner-id',
          name: 'Test Library',
          type: LibraryType.gdrive,
          config: {'clientId': 'test-client-id'},
          createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
        );

        final json = library.toJson();
        expect(json['id'], equals('lib-id'));
        expect(json['owner_id'], equals('owner-id'));
        expect(json['name'], equals('Test Library'));
        expect(json['type'], equals('gdrive'));
        expect(json['config'], equals({'clientId': 'test-client-id'}));
        expect(json['created_at'], equals('2024-01-01T00:00:00.000Z'));
      });

      test('should deserialize Library from JSON correctly', () {
        final json = {
          'id': 'lib-id',
          'owner_id': 'owner-id',
          'name': 'Test Library',
          'type': 'local',
          'config': {'path': '/test/path'},
          'created_at': '2024-01-01T00:00:00.000Z',
        };

        final library = Library.fromJson(json);
        expect(library.id, equals('lib-id'));
        expect(library.ownerId, equals('owner-id'));
        expect(library.name, equals('Test Library'));
        expect(library.type, equals(LibraryType.local));
        expect(library.config, equals({'path': '/test/path'}));
        expect(library.createdAt, equals(DateTime.parse('2024-01-01T00:00:00Z')));
      });
    });

    group('Document Model', () {
      test('should create Document instance correctly', () {
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

        expect(document.id, equals('doc-id'));
        expect(document.libraryId, equals('lib-id'));
        expect(document.title, equals('Test Document'));
        expect(document.author, equals('Test Author'));
        expect(document.filename, equals('test.pdf'));
        expect(document.isbn, equals('978-0123456789'));
        expect(document.yearPublished, equals(2024));
        expect(document.sizeBytes, equals(1024000));
        expect(document.pageCount, equals(100));
        expect(document.metadataJson, equals({'custom': 'data'}));
      });

      test('should serialize Document to JSON correctly', () {
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
        expect(json['id'], equals('doc-id'));
        expect(json['library_id'], equals('lib-id'));
        expect(json['title'], equals('Test Document'));
        expect(json['author'], equals('Test Author'));
        expect(json['filename'], equals('test.pdf'));
        expect(json['isbn'], equals('978-0123456789'));
        expect(json['year_published'], equals(2024));
        expect(json['size_bytes'], equals(1024000));
        expect(json['page_count'], equals(100));
        expect(json['metadata_json'], equals({'custom': 'data'}));
      });
    });

    group('AuthResult Model', () {
      test('should create AuthResult instance correctly', () {
        final authResult = AuthResult(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
          expiresIn: 3600,
          tokenType: 'Bearer',
        );

        expect(authResult.accessToken, equals('access-token'));
        expect(authResult.refreshToken, equals('refresh-token'));
        expect(authResult.expiresIn, equals(3600));
        expect(authResult.tokenType, equals('Bearer'));
      });

      test('should serialize AuthResult to JSON correctly', () {
        final authResult = AuthResult(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
          expiresIn: 3600,
          tokenType: 'Bearer',
        );

        final json = authResult.toJson();
        expect(json['access_token'], equals('access-token'));
        expect(json['refresh_token'], equals('refresh-token'));
        expect(json['expires_in'], equals(3600));
        expect(json['token_type'], equals('Bearer'));
      });

      test('should deserialize AuthResult from JSON correctly', () {
        final json = {
          'access_token': 'access-token',
          'refresh_token': 'refresh-token',
          'expires_in': 3600,
          'token_type': 'Bearer',
        };

        final authResult = AuthResult.fromJson(json);
        expect(authResult.accessToken, equals('access-token'));
        expect(authResult.refreshToken, equals('refresh-token'));
        expect(authResult.expiresIn, equals(3600));
        expect(authResult.tokenType, equals('Bearer'));
      });
    });

    group('SyncChange Model', () {
      test('should create SyncChange instance correctly', () {
        final syncChange = SyncChange(
          entityType: 'document',
          entityId: 'doc-id',
          operation: 'update',
          data: {'title': 'Updated Title'},
          timestamp: DateTime.parse('2024-01-01T00:00:00Z'),
        );

        expect(syncChange.entityType, equals('document'));
        expect(syncChange.entityId, equals('doc-id'));
        expect(syncChange.operation, equals('update'));
        expect(syncChange.data, equals({'title': 'Updated Title'}));
        expect(syncChange.timestamp, equals(DateTime.parse('2024-01-01T00:00:00Z')));
      });

      test('should serialize SyncChange to JSON correctly', () {
        final syncChange = SyncChange(
          entityType: 'document',
          entityId: 'doc-id',
          operation: 'update',
          data: {'title': 'Updated Title'},
          timestamp: DateTime.parse('2024-01-01T00:00:00Z'),
        );

        final json = syncChange.toJson();
        expect(json['entity_type'], equals('document'));
        expect(json['entity_id'], equals('doc-id'));
        expect(json['operation'], equals('update'));
        expect(json['data'], equals({'title': 'Updated Title'}));
        expect(json['timestamp'], equals('2024-01-01T00:00:00.000Z'));
      });
    });

    group('CreateLibraryRequest Model', () {
      test('should create CreateLibraryRequest instance correctly', () {
        final request = CreateLibraryRequest(
          name: 'Test Library',
          type: LibraryType.gdrive,
          config: {'clientId': 'test-client-id'},
        );

        expect(request.name, equals('Test Library'));
        expect(request.type, equals(LibraryType.gdrive));
        expect(request.config, equals({'clientId': 'test-client-id'}));
      });

      test('should serialize CreateLibraryRequest to JSON correctly', () {
        final request = CreateLibraryRequest(
          name: 'Test Library',
          type: LibraryType.local,
          config: {'path': '/test/path'},
        );

        final json = request.toJson();
        expect(json['name'], equals('Test Library'));
        expect(json['type'], equals('local'));
        expect(json['config'], equals({'path': '/test/path'}));
      });

      test('should deserialize CreateLibraryRequest from JSON correctly', () {
        final json = {
          'name': 'Test Library',
          'type': 'gdrive',
          'config': {'clientId': 'test-client-id'},
        };

        final request = CreateLibraryRequest.fromJson(json);
        expect(request.name, equals('Test Library'));
        expect(request.type, equals(LibraryType.gdrive));
        expect(request.config, equals({'clientId': 'test-client-id'}));
      });
    });
  });
}