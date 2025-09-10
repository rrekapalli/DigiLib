import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ui/reader_settings.dart';
import '../providers/reader_provider.dart';

/// Settings panel for reader customization
class ReaderSettingsPanel extends ConsumerWidget {
  final VoidCallback? onClose;

  const ReaderSettingsPanel({
    super.key,
    this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(readerSettingsProvider);

    return Container(
      width: 320,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Reader Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  tooltip: 'Close settings',
                ),
              ],
            ),
          ),
          
          // Settings content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reading mode section
                  _buildSectionHeader(context, 'Reading Mode'),
                  _buildReadingModeSelector(context, ref, settings),
                  const SizedBox(height: 24),
                  
                  // Display settings section
                  _buildSectionHeader(context, 'Display'),
                  _buildPageFitSelector(context, ref, settings),
                  const SizedBox(height: 16),
                  _buildThemeSelector(context, ref, settings),
                  const SizedBox(height: 16),
                  _buildBrightnessSlider(context, ref, settings),
                  const SizedBox(height: 16),
                  _buildZoomSlider(context, ref, settings),
                  const SizedBox(height: 24),
                  
                  // Interface settings section
                  _buildSectionHeader(context, 'Interface'),
                  _buildToggleSettings(context, ref, settings),
                  const SizedBox(height: 24),
                  
                  // Performance settings section
                  _buildSectionHeader(context, 'Performance'),
                  _buildPerformanceSettings(context, ref, settings),
                  const SizedBox(height: 24),
                  
                  // Reset button
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(readerSettingsProvider.notifier).resetToDefaults();
                      },
                      child: const Text('Reset to Defaults'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildReadingModeSelector(BuildContext context, WidgetRef ref, ReaderSettings settings) {
    return Column(
      children: [
        RadioListTile<ReadingMode>(
          title: const Text('Scroll Mode'),
          subtitle: const Text('Continuous scrolling through pages'),
          value: ReadingMode.scroll,
          groupValue: settings.readingMode,
          onChanged: (mode) {
            if (mode != null) {
              ref.read(readerSettingsProvider.notifier).updateReadingMode(mode);
            }
          },
        ),
        RadioListTile<ReadingMode>(
          title: const Text('Page Mode'),
          subtitle: const Text('Navigate page by page'),
          value: ReadingMode.paginated,
          groupValue: settings.readingMode,
          onChanged: (mode) {
            if (mode != null) {
              ref.read(readerSettingsProvider.notifier).updateReadingMode(mode);
            }
          },
        ),
      ],
    );
  }

  Widget _buildPageFitSelector(BuildContext context, WidgetRef ref, ReaderSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Page Fit',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: PageFitMode.values.map((mode) {
            final isSelected = settings.pageFitMode == mode;
            return FilterChip(
              label: Text(_getPageFitLabel(mode)),
              selected: isSelected,
              onSelected: (_) {
                ref.read(readerSettingsProvider.notifier).updatePageFitMode(mode);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getPageFitLabel(PageFitMode mode) {
    switch (mode) {
      case PageFitMode.fitWidth:
        return 'Fit Width';
      case PageFitMode.fitHeight:
        return 'Fit Height';
      case PageFitMode.fitPage:
        return 'Fit Page';
      case PageFitMode.actualSize:
        return 'Actual Size';
    }
  }

  Widget _buildThemeSelector(BuildContext context, WidgetRef ref, ReaderSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ReaderTheme.values.map((theme) {
            final isSelected = settings.theme == theme;
            return FilterChip(
              label: Text(_getThemeLabel(theme)),
              selected: isSelected,
              onSelected: (_) {
                ref.read(readerSettingsProvider.notifier).updateTheme(theme);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getThemeLabel(ReaderTheme theme) {
    switch (theme) {
      case ReaderTheme.light:
        return 'Light';
      case ReaderTheme.dark:
        return 'Dark';
      case ReaderTheme.sepia:
        return 'Sepia';
      case ReaderTheme.system:
        return 'System';
    }
  }

  Widget _buildBrightnessSlider(BuildContext context, WidgetRef ref, ReaderSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Brightness',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '${(settings.brightness * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        Slider(
          value: settings.brightness,
          min: 0.1,
          max: 1.0,
          divisions: 18,
          onChanged: (value) {
            ref.read(readerSettingsProvider.notifier).updateBrightness(value);
          },
        ),
      ],
    );
  }

  Widget _buildZoomSlider(BuildContext context, WidgetRef ref, ReaderSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Zoom',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '${(settings.zoom * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        Slider(
          value: settings.zoom,
          min: 0.5,
          max: 3.0,
          divisions: 25,
          onChanged: (value) {
            ref.read(readerSettingsProvider.notifier).updateZoom(value);
          },
        ),
      ],
    );
  }

  Widget _buildToggleSettings(BuildContext context, WidgetRef ref, ReaderSettings settings) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Show Page Numbers'),
          subtitle: const Text('Display page numbers on pages'),
          value: settings.showPageNumbers,
          onChanged: (_) {
            ref.read(readerSettingsProvider.notifier).togglePageNumbers();
          },
        ),
        SwitchListTile(
          title: const Text('Text Selection'),
          subtitle: const Text('Enable text selection and copying'),
          value: settings.enableTextSelection,
          onChanged: (_) {
            ref.read(readerSettingsProvider.notifier).toggleTextSelection();
          },
        ),
        SwitchListTile(
          title: const Text('Annotations'),
          subtitle: const Text('Enable bookmarks and comments'),
          value: settings.enableAnnotations,
          onChanged: (_) {
            ref.read(readerSettingsProvider.notifier).toggleAnnotations();
          },
        ),
        SwitchListTile(
          title: const Text('Auto-save Progress'),
          subtitle: const Text('Automatically save reading position'),
          value: settings.autoSaveProgress,
          onChanged: (_) {
            // TODO: Implement auto-save toggle
          },
        ),
      ],
    );
  }

  Widget _buildPerformanceSettings(BuildContext context, WidgetRef ref, ReaderSettings settings) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Preload Pages'),
          subtitle: const Text('Preload nearby pages for faster navigation'),
          value: settings.preloadPages,
          onChanged: (_) {
            ref.read(readerSettingsProvider.notifier).togglePreloading();
          },
        ),
        if (settings.preloadPages)
          ListTile(
            title: const Text('Preload Count'),
            subtitle: Text('Preload ${settings.preloadCount} pages ahead'),
            trailing: SizedBox(
              width: 100,
              child: Slider(
                value: settings.preloadCount.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: settings.preloadCount.toString(),
                onChanged: (value) {
                  ref.read(readerSettingsProvider.notifier).updatePreloadCount(value.round());
                },
              ),
            ),
          ),
      ],
    );
  }
}

/// Quick settings overlay for fullscreen mode
class QuickSettingsOverlay extends ConsumerWidget {
  final VoidCallback? onClose;

  const QuickSettingsOverlay({
    super.key,
    this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(readerSettingsProvider);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Quick Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Brightness control
          Row(
            children: [
              const Icon(Icons.brightness_6, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Slider(
                  value: settings.brightness,
                  min: 0.1,
                  max: 1.0,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white30,
                  onChanged: (value) {
                    ref.read(readerSettingsProvider.notifier).updateBrightness(value);
                  },
                ),
              ),
              Text(
                '${(settings.brightness * 100).round()}%',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Theme toggles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildThemeButton(
                context,
                ref,
                ReaderTheme.light,
                Icons.light_mode,
                'Light',
                settings.theme == ReaderTheme.light,
              ),
              _buildThemeButton(
                context,
                ref,
                ReaderTheme.dark,
                Icons.dark_mode,
                'Dark',
                settings.theme == ReaderTheme.dark,
              ),
              _buildThemeButton(
                context,
                ref,
                ReaderTheme.sepia,
                Icons.auto_stories,
                'Sepia',
                settings.theme == ReaderTheme.sepia,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeButton(
    BuildContext context,
    WidgetRef ref,
    ReaderTheme theme,
    IconData icon,
    String label,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(readerSettingsProvider.notifier).updateTheme(theme);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white24 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white30,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}