import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Widget for displaying search history
class SearchHistoryList extends StatelessWidget {
  final List<String> history;
  final ValueChanged<String> onHistoryTap;
  final VoidCallback onClearHistory;

  const SearchHistoryList({
    super.key,
    required this.history,
    required this.onHistoryTap,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Row(
            children: [
              Icon(
                Icons.history,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Recent Searches',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _showClearConfirmation(context),
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final query = history[index];
            return _buildHistoryTile(context, query);
          },
        ),
      ],
    );
  }

  Widget _buildHistoryTile(BuildContext context, String query) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Icon(
        Icons.history,
        color: colorScheme.onSurfaceVariant,
        size: 20,
      ),
      title: Text(
        query,
        style: theme.textTheme.bodyMedium,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.north_west,
          color: colorScheme.onSurfaceVariant,
          size: 16,
        ),
        onPressed: () => onHistoryTap(query),
        tooltip: 'Use this search',
      ),
      onTap: () => onHistoryTap(query),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 4,
      ),
    );
  }

  VoidCallback _showClearConfirmation(BuildContext context) {
    return () {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Clear Search History'),
          content: const Text(
            'Are you sure you want to clear all search history? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                onClearHistory();
              },
              child: const Text('Clear'),
            ),
          ],
        ),
      );
    };
  }
}