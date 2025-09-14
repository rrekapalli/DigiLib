import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/entities/document.dart';
import '../../providers/document_provider.dart';
import '../../widgets/document_detail_view.dart';
import '../../widgets/error_dialog.dart';
import '../../widgets/loading_states.dart';
import 'document_edit_screen.dart';
import '../reader/document_reader_screen.dart';
import '../reader/web_document_reader_screen.dart';

/// Screen for displaying detailed document information
class DocumentDetailScreen extends ConsumerStatefulWidget {
  final String documentId;
  final Document? initialDocument;

  const DocumentDetailScreen({
    super.key,
    required this.documentId,
    this.initialDocument,
  });

  @override
  ConsumerState<DocumentDetailScreen> createState() =>
      _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load document if not provided initially
    if (widget.initialDocument == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(documentNotifierProvider.notifier)
            .loadDocument(widget.documentId);
      });
    } else {
      // Set initial document in provider
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(documentNotifierProvider.notifier)
            .setDocument(widget.initialDocument);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final documentState = ref.watch(documentNotifierProvider);

    return documentState.when(
      data: (document) {
        if (document == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Document Not Found')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Document not found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return DocumentDetailView(
          document: document,
          onEdit: () => _navigateToEdit(context, document),
          onShare: () => _shareDocument(context, document),
          onDelete: () => _deleteDocument(context, document),
          onAddTag: () => _addTags(context, document),
          onOpen: () => _openDocument(context, document),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: LoadingSpinner()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load document',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _retryLoad(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToEdit(BuildContext context, Document document) async {
    final result = await Navigator.of(context).push<Document>(
      MaterialPageRoute(
        builder: (context) => DocumentEditScreen(document: document),
      ),
    );

    // If document was updated, refresh the current view
    if (result != null) {
      ref.read(documentNotifierProvider.notifier).refresh();
    }
  }

  void _shareDocument(BuildContext context, Document document) {
    // TODO: Implement document sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document sharing not implemented yet')),
    );
  }

  void _deleteDocument(BuildContext context, Document document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this document?'),
            const SizedBox(height: 16),
            Text(
              document.title ?? document.filename ?? 'Unknown Document',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(documentNotifierProvider.notifier)
            .deleteDocument(document.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back after successful deletion
          Navigator.of(context).pop();
        }
      } catch (error) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => SimpleErrorDialog(
              title: 'Delete Failed',
              message: 'Failed to delete document: ${error.toString()}',
            ),
          );
        }
      }
    }
  }

  void _addTags(BuildContext context, Document document) {
    // TODO: Implement tag management
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tag management not implemented yet')),
    );
  }

  void _openDocument(BuildContext context, Document document) {
    // Use web-compatible reader for web platform, native reader for others
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => kIsWeb
            ? WebDocumentReaderScreen(documentId: document.id)
            : DocumentReaderScreen(documentId: document.id),
      ),
    );
  }

  void _retryLoad() {
    ref.read(documentNotifierProvider.notifier).loadDocument(widget.documentId);
  }
}
