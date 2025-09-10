import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/connectivity_service.dart';
import '../utils/constants.dart';

/// Banner that shows when the app is in offline mode
class OfflineModeBanner extends ConsumerWidget {
  final Widget child;

  const OfflineModeBanner({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityState = ref.watch(connectivityServiceProvider);

    return Column(
      children: [
        if (!connectivityState.isConnected)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
              vertical: AppConstants.defaultPadding / 2,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.wifi_off,
                  size: 16,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You\'re offline. Some features may be limited.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _showOfflineInfo(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('Learn More'),
                ),
              ],
            ),
          ),
        Expanded(child: child),
      ],
    );
  }

  void _showOfflineInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const OfflineInfoDialog(),
    );
  }
}

/// Dialog explaining offline mode capabilities and limitations
class OfflineInfoDialog extends StatelessWidget {
  const OfflineInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.info_outline, color: Colors.blue),
      title: const Text('Offline Mode'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You\'re currently offline, but you can still:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Available features
          _buildFeatureList(
            context,
            'Available Features',
            [
              'Browse cached documents and libraries',
              'Read previously opened documents',
              'View bookmarks and comments',
              'Search through cached content',
              'Make annotations (will sync when online)',
            ],
            Icons.check_circle_outline,
            Colors.green,
          ),
          
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Limited features
          _buildFeatureList(
            context,
            'Limited Features',
            [
              'Cannot sync with other devices',
              'Cannot access new documents from cloud',
              'Cannot share documents or collaborate',
              'Search limited to cached content',
              'Cannot scan new libraries',
            ],
            Icons.warning_amber_outlined,
            Colors.orange,
          ),
          
          const SizedBox(height: AppConstants.defaultPadding),
          
          Text(
            'Your changes will be automatically synced when you\'re back online.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it'),
        ),
      ],
    );
  }

  Widget _buildFeatureList(
    BuildContext context,
    String title,
    List<String> features,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...features.map((feature) => Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Expanded(
                child: Text(
                  feature,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

/// Widget that shows degraded functionality when offline
class OfflineDegradedWidget extends ConsumerWidget {
  final Widget child;
  final Widget offlineChild;
  final bool showOfflineMessage;

  const OfflineDegradedWidget({
    super.key,
    required this.child,
    required this.offlineChild,
    this.showOfflineMessage = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityState = ref.watch(connectivityServiceProvider);

    if (connectivityState.isConnected) {
      return child;
    }

    return Column(
      children: [
        if (showOfflineMessage)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            margin: const EdgeInsets.all(AppConstants.defaultPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_off,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppConstants.defaultPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Limited Offline Mode',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Some features are not available while offline',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Expanded(child: offlineChild),
      ],
    );
  }
}

/// Button that shows different states based on connectivity
class ConnectivityAwareButton extends ConsumerWidget {
  final VoidCallback? onPressed;
  final VoidCallback? onOfflinePressed;
  final Widget child;
  final Widget? offlineChild;
  final String? offlineTooltip;

  const ConnectivityAwareButton({
    super.key,
    this.onPressed,
    this.onOfflinePressed,
    required this.child,
    this.offlineChild,
    this.offlineTooltip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityState = ref.watch(connectivityServiceProvider);

    if (!connectivityState.isConnected) {
      final button = ElevatedButton(
        onPressed: onOfflinePressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        child: offlineChild ?? child,
      );

      if (offlineTooltip != null) {
        return Tooltip(
          message: offlineTooltip!,
          child: button,
        );
      }

      return button;
    }

    return ElevatedButton(
      onPressed: onPressed,
      child: child,
    );
  }
}