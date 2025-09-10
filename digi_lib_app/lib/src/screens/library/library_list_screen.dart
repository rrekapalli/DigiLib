import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/library_provider.dart';
import '../../models/entities/library.dart';
import '../../widgets/library_card.dart';
import '../../widgets/add_library_dialog.dart';
import '../../widgets/library_deletion_dialog.dart';
import 'library_configuration_screen.dart';
import 'folder_browser_screen.dart';


/// Screen displaying the list of user's libraries
class LibraryListScreen extends ConsumerWidget {
  const LibraryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Libraries'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _refreshLibraries(ref),
            icon: libraryState.isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onSurface,
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh Libraries',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshLibraries(ref),
        child: _buildBody(context, ref, libraryState),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLibraryDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Library'),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, LibraryState state) {
    if (state.isLoading && state.libraries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading libraries...'),
          ],
        ),
      );
    }

    if (state.error != null && state.libraries.isEmpty) {
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
              'Error loading libraries',
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
              onPressed: () => ref.read(libraryProvider.notifier).retry(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.libraries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Libraries Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first library to get started with organizing your digital documents.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showAddLibraryDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Library'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (state.error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    state.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => ref.read(libraryProvider.notifier).clearError(),
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.libraries.length,
            itemBuilder: (context, index) {
              final library = state.libraries[index];
              final scanProgress = state.scanProgress[library.id];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: LibraryCard(
                  library: library,
                  scanProgress: scanProgress,
                  onTap: () => _openLibrary(context, library),
                  onScan: () => _scanLibrary(ref, library.id),
                  onSettings: () => _showLibrarySettings(context, ref, library),
                  onDelete: () => _showDeleteConfirmation(context, ref, library),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _refreshLibraries(WidgetRef ref) async {
    await ref.read(libraryProvider.notifier).refreshLibraries();
  }

  void _showAddLibraryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const AddLibraryDialog(),
    );
  }



  void _openLibrary(BuildContext context, Library library) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FolderBrowserScreen(library: library),
      ),
    );
  }

  Future<void> _scanLibrary(WidgetRef ref, String libraryId) async {
    try {
      await ref.read(libraryProvider.notifier).scanLibrary(libraryId);
    } catch (e) {
      // Error is handled by the provider and shown in the UI
    }
  }

  void _showLibrarySettings(BuildContext context, WidgetRef ref, Library library) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LibraryConfigurationScreen(
          library: library,
          libraryType: library.type,
          libraryName: library.name,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Library library) {
    showDialog(
      context: context,
      builder: (context) => LibraryDeletionDialog(
        library: library,
      ),
    );
  }


}