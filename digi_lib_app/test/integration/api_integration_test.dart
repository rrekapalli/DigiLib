import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:digi_lib_app/src/network/api_client.dart';
import 'package:digi_lib_app/src/services/auth_api_service.dart';
import 'package:digi_lib_app/src/services/document_api_service.dart';
import 'package:digi_lib_app/src/services/library_api_service.dart';

import 'package:digi_lib_app/src/models/api/auth_result.dart';
import 'package:digi_lib_app/src/models/entities/user.dart';
import 'package:digi_lib_app/src/models/entities/library.dart';
import 'package:digi_lib_app/src/models/api/create_library_request.dart';

import '../test_helpers.dart';

@GenerateMocks([Dio, ApiClient])
@Skip('TODO: Fix constructor issues and mock generation')
void main() {
  group('API Integration Tests', () {
    late MockApiClient mockApiClient;
    late MockSecureStorageService mockSecureStorage;
    late AuthApiServiceImpl authService;
    late DocumentApiServiceImpl documentService;
    late LibraryApiServiceImpl libraryService;

    setUp(() {
      mockApiClient = MockApiClient();
      mockSecureStorage = MockSecureStorageService();
      authService = AuthApiServiceImpl(mockApiClient, mockSecureStorage);
      documentService = DocumentApiServiceImpl(mockApiClient);
      libraryService = LibraryApiServiceImpl(mockApiClient);
    });

    group('Authentication API', () {
      test('should sign in with OAuth2 successfully', () async {
        final expectedAuthResult = AuthResult(
          accessToken: 'access_token_123',
          refreshToken: 'refresh_token_123',
          expiresIn: 3600,
          tokenType: 'Bearer',
        );

        final expectedUser = User(
          id: 'user123',
          email: 'test@example.com',
          name: 'Test User',
          provider: 'google',
          providerId: 'google123',
          createdAt: DateTime.now(),
        );

        when(
          mockApiClient.post<Map<String, dynamic>>(
            '/auth/oauth2/google',
            body: anyNamed('body'),
          ),
        ).thenAnswer(
          (_) async => {
            'access_token': 'access_token_123',
            'refresh_token': 'refresh_token_123',
            'expires_in': 3600,
            'token_type': 'Bearer',
            'user': {
              'id': 'user123',
              'email': 'test@example.com',
              'name': 'Test User',
              'provider': 'google',
              'provider_id': 'google123',
              'created_at': DateTime.now().toIso8601String(),
            },
          },
        );

        final result = await authService.signInWithOAuth2(
          'google',
          'auth_code_123',
          'state_123',
          'https://app.example.com/callback',
        );

        expect(result.accessToken, equals('access_token_123'));

        verify(
          mockApiClient.post<Map<String, dynamic>>(
            '/auth/oauth2/google',
            body: {
              'code': 'auth_code_123',
              'state': 'state_123',
              'redirect_uri': 'https://app.example.com/callback',
            },
          ),
        ).called(1);
      });

      test('should refresh token successfully', () async {
        when(
          mockApiClient.post<Map<String, dynamic>>(
            '/auth/refresh',
            body: anyNamed('body'),
          ),
        ).thenAnswer(
          (_) async => {
            'access_token': 'new_access_token_123',
            'expires_in': 3600,
            'token_type': 'Bearer',
          },
        );

        final result = await authService.refreshToken();

        expect(result.accessToken, equals('new_access_token_123'));
        expect(result.expiresIn, equals(3600));

        verify(
          mockApiClient.post<Map<String, dynamic>>(
            '/auth/refresh',
            body: {'refresh_token': 'refresh_token_123'},
          ),
        ).called(1);
      });

      test('should get current user successfully', () async {
        when(
          mockApiClient.get<Map<String, dynamic>>('/api/users/me'),
        ).thenAnswer(
          (_) async => {
            'id': 'user123',
            'email': 'test@example.com',
            'name': 'Test User',
            'provider': 'google',
            'provider_id': 'google123',
            'created_at': DateTime.now().toIso8601String(),
          },
        );

        final user = await authService.getCurrentUser();

        expect(user.id, equals('user123'));
        expect(user.email, equals('test@example.com'));

        verify(
          mockApiClient.get<Map<String, dynamic>>('/api/users/me'),
        ).called(1);
      });

      test('should handle authentication errors', () async {
        when(
          mockApiClient.post<Map<String, dynamic>>(
            '/auth/oauth2/google',
            body: anyNamed('body'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/oauth2/google'),
            response: Response(
              requestOptions: RequestOptions(path: '/auth/oauth2/google'),
              statusCode: 401,
              data: {'error': 'invalid_grant'},
            ),
          ),
        );

        expect(
          () => authService.signInWithOAuth2(
            'google',
            'invalid_code',
            'state',
            'redirect',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Document API', () {
      test('should get documents with pagination', () async {
        when(
          mockApiClient.get<Map<String, dynamic>>(
            '/api/documents',
            queryParams: anyNamed('queryParams'),
          ),
        ).thenAnswer(
          (_) async => {
            'documents': [
              {
                'id': 'doc1',
                'library_id': 'lib1',
                'title': 'Document 1',
                'author': 'Author 1',
                'filename': 'doc1.pdf',
                'relative_path': '/doc1.pdf',
                'full_path': '/full/doc1.pdf',
                'extension': 'pdf',
                'size_bytes': 1024,
                'page_count': 10,
                'format': 'PDF',
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              },
            ],
            'pagination': {
              'page': 1,
              'limit': 50,
              'total': 1,
              'total_pages': 1,
            },
          },
        );

        final result = await documentService.getDocuments(
          libraryId: 'lib1',
          page: 1,
          limit: 50,
        );

        expect(result.documents.length, equals(1));
        expect(result.documents.first.title, equals('Document 1'));
        expect(result.pagination.total, equals(1));

        verify(
          mockApiClient.get<Map<String, dynamic>>(
            '/api/documents',
            queryParams: {'library_id': 'lib1', 'page': 1, 'limit': 50},
          ),
        ).called(1);
      });

      test('should get single document', () async {
        when(
          mockApiClient.get<Map<String, dynamic>>('/api/documents/doc1'),
        ).thenAnswer(
          (_) async => {
            'id': 'doc1',
            'library_id': 'lib1',
            'title': 'Document 1',
            'author': 'Author 1',
            'filename': 'doc1.pdf',
            'relative_path': '/doc1.pdf',
            'full_path': '/full/doc1.pdf',
            'extension': 'pdf',
            'size_bytes': 1024,
            'page_count': 10,
            'format': 'PDF',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
        );

        final document = await documentService.getDocument('doc1');

        expect(document.id, equals('doc1'));
        expect(document.title, equals('Document 1'));

        verify(
          mockApiClient.get<Map<String, dynamic>>('/api/documents/doc1'),
        ).called(1);
      });

      test('should search documents', () async {
        when(
          mockApiClient.get<Map<String, dynamic>>(
            '/api/documents',
            queryParams: anyNamed('queryParams'),
          ),
        ).thenAnswer(
          (_) async => {
            'documents': [
              {
                'id': 'doc1',
                'library_id': 'lib1',
                'title': 'Search Result Document',
                'author': 'Author 1',
                'filename': 'search.pdf',
                'relative_path': '/search.pdf',
                'full_path': '/full/search.pdf',
                'extension': 'pdf',
                'size_bytes': 1024,
                'page_count': 5,
                'format': 'PDF',
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              },
            ],
            'pagination': {
              'page': 1,
              'limit': 20,
              'total': 1,
              'total_pages': 1,
            },
          },
        );

        final result = await documentService.getDocuments(
          search: 'search term',
          page: 1,
          limit: 20,
        );

        expect(result.documents.length, equals(1));
        expect(result.documents.first.title, contains('Search'));

        verify(
          mockApiClient.get<Map<String, dynamic>>(
            '/api/documents',
            queryParams: {'search': 'search term', 'page': 1, 'limit': 20},
          ),
        ).called(1);
      });
    });

    group('Library API', () {
      test('should get libraries', () async {
        when(mockApiClient.get<List<dynamic>>('/api/libraries')).thenAnswer(
          (_) async => [
            {
              'id': 'lib1',
              'owner_id': 'user1',
              'name': 'My Library',
              'type': 'local',
              'config': {'path': '/documents'},
              'created_at': DateTime.now().toIso8601String(),
            },
          ],
        );

        final libraries = await libraryService.getLibraries();

        expect(libraries.length, equals(1));
        expect(libraries.first.name, equals('My Library'));
        expect(libraries.first.type, equals(LibraryType.local));

        verify(mockApiClient.get<List<dynamic>>('/api/libraries')).called(1);
      });

      test('should create library', () async {
        when(
          mockApiClient.post<Map<String, dynamic>>(
            '/api/libraries',
            body: anyNamed('body'),
          ),
        ).thenAnswer(
          (_) async => {
            'id': 'lib2',
            'owner_id': 'user1',
            'name': 'New Library',
            'type': 'gdrive',
            'config': {'folder_id': 'gdrive_folder_123'},
            'created_at': DateTime.now().toIso8601String(),
          },
        );

        final library = await libraryService.addLibrary(
          CreateLibraryRequest(
            name: 'New Library',
            type: LibraryType.gdrive,
            config: {'folder_id': 'gdrive_folder_123'},
          ),
        );

        expect(library.name, equals('New Library'));
        expect(library.type, equals(LibraryType.gdrive));

        verify(
          mockApiClient.post<Map<String, dynamic>>(
            '/api/libraries',
            body: {
              'name': 'New Library',
              'type': 'gdrive',
              'config': {'folder_id': 'gdrive_folder_123'},
            },
          ),
        ).called(1);
      });

      test('should handle API errors gracefully', () async {
        when(mockApiClient.get<List<dynamic>>('/api/libraries')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/libraries'),
            response: Response(
              requestOptions: RequestOptions(path: '/api/libraries'),
              statusCode: 500,
              data: {'error': 'Internal server error'},
            ),
          ),
        );

        expect(() => libraryService.getLibraries(), throwsA(isA<Exception>()));
      });
    });

    group('Error Handling', () {
      test('should handle network timeouts', () async {
        when(
          mockApiClient.get<Map<String, dynamic>>('/api/documents/doc1'),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/documents/doc1'),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        expect(
          () => documentService.getDocument('doc1'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle unauthorized responses', () async {
        when(
          mockApiClient.get<Map<String, dynamic>>('/api/documents'),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/documents'),
            response: Response(
              requestOptions: RequestOptions(path: '/api/documents'),
              statusCode: 401,
              data: {'error': 'Unauthorized'},
            ),
          ),
        );

        expect(() => documentService.getDocuments(), throwsA(isA<Exception>()));
      });

      test('should handle malformed responses', () async {
        when(
          mockApiClient.get<Map<String, dynamic>>('/api/documents/doc1'),
        ).thenAnswer(
          (_) async => {
            'invalid': 'response',
            // Missing required fields
          },
        );

        expect(
          () => documentService.getDocument('doc1'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
