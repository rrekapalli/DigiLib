import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Widget for displaying search suggestions
class SearchSuggestionsList extends StatelessWidget {
  final List<String> suggestions;
  final String query;
  final ValueChanged<String> onSuggestionTap;

  const SearchSuggestionsList({
    super.key,
    required this.suggestions,
    required this.query,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (suggestions.isEmpty) {
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
                Icons.lightbulb_outline,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Suggestions',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return _buildSuggestionTile(context, suggestion);
          },
        ),
      ],
    );
  }

  Widget _buildSuggestionTile(BuildContext context, String suggestion) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Icon(
        Icons.search,
        color: colorScheme.onSurfaceVariant,
        size: 20,
      ),
      title: _buildHighlightedSuggestion(context, suggestion),
      onTap: () => onSuggestionTap(suggestion),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 4,
      ),
    );
  }

  Widget _buildHighlightedSuggestion(BuildContext context, String suggestion) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (query.isEmpty) {
      return Text(
        suggestion,
        style: theme.textTheme.bodyMedium,
      );
    }

    final spans = <TextSpan>[];
    final lowerSuggestion = suggestion.toLowerCase();
    final lowerQuery = query.toLowerCase();
    
    int start = 0;
    int index = lowerSuggestion.indexOf(lowerQuery);
    
    while (index != -1) {
      // Add text before match
      if (index > start) {
        spans.add(TextSpan(
          text: suggestion.substring(start, index),
          style: theme.textTheme.bodyMedium,
        ));
      }
      
      // Add highlighted match
      spans.add(TextSpan(
        text: suggestion.substring(index, index + query.length),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ));
      
      start = index + query.length;
      index = lowerSuggestion.indexOf(lowerQuery, start);
    }
    
    // Add remaining text
    if (start < suggestion.length) {
      spans.add(TextSpan(
        text: suggestion.substring(start),
        style: theme.textTheme.bodyMedium,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      overflow: TextOverflow.ellipsis,
    );
  }
}