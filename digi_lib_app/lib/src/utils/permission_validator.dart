import '../models/entities/share.dart';

/// Utility class for validating permissions and access control
class PermissionValidator {
  /// Check if a permission level allows a specific action
  static bool hasPermission(SharePermission userPermission, SharePermission requiredPermission) {
    // Permission hierarchy: full > comment > view
    switch (requiredPermission) {
      case SharePermission.view:
        return true; // All permissions include view
      case SharePermission.comment:
        return userPermission == SharePermission.comment || userPermission == SharePermission.full;
      case SharePermission.full:
        return userPermission == SharePermission.full;
    }
  }

  /// Check if user can perform view actions
  static bool canView(SharePermission? permission) {
    return permission != null && hasPermission(permission, SharePermission.view);
  }

  /// Check if user can perform comment actions
  static bool canComment(SharePermission? permission) {
    return permission != null && hasPermission(permission, SharePermission.comment);
  }

  /// Check if user can perform full edit actions
  static bool canEdit(SharePermission? permission) {
    return permission != null && hasPermission(permission, SharePermission.full);
  }

  /// Get permission level as integer for comparison
  static int getPermissionLevel(SharePermission permission) {
    switch (permission) {
      case SharePermission.view:
        return 1;
      case SharePermission.comment:
        return 2;
      case SharePermission.full:
        return 3;
    }
  }

  /// Compare two permissions (returns positive if first is higher, negative if lower, 0 if equal)
  static int comparePermissions(SharePermission permission1, SharePermission permission2) {
    return getPermissionLevel(permission1) - getPermissionLevel(permission2);
  }

  /// Get the highest permission from a list
  static SharePermission? getHighestPermission(List<SharePermission> permissions) {
    if (permissions.isEmpty) return null;
    
    SharePermission highest = permissions.first;
    for (final permission in permissions.skip(1)) {
      if (comparePermissions(permission, highest) > 0) {
        highest = permission;
      }
    }
    return highest;
  }

  /// Check if permission allows creating annotations
  static bool canCreateAnnotations(SharePermission? permission) {
    return canView(permission); // Users with view permission can create their own annotations
  }

  /// Check if permission allows viewing others' annotations
  static bool canViewOthersAnnotations(SharePermission? permission) {
    return canComment(permission); // Users need comment permission to see others' annotations
  }

  /// Check if permission allows editing others' annotations
  static bool canEditOthersAnnotations(SharePermission? permission) {
    return canEdit(permission); // Users need full permission to edit others' annotations
  }

  /// Check if permission allows managing shares
  static bool canManageShares(SharePermission? permission) {
    return canEdit(permission); // Users need full permission to manage shares
  }

  /// Validate permission transition (e.g., when updating share permission)
  static bool isValidPermissionTransition(SharePermission from, SharePermission to) {
    // All transitions are valid for now
    // This could be extended to implement business rules like:
    // - Can't downgrade from full to view directly
    // - Certain roles can't grant full permission
    return true;
  }

  /// Get user-friendly permission description
  static String getPermissionDescription(SharePermission permission) {
    switch (permission) {
      case SharePermission.view:
        return 'Can view document and create personal bookmarks';
      case SharePermission.comment:
        return 'Can view, comment, and see all annotations';
      case SharePermission.full:
        return 'Can view, comment, edit, and manage sharing';
    }
  }

  /// Get permission display name
  static String getPermissionDisplayName(SharePermission permission) {
    switch (permission) {
      case SharePermission.view:
        return 'Viewer';
      case SharePermission.comment:
        return 'Commenter';
      case SharePermission.full:
        return 'Editor';
    }
  }

  /// Get available actions for a permission level
  static List<String> getAvailableActions(SharePermission permission) {
    final actions = <String>['View document', 'Create bookmarks'];
    
    if (canComment(permission)) {
      actions.addAll(['Add comments', 'View all annotations']);
    }
    
    if (canEdit(permission)) {
      actions.addAll(['Edit document metadata', 'Manage sharing', 'Delete annotations']);
    }
    
    return actions;
  }
}