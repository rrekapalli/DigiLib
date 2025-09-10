import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/tag.dart';
import '../models/entities/document.dart';

/// Provider for TagService
final tagServiceProvider = Provider<TagService>((ref) {
  // This would be injected from a higher level provider in a real app
  // For now, we'll use a mock implementation
  return MockTagService();
});

/// State for tag management
class TagState {
  final List<Tag> tags;
  final bool isLoading;
  final String? error;

  const TagState({
    this.tags = const [],
    this.isLoading = false,
    this.error,
  });

  TagState copyWith({
    List<Tag>? tags,
    bool? isLoading,
    String? error,
  }) {
    return TagState(
      tags: tags ?? this.tags,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing tag state
class TagNotifier extends StateNotifier<TagState> {
  final TagService _tagService;

  TagNotifier(this._tagService) : super(const TagState()) {
    _loadTags();
  }

  /// Load tags from service
  Future<void> _loadTags() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final tags = await _tagService.getTags();
      state = state.copyWith(
        tags: tags,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load tags: $e',
      );
    }
  }

  /// Create a new tag
  Future<Tag> createTag(String name) async {
    try {
      state = state.copyWith(error: null);
      
      final tag = await _tagService.createTag(name);
      
      // Add to current state
      final updatedTags = [...state.tags, tag];
      state = state.copyWith(tags: updatedTags);
      
      return tag;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to create tag: $e',
      );
      rethrow;
    }
  }

  /// Delete a tag
  Future<void> deleteTag(String tagId) async {
    try {
      state = state.copyWith(error: null);
      
      await _tagService.deleteTag(tagId);
      
      // Remove from current state
      final updatedTags = state.tags
          .where((tag) => tag.id != tagId)
          .toList();
      state = state.copyWith(tags: updatedTags);
      
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to delete tag: $e',
      );
      rethrow;
    }
  }

  /// Refresh tags
  Future<void> refreshTags() async {
    await _loadTags();
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for TagNotifier
final tagProvider = StateNotifierProvider<TagNotifier, TagState>((ref) {
  final tagService = ref.watch(tagServiceProvider);
  return TagNotifier(tagService);
});

/// Provider for getting all tags as a simple list
final tagsProvider = Provider<AsyncValue<List<Tag>>>((ref) {
  final tagState = ref.watch(tagProvider);
  
  if (tagState.isLoading) {
    return const AsyncValue.loading();
  }
  
  if (tagState.error != null) {
    return AsyncValue.error(tagState.error!, StackTrace.current);
  }
  
  return AsyncValue.data(tagState.tags);
});

/// Provider for getting a specific tag by ID
final tagByIdProvider = Provider.family<Tag?, String>((ref, tagId) {
  final tagState = ref.watch(tagProvider);
  return tagState.tags.cast<Tag?>().firstWhere(
    (tag) => tag?.id == tagId,
    orElse: () => null,
  );
});

/// Mock TagService for development
class MockTagService implements TagService {
  static final List<Tag> _mockTags = [
    Tag(
      id: '1',
      ownerId: 'user1',
      name: 'Fiction',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Tag(
      id: '2',
      ownerId: 'user1',
      name: 'Non-Fiction',
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
    ),
    Tag(
      id: '3',
      ownerId: 'user1',
      name: 'Technical',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    Tag(
      id: '4',
      ownerId: 'user1',
      name: 'Biography',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    Tag(
      id: '5',
      ownerId: 'user1',
      name: 'History',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  @override
  Future<List<Tag>> getTags() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_mockTags);
  }

  @override
  Future<Tag> createTag(String name) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final tag = Tag(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      ownerId: 'user1',
      name: name,
      createdAt: DateTime.now(),
    );
    
    _mockTags.add(tag);
    return tag;
  }

  @override
  Future<void> deleteTag(String tagId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockTags.removeWhere((tag) => tag.id == tagId);
  }

  @override
  Future<void> addTagToDocument(String documentId, String tagId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Mock implementation - would normally update database
  }

  @override
  Future<void> removeTagFromDocument(String documentId, String tagId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Mock implementation - would normally update database
  }

  @override
  Future<List<Tag>> getDocumentTags(String documentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Mock implementation - return random subset of tags
    return _mockTags.take(2).toList();
  }

  @override
  Future<List<Document>> getDocumentsByTag(String tagId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock implementation - would normally query database
    return [];
  }
}

/// Abstract TagService interface
abstract class TagService {
  Future<List<Tag>> getTags();
  Future<Tag> createTag(String name);
  Future<void> deleteTag(String tagId);
  Future<void> addTagToDocument(String documentId, String tagId);
  Future<void> removeTagFromDocument(String documentId, String tagId);
  Future<List<Tag>> getDocumentTags(String documentId);
  Future<List<Document>> getDocumentsByTag(String tagId);
}

