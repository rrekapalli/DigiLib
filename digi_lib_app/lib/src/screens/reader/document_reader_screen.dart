import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/entities/document.dart';
import '../../models/ui/reader_settings.dart';
import '../../providers/reader_provider.dart';
import '../../widgets/page_viewer.dart';
import '../../widgets/reader_settings_panel.dart';
import '../../widgets/reader_toolbar.dart';
import '../../widgets/permission_restricted_widget.dart';
import '../../widgets/shared_document_overlay.dart';

/// Main document reader screen with full reading interface
class DocumentReaderScreen extends ConsumerStatefulWidget {
  final String documentId;
  final String? initialPage;

  const DocumentReaderScreen({
    super.key,
    required this.documentId,
    this.initialPage,
  });

  @override
  ConsumerState<DocumentReaderScreen> createState() =>
      _DocumentReaderScreenState();
}

class _DocumentReaderScreenState extends ConsumerState<DocumentReaderScreen>
    with TickerProviderStateMixin {
  bool _isFullscreen = false;
  bool _showControls = true;
  bool _showSettingsPanel = false;
  bool _showFindBar = false;
  bool _showCollaborationPanel = false;

  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsAnimation;

  @override
  void initState() {
    super.initState();

    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _controlsAnimation = CurvedAnimation(
      parent: _controlsAnimationController,
      curve: Curves.easeInOut,
    );

    _controlsAnimationController.forward();

    // Initialize reader if initial page is provided
    if (widget.initialPage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final pageNumber = int.tryParse(widget.initialPage!);
        if (pageNumber != null) {
          ref
              .read(readerStateProvider(widget.documentId).notifier)
              .goToPage(pageNumber);
        }
      });
    }
  }

  @override
  void dispose() {
    _controlsAnimationController.dispose();
    super.dispose();
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _controlsAnimationController.forward();
    } else {
      _controlsAnimationController.reverse();
    }
  }

  void _toggleSettingsPanel() {
    setState(() {
      _showSettingsPanel = !_showSettingsPanel;
    });
  }

  void _toggleFindBar() {
    setState(() {
      _showFindBar = !_showFindBar;
    });
  }

  void _toggleCollaborationPanel() {
    setState(() {
      _showCollaborationPanel = !_showCollaborationPanel;
    });
  }

  void _onPageChanged() {
    // Auto-hide controls after page change in fullscreen
    if (_isFullscreen && _showControls) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isFullscreen) {
          _toggleControls();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final document = ref.watch(currentDocumentProvider(widget.documentId));
    final settings = ref.watch(readerSettingsProvider);

    return Scaffold(
      backgroundColor: _getBackgroundColor(settings.theme),
      body: document.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _buildErrorView(error),
        data: (doc) => _buildReaderView(doc, settings),
      ),
    );
  }

  Widget _buildErrorView(Object error) {
    return Center(
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
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildReaderView(Document document, ReaderSettings settings) {
    return Stack(
      children: [
        // Main reader content
        Column(
          children: [
            // Top toolbar
            if (!_isFullscreen)
              AnimatedBuilder(
                animation: _controlsAnimation,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, -60 * (1 - _controlsAnimation.value)),
                  child: Opacity(
                    opacity: _controlsAnimation.value,
                    child: ReaderToolbar(
                      document: document,
                      onFullscreenToggle: _toggleFullscreen,
                      onSettingsToggle: _toggleSettingsPanel,
                      onSearchPressed: _toggleFindBar,
                      onCollaborationPressed: _toggleCollaborationPanel,
                      isFullscreen: _isFullscreen,
                    ),
                  ),
                ),
              ),

            // Collaboration status bar
            if (!_isFullscreen)
              CollaborationStatusBar(
                subjectId: document.id,
                userEmail: 'user@example.com', // TODO: Get from auth provider
              ),

            // Progress indicator
            if (_showControls || !_isFullscreen)
              AnimatedBuilder(
                animation: _controlsAnimation,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, -4 * (1 - _controlsAnimation.value)),
                  child: Opacity(
                    opacity: _controlsAnimation.value,
                    child: ReadingProgressIndicator(
                      documentId: widget.documentId,
                    ),
                  ),
                ),
              ),

            // Page viewer
            Expanded(
              child: GestureDetector(
                onTap: _isFullscreen ? _toggleControls : null,
                child: PageViewer(
                  documentId: widget.documentId,
                  showFindBar: _showFindBar,
                  onPageChanged: _onPageChanged,
                  onZoomChanged: () {
                    // Handle zoom changes if needed
                  },
                  onError: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to load page'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Bottom navigation controls
            if (_showControls || !_isFullscreen)
              AnimatedBuilder(
                animation: _controlsAnimation,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, 60 * (1 - _controlsAnimation.value)),
                  child: Opacity(
                    opacity: _controlsAnimation.value,
                    child: PageNavigationControls(
                      documentId: widget.documentId,
                      onSettingsPressed: _toggleSettingsPanel,
                    ),
                  ),
                ),
              ),
          ],
        ),

        // Settings panel overlay
        if (_showSettingsPanel)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: ReaderSettingsPanel(onClose: _toggleSettingsPanel),
          ),

        // Collaboration panel overlay
        if (_showCollaborationPanel)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: SharedDocumentOverlay(
              documentId: document.id,
              documentTitle:
                  document.title ?? document.filename ?? 'Unknown Document',
              userEmail: 'user@example.com', // TODO: Get from auth provider
              onClose: _toggleCollaborationPanel,
            ),
          ),

        // Fullscreen overlay controls
        if (_isFullscreen && _showControls)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: AnimatedBuilder(
              animation: _controlsAnimation,
              builder: (context, child) => Opacity(
                opacity: _controlsAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _toggleSettingsPanel,
                        icon: const Icon(Icons.settings, color: Colors.white),
                        tooltip: 'Settings',
                      ),
                      IconButton(
                        onPressed: _toggleCollaborationPanel,
                        icon: const Icon(Icons.people, color: Colors.white),
                        tooltip: 'Collaboration',
                      ),
                      IconButton(
                        onPressed: _toggleFullscreen,
                        icon: const Icon(
                          Icons.fullscreen_exit,
                          color: Colors.white,
                        ),
                        tooltip: 'Exit fullscreen',
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _getBackgroundColor(ReaderTheme theme) {
    switch (theme) {
      case ReaderTheme.dark:
        return const Color(0xFF121212);
      case ReaderTheme.sepia:
        return const Color(0xFFF4ECD8);
      case ReaderTheme.light:
        return Colors.white;
      case ReaderTheme.system:
        return Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF121212)
            : Colors.white;
    }
  }
}

/// Compact reader screen for embedded use
class CompactReaderScreen extends ConsumerWidget {
  final String documentId;
  final int? initialPage;
  final double? height;

  const CompactReaderScreen({
    super.key,
    required this.documentId,
    this.initialPage,
    this.height,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(readerSettingsProvider);

    // Initialize reader with initial page if provided
    if (initialPage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(readerStateProvider(documentId).notifier)
            .goToPage(initialPage!);
      });
    }

    return Container(
      height: height ?? 600,
      decoration: BoxDecoration(
        color: _getBackgroundColor(settings.theme, context),
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Compact progress indicator
          ReadingProgressIndicator(documentId: documentId),

          // Page viewer
          Expanded(
            child: PageViewer(
              documentId: documentId,
              onError: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to load page'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),

          // Compact navigation controls
          PageNavigationControls(documentId: documentId),
        ],
      ),
    );
  }

  Color _getBackgroundColor(ReaderTheme theme, BuildContext context) {
    switch (theme) {
      case ReaderTheme.dark:
        return const Color(0xFF121212);
      case ReaderTheme.sepia:
        return const Color(0xFFF4ECD8);
      case ReaderTheme.light:
        return Colors.white;
      case ReaderTheme.system:
        return Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF121212)
            : Colors.white;
    }
  }
}
