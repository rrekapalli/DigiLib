import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/share.dart';
import '../models/api/create_share_request.dart';
import '../models/ui/share_event.dart' as ui;
import '../services/share_service.dart';
import '../services/share_api_service.dart';
import '../services/job_queue_service.dart';
import '../network/connectivity_service.dart';
import '../network/api_client.dart';
import '../database/repositories/share_repository.dart';
import 'connectivity_provider.dart';

// Provider for ShareApiService
final shareApiServiceProvider = Provider<ShareApiService>((ref) {
  // TODO: Replace with actual API client provider
  throw UnimplementedError('API client provider must be implemented');
});

// Provider for ShareService
final shareServiceProvider = Provider<ShareService>((ref) {
  // TODO: Replace with actual service implementations
  throw UnimplementedError('ShareService dependencies must be implemented');
});

// Provider for shares owned by current user
final sharesProvider = StreamProvider.autoDispose<List<Share>>((ref) {
  final shareService = ref.watch(shareServiceProvider);
  return shareService.sharesStream;
});

// Provider for shares shared with current user
final sharedWithMeProvider = FutureProvider.autoDispose<List<Share>>((ref) async {
  final shareService = ref.watch(shareServiceProvider);
  // TODO: Get current user email from auth provider
  return shareService.getSharedWithMe('user@example.com');
});

// Provider for shares of a specific subject (document/folder)
final sharesBySubjectProvider = FutureProvider.autoDispose.family<List<Share>, String>((ref, subjectId) async {
  final shareService = ref.watch(shareServiceProvider);
  return shareService.getSharesBySubject(subjectId);
});

// Provider for share events stream
final shareEventsProvider = StreamProvider.autoDispose((ref) {
  final shareService = ref.watch(shareServiceProvider);
  return shareService.shareEventsStream;
});

// State notifier for managing share operations
class ShareNotifier extends StateNotifier<AsyncValue<List<Share>>> {
  final ShareService _shareService;
  final String _ownerId;

  ShareNotifier(this._shareService, this._ownerId) : super(const AsyncValue.loading()) {
    _loadShares();
  }

  Future<void> _loadShares() async {
    try {
      final shares = await _shareService.getShares(_ownerId);
      state = AsyncValue.data(shares);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createShare(CreateShareRequest request) async {
    try {
      await _shareService.createShare(request, _ownerId);
      await _loadShares(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateSharePermission(String shareId, SharePermission permission) async {
    try {
      await _shareService.updateSharePermission(shareId, permission);
      await _loadShares(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteShare(String shareId) async {
    try {
      await _shareService.deleteShare(shareId);
      await _loadShares(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await _loadShares();
  }
}

// Provider for share notifier
final shareNotifierProvider = StateNotifierProvider.autoDispose.family<ShareNotifier, AsyncValue<List<Share>>, String>((ref, ownerId) {
  final shareService = ref.watch(shareServiceProvider);
  return ShareNotifier(shareService, ownerId);
});

// Provider for checking if a subject is shared
final isSharedProvider = FutureProvider.autoDispose.family<bool, ({String subjectId, String userEmail})>((ref, params) async {
  final shareService = ref.watch(shareServiceProvider);
  return shareService.isSharedWithUser(params.subjectId, params.userEmail);
});

// Provider for getting share permission
final sharePermissionProvider = FutureProvider.autoDispose.family<SharePermission?, ({String subjectId, String userEmail})>((ref, params) async {
  final shareService = ref.watch(shareServiceProvider);
  return shareService.getSharePermission(params.subjectId, params.userEmail);
});

// Provider for shares count
final sharesCountProvider = FutureProvider.autoDispose.family<int, String>((ref, subjectId) async {
  final shareService = ref.watch(shareServiceProvider);
  return shareService.getSharesCount(subjectId);
});