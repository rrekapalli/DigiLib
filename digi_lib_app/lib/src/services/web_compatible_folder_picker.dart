import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

/// Web-compatible folder picker that handles platform differences
class WebCompatibleFolderPicker {
  /// Pick a directory path. On web, shows an alternative UI since directory picking is not supported.
  static Future<String?> pickDirectory({
    String? dialogTitle,
    BuildContext? context,
  }) async {
    if (kIsWeb) {
      // On web, directory picking is not supported
      if (context != null) {
        return await _showWebFolderAlternative(context, dialogTitle);
      } else {
        debugPrint('⚠️ Directory selection not supported on web platform');
        return null;
      }
    } else {
      // On desktop/mobile platforms, use file_picker
      try {
        return await FilePicker.platform.getDirectoryPath(
          dialogTitle: dialogTitle ?? 'Select Library Folder',
        );
      } catch (e) {
        debugPrint('Error picking folder: $e');
        return null;
      }
    }
  }

  /// Shows alternative options for web users since folder picking isn't available
  static Future<String?> _showWebFolderAlternative(
    BuildContext context,
    String? dialogTitle,
  ) async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(dialogTitle ?? 'Library Location'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Folder selection is not available in web browsers for security reasons.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('Web-based library options:'),
              SizedBox(height: 8),
              Text('• Use cloud storage (Google Drive, Dropbox)'),
              Text('• Upload files individually'),
              Text('• Use the web API directly'),
              SizedBox(height: 16),
              Text(
                'For full folder support, please use the desktop version of this app.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop('web-upload'),
              child: const Text('Use File Upload Instead'),
            ),
          ],
        );
      },
    );
  }

  /// Pick files instead of directories (for web compatibility)
  static Future<List<PlatformFile>?> pickFiles({
    String? dialogTitle,
    List<String>? allowedExtensions,
    bool allowMultiple = true,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: dialogTitle ?? 'Select Files',
        allowedExtensions: allowedExtensions ?? ['pdf', 'epub', 'docx', 'txt'],
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowMultiple: allowMultiple,
        withData: kIsWeb, // Load file data for web
        withReadStream: !kIsWeb, // Use streams for desktop
      );

      return result?.files;
    } catch (e) {
      debugPrint('Error picking files: $e');
      return null;
    }
  }
}
