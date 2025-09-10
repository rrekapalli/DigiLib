import 'dart:ffi';
import 'dart:io';

/// Platform-specific native library loader with comprehensive error handling
class NativeLibraryLoader {
  static const String _baseLibraryName = 'digi_lib_native';
  
  /// Load the native library for the current platform
  static DynamicLibrary loadLibrary() {
    final libraryName = _getPlatformLibraryName();
    final searchPaths = _getLibrarySearchPaths(libraryName);
    
    // Try each search path
    for (final path in searchPaths) {
      try {
        if (File(path).existsSync()) {
          return DynamicLibrary.open(path);
        }
      } catch (e) {
        // Continue to next path
        continue;
      }
    }
    
    // Try loading by name only (system paths)
    try {
      return DynamicLibrary.open(libraryName);
    } catch (e) {
      // Final attempt with process lookup for embedded libraries
      try {
        return DynamicLibrary.process();
      } catch (processError) {
        throw NativeLibraryLoadException(
          'Failed to load native library "$libraryName". Searched paths: ${searchPaths.join(", ")}',
          searchPaths,
          e,
        );
      }
    }
  }

  /// Get the platform-specific library name
  static String _getPlatformLibraryName() {
    if (Platform.isWindows) {
      return '$_baseLibraryName.dll';
    } else if (Platform.isMacOS) {
      return 'lib$_baseLibraryName.dylib';
    } else if (Platform.isLinux) {
      return 'lib$_baseLibraryName.so';
    } else if (Platform.isAndroid) {
      return 'lib$_baseLibraryName.so';
    } else if (Platform.isIOS) {
      return '$_baseLibraryName.framework/$_baseLibraryName';
    } else {
      throw UnsupportedError('Platform ${Platform.operatingSystem} is not supported');
    }
  }

  /// Get all possible search paths for the library
  static List<String> _getLibrarySearchPaths(String libraryName) {
    final paths = <String>[];
    
    // Current directory
    paths.add(libraryName);
    
    // Platform-specific paths
    if (Platform.isWindows) {
      paths.addAll(_getWindowsSearchPaths(libraryName));
    } else if (Platform.isMacOS) {
      paths.addAll(_getMacOSSearchPaths(libraryName));
    } else if (Platform.isLinux) {
      paths.addAll(_getLinuxSearchPaths(libraryName));
    } else if (Platform.isAndroid) {
      paths.addAll(_getAndroidSearchPaths(libraryName));
    } else if (Platform.isIOS) {
      paths.addAll(_getIOSSearchPaths(libraryName));
    }
    
    return paths;
  }

  static List<String> _getWindowsSearchPaths(String libraryName) {
    return [
      // Relative paths
      'native\\\\$libraryName',
      'lib\\\\$libraryName',
      'bin\\\\$libraryName',
      'build\\\\windows\\\\runner\\\\Release\\\\$libraryName',
      'build\\\\windows\\\\runner\\\\Debug\\\\$libraryName',
      
      // Absolute paths
      '${Platform.environment['PROGRAMFILES']}\\\\DigitalLibrary\\\\$libraryName',
      '${Platform.environment['PROGRAMFILES(X86)']}\\\\DigitalLibrary\\\\$libraryName',
      '${Platform.environment['LOCALAPPDATA']}\\\\DigitalLibrary\\\\$libraryName',
      
      // System paths
      '${Platform.environment['WINDIR']}\\\\System32\\\\$libraryName',
      '${Platform.environment['WINDIR']}\\\\SysWOW64\\\\$libraryName',
    ].where((path) => path.isNotEmpty).toList();
  }

  static List<String> _getMacOSSearchPaths(String libraryName) {
    final homeDir = Platform.environment['HOME'] ?? '';
    
    return [
      // Relative paths
      'native/$libraryName',
      'lib/$libraryName',
      'build/macos/Build/Products/Release/$libraryName',
      'build/macos/Build/Products/Debug/$libraryName',
      
      // Application bundle paths
      '../Frameworks/$libraryName',
      '../Resources/$libraryName',
      
      // System paths
      '/usr/local/lib/$libraryName',
      '/usr/lib/$libraryName',
      '/opt/homebrew/lib/$libraryName',
      '/opt/local/lib/$libraryName',
      
      // User paths
      '$homeDir/Library/Frameworks/$libraryName',
      '$homeDir/.local/lib/$libraryName',
    ].where((path) => path.isNotEmpty).toList();
  }

  static List<String> _getLinuxSearchPaths(String libraryName) {
    final homeDir = Platform.environment['HOME'] ?? '';
    
    return [
      // Relative paths
      'native/$libraryName',
      'lib/$libraryName',
      'build/linux/x64/release/bundle/lib/$libraryName',
      'build/linux/x64/debug/bundle/lib/$libraryName',
      
      // System paths
      '/usr/local/lib/$libraryName',
      '/usr/lib/$libraryName',
      '/usr/lib/x86_64-linux-gnu/$libraryName',
      '/lib/$libraryName',
      '/lib/x86_64-linux-gnu/$libraryName',
      
      // User paths
      '$homeDir/.local/lib/$libraryName',
      '$homeDir/lib/$libraryName',
      
      // Snap paths
      '/snap/digital-library/current/lib/$libraryName',
      
      // Flatpak paths
      '/app/lib/$libraryName',
    ].where((path) => path.isNotEmpty).toList();
  }

  static List<String> _getAndroidSearchPaths(String libraryName) {
    return [
      // Android native library paths
      'lib/arm64-v8a/$libraryName',
      'lib/armeabi-v7a/$libraryName',
      'lib/x86_64/$libraryName',
      'lib/x86/$libraryName',
      
      // APK paths
      '/data/app/*/lib/arm64-v8a/$libraryName',
      '/data/app/*/lib/armeabi-v7a/$libraryName',
      
      // System paths
      '/system/lib64/$libraryName',
      '/system/lib/$libraryName',
      '/vendor/lib64/$libraryName',
      '/vendor/lib/$libraryName',
    ];
  }

  static List<String> _getIOSSearchPaths(String libraryName) {
    return [
      // iOS framework paths
      '../Frameworks/$libraryName',
      'Frameworks/$libraryName',
      
      // Bundle paths
      '$libraryName.framework/$libraryName',
      '../$libraryName.framework/$libraryName',
      
      // System paths (for jailbroken devices)
      '/usr/lib/$libraryName',
      '/Library/Frameworks/$libraryName.framework/$libraryName',
    ];
  }

  /// Check if the native library is available
  static bool isLibraryAvailable() {
    try {
      final library = loadLibrary();
      // Try to lookup a basic function to verify the library is valid
      library.lookup('get_page_count');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get detailed information about library availability
  static LibraryAvailabilityInfo getAvailabilityInfo() {
    final libraryName = _getPlatformLibraryName();
    final searchPaths = _getLibrarySearchPaths(libraryName);
    final availablePaths = <String>[];
    final errors = <String, String>{};

    for (final path in searchPaths) {
      try {
        if (File(path).existsSync()) {
          // Try to load the library
          final library = DynamicLibrary.open(path);
          // Verify it has the expected functions
          library.lookup('render_page');
          library.lookup('extract_text');
          library.lookup('get_page_count');
          availablePaths.add(path);
        }
      } catch (e) {
        if (File(path).existsSync()) {
          errors[path] = e.toString();
        }
      }
    }

    return LibraryAvailabilityInfo(
      libraryName: libraryName,
      searchPaths: searchPaths,
      availablePaths: availablePaths,
      errors: errors,
      isAvailable: availablePaths.isNotEmpty,
    );
  }
}

/// Exception thrown when native library loading fails
class NativeLibraryLoadException implements Exception {
  final String message;
  final List<String> searchPaths;
  final Object? cause;

  const NativeLibraryLoadException(this.message, this.searchPaths, [this.cause]);

  @override
  String toString() {
    return 'NativeLibraryLoadException: $message${cause != null ? ' (Caused by: $cause)' : ''}';
  }
}

/// Information about native library availability
class LibraryAvailabilityInfo {
  final String libraryName;
  final List<String> searchPaths;
  final List<String> availablePaths;
  final Map<String, String> errors;
  final bool isAvailable;

  const LibraryAvailabilityInfo({
    required this.libraryName,
    required this.searchPaths,
    required this.availablePaths,
    required this.errors,
    required this.isAvailable,
  });

  /// Get a detailed report of the availability check
  String getDetailedReport() {
    final buffer = StringBuffer();
    buffer.writeln('Native Library Availability Report');
    buffer.writeln('Library Name: $libraryName');
    buffer.writeln('Platform: ${Platform.operatingSystem}');
    buffer.writeln('Available: $isAvailable');
    buffer.writeln();
    
    if (availablePaths.isNotEmpty) {
      buffer.writeln('Available Paths:');
      for (final path in availablePaths) {
        buffer.writeln('  ✓ $path');
      }
      buffer.writeln();
    }
    
    if (errors.isNotEmpty) {
      buffer.writeln('Errors:');
      for (final entry in errors.entries) {
        buffer.writeln('  ✗ ${entry.key}: ${entry.value}');
      }
      buffer.writeln();
    }
    
    buffer.writeln('Search Paths:');
    for (final path in searchPaths) {
      final exists = File(path).existsSync();
      final status = availablePaths.contains(path) ? '✓' : 
                    errors.containsKey(path) ? '✗' : 
                    exists ? '?' : '○';
      buffer.writeln('  $status $path');
    }
    
    return buffer.toString();
  }

  @override
  String toString() {
    return 'LibraryAvailabilityInfo(libraryName: $libraryName, isAvailable: $isAvailable, availablePaths: ${availablePaths.length}, errors: ${errors.length})';
  }
}