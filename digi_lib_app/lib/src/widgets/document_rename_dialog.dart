import 'package:flutter/material.dart';
import '../models/entities/document.dart';

/// Dialog for renaming documents
class DocumentRenameDialog extends StatefulWidget {
  final Document document;
  final Function(String newName)? onRename;

  const DocumentRenameDialog({
    super.key,
    required this.document,
    this.onRename,
  });

  @override
  State<DocumentRenameDialog> createState() => _DocumentRenameDialogState();
}

class _DocumentRenameDialogState extends State<DocumentRenameDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current display name or title
    _nameController.text = widget.document.renamedName ?? 
                          widget.document.title ?? 
                          widget.document.filename ?? 
                          '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('Rename Document'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildFileIcon(context),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.document.filename ?? 'Unknown File',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.document.extension?.toUpperCase() ?? 'DOC'} • ${_formatFileSize(widget.document.sizeBytes)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Name input field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                hintText: 'Enter new display name',
                border: OutlineInputBorder(),
                helperText: 'This will change how the document appears in your library',
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name cannot be empty';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 8),
            
            // Info text
            Text(
              'Note: This only changes the display name. The original filename will remain unchanged.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _handleRename,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Rename'),
        ),
      ],
    );
  }

  Widget _buildFileIcon(BuildContext context) {
    final extension = widget.document.extension?.toLowerCase() ?? '';
    
    IconData iconData;
    Color iconColor;
    
    switch (extension) {
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case 'epub':
        iconData = Icons.menu_book;
        iconColor = Colors.green;
        break;
      case 'docx':
      case 'doc':
        iconData = Icons.description;
        iconColor = Colors.blue;
        break;
      case 'txt':
        iconData = Icons.text_snippet;
        iconColor = Colors.grey;
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    }
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        iconData,
        size: 24,
        color: iconColor,
      ),
    );
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return 'Unknown size';
    
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _handleRename() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newName = _nameController.text.trim();
    final currentName = widget.document.renamedName ?? 
                       widget.document.title ?? 
                       widget.document.filename ?? 
                       '';

    // Check if name actually changed
    if (newName == currentName) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Call the rename callback
      widget.onRename?.call(newName);
      
      if (mounted) {
        Navigator.of(context).pop(newName);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to rename document: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Show the document rename dialog
  static Future<String?> show(BuildContext context, Document document) {
    return showDialog<String>(
      context: context,
      builder: (context) => DocumentRenameDialog(document: document),
    );
  }
}