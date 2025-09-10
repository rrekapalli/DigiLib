/// Utility class for file-related operations
class FileUtils {
  /// Format file size in bytes to human-readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Get file extension from filename
  static String? getFileExtension(String filename) {
    final lastDot = filename.lastIndexOf('.');
    if (lastDot == -1 || lastDot == filename.length - 1) {
      return null;
    }
    return filename.substring(lastDot + 1).toLowerCase();
  }

  /// Get filename without extension
  static String getFilenameWithoutExtension(String filename) {
    final lastDot = filename.lastIndexOf('.');
    if (lastDot == -1) {
      return filename;
    }
    return filename.substring(0, lastDot);
  }

  /// Check if file is a supported document type
  static bool isSupportedDocument(String filename) {
    final extension = getFileExtension(filename);
    if (extension == null) return false;
    
    const supportedExtensions = ['pdf', 'epub', 'docx', 'doc', 'txt'];
    return supportedExtensions.contains(extension);
  }

  /// Get MIME type for file extension
  static String? getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'epub':
        return 'application/epub+zip';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'doc':
        return 'application/msword';
      case 'txt':
        return 'text/plain';
      default:
        return null;
    }
  }

  /// Sanitize filename for safe storage
  static String sanitizeFilename(String filename) {
    // Remove or replace invalid characters
    return filename
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Generate a safe path from components
  static String joinPath(List<String> components) {
    return components
        .where((component) => component.isNotEmpty)
        .map((component) => component.replaceAll('/', '_'))
        .join('/');
  }

  /// Normalize path separators
  static String normalizePath(String path) {
    return path
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'/+'), '/')
        .replaceAll(RegExp(r'^/+'), '/')
        .replaceAll(RegExp(r'/+$'), '');
  }

  /// Get parent directory path
  static String? getParentPath(String path) {
    final normalizedPath = normalizePath(path);
    if (normalizedPath == '/' || normalizedPath.isEmpty) {
      return null;
    }
    
    final lastSlash = normalizedPath.lastIndexOf('/');
    if (lastSlash <= 0) {
      return '/';
    }
    
    return normalizedPath.substring(0, lastSlash);
  }

  /// Check if path is a subdirectory of another path
  static bool isSubdirectoryOf(String childPath, String parentPath) {
    final normalizedChild = normalizePath(childPath);
    final normalizedParent = normalizePath(parentPath);
    
    if (normalizedParent == '/') {
      return normalizedChild != '/';
    }
    
    return normalizedChild.startsWith('$normalizedParent/');
  }

  /// Get relative path from base path
  static String getRelativePath(String fullPath, String basePath) {
    final normalizedFull = normalizePath(fullPath);
    final normalizedBase = normalizePath(basePath);
    
    if (normalizedBase == '/') {
      return normalizedFull.substring(1);
    }
    
    if (normalizedFull.startsWith('$normalizedBase/')) {
      return normalizedFull.substring(normalizedBase.length + 1);
    }
    
    return normalizedFull;
  }
}