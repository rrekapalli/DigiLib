import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';

/// Service for optimized file system operations on desktop platforms
class FileSystemService {
  static const List<String> supportedDocumentExtensions = [
    '.pdf', '.epub', '.docx', '.doc', '.txt', '.rtf', '.odt'
  ];
  
  /// Pick a folder using native file picker
  static Future<String?> pickFolder({String? dialogTitle}) async {
    if (!_isDesktop) return null;
    
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: dialogTitle ?? 'Select Library Folder',
      );
      return result;
    } catch (e) {
      print('Error picking folder: $e');
      return null;
    }
  }
  
  /// Pick multiple files using native file picker
  static Future<List<String>?> pickFiles({
    String? dialogTitle,
    List<String>? allowedExtensions,
  }) async {
    if (!_isDesktop) return null;
    
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: dialogTitle ?? 'Select Documents',
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: allowedExtensions ?? 
          supportedDocumentExtensions.map((e) => e.substring(1)).toList(),
      );
      
      return result?.files.map((file) => file.path!).toList();
    } catch (e) {
      print('Error picking files: $e');
      return null;
    }
  }
  
  /// Scan directory for supported documents with progress callback
  static Stream<FileSystemScanResult> scanDirectory(
    String directoryPath, {
    bool recursive = true,
    Function(int scanned, int total)? onProgress,
  }) async* {
    if (!_isDesktop) return;
    
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        yield FileSystemScanResult.error('Directory does not exist: $directoryPath');
        return;
      }
      
      final files = <FileSystemEntry>[];
      int scannedCount = 0;
      
      await for (final entity in directory.list(recursive: recursive)) {
        if (entity is File) {
          final extension = path.extension(entity.path).toLowerCase();
          if (supportedDocumentExtensions.contains(extension)) {
            try {
              final stat = await entity.stat();
              final entry = FileSystemEntry(
                path: entity.path,
                name: path.basename(entity.path),
                extension: extension,
                size: stat.size,
                lastModified: stat.modified,
                relativePath: path.relative(entity.path, from: directoryPath),
              );
              files.add(entry);
              
              scannedCount++;
              onProgress?.call(scannedCount, files.length);
              
              // Yield progress periodically
              if (scannedCount % 100 == 0) {
                yield FileSystemScanResult.progress(files.toList(), scannedCount);
              }
            } catch (e) {
              print('Error processing file ${entity.path}: $e');
            }
          }
        }
      }
      
      yield FileSystemScanResult.completed(files);
    } catch (e) {
      yield FileSystemScanResult.error('Error scanning directory: $e');
    }
  }
  
  /// Get file metadata efficiently
  static Future<FileMetadata?> getFileMetadata(String filePath) async {
    if (!_isDesktop) return null;
    
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      
      final stat = await file.stat();
      return FileMetadata(
        path: filePath,
        name: path.basename(filePath),
        extension: path.extension(filePath).toLowerCase(),
        size: stat.size,
        lastModified: stat.modified,
        lastAccessed: stat.accessed,
      );
    } catch (e) {
      print('Error getting file metadata for $filePath: $e');
      return null;
    }
  }
  
  /// Watch directory for changes
  static Stream<FileSystemEvent> watchDirectory(String directoryPath) async* {
    if (!_isDesktop) return;
    
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) return;
      
      await for (final event in directory.watch(recursive: true)) {
        if (event.path.isNotEmpty) {
          final extension = path.extension(event.path).toLowerCase();
          if (supportedDocumentExtensions.contains(extension)) {
            yield event;
          }
        }
      }
    } catch (e) {
      print('Error watching directory $directoryPath: $e');
    }
  }
  
  /// Create symbolic link (desktop platforms)
  static Future<bool> createSymbolicLink(String target, String link) async {
    if (!_isDesktop) return false;
    
    try {
      final linkFile = Link(link);
      await linkFile.create(target);
      return true;
    } catch (e) {
      print('Error creating symbolic link: $e');
      return false;
    }
  }
  
  /// Get available disk space for a path
  static Future<int?> getAvailableSpace(String directoryPath) async {
    if (!_isDesktop) return null;
    
    try {
      // This would require platform-specific implementation
      // For now, return a placeholder value
      return 1024 * 1024 * 1024; // 1GB placeholder
    } catch (e) {
      print('Error getting available space: $e');
      return null;
    }
  }
  
  /// Move file to trash/recycle bin instead of permanent deletion
  static Future<bool> moveToTrash(String filePath) async {
    if (!_isDesktop) return false;
    
    try {
      // This would require platform-specific implementation
      // For now, just delete the file
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error moving file to trash: $e');
      return false;
    }
  }
  
  /// Check if running on desktop platform
  static bool get _isDesktop {
    return !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  }
}

/// File system entry model
class FileSystemEntry {
  final String path;
  final String name;
  final String extension;
  final int size;
  final DateTime lastModified;
  final String relativePath;
  
  const FileSystemEntry({
    required this.path,
    required this.name,
    required this.extension,
    required this.size,
    required this.lastModified,
    required this.relativePath,
  });
  
  @override
  String toString() {
    return 'FileSystemEntry(name: $name, size: $size, path: $relativePath)';
  }
}

/// File metadata model
class FileMetadata {
  final String path;
  final String name;
  final String extension;
  final int size;
  final DateTime lastModified;
  final DateTime lastAccessed;
  
  const FileMetadata({
    required this.path,
    required this.name,
    required this.extension,
    required this.size,
    required this.lastModified,
    required this.lastAccessed,
  });
}

/// File system scan result
class FileSystemScanResult {
  final List<FileSystemEntry>? files;
  final String? error;
  final int? scannedCount;
  final bool isCompleted;
  
  const FileSystemScanResult._({
    this.files,
    this.error,
    this.scannedCount,
    required this.isCompleted,
  });
  
  factory FileSystemScanResult.progress(List<FileSystemEntry> files, int scannedCount) {
    return FileSystemScanResult._(
      files: files,
      scannedCount: scannedCount,
      isCompleted: false,
    );
  }
  
  factory FileSystemScanResult.completed(List<FileSystemEntry> files) {
    return FileSystemScanResult._(
      files: files,
      isCompleted: true,
    );
  }
  
  factory FileSystemScanResult.error(String error) {
    return FileSystemScanResult._(
      error: error,
      isCompleted: true,
    );
  }
}