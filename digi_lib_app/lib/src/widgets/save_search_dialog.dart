import 'package:flutter/material.dart';
import '../services/search_service.dart';
import '../utils/constants.dart';

/// Dialog for saving a search with a custom name
class SaveSearchDialog extends StatefulWidget {
  final String query;
  final SearchFilters? filters;
  final String? initialName;
  final bool isEditing;

  const SaveSearchDialog({
    super.key,
    required this.query,
    this.filters,
    this.initialName,
    this.isEditing = false,
  });

  @override
  State<SaveSearchDialog> createState() => _SaveSearchDialogState();
}

class _SaveSearchDialogState extends State<SaveSearchDialog> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();

    if (widget.initialName != null) {
      _nameController.text = widget.initialName!;
      _isValid = widget.initialName!.trim().isNotEmpty;
    } else {
      // Generate a default name based on the query
      _nameController.text = _generateDefaultName();
      _isValid = true;
    }

    _nameController.addListener(_validateInput);

    // Focus and select all text for easy editing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocusNode.requestFocus();
      _nameController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _nameController.text.length,
      );
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _validateInput() {
    final isValid = _nameController.text.trim().isNotEmpty;
    if (isValid != _isValid) {
      setState(() {
        _isValid = isValid;
      });
    }
  }

  String _generateDefaultName() {
    final query = widget.query.trim();
    if (query.isEmpty) return 'Untitled Search';

    // Capitalize first letter and limit length
    final name = query.length > 30 ? '${query.substring(0, 30)}...' : query;

    return name[0].toUpperCase() + name.substring(1);
  }

  void _save() {
    if (!_isValid) return;

    final result = {
      'name': _nameController.text.trim(),
      'query': widget.query,
      'filters': widget.filters,
    };

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit Saved Search' : 'Save Search'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Query display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Query:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.query,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          // Filters display (if any)
          if (widget.filters != null) ...[
            const SizedBox(height: 12),
            _buildFiltersDisplay(),
          ],

          const SizedBox(height: 16),

          // Name input
          TextField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            decoration: InputDecoration(
              labelText: 'Search Name',
              hintText: 'Enter a name for this search',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppConstants.defaultBorderRadius,
                ),
              ),
              errorText:
                  _nameController.text.trim().isEmpty &&
                      _nameController.text.isNotEmpty
                  ? 'Name cannot be empty'
                  : null,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isValid ? _save : null,
          child: Text(widget.isEditing ? 'Update' : 'Save'),
        ),
      ],
    );
  }

  Widget _buildFiltersDisplay() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filters = widget.filters!;

    final filterItems = <Widget>[];

    // Library filter
    if (filters.libraryId != null) {
      filterItems.add(
        _buildFilterItem('Library', 'Specific library selected', Icons.folder),
      );
    }

    // Tags filter
    if (filters.tags != null && filters.tags!.isNotEmpty) {
      filterItems.add(
        _buildFilterItem(
          'Tags',
          '${filters.tags!.length} tags selected',
          Icons.label,
        ),
      );
    }

    // File types filter
    if (filters.fileTypes != null && filters.fileTypes!.isNotEmpty) {
      filterItems.add(
        _buildFilterItem(
          'File Types',
          filters.fileTypes!.join(', ').toUpperCase(),
          Icons.description,
        ),
      );
    }

    // Authors filter
    if (filters.authors != null && filters.authors!.isNotEmpty) {
      filterItems.add(
        _buildFilterItem(
          'Authors',
          '${filters.authors!.length} authors selected',
          Icons.person,
        ),
      );
    }

    // Date range filter
    if (filters.dateFrom != null || filters.dateTo != null) {
      String dateText = 'Date range selected';
      if (filters.dateFrom != null && filters.dateTo != null) {
        dateText =
            '${_formatDate(filters.dateFrom!)} - ${_formatDate(filters.dateTo!)}';
      } else if (filters.dateFrom != null) {
        dateText = 'From ${_formatDate(filters.dateFrom!)}';
      } else if (filters.dateTo != null) {
        dateText = 'Until ${_formatDate(filters.dateTo!)}';
      }

      filterItems.add(
        _buildFilterItem('Date Range', dateText, Icons.date_range),
      );
    }

    if (filterItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Filters:',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ...filterItems,
        ],
      ),
    );
  }

  Widget _buildFilterItem(String title, String description, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  TextSpan(
                    text: description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
