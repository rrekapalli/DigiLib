import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/entities/tag.dart';
import '../models/entities/document.dart';
import '../models/api/create_tag_request.dart';
import '../database/repositories/tag_repository.dart';
import '../network/connectivity_service.dart';
import 'tag_api_service.dart';
import 'job_queue_service.dart';

/// Exception thrown when tag operations fail
class TagException implements Exception {
  final String message;
  final String? code;
  final Exception? cause;

  const TagException(this.message, {this.code, this.cause});

  @override
  String toString() => 'TagException: $message';
}

/// Service for managing tags with API integration, local caching, and offline support
class TagService {
  final TagApiService _apiService;
  final TagRepository _repository;
  final JobQueueService _jobQueueService;
  final ConnectivityService _connectivityService;
  final Uuid _uuid = const Uuid();

  // Stream controllers for real-time updates
  final StreamController<List<Tag>> _tagsController = StreamController<List<Tag>>.broadcast();
  final StreamController<TagEvent> _tagEventsController = StreamController<TagEvent>.broadcast();

  TagService({
    required TagApiService apiService,
    required TagRepository repository,
    required JobQueueService jobQueueService,
    required ConnectivityService connectivityService,
  }) : _apiService = apiService,
       _repository = repository,
       _jobQueueService = jobQueueService,
       _connectivityService = connectivityService;

  /// Stream of tag lists (for UI updates)
  Stream<List<Tag>> get tagsStream => _tagsController.stream;

  /// Stream of tag events (create, delete, document association changes)
  Stream<TagEvent> get tagEventsStream => _tagEventsController.stream;

  /// Get all tags for a specific owner
  Future<List<Tag>> getTags({String? ownerId}) async {
    try {
      // Always return local data first for immediate UI response
      final localTags = ownerId != null 
          ? await _repository.getTagsByOwnerId(ownerId)
          : await _repository.getAllTags();
      
      // If online, try to sync with server
      if (_connectivityService.hasConnectivity()) {
        try {
          final serverTags = await _apiService.getTags();
          
          // Update local cache with server data
          await _syncTagsToLocal(serverTags);
          
          // Return updated local data
          final updatedTags = ownerId != null 
              ? await _repository.getTagsByOwnerId(ownerId)
              : await _repository.getAllTags();
          _tagsController.add(updatedTags);
          return updatedTags;
        } catch (e) {
          // If server request fails, continue with local data
          // Log the error but don't throw to maintain offline functionality
        }
      }
      
      _tagsController.add(localTags);
      return localTags;
    } catch (e) {
      throw TagException('Failed to get tags: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Create a new tag
  Future<Tag> createTag(String name, String ownerId) async {
    try {
      // Check if tag already exists locally
      final existingTag = await _repository.getTagByName(name, ownerId);
      if (existingTag != null) {
        throw TagException('Tag with name "$name" already exists', code: 'DUPLICATE_TAG');
      }

      // Create tag with local ID
      final tag = Tag(
        id: _uuid.v4(),
        ownerId: ownerId,
        name: name,
        createdAt: DateTime.now(),
      );

      // Save to local database immediately
      await _repository.insertTag(tag);

      // If online, try to sync with server
      if (_connectivityService.hasConnectivity()) {
        try {
          final request = CreateTagRequest(name: name);
          final serverTag = await _apiService.createTag(request);
          
          // Update local tag with server ID
          await _repository.deleteTag(tag.id); // Remove old local tag
          await _repository.insertTag(serverTag);
          
          _tagEventsController.add(TagEvent.created(serverTag));
          return serverTag;
        } catch (e) {
          // If server request fails, queue for offline processing
          await _jobQueueService.addJob(JobType.createTag, {
            'tag_id': tag.id,
            'name': name,
            'owner_id': ownerId,
          });
        }
      } else {
        // Queue for offline processing
        await _jobQueueService.addJob(JobType.createTag, {
          'tag_id': tag.id,
          'name': name,
          'owner_id': ownerId,
        });
      }

      _tagEventsController.add(TagEvent.created(tag));
      return tag;
    } catch (e) {
      throw TagException('Failed to create tag: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Delete a tag
  Future<void> deleteTag(String tagId) async {
    try {
      // Get tag before deletion for event notification
      final tag = await _repository.getTagById(tagId);
      
      // Delete from local database immediately (this will also remove document associations due to foreign key constraints)
      await _repository.deleteTag(tagId);

      // If online, try to sync with server
      if (_connectivityService.hasConnectivity()) {
        try {
          await _apiService.deleteTag(tagId);
        } catch (e) {
          // If server request fails, queue for offline processing
          await _jobQueueService.addJob(JobType.deleteTag, {
            'tag_id': tagId,
          });
        }
      } else {
        // Queue for offline processing
        await _jobQueueService.addJob(JobType.deleteTag, {
          'tag_id': tagId,
        });
      }

      if (tag != null) {
        _tagEventsController.add(TagEvent.deleted(tag));
      }
    } catch (e) {
      throw TagException('Failed to delete tag: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Add tag to document
  Future<void> addTagToDocument(String documentId, String tagId) async {
    try {
      // Check if association already exists
      if (await _repository.documentHasTag(documentId, tagId)) {
        return; // Already associated, nothing to do
      }

      // Add association to local database immediately
      await _repository.addTagToDocument(documentId, tagId);

      // If online, try to sync with server
      if (_connectivityService.hasConnectivity()) {
        try {
          final request = AddTagToDocumentRequest(tagId: tagId);
          await _apiService.addTagToDocument(documentId, request);
        } catch (e) {
          // If server request fails, queue for offline processing
          await _jobQueueService.addJob(JobType.addTagToDocument, {
            'document_id': documentId,
            'tag_id': tagId,
          });
        }
      } else {
        // Queue for offline processing
        await _jobQueueService.addJob(JobType.addTagToDocument, {
          'document_id': documentId,
          'tag_id': tagId,
        });
      }

      _tagEventsController.add(TagEvent.documentTagged(documentId, tagId));
    } catch (e) {
      throw TagException('Failed to add tag to document: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Remove tag from document
  Future<void> removeTagFromDocument(String documentId, String tagId) async {
    try {
      // Remove association from local database immediately
      await _repository.removeTagFromDocument(documentId, tagId);

      // If online, try to sync with server
      if (_connectivityService.hasConnectivity()) {
        try {
          await _apiService.removeTagFromDocument(documentId, tagId);
        } catch (e) {
          // If server request fails, queue for offline processing
          await _jobQueueService.addJob(JobType.removeTagFromDocument, {
            'document_id': documentId,
            'tag_id': tagId,
          });
        }
      } else {
        // Queue for offline processing
        await _jobQueueService.addJob(JobType.removeTagFromDocument, {
          'document_id': documentId,
          'tag_id': tagId,
        });
      }

      _tagEventsController.add(TagEvent.documentUntagged(documentId, tagId));
    } catch (e) {
      throw TagException('Failed to remove tag from document: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get tags for a specific document
  Future<List<Tag>> getDocumentTags(String documentId) async {
    try {
      // Always return local data first for immediate UI response
      final localTags = await _repository.getDocumentTags(documentId);
      
      // If online, try to sync with server
      if (_connectivityService.hasConnectivity()) {
        try {
          final serverTags = await _apiService.getDocumentTags(documentId);
          
          // Update local cache with server data
          await _syncDocumentTagsToLocal(documentId, serverTags);
          
          // Return updated local data
          final updatedTags = await _repository.getDocumentTags(documentId);
          return updatedTags;
        } catch (e) {
          // If server request fails, continue with local data
        }
      }
      
      return localTags;
    } catch (e) {
      throw TagException('Failed to get document tags: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get documents for a specific tag
  Future<List<Document>> getDocumentsByTag(String tagId) async {
    try {
      // Always return local data first for immediate UI response
      final localDocuments = await _repository.getDocumentsByTag(tagId);
      
      // If online, try to sync with server
      if (_connectivityService.hasConnectivity()) {
        try {
          final serverDocuments = await _apiService.getDocumentsByTag(tagId);
          
          // Note: We don't sync documents here as they should be managed by DocumentService
          // This is just for getting the association data
          return serverDocuments;
        } catch (e) {
          // If server request fails, continue with local data
        }
      }
      
      return localDocuments;
    } catch (e) {
      throw TagException('Failed to get documents by tag: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Search tags by name
  Future<List<Tag>> searchTags(String query, {String? ownerId}) async {
    try {
      // Always search local data first
      final localTags = await _repository.searchTags(query, ownerId: ownerId);
      
      // If online, try to get server results
      if (_connectivityService.hasConnectivity()) {
        try {
          final serverTags = await _apiService.searchTags(query);
          
          // Combine and deduplicate results
          final combinedTags = <String, Tag>{};
          for (final tag in localTags) {
            combinedTags[tag.id] = tag;
          }
          for (final tag in serverTags) {
            combinedTags[tag.id] = tag;
          }
          
          return combinedTags.values.toList()..sort((a, b) => a.name.compareTo(b.name));
        } catch (e) {
          // If server request fails, continue with local data
        }
      }
      
      return localTags;
    } catch (e) {
      throw TagException('Failed to search tags: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get popular tags (most used)
  Future<List<TagWithCount>> getPopularTags({int limit = 10}) async {
    try {
      // Always return local data first
      final localTags = await _repository.getPopularTags(limit: limit);
      
      // If online, try to get server results
      if (_connectivityService.hasConnectivity()) {
        try {
          final serverTags = await _apiService.getPopularTags(limit: limit);
          
          // For popular tags, we prefer server data as it has global statistics
          // But we still return local data if server fails
          return serverTags.map((tag) => TagWithCount(tag: tag, count: 0)).toList();
        } catch (e) {
          // If server request fails, continue with local data
        }
      }
      
      return localTags;
    } catch (e) {
      throw TagException('Failed to get popular tags: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get tag usage count
  Future<int> getTagUsageCount(String tagId) async {
    try {
      return await _repository.getTagUsageCount(tagId);
    } catch (e) {
      throw TagException('Failed to get tag usage count: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get unused tags
  Future<List<Tag>> getUnusedTags({String? ownerId}) async {
    try {
      return await _repository.getUnusedTags(ownerId: ownerId);
    } catch (e) {
      throw TagException('Failed to get unused tags: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get tag suggestions based on partial input (for auto-completion)
  Future<List<Tag>> getTagSuggestions(String partialName, {String? ownerId, int limit = 10}) async {
    try {
      // Search local tags first
      final localSuggestions = await _repository.searchTags(partialName, ownerId: ownerId);
      
      // Limit local results
      final limitedLocal = localSuggestions.take(limit).toList();
      
      // If online, try to get server suggestions
      if (_connectivityService.hasConnectivity()) {
        try {
          final serverSuggestions = await _apiService.searchTags(partialName, limit: limit);
          
          // Combine and deduplicate results, prioritizing server results
          final combinedSuggestions = <String, Tag>{};
          
          // Add local results first
          for (final tag in limitedLocal) {
            combinedSuggestions[tag.id] = tag;
          }
          
          // Add server results (will override local if same ID)
          for (final tag in serverSuggestions) {
            combinedSuggestions[tag.id] = tag;
          }
          
          final result = combinedSuggestions.values.toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          
          return result.take(limit).toList();
        } catch (e) {
          // If server request fails, continue with local data
        }
      }
      
      return limitedLocal;
    } catch (e) {
      throw TagException('Failed to get tag suggestions: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get tag analytics (usage statistics)
  Future<TagAnalytics> getTagAnalytics({String? ownerId}) async {
    try {
      final allTags = ownerId != null 
          ? await _repository.getTagsByOwnerId(ownerId)
          : await _repository.getAllTags();
      
      final popularTags = await _repository.getPopularTags(limit: 10);
      final unusedTags = await _repository.getUnusedTags(ownerId: ownerId);
      
      // Calculate usage statistics
      int totalUsage = 0;
      for (final tagWithCount in popularTags) {
        totalUsage += tagWithCount.count;
      }
      
      return TagAnalytics(
        totalTags: allTags.length,
        usedTags: allTags.length - unusedTags.length,
        unusedTags: unusedTags.length,
        totalUsage: totalUsage,
        popularTags: popularTags,
        averageUsagePerTag: allTags.isNotEmpty ? totalUsage / allTags.length : 0.0,
      );
    } catch (e) {
      throw TagException('Failed to get tag analytics: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Process offline tag actions
  Future<void> processOfflineActions() async {
    if (!_connectivityService.hasConnectivity()) {
      return; // Skip if offline
    }

    try {
      final pendingJobs = await _jobQueueService.getPendingJobs();
      final tagJobs = pendingJobs.where((job) => 
        job.type == JobType.createTag ||
        job.type == JobType.deleteTag ||
        job.type == JobType.addTagToDocument ||
        job.type == JobType.removeTagFromDocument
      ).toList();

      for (final job in tagJobs) {
        try {
          await _jobQueueService.updateJobStatus(job.id, JobStatus.processing);
          
          switch (job.type) {
            case JobType.createTag:
              await _processCreateTagJob(job);
              break;
            case JobType.deleteTag:
              await _processDeleteTagJob(job);
              break;
            case JobType.addTagToDocument:
              await _processAddTagToDocumentJob(job);
              break;
            case JobType.removeTagFromDocument:
              await _processRemoveTagFromDocumentJob(job);
              break;
            default:
              continue;
          }
          
          await _jobQueueService.completeJob(job.id);
        } catch (e) {
          await _jobQueueService.incrementJobAttempts(job.id, error: e.toString());
          
          // Fail job after 3 attempts
          if (job.attempts >= 2) {
            await _jobQueueService.failJob(job.id, 'Max attempts reached: ${e.toString()}');
          }
        }
      }
    } catch (e) {
      // Log error but don't throw to avoid breaking sync process
    }
  }

  /// Sync server tags to local database
  Future<void> _syncTagsToLocal(List<Tag> serverTags) async {
    for (final tag in serverTags) {
      await _repository.insertTag(tag);
    }
  }

  /// Sync document tags from server to local database
  Future<void> _syncDocumentTagsToLocal(String documentId, List<Tag> serverTags) async {
    // First, get current local tags for the document
    final localTags = await _repository.getDocumentTags(documentId);
    final localTagIds = localTags.map((tag) => tag.id).toSet();
    final serverTagIds = serverTags.map((tag) => tag.id).toSet();

    // Remove tags that are no longer on server
    for (final localTagId in localTagIds) {
      if (!serverTagIds.contains(localTagId)) {
        await _repository.removeTagFromDocument(documentId, localTagId);
      }
    }

    // Add tags that are new on server
    for (final serverTag in serverTags) {
      await _repository.insertTag(serverTag); // Ensure tag exists locally
      if (!localTagIds.contains(serverTag.id)) {
        await _repository.addTagToDocument(documentId, serverTag.id);
      }
    }
  }

  /// Process create tag job
  Future<void> _processCreateTagJob(Job job) async {
    final payload = job.payload;
    final request = CreateTagRequest(name: payload['name'] as String);
    
    final serverTag = await _apiService.createTag(request);
    
    // Update local tag with server ID
    final localTagId = payload['tag_id'] as String;
    await _repository.deleteTag(localTagId); // Remove old local tag
    await _repository.insertTag(serverTag);
  }

  /// Process delete tag job
  Future<void> _processDeleteTagJob(Job job) async {
    final payload = job.payload;
    await _apiService.deleteTag(payload['tag_id'] as String);
    // Local tag should already be deleted
  }

  /// Process add tag to document job
  Future<void> _processAddTagToDocumentJob(Job job) async {
    final payload = job.payload;
    final request = AddTagToDocumentRequest(tagId: payload['tag_id'] as String);
    
    await _apiService.addTagToDocument(
      payload['document_id'] as String,
      request,
    );
  }

  /// Process remove tag from document job
  Future<void> _processRemoveTagFromDocumentJob(Job job) async {
    final payload = job.payload;
    await _apiService.removeTagFromDocument(
      payload['document_id'] as String,
      payload['tag_id'] as String,
    );
  }

  /// Dispose resources
  void dispose() {
    _tagsController.close();
    _tagEventsController.close();
  }
}

/// Event types for tag operations
enum TagEventType { created, deleted, documentTagged, documentUntagged }

/// Event model for tag operations
class TagEvent {
  final TagEventType type;
  final Tag? tag;
  final String? documentId;
  final String? tagId;
  final DateTime timestamp;

  TagEvent._(this.type, {this.tag, this.documentId, this.tagId}) : timestamp = DateTime.now();

  factory TagEvent.created(Tag tag) => TagEvent._(TagEventType.created, tag: tag);
  factory TagEvent.deleted(Tag tag) => TagEvent._(TagEventType.deleted, tag: tag);
  factory TagEvent.documentTagged(String documentId, String tagId) => 
      TagEvent._(TagEventType.documentTagged, documentId: documentId, tagId: tagId);
  factory TagEvent.documentUntagged(String documentId, String tagId) => 
      TagEvent._(TagEventType.documentUntagged, documentId: documentId, tagId: tagId);
}

/// Analytics data for tag usage
class TagAnalytics {
  final int totalTags;
  final int usedTags;
  final int unusedTags;
  final int totalUsage;
  final List<TagWithCount> popularTags;
  final double averageUsagePerTag;

  const TagAnalytics({
    required this.totalTags,
    required this.usedTags,
    required this.unusedTags,
    required this.totalUsage,
    required this.popularTags,
    required this.averageUsagePerTag,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TagAnalytics &&
        other.totalTags == totalTags &&
        other.usedTags == usedTags &&
        other.unusedTags == unusedTags &&
        other.totalUsage == totalUsage &&
        other.popularTags == popularTags &&
        other.averageUsagePerTag == averageUsagePerTag;
  }

  @override
  int get hashCode => Object.hash(
    totalTags,
    usedTags,
    unusedTags,
    totalUsage,
    popularTags,
    averageUsagePerTag,
  );

  @override
  String toString() {
    return 'TagAnalytics(totalTags: $totalTags, usedTags: $usedTags, '
           'unusedTags: $unusedTags, totalUsage: $totalUsage, '
           'popularTags: $popularTags, averageUsagePerTag: $averageUsagePerTag)';
  }
}