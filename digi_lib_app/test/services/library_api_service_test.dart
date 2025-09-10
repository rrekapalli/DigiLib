import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:digi_lib_app/src/services/library_api_service.dart';
import 'package:digi_lib_app/src/network/api_client.dart';
import 'package:digi_lib_app/src/models/entities/library.dart';
import 'package:digi_lib_app/src/models/api/create_library_request.dart';
import 'package:digi_lib_app/src/models/api/scan_job.dart';
import 'package:digi_lib_app/src/models/api/api_error.dart';

import 'library_api_service_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  group('LibraryApiServiceImpl', () {
    late LibraryApiServiceImpl libraryService;
    late MockApiClient mockApiClient;

    setUp(() {
      mockApiClient = MockApiClient();
      libraryService = LibraryApiServiceImpl(mockApiClient);
    });

    tearDown(() {
      libraryService.dispose();
    });

    group('getLibraries', () {
      test('should get libraries successfully', () async {
        // Arrange
        final librariesJson = [
          {
            'id': 'library-1',
            'owner_id': 'user-1',
            'name': 'My Documents',
            'type': 'local',
            'config': {'path': '/documents'},
            'created_at': DateTime.now().toIso8601String(),
          },
          {
            'id': 'library-2',
            'owner_id': 'user-1',
            'name': 'Google Drive',
            'type': 'gdrive',
            'config': {'folder_id': 'gdrive-folder-id'},
            'created_at': DateTime.now().toIso8601String(),
          },
        ];

        when(mockApiClient.get<List<dynamic>>('/api/libraries'))
            .thenAnswer((_) async => librariesJson);

        // Act
        final libraries = await libraryService.getLibraries();

        // Assert
        expect(libraries, hasLength(2));
        expect(libraries[0].name, 'My Documents');
        expect(libraries[0].type, LibraryType.local);
        expect(libraries[1].name, 'Google Drive');
        expect(libraries[1].type, LibraryType.gdrive);
      });

      test('should handle get libraries error', () async {
        // Arrange
        when(mockApiClient.get<List<dynamic>>('/api/libraries'))
            .thenThrow(ApiException(
              ApiError(
                message: 'Server error',
                code: 'SERVER_ERROR',
                status: 500,
                timestamp: DateTime.now(),
              ),
            ));

        // Act & Assert
        expect(
          () => libraryService.getLibraries(),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('addLibrary', () {
      test('should add library successfully', () async {
        // Arrange
        const request = CreateLibraryRequest(
          name: 'New Library',
          type: LibraryType.local,
          config: {'path': '/new-library'},
        );

        final libraryJson = {
          'id': 'new-library-id',
          'owner_id': 'user-1',
          'name': 'New Library',
          'type': 'local',
          'config': {'path': '/new-library'},
          'created_at': DateTime.now().toIso8601String(),
        };

        when(mockApiClient.post<Map<String, dynamic>>(
          '/api/libraries',
          body: request.toJson(),
        )).thenAnswer((_) async => libraryJson);

        // Act
        final library = await libraryService.addLibrary(request);

        // Assert
        expect(library.name, 'New Library');
        expect(library.type, LibraryType.local);
        expect(library.config, {'path': '/new-library'});
      });

      test('should handle add library error', () async {
        // Arrange
        const request = CreateLibraryRequest(
          name: 'Invalid Library',
          type: LibraryType.local,
        );

        when(mockApiClient.post<Map<String, dynamic>>(
          '/api/libraries',
          body: anyNamed('body'),
        )).thenThrow(ApiException(
          ApiError(
            message: 'Invalid library configuration',
            code: 'INVALID_CONFIG',
            status: 400,
            timestamp: DateTime.now(),
          ),
        ));

        // Act & Assert
        expect(
          () => libraryService.addLibrary(request),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('getLibrary', () {
      test('should get library successfully', () async {
        // Arrange
        const libraryId = 'library-1';
        final libraryJson = {
          'id': libraryId,
          'owner_id': 'user-1',
          'name': 'My Library',
          'type': 'local',
          'config': {'path': '/my-library'},
          'created_at': DateTime.now().toIso8601String(),
        };

        when(mockApiClient.get<Map<String, dynamic>>('/api/libraries/$libraryId'))
            .thenAnswer((_) async => libraryJson);

        // Act
        final library = await libraryService.getLibrary(libraryId);

        // Assert
        expect(library.id, libraryId);
        expect(library.name, 'My Library');
        expect(library.type, LibraryType.local);
      });

      test('should handle library not found', () async {
        // Arrange
        const libraryId = 'non-existent-library';

        when(mockApiClient.get<Map<String, dynamic>>('/api/libraries/$libraryId'))
            .thenThrow(ApiException(
              ApiError(
                message: 'Library not found',
                code: 'LIBRARY_NOT_FOUND',
                status: 404,
                timestamp: DateTime.now(),
              ),
            ));

        // Act & Assert
        expect(
          () => libraryService.getLibrary(libraryId),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('scanLibrary', () {
      test('should start library scan successfully', () async {
        // Arrange
        const libraryId = 'library-1';
        final scanJobJson = {
          'id': 'scan-job-1',
          'library_id': libraryId,
          'status': 'running',
          'progress': 0,
          'created_at': DateTime.now().toIso8601String(),
        };

        when(mockApiClient.post<Map<String, dynamic>>('/api/libraries/$libraryId/scan'))
            .thenAnswer((_) async => scanJobJson);

        // Act
        final scanJob = await libraryService.scanLibrary(libraryId);

        // Assert
        expect(scanJob.libraryId, libraryId);
        expect(scanJob.status, 'running');
        expect(scanJob.progress, 0);
      });

      test('should handle scan library error', () async {
        // Arrange
        const libraryId = 'library-1';

        when(mockApiClient.post<Map<String, dynamic>>('/api/libraries/$libraryId/scan'))
            .thenThrow(ApiException(
              ApiError(
                message: 'Library scan failed',
                code: 'SCAN_FAILED',
                status: 500,
                timestamp: DateTime.now(),
              ),
            ));

        // Act & Assert
        expect(
          () => libraryService.scanLibrary(libraryId),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('deleteLibrary', () {
      test('should delete library successfully', () async {
        // Arrange
        const libraryId = 'library-1';

        when(mockApiClient.delete('/api/libraries/$libraryId'))
            .thenAnswer((_) async => null);

        // Act
        await libraryService.deleteLibrary(libraryId);

        // Assert
        verify(mockApiClient.delete('/api/libraries/$libraryId')).called(1);
      });

      test('should handle delete library error', () async {
        // Arrange
        const libraryId = 'library-1';

        when(mockApiClient.delete('/api/libraries/$libraryId'))
            .thenThrow(ApiException(
              ApiError(
                message: 'Cannot delete library with documents',
                code: 'LIBRARY_NOT_EMPTY',
                status: 409,
                timestamp: DateTime.now(),
              ),
            ));

        // Act & Assert
        expect(
          () => libraryService.deleteLibrary(libraryId),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('getScanJob', () {
      test('should get scan job successfully', () async {
        // Arrange
        const jobId = 'scan-job-1';
        final scanJobJson = {
          'id': jobId,
          'library_id': 'library-1',
          'status': 'completed',
          'progress': 100,
          'created_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
          'completed_at': DateTime.now().toIso8601String(),
        };

        when(mockApiClient.get<Map<String, dynamic>>('/api/scan-jobs/$jobId'))
            .thenAnswer((_) async => scanJobJson);

        // Act
        final scanJob = await libraryService.getScanJob(jobId);

        // Assert
        expect(scanJob.id, jobId);
        expect(scanJob.status, 'completed');
        expect(scanJob.progress, 100);
        expect(scanJob.completedAt, isNotNull);
      });

      test('should handle scan job not found', () async {
        // Arrange
        const jobId = 'non-existent-job';

        when(mockApiClient.get<Map<String, dynamic>>('/api/scan-jobs/$jobId'))
            .thenThrow(ApiException(
              ApiError(
                message: 'Scan job not found',
                code: 'SCAN_JOB_NOT_FOUND',
                status: 404,
                timestamp: DateTime.now(),
              ),
            ));

        // Act & Assert
        expect(
          () => libraryService.getScanJob(jobId),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('cancelScanJob', () {
      test('should cancel scan job successfully', () async {
        // Arrange
        const jobId = 'scan-job-1';

        when(mockApiClient.post('/api/scan-jobs/$jobId/cancel'))
            .thenAnswer((_) async => null);

        // Act
        await libraryService.cancelScanJob(jobId);

        // Assert
        verify(mockApiClient.post('/api/scan-jobs/$jobId/cancel')).called(1);
      });

      test('should handle cancel scan job error', () async {
        // Arrange
        const jobId = 'scan-job-1';

        when(mockApiClient.post('/api/scan-jobs/$jobId/cancel'))
            .thenThrow(ApiException(
              ApiError(
                message: 'Cannot cancel completed job',
                code: 'JOB_ALREADY_COMPLETED',
                status: 409,
                timestamp: DateTime.now(),
              ),
            ));

        // Act & Assert
        expect(
          () => libraryService.cancelScanJob(jobId),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('watchScanProgress', () {
      test('should provide scan progress stream', () async {
        // Arrange
        const libraryId = 'library-1';

        // Act
        final stream = libraryService.watchScanProgress(libraryId);

        // Assert
        expect(stream, isA<Stream<ScanProgress>>());
      });
    });
  });

  group('MockLibraryApiService', () {
    late MockLibraryApiService mockLibraryService;

    setUp(() {
      mockLibraryService = MockLibraryApiService();
    });

    tearDown(() {
      mockLibraryService.dispose();
    });

    test('should start with empty libraries', () async {
      final libraries = await mockLibraryService.getLibraries();
      expect(libraries, isEmpty);
    });

    test('should add and retrieve libraries', () async {
      // Arrange
      const request = CreateLibraryRequest(
        name: 'Test Library',
        type: LibraryType.local,
        config: {'path': '/test'},
      );

      // Act
      final addedLibrary = await mockLibraryService.addLibrary(request);
      final libraries = await mockLibraryService.getLibraries();
      final retrievedLibrary = await mockLibraryService.getLibrary(addedLibrary.id);

      // Assert
      expect(libraries, hasLength(1));
      expect(libraries.first.name, 'Test Library');
      expect(retrievedLibrary.id, addedLibrary.id);
      expect(retrievedLibrary.name, 'Test Library');
    });

    test('should throw error for non-existent library', () async {
      expect(
        () => mockLibraryService.getLibrary('non-existent'),
        throwsA(isA<ApiException>()),
      );
    });

    test('should delete library', () async {
      // Arrange
      const request = CreateLibraryRequest(
        name: 'Test Library',
        type: LibraryType.local,
      );
      final library = await mockLibraryService.addLibrary(request);

      // Act
      await mockLibraryService.deleteLibrary(library.id);
      final libraries = await mockLibraryService.getLibraries();

      // Assert
      expect(libraries, isEmpty);
    });

    test('should start and track scan job', () async {
      // Arrange
      const request = CreateLibraryRequest(
        name: 'Test Library',
        type: LibraryType.local,
      );
      final library = await mockLibraryService.addLibrary(request);

      // Act
      final scanJob = await mockLibraryService.scanLibrary(library.id);
      final retrievedJob = await mockLibraryService.getScanJob(scanJob.id);

      // Assert
      expect(scanJob.libraryId, library.id);
      expect(scanJob.status, 'running');
      expect(retrievedJob.id, scanJob.id);
    });

    test('should provide scan progress stream', () async {
      // Arrange
      const request = CreateLibraryRequest(
        name: 'Test Library',
        type: LibraryType.local,
      );
      final library = await mockLibraryService.addLibrary(request);

      // Act
      final stream = mockLibraryService.watchScanProgress(library.id);
      await mockLibraryService.scanLibrary(library.id);

      // Assert
      expect(stream, isA<Stream<ScanProgress>>());
      
      // Listen to a few progress updates
      final progressUpdates = <ScanProgress>[];
      final subscription = stream.listen(progressUpdates.add);
      
      // Wait for some progress updates
      await Future.delayed(const Duration(milliseconds: 1200));
      await subscription.cancel();
      
      expect(progressUpdates, isNotEmpty);
      expect(progressUpdates.first.libraryId, library.id);
    });

    test('should cancel scan job', () async {
      // Arrange
      const request = CreateLibraryRequest(
        name: 'Test Library',
        type: LibraryType.local,
      );
      final library = await mockLibraryService.addLibrary(request);
      final scanJob = await mockLibraryService.scanLibrary(library.id);

      // Act
      await mockLibraryService.cancelScanJob(scanJob.id);
      final updatedJob = await mockLibraryService.getScanJob(scanJob.id);

      // Assert
      expect(updatedJob.status, 'cancelled');
      expect(updatedJob.completedAt, isNotNull);
    });
  });

  group('ScanProgress', () {
    test('should create from scan job', () {
      // Arrange
      final scanJob = ScanJob(
        id: 'job-1',
        libraryId: 'library-1',
        status: 'running',
        progress: 50,
        createdAt: DateTime.now(),
      );

      // Act
      final progress = ScanProgress.fromScanJob(scanJob);

      // Assert
      expect(progress.jobId, 'job-1');
      expect(progress.libraryId, 'library-1');
      expect(progress.status, 'running');
      expect(progress.progress, 50);
      expect(progress.error, isNull);
    });

    test('should create from scan job with error', () {
      // Arrange
      final scanJob = ScanJob(
        id: 'job-1',
        libraryId: 'library-1',
        status: 'failed',
        progress: 25,
        createdAt: DateTime.now(),
      );

      // Act
      final progress = ScanProgress.fromScanJob(scanJob, error: 'Scan failed');

      // Assert
      expect(progress.jobId, 'job-1');
      expect(progress.status, 'failed');
      expect(progress.progress, 25);
      expect(progress.error, 'Scan failed');
    });
  });
}