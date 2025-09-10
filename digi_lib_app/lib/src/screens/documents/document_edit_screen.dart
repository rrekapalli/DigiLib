import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/entities/document.dart';
import '../../models/api/update_document_request.dart';
import '../../providers/document_provider.dart';
import '../../widgets/error_dialog.dart';

/// Screen for editing document metadata
class DocumentEditScreen extends ConsumerStatefulWidget {
  final Document document;

  const DocumentEditScreen({
    super.key,
    required this.document,
  });

  @override
  ConsumerState<DocumentEditScreen> createState() => _DocumentEditScreenState();
}

class _DocumentEditScreenState extends ConsumerState<DocumentEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _renamedNameController = TextEditingController();
  final _isbnController = TextEditingController();
  final _yearController = TextEditingController();
  
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _addListeners();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _renamedNameController.dispose();
    _isbnController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _titleController.text = widget.document.title ?? '';
    _authorController.text = widget.document.author ?? '';
    _renamedNameController.text = widget.document.renamedName ?? '';
    _isbnController.text = widget.document.isbn ?? '';
    _yearController.text = widget.document.yearPublished?.toString() ?? '';
  }

  void _addListeners() {
    _titleController.addListener(_onFieldChanged);
    _authorController.addListener(_onFieldChanged);
    _renamedNameController.addListener(_onFieldChanged);
    _isbnController.addListener(_onFieldChanged);
    _yearController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    final hasChanges = _titleController.text != (widget.document.title ?? '') ||
        _authorController.text != (widget.document.author ?? '') ||
        _renamedNameController.text != (widget.document.renamedName ?? '') ||
        _isbnController.text != (widget.document.isbn ?? '') ||
        _yearController.text != (widget.document.yearPublished?.toString() ?? '');

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasChanges) {
          final shouldPop = await _showDiscardChangesDialog();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Document'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _isLoading ? null : _saveChanges,
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Document info header
                _buildDocumentHeader(context),
                
                const SizedBox(height: 24),
                
                // Editable fields
                _buildEditableFields(context),
                
                const SizedBox(height: 24),
                
                // Read-only system info
                _buildSystemInfo(context),
                
                const SizedBox(height: 32),
                
                // Action buttons
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // File icon
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildFileIcon(context),
            ),
            
            const SizedBox(width: 16),
            
            // File info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.document.filename ?? 'Unknown File',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.document.extension?.toUpperCase() ?? 'DOC'} • ${_formatFileSize(widget.document.sizeBytes)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  if (widget.document.pageCount != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${widget.document.pageCount} pages',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableFields(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Document Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Title field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter document title',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Author field
            TextFormField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: 'Author',
                hintText: 'Enter author name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            
            const SizedBox(height: 16),
            
            // Display name field
            TextFormField(
              controller: _renamedNameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                hintText: 'Custom display name (optional)',
                border: OutlineInputBorder(),
                helperText: 'Override the default title for display purposes',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            
            const SizedBox(height: 16),
            
            // ISBN field
            TextFormField(
              controller: _isbnController,
              decoration: const InputDecoration(
                labelText: 'ISBN',
                hintText: 'Enter ISBN (optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9\-X]')),
              ],
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  // Basic ISBN validation (10 or 13 digits with optional hyphens)
                  final cleanIsbn = value.replaceAll('-', '');
                  if (cleanIsbn.length != 10 && cleanIsbn.length != 13) {
                    return 'ISBN must be 10 or 13 digits';
                  }
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Year published field
            TextFormField(
              controller: _yearController,
              decoration: const InputDecoration(
                labelText: 'Year Published',
                hintText: 'Enter publication year (optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final year = int.tryParse(value);
                  if (year == null) {
                    return 'Enter a valid year';
                  }
                  final currentYear = DateTime.now().year;
                  if (year < 1000 || year > currentYear + 10) {
                    return 'Year must be between 1000 and ${currentYear + 10}';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfo(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow('Created', _formatDateTime(widget.document.createdAt)),
            _buildInfoRow('Modified', _formatDateTime(widget.document.updatedAt)),
            if (widget.document.relativePath != null)
              _buildInfoRow('Path', widget.document.relativePath!),
            if (widget.document.sha256 != null)
              _buildInfoRow('Checksum', '${widget.document.sha256!.substring(0, 16)}...'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FilledButton(
            onPressed: _hasChanges && !_isLoading ? _saveChanges : null,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save Changes'),
          ),
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
    
    return Center(
      child: Icon(
        iconData,
        size: 32,
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<bool> _showDiscardChangesDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = UpdateDocumentRequest(
        title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
        author: _authorController.text.trim().isEmpty ? null : _authorController.text.trim(),
        renamedName: _renamedNameController.text.trim().isEmpty ? null : _renamedNameController.text.trim(),
        isbn: _isbnController.text.trim().isEmpty ? null : _isbnController.text.trim(),
        yearPublished: _yearController.text.trim().isEmpty ? null : int.tryParse(_yearController.text.trim()),
      );

      await ref.read(documentNotifierProvider.notifier).updateDocument(widget.document.id, request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Return the updated document
        final updatedDocument = ref.read(documentNotifierProvider).value;
        Navigator.of(context).pop(updatedDocument);
      }
    } catch (error) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => SimpleErrorDialog(
            title: 'Save Failed',
            message: 'Failed to save changes: ${error.toString()}',
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
}