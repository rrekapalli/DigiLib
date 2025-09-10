import 'dart:async';
import '../models/entities/document.dart';
import '../models/entities/share.dart';
import '../services/share_service.dart';
import '../services/document_service.dart';
import '../utils/permission_validator.dart';

/// Exception thrown when shared document operations fail
class SharedDocumentException implements Exception {
  final String message;
  final String? code;
  final Exception? cause;

  const SharedDocumentException(this.message, {this.code, this.cause});

  @override
  String toString() => 'SharedDocumentException: $message';
}

/// Model for shared document with permission context
class SharedDocumentAccess {
  final Document document;
  final Share share;
  final SharePermission permission;
  final String ownerName;
  final DateTime sharedAt;

  const SharedDocumentAccess({
    required this.document,
    required this.share,
    required this.permission,
    required this.ownerName,
    required this.sharedAt,
  });

  /// Check if user can perform specific actions
  bool canView() => PermissionValidator.canView(permission);
  bool canComment() => PermissionValidator.canComment(permission);
  bool canEdit() => PermissionValidator.canEdit(permission);

  /// Get permission display name
  String get permissionDisplayName =>
      PermissionValidator.getPermissionDisplayName(permission);

  /// Get permission description
  String get permissionDescription =>
      PermissionValidator.getPermissionDescription(permission);

  /// Get available actions
  List<String> get availableActions =>
      PermissionValidator.getAvailableActions(permission);
}

/// Service for managing shared document access and viewing
class SharedDocumentService {
  final ShareService _shareService;
  final DocumentService _documentService;

  // Stream controllers for shared document updates
  final StreamController<List<SharedDocumentAccess>>
  _sharedDocumentsController =
      StreamController<List<SharedDocumentAccess>>.broadcast();

  SharedDocumentService({
    required ShareService shareService,
    required DocumentService documentService,
  }) : _shareService = shareService,
       _documentService = documentService;

  /// Stream of shared documents accessible to user
  Stream<List<SharedDocumentAccess>> get sharedDocumentsStream =>
      _sharedDocumentsController.stream;

  /// Get all documents shared with a user
  Future<List<SharedDocumentAccess>> getSharedDocuments(
    String userEmail,
  ) async {
    try {
      final shares = await _shareService.getSharedWithMe(userEmail);
      final documentShares = shares
          .where((share) => share.subjectType == ShareSubjectType.document)
          .toList();

      final sharedDocuments = <SharedDocumentAccess>[];

      for (final share in documentShares) {
        try {
          final document = await _documentService.getDocument(share.subjectId);
          if (document != null) {
            // Get owner information (this would typically come from a user service)
            final ownerName = await _getOwnerName(share.ownerId);

            final sharedDoc = SharedDocumentAccess(
              document: document,
              share: share,
              permission: share.permission,
              ownerName: ownerName,
              sharedAt: share.createdAt,
            );

            sharedDocuments.add(sharedDoc);
          }
        } catch (e) {
          // Skip documents that can't be accessed
          continue;
        }
      }

      // Sort by shared date (most recent first)
      sharedDocuments.sort((a, b) => b.sharedAt.compareTo(a.sharedAt));

      _sharedDocumentsController.add(sharedDocuments);
      return sharedDocuments;
    } catch (e) {
      throw SharedDocumentException(
        'Failed to get shared documents: ${e.toString()}',
        cause: e is Exception ? e : null,
      );
    }
  }

  /// Get shared document access details
  Future<SharedDocumentAccess?> getSharedDocumentAccess(
    String documentId,
    String userEmail,
  ) async {
    try {
      final permission = await _shareService.getSharePermission(
        documentId,
        userEmail,
      );
      if (permission == null) {
        return null; // No access
      }

      final document = await _documentService.getDocument(documentId);
      if (document == null) {
        return null; // Document not found
      }

      // Get the share record
      final shares = await _shareService.getSharesBySubject(documentId);
      final userShare = shares.firstWhere(
        (share) => share.granteeEmail == userEmail,
        orElse: () => throw SharedDocumentException('Share not found'),
      );

      final ownerName = await _getOwnerName(userShare.ownerId);

      return SharedDocumentAccess(
        document: document,
        share: userShare,
        permission: permission,
        ownerName: ownerName,
        sharedAt: userShare.createdAt,
      );
    } catch (e) {
      throw SharedDocumentException(
        'Failed to get shared document access: ${e.toString()}',
        cause: e is Exception ? e : null,
      );
    }
  }

  /// Check if user has access to a shared document
  Future<bool> hasAccess(String documentId, String userEmail) async {
    try {
      final access = await getSharedDocumentAccess(documentId, userEmail);
      return access != null;
    } catch (e) {
      return false;
    }
  }

  /// Get documents shared by a user (documents they own and have shared)
  Future<List<SharedDocumentInfo>> getDocumentsSharedByUser(
    String ownerId,
  ) async {
    try {
      final shares = await _shareService.getShares(ownerId);
      final documentShares = shares
          .where((share) => share.subjectType == ShareSubjectType.document)
          .toList();

      // Group shares by document
      final documentSharesMap = <String, List<Share>>{};
      for (final share in documentShares) {
        documentSharesMap.putIfAbsent(share.subjectId, () => []).add(share);
      }

      final sharedDocuments = <SharedDocumentInfo>[];

      for (final entry in documentSharesMap.entries) {
        final documentId = entry.key;
        final documentShares = entry.value;

        try {
          final document = await _documentService.getDocument(documentId);
          if (document != null) {
            final sharedDoc = SharedDocumentInfo(
              document: document,
              shares: documentShares,
              shareCount: documentShares.length,
              lastSharedAt: documentShares
                  .map((s) => s.createdAt)
                  .reduce((a, b) => a.isAfter(b) ? a : b),
            );

            sharedDocuments.add(sharedDoc);
          }
        } catch (e) {
          // Skip documents that can't be accessed
          continue;
        }
      }

      // Sort by last shared date (most recent first)
      sharedDocuments.sort((a, b) => b.lastSharedAt.compareTo(a.lastSharedAt));

      return sharedDocuments;
    } catch (e) {
      throw SharedDocumentException(
        'Failed to get documents shared by user: ${e.toString()}',
        cause: e is Exception ? e : null,
      );
    }
  }

  /// Get sharing statistics for a user
  Future<SharingStatistics> getSharingStatistics(String userId) async {
    try {
      final sharedWithMe = await _shareService.getSharedWithMe(
        '$userId@example.com',
      ); // This would need proper email resolution
      final sharedByMe = await _shareService.getShares(userId);

      final documentsSharedWithMe = sharedWithMe
          .where((s) => s.subjectType == ShareSubjectType.document)
          .length;
      final documentsSharedByMe = sharedByMe
          .where((s) => s.subjectType == ShareSubjectType.document)
          .length;

      return SharingStatistics(
        documentsSharedWithMe: documentsSharedWithMe,
        documentsSharedByMe: documentsSharedByMe,
        totalShares: sharedWithMe.length + sharedByMe.length,
        recentShares: [...sharedWithMe, ...sharedByMe]
            .where(
              (s) => s.createdAt.isAfter(
                DateTime.now().subtract(const Duration(days: 7)),
              ),
            )
            .length,
      );
    } catch (e) {
      throw SharedDocumentException(
        'Failed to get sharing statistics: ${e.toString()}',
        cause: e is Exception ? e : null,
      );
    }
  }

  /// Filter shared documents by permission level
  List<SharedDocumentAccess> filterByPermission(
    List<SharedDocumentAccess> documents,
    SharePermission permission,
  ) {
    return documents.where((doc) => doc.permission == permission).toList();
  }

  /// Search shared documents
  List<SharedDocumentAccess> searchSharedDocuments(
    List<SharedDocumentAccess> documents,
    String query,
  ) {
    if (query.isEmpty) return documents;

    final lowerQuery = query.toLowerCase();
    return documents.where((doc) {
      return doc.document.title?.toLowerCase().contains(lowerQuery) == true ||
          doc.document.author?.toLowerCase().contains(lowerQuery) == true ||
          doc.ownerName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get owner name (placeholder - would integrate with user service)
  Future<String> _getOwnerName(String ownerId) async {
    // This would typically call a user service to get user details
    // For now, return a placeholder
    return 'User $ownerId';
  }

  /// Dispose resources
  void dispose() {
    _sharedDocumentsController.close();
  }
}

/// Model for documents shared by a user
class SharedDocumentInfo {
  final Document document;
  final List<Share> shares;
  final int shareCount;
  final DateTime lastSharedAt;

  const SharedDocumentInfo({
    required this.document,
    required this.shares,
    required this.shareCount,
    required this.lastSharedAt,
  });

  /// Get unique grantees
  List<String> get grantees => shares
      .map((s) => s.granteeEmail)
      .where((e) => e != null)
      .cast<String>()
      .toSet()
      .toList();

  /// Get permission distribution
  Map<SharePermission, int> get permissionDistribution {
    final distribution = <SharePermission, int>{};
    for (final share in shares) {
      distribution[share.permission] =
          (distribution[share.permission] ?? 0) + 1;
    }
    return distribution;
  }
}

/// Model for sharing statistics
class SharingStatistics {
  final int documentsSharedWithMe;
  final int documentsSharedByMe;
  final int totalShares;
  final int recentShares;

  const SharingStatistics({
    required this.documentsSharedWithMe,
    required this.documentsSharedByMe,
    required this.totalShares,
    required this.recentShares,
  });
}
