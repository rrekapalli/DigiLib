import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/entities/library.dart';
import '../../models/entities/folder_node.dart';
import '../../models/entities/document.dart';
import '../../models/ui/document_view_settings.dart';
import '../../models/ui/folder_browser_state.dart';
import '../../providers/folder_browser_provider.dart';
import '../../widgets/folder_breadcrumb_bar.dart';
import '../../widgets/folder_node_tile.dart';
import '../../widgets/folder_context_menu.dart';
import '../../widgets/document_card.dart';
import '../../widgets/document_list_tile.dart';
import '../../widgets/document_detail_view.dart';
import '../../widgets/document_sort_dialog.dart';
import '../../widgets/document_view_mode_dialog.dart';
import '../reader/document_reader_screen.dart';
import '../reader/web_document_reader_screen.dart';

/// Screen for browsing documents in a folder structure
class FolderBrowserScreen extends ConsumerStatefulWidget {
  final Library library;

  const FolderBrowserScreen({super.key, required this.library});

  @override
  ConsumerState<FolderBrowserScreen> createState() =>
      _FolderBrowserScreenState();
}

class _FolderBrowserScreenState extends ConsumerState<FolderBrowserScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  DocumentViewSettings _viewSettings = const DocumentViewSettings();

  @override
  void initState() {
    super.initState();
    // Initialize the folder browser for this library
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(folderBrowserProvider.notifier)
          .initializeLibrary(widget.library.id);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final folderState = ref.watch(folderBrowserProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.library.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (folderState.isMultiSelectMode) ...[
            IconButton(
              onPressed: folderState.selectedPaths.isEmpty
                  ? null
                  : () => _showBulkActionsMenu(context),
              icon: const Icon(Icons.more_vert),
              tooltip: 'Bulk Actions',
            ),
            IconButton(
              onPressed: () =>
                  ref.read(folderBrowserProvider.notifier).clearSelection(),
              icon: const Icon(Icons.clear),
              tooltip: 'Clear Selection',
            ),
            IconButton(
              onPressed: () => ref
                  .read(folderBrowserProvider.notifier)
                  .toggleMultiSelectMode(),
              icon: const Icon(Icons.close),
              tooltip: 'Exit Multi-Select',
            ),
          ] else ...[
            IconButton(
              onPressed: () => _toggleSearch(),
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              tooltip: _isSearching ? 'Close Search' : 'Search',
            ),
            IconButton(
              onPressed: () =>
                  ref.read(folderBrowserProvider.notifier).refresh(),
              icon: folderState.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onSurface,
                      ),
                    )
                  : const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'multi_select',
                  child: ListTile(
                    leading: Icon(Icons.checklist),
                    title: Text('Multi-Select'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'sort',
                  child: ListTile(
                    leading: Icon(Icons.sort),
                    title: Text('Sort Options'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'view_mode',
                  child: ListTile(
                    leading: Icon(Icons.view_module),
                    title: Text('View Mode'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ],
        bottom: _isSearching ? _buildSearchBar() : null,
      ),
      body: Column(
        children: [
          // Breadcrumb navigation
          if (!_isSearching)
            FolderBreadcrumbBar(
              breadcrumbs: folderState.breadcrumbs,
              onBreadcrumbTap: (path) => ref
                  .read(folderBrowserProvider.notifier)
                  .navigateToBreadcrumb(path),
            ),

          // Multi-select toolbar
          if (folderState.isMultiSelectMode)
            _buildMultiSelectToolbar(folderState),

          // Main content
          Expanded(child: _buildContent(folderState)),
        ],
      ),
      floatingActionButton:
          folderState.isMultiSelectMode && folderState.selectedPaths.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showBulkActionsMenu(context),
              icon: const Icon(Icons.edit),
              label: Text('${folderState.selectedPaths.length} Selected'),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildSearchBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search documents...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      ref
                          .read(folderBrowserProvider.notifier)
                          .searchInLibrary('');
                    },
                    icon: const Icon(Icons.clear),
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          onChanged: (query) {
            ref.read(folderBrowserProvider.notifier).searchInLibrary(query);
          },
          onSubmitted: (query) {
            ref.read(folderBrowserProvider.notifier).searchInLibrary(query);
          },
        ),
      ),
    );
  }

  Widget _buildMultiSelectToolbar(FolderBrowserState state) {
    final notifier = ref.read(folderBrowserProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: notifier.isAllSelected,
            tristate: true,
            onChanged: (value) {
              if (notifier.isAllSelected) {
                notifier.clearSelection();
              } else {
                notifier.selectAll();
              }
            },
          ),
          const SizedBox(width: 8),
          Text(
            '${state.selectedPaths.length} of ${state.currentNodes.length} selected',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          TextButton(
            onPressed: () => notifier.selectAll(),
            child: const Text('Select All'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(FolderBrowserState state) {
    if (state.isLoading && state.currentNodes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading folder contents...'),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading folder',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () =>
                  ref.read(folderBrowserProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.currentNodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 80,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              _isSearching ? 'No Results Found' : 'Empty Folder',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _isSearching
                  ? 'Try adjusting your search terms.'
                  : 'This folder doesn\'t contain any documents or subfolders.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(folderBrowserProvider.notifier).refresh(),
      child: _buildContentView(state),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
    });

    if (!_isSearching) {
      _searchController.clear();
      ref.read(folderBrowserProvider.notifier).searchInLibrary('');
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'multi_select':
        ref.read(folderBrowserProvider.notifier).toggleMultiSelectMode();
        break;
      case 'sort':
        _showSortOptions();
        break;
      case 'view_mode':
        _showViewModeOptions();
        break;
    }
  }

  void _handleNodeTap(FolderNode node) {
    final notifier = ref.read(folderBrowserProvider.notifier);

    if (ref.read(folderBrowserProvider).isMultiSelectMode) {
      notifier.toggleNodeSelection(node.path);
    } else if (node.isFolder) {
      notifier.navigateToFolder(node.path);
    } else {
      // Open document
      _openDocument(node.document!);
    }
  }

  void _handleNodeLongPress(FolderNode node) {
    if (!ref.read(folderBrowserProvider).isMultiSelectMode) {
      ref.read(folderBrowserProvider.notifier).toggleMultiSelectMode();
    }
    ref.read(folderBrowserProvider.notifier).toggleNodeSelection(node.path);
  }

  void _openDocument(Document document) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocumentDetailView(
          document: document,
          onOpen: () => _openDocumentReader(document),
          onEdit: () => _editDocument(document),
          onShare: () => _shareDocument(document),
          onDelete: () => _deleteDocument(document),
          onAddTag: () => _addTagToDocument(document),
        ),
      ),
    );
  }

  void _openDocumentReader(Document document) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => kIsWeb
            ? WebDocumentReaderScreen(documentId: document.id)
            : DocumentReaderScreen(documentId: document.id),
      ),
    );
  }

  void _editDocument(Document document) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Edit ${document.title ?? document.filename} - To be implemented',
        ),
      ),
    );
  }

  void _shareDocument(Document document) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Share ${document.title ?? document.filename} - To be implemented',
        ),
      ),
    );
  }

  void _deleteDocument(Document document) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Delete ${document.title ?? document.filename} - To be implemented',
        ),
      ),
    );
  }

  void _addTagToDocument(Document document) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Add tag to ${document.title ?? document.filename} - To be implemented',
        ),
      ),
    );
  }

  void _showNodeContextMenu(BuildContext context, FolderNode node) {
    showModalBottomSheet(
      context: context,
      builder: (context) => FolderContextMenu(
        node: node,
        onRename: () => _renameNode(node),
        onDelete: () => _deleteNode(node),
        onShare: () => _shareNode(node),
        onAddTag: () => _addTagToNode(node),
        onViewDetails: () => _viewNodeDetails(node),
      ),
    );
  }

  void _showBulkActionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename'),
            onTap: () {
              Navigator.pop(context);
              _bulkRename();
            },
          ),
          ListTile(
            leading: const Icon(Icons.label),
            title: const Text('Add Tags'),
            onTap: () {
              Navigator.pop(context);
              _bulkAddTags();
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () {
              Navigator.pop(context);
              _bulkShare();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete'),
            onTap: () {
              Navigator.pop(context);
              _bulkDelete();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContentView(FolderBrowserState state) {
    // Separate folders and documents
    final folders = state.currentNodes.where((node) => node.isFolder).toList();
    final documents = state.currentNodes
        .where((node) => !node.isFolder)
        .toList();

    // Sort documents based on current settings
    _sortDocuments(documents);

    if (_viewSettings.viewMode == DocumentViewMode.grid) {
      return _buildGridView(state, folders, documents);
    } else {
      return _buildListView(state, folders, documents);
    }
  }

  Widget _buildListView(
    FolderBrowserState state,
    List<FolderNode> folders,
    List<FolderNode> documents,
  ) {
    final allItems = [...folders, ...documents];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        final node = allItems[index];
        final isSelected = state.selectedPaths.contains(node.path);

        if (node.isFolder) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FolderNodeTile(
              node: node,
              isSelected: isSelected,
              isMultiSelectMode: state.isMultiSelectMode,
              onTap: () => _handleNodeTap(node),
              onLongPress: () => _handleNodeLongPress(node),
              onSelectionChanged: (selected) {
                if (selected) {
                  ref
                      .read(folderBrowserProvider.notifier)
                      .toggleNodeSelection(node.path);
                }
              },
              onContextMenu: () => _showNodeContextMenu(context, node),
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DocumentListTile(
              document: node.document!,
              isSelected: isSelected,
              isMultiSelectMode: state.isMultiSelectMode,
              onTap: () => _handleNodeTap(node),
              onLongPress: () => _handleNodeLongPress(node),
              onSelectionChanged: (selected) {
                if (selected) {
                  ref
                      .read(folderBrowserProvider.notifier)
                      .toggleNodeSelection(node.path);
                }
              },
              onContextMenu: () => _showNodeContextMenu(context, node),
              showThumbnail: _viewSettings.showThumbnails,
              showMetadata: _viewSettings.showMetadata,
            ),
          );
        }
      },
    );
  }

  Widget _buildGridView(
    FolderBrowserState state,
    List<FolderNode> folders,
    List<FolderNode> documents,
  ) {
    return CustomScrollView(
      slivers: [
        // Folders section (always in list view)
        if (folders.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final node = folders[index];
                final isSelected = state.selectedPaths.contains(node.path);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FolderNodeTile(
                    node: node,
                    isSelected: isSelected,
                    isMultiSelectMode: state.isMultiSelectMode,
                    onTap: () => _handleNodeTap(node),
                    onLongPress: () => _handleNodeLongPress(node),
                    onSelectionChanged: (selected) {
                      if (selected) {
                        ref
                            .read(folderBrowserProvider.notifier)
                            .toggleNodeSelection(node.path);
                      }
                    },
                    onContextMenu: () => _showNodeContextMenu(context, node),
                  ),
                );
              }, childCount: folders.length),
            ),
          ),

        // Documents section (in grid view)
        if (documents.isNotEmpty)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              folders.isNotEmpty ? 8 : 16,
              16,
              16,
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _viewSettings.gridColumns,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final node = documents[index];
                final isSelected = state.selectedPaths.contains(node.path);

                return DocumentCard(
                  document: node.document!,
                  isSelected: isSelected,
                  isMultiSelectMode: state.isMultiSelectMode,
                  onTap: () => _handleNodeTap(node),
                  onLongPress: () => _handleNodeLongPress(node),
                  onSelectionChanged: (selected) {
                    if (selected) {
                      ref
                          .read(folderBrowserProvider.notifier)
                          .toggleNodeSelection(node.path);
                    }
                  },
                  onContextMenu: () => _showNodeContextMenu(context, node),
                  showThumbnail: _viewSettings.showThumbnails,
                  showMetadata: _viewSettings.showMetadata,
                );
              }, childCount: documents.length),
            ),
          ),
      ],
    );
  }

  void _sortDocuments(List<FolderNode> documents) {
    documents.sort((a, b) {
      final docA = a.document!;
      final docB = b.document!;
      int comparison = 0;

      switch (_viewSettings.sortBy) {
        case DocumentSortBy.name:
          final nameA = docA.title ?? docA.filename ?? '';
          final nameB = docB.title ?? docB.filename ?? '';
          comparison = nameA.toLowerCase().compareTo(nameB.toLowerCase());
          break;
        case DocumentSortBy.author:
          final authorA = docA.author ?? '';
          final authorB = docB.author ?? '';
          comparison = authorA.toLowerCase().compareTo(authorB.toLowerCase());
          break;
        case DocumentSortBy.dateCreated:
          comparison = docA.createdAt.compareTo(docB.createdAt);
          break;
        case DocumentSortBy.dateModified:
          comparison = docA.updatedAt.compareTo(docB.updatedAt);
          break;
        case DocumentSortBy.size:
          final sizeA = docA.sizeBytes ?? 0;
          final sizeB = docB.sizeBytes ?? 0;
          comparison = sizeA.compareTo(sizeB);
          break;
        case DocumentSortBy.pageCount:
          final pagesA = docA.pageCount ?? 0;
          final pagesB = docB.pageCount ?? 0;
          comparison = pagesA.compareTo(pagesB);
          break;
      }

      return _viewSettings.ascending ? comparison : -comparison;
    });
  }

  void _showSortOptions() {
    showDialog(
      context: context,
      builder: (context) => DocumentSortDialog(
        currentSettings: _viewSettings,
        onSettingsChanged: (settings) {
          setState(() {
            _viewSettings = settings;
          });
        },
      ),
    );
  }

  void _showViewModeOptions() {
    showDialog(
      context: context,
      builder: (context) => DocumentViewModeDialog(
        currentSettings: _viewSettings,
        onSettingsChanged: (settings) {
          setState(() {
            _viewSettings = settings;
          });
        },
      ),
    );
  }

  // Placeholder methods for actions (to be implemented in future tasks)
  void _renameNode(FolderNode node) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rename ${node.name} - To be implemented')),
    );
  }

  void _deleteNode(FolderNode node) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Delete ${node.name} - To be implemented')),
    );
  }

  void _shareNode(FolderNode node) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share ${node.name} - To be implemented')),
    );
  }

  void _addTagToNode(FolderNode node) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Add tag to ${node.name} - To be implemented')),
    );
  }

  void _viewNodeDetails(FolderNode node) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('View details for ${node.name} - To be implemented'),
      ),
    );
  }

  void _bulkRename() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk rename - To be implemented')),
    );
  }

  void _bulkAddTags() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk add tags - To be implemented')),
    );
  }

  void _bulkShare() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk share - To be implemented')),
    );
  }

  void _bulkDelete() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk delete - To be implemented')),
    );
  }
}
