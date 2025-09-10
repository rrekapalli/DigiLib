import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ui/reader_settings.dart';
import '../models/ui/reader_state.dart';
import '../providers/reader_provider.dart';
import '../services/page_rendering_service.dart';
import 'find_in_document.dart';
import 'annotation_toolbar.dart';

/// Page viewer widget for displaying document pages with zoom, pan, and navigation
class PageViewer extends ConsumerStatefulWidget {
  final String documentId;
  final VoidCallback? onPageChanged;
  final VoidCallback? onZoomChanged;
  final VoidCallback? onError;
  final bool enableTextSelection;
  final bool enableAnnotations;
  final bool showFindBar;

  const PageViewer({
    super.key,
    required this.documentId,
    this.onPageChanged,
    this.onZoomChanged,
    this.onError,
    this.enableTextSelection = true,
    this.enableAnnotations = true,
    this.showFindBar = false,
  });

  @override
  ConsumerState<PageViewer> createState() => _PageViewerState();
}

class _PageViewerState extends ConsumerState<PageViewer>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late TransformationController _transformationController;
  late AnimationController _animationController;

  // Gesture handling
  TapDownDetails? _doubleTapDetails;

  // Text selection and search
  bool _showFindBar = false;
  List<SearchMatch> _searchMatches = [];
  int? _selectedMatchIndex;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Listen to transformation changes
    _transformationController.addListener(_onTransformationChanged);

    // Initialize find bar state
    _showFindBar = widget.showFindBar;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    final matrix = _transformationController.value;
    final scale = matrix.getMaxScaleOnAxis();

    // Update zoom level in provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(readerStateProvider(widget.documentId).notifier)
          .updateZoom(scale);
    });

    widget.onZoomChanged?.call();
  }

  void _onPageChanged(int page) {
    // Update current page in provider (1-indexed)
    ref
        .read(readerStateProvider(widget.documentId).notifier)
        .goToPage(page + 1);
    widget.onPageChanged?.call();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_doubleTapDetails == null) return;

    final matrix = _transformationController.value;
    final currentScale = matrix.getMaxScaleOnAxis();

    // Toggle between fit and zoom
    final targetScale = currentScale > 1.5 ? 1.0 : 2.5;
    final position = _doubleTapDetails!.localPosition;

    _animateZoom(targetScale, position);
  }

  void _animateZoom(double targetScale, Offset focalPoint) {
    // Zoom started

    final matrix = _transformationController.value;
    final currentScale = matrix.getMaxScaleOnAxis();

    final animation = Tween<double>(begin: currentScale, end: targetScale)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    animation.addListener(() {
      final scale = animation.value;
      final newMatrix = Matrix4.identity()..scale(scale);

      // Adjust translation to keep focal point centered
      if (targetScale > 1.0) {
        final translation = focalPoint * (1 - scale);
        newMatrix.translate(translation.dx, translation.dy);
      }

      _transformationController.value = newMatrix;
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Zoom ended
      }
    });

    _animationController.forward(from: 0);
  }

  void _toggleFindBar() {
    setState(() {
      _showFindBar = !_showFindBar;
    });
  }

  void _onSearchResults(String query, List<SearchMatch> matches) {
    setState(() {
      _searchMatches = matches;
      _selectedMatchIndex = matches.isNotEmpty ? 0 : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final readerState = ref.watch(readerStateProvider(widget.documentId));
    final settings = ref.watch(readerSettingsProvider);

    return readerState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
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
              onPressed: () {
                ref
                    .read(readerStateProvider(widget.documentId).notifier)
                    .refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (state) => Stack(
        children: [
          _buildPageViewer(context, state, settings),

          // Find bar overlay
          if (_showFindBar)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FindInDocument(
                documentId: widget.documentId,
                onClose: _toggleFindBar,
                onSearchResults: _onSearchResults,
              ),
            ),

          // Annotation toolbar
          if (widget.enableAnnotations && settings.enableAnnotations)
            AnnotationToolbar(
              documentId: widget.documentId,
              currentPage: state.currentPage,
              isVisible: !_showFindBar,
            ),
        ],
      ),
    );
  }

  Widget _buildPageViewer(
    BuildContext context,
    ReaderState state,
    ReaderSettings settings,
  ) {
    if (settings.readingMode == ReadingMode.scroll) {
      return _buildScrollViewer(context, state, settings);
    } else {
      return _buildPaginatedViewer(context, state, settings);
    }
  }

  Widget _buildScrollViewer(
    BuildContext context,
    ReaderState state,
    ReaderSettings settings,
  ) {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.5,
      maxScale: 5.0,
      child: SingleChildScrollView(
        child: Column(
          children: List.generate(state.totalPages, (index) {
            final pageNumber = index + 1;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: _buildPageWidget(pageNumber, settings),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPaginatedViewer(
    BuildContext context,
    ReaderState state,
    ReaderSettings settings,
  ) {
    return GestureDetector(
      onDoubleTapDown: _handleDoubleTapDown,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.5,
        maxScale: 5.0,
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          itemCount: state.totalPages,
          itemBuilder: (context, index) {
            final pageNumber = index + 1;
            return Center(child: _buildPageWidget(pageNumber, settings));
          },
        ),
      ),
    );
  }

  Widget _buildPageWidget(int pageNumber, ReaderSettings settings) {
    final pageRequest = PageRequest(
      documentId: widget.documentId,
      pageNumber: pageNumber,
      dpi: 150,
      format: 'webp',
    );

    return Consumer(
      builder: (context, ref, child) {
        final pageImage = ref.watch(pageImageProvider(pageRequest));

        return pageImage.when(
          loading: () => Container(
            width: double.infinity,
            height: 600,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => Container(
            width: double.infinity,
            height: 600,
            decoration: BoxDecoration(
              color: Colors.red[50],
              border: Border.all(color: Colors.red[300]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Failed to load page $pageNumber',
                  style: TextStyle(color: Colors.red[700]),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    ref.invalidate(pageImageProvider(pageRequest));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (result) => Stack(
            children: [
              _buildPageImage(context, result, pageNumber, settings),

              // Text selection overlay (TODO: Implement properly)
              if (widget.enableTextSelection && settings.enableTextSelection)
                Container(), // Placeholder for text selection
              // Search highlights overlay
              if (_searchMatches.isNotEmpty)
                SearchHighlightOverlay(
                  matches: _searchMatches,
                  currentPageNumber: pageNumber,
                  selectedMatchIndex: _selectedMatchIndex,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageImage(
    BuildContext context,
    PageRenderResult result,
    int pageNumber,
    ReaderSettings settings,
  ) {
    Widget image = Image.memory(
      result.imageData,
      fit: _getBoxFit(settings.pageFitMode),
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: double.infinity,
          height: 600,
          decoration: BoxDecoration(
            color: Colors.red[50],
            border: Border.all(color: Colors.red[300]!),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 48, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                'Invalid image data for page $pageNumber',
                style: TextStyle(color: Colors.red[700]),
              ),
            ],
          ),
        );
      },
    );

    // Apply theme overlay
    if (settings.theme != ReaderTheme.light) {
      image = _applyThemeOverlay(image, settings.theme);
    }

    // Apply brightness
    if (settings.brightness != 1.0) {
      image = _applyBrightness(image, settings.brightness);
    }

    // Add page number overlay if enabled
    if (settings.showPageNumbers) {
      image = Stack(
        children: [
          image,
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$pageNumber',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Add cache indicator if from cache
    if (result.fromCache) {
      image = Stack(
        children: [
          image,
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.cached, size: 16, color: Colors.white),
            ),
          ),
        ],
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 800, maxHeight: 1200),
      child: image,
    );
  }

  BoxFit _getBoxFit(PageFitMode fitMode) {
    switch (fitMode) {
      case PageFitMode.fitWidth:
        return BoxFit.fitWidth;
      case PageFitMode.fitHeight:
        return BoxFit.fitHeight;
      case PageFitMode.fitPage:
        return BoxFit.contain;
      case PageFitMode.actualSize:
        return BoxFit.none;
    }
  }

  Widget _applyThemeOverlay(Widget image, ReaderTheme theme) {
    Color? overlayColor;
    BlendMode blendMode = BlendMode.multiply;

    switch (theme) {
      case ReaderTheme.dark:
        overlayColor = Colors.black.withOpacity(0.3);
        blendMode = BlendMode.darken;
        break;
      case ReaderTheme.sepia:
        overlayColor = const Color(0xFFF4ECD8).withOpacity(0.7);
        blendMode = BlendMode.multiply;
        break;
      case ReaderTheme.light:
      case ReaderTheme.system:
        return image;
    }

    return ColorFiltered(
      colorFilter: ColorFilter.mode(overlayColor, blendMode),
      child: image,
    );
  }

  Widget _applyBrightness(Widget image, double brightness) {
    return ColorFiltered(
      colorFilter: ColorFilter.matrix([
        brightness,
        0,
        0,
        0,
        0,
        0,
        brightness,
        0,
        0,
        0,
        0,
        0,
        brightness,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: image,
    );
  }
}

/// Page navigation controls widget
class PageNavigationControls extends ConsumerWidget {
  final String documentId;
  final VoidCallback? onSettingsPressed;

  const PageNavigationControls({
    super.key,
    required this.documentId,
    this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readerState = ref.watch(readerStateProvider(documentId));

    return readerState.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (state) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Previous page button
            IconButton(
              onPressed: state.isFirstPage
                  ? null
                  : () {
                      ref
                          .read(readerStateProvider(documentId).notifier)
                          .previousPage();
                    },
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous page',
            ),

            // Page indicator
            Expanded(
              child: GestureDetector(
                onTap: () => _showPageJumpDialog(context, ref, state),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${state.currentPage} / ${state.totalPages}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Next page button
            IconButton(
              onPressed: state.isLastPage
                  ? null
                  : () {
                      ref
                          .read(readerStateProvider(documentId).notifier)
                          .nextPage();
                    },
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next page',
            ),

            // Settings button
            if (onSettingsPressed != null)
              IconButton(
                onPressed: onSettingsPressed,
                icon: const Icon(Icons.settings),
                tooltip: 'Reader settings',
              ),
          ],
        ),
      ),
    );
  }

  void _showPageJumpDialog(
    BuildContext context,
    WidgetRef ref,
    ReaderState state,
  ) {
    final controller = TextEditingController(
      text: state.currentPage.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go to Page'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Page number (1-${state.totalPages})',
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            Navigator.of(context).pop();
            _jumpToPage(ref, value, state.totalPages);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _jumpToPage(ref, controller.text, state.totalPages);
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  void _jumpToPage(WidgetRef ref, String pageText, int totalPages) {
    final pageNumber = int.tryParse(pageText);
    if (pageNumber != null && pageNumber >= 1 && pageNumber <= totalPages) {
      ref.read(readerStateProvider(documentId).notifier).goToPage(pageNumber);
    }
  }
}

/// Reading progress indicator widget
class ReadingProgressIndicator extends ConsumerWidget {
  final String documentId;

  const ReadingProgressIndicator({super.key, required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readerState = ref.watch(readerStateProvider(documentId));

    return readerState.when(
      loading: () => const LinearProgressIndicator(value: 0),
      error: (_, __) => const SizedBox.shrink(),
      data: (state) => LinearProgressIndicator(
        value: state.progressPercentage,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
