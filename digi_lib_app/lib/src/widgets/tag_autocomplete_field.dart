import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/tag.dart';
import '../providers/tag_provider.dart';

/// Autocomplete text field for tag input with suggestions
class TagAutocompleteField extends ConsumerStatefulWidget {
  final Function(Tag tag) onTagSelected;
  final Function(String tagName) onTagCreated;
  final String? hintText;
  final List<Tag> excludeTags;

  const TagAutocompleteField({
    super.key,
    required this.onTagSelected,
    required this.onTagCreated,
    this.hintText,
    this.excludeTags = const [],
  });

  @override
  ConsumerState<TagAutocompleteField> createState() => _TagAutocompleteFieldState();
}

class _TagAutocompleteFieldState extends ConsumerState<TagAutocompleteField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<Tag> _suggestions = [];
  bool _showSuggestions = false;
  int _selectedSuggestionIndex = -1;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onTextChanged,
          onSubmitted: _onSubmitted,
          decoration: InputDecoration(
            hintText: widget.hintText ?? 'Type to search or create tags...',
            prefixIcon: const Icon(Icons.label),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    onPressed: _clearText,
                    icon: const Icon(Icons.clear),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        
        // Suggestions dropdown
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length + (_canCreateNewTag() ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _suggestions.length) {
                  return _buildSuggestionTile(
                    _suggestions[index],
                    index,
                    false,
                  );
                } else {
                  // Create new tag option
                  return _buildSuggestionTile(
                    null,
                    index,
                    true,
                  );
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestionTile(Tag? tag, int index, bool isCreateNew) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = index == _selectedSuggestionIndex;
    final query = _controller.text.trim();

    return Material(
      color: isSelected 
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : Colors.transparent,
      child: ListTile(
        dense: true,
        onTap: () => _selectSuggestion(index),
        leading: isCreateNew
            ? Icon(
                Icons.add_circle,
                color: colorScheme.primary,
                size: 20,
              )
            : Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _getTagColor(tag!.name),
                  shape: BoxShape.circle,
                ),
              ),
        title: isCreateNew
            ? RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyMedium,
                  children: [
                    const TextSpan(text: 'Create "'),
                    TextSpan(
                      text: query,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: '"'),
                  ],
                ),
              )
            : _buildHighlightedText(tag!.name, query, theme),
        subtitle: isCreateNew
            ? Text(
                'Create new tag',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                ),
              )
            : Text(
                'Created ${_formatDate(tag!.createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
        trailing: isCreateNew
            ? null
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getTagColor(tag!.name).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '0', // Mock usage count
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getTagColor(tag.name),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query, ThemeData theme) {
    if (query.isEmpty) {
      return Text(text);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(text);
    }

    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium,
        children: [
          if (index > 0)
            TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: TextStyle(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.3),
              fontWeight: FontWeight.bold,
            ),
          ),
          if (index + query.length < text.length)
            TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }

  void _onTextChanged(String value) {
    if (value.trim().isEmpty) {
      setState(() {
        _suggestions.clear();
        _showSuggestions = false;
        _selectedSuggestionIndex = -1;
      });
      return;
    }

    _updateSuggestions(value.trim());
  }

  void _updateSuggestions(String query) {
    final tagState = ref.read(tagProvider);
    final allTags = tagState.tags;
    
    // Filter tags based on query and exclude already selected tags
    final excludeIds = widget.excludeTags.map((tag) => tag.id).toSet();
    final filteredTags = allTags.where((tag) {
      return !excludeIds.contains(tag.id) &&
             tag.name.toLowerCase().contains(query.toLowerCase());
    }).toList();

    // Sort by relevance (exact matches first, then starts with, then contains)
    filteredTags.sort((a, b) {
      final aLower = a.name.toLowerCase();
      final bLower = b.name.toLowerCase();
      final queryLower = query.toLowerCase();

      // Exact match
      if (aLower == queryLower) return -1;
      if (bLower == queryLower) return 1;

      // Starts with
      final aStartsWith = aLower.startsWith(queryLower);
      final bStartsWith = bLower.startsWith(queryLower);
      if (aStartsWith && !bStartsWith) return -1;
      if (bStartsWith && !aStartsWith) return 1;

      // Alphabetical
      return a.name.compareTo(b.name);
    });

    setState(() {
      _suggestions = filteredTags.take(5).toList(); // Limit to 5 suggestions
      _showSuggestions = true;
      _selectedSuggestionIndex = -1;
    });
  }

  void _onSubmitted(String value) {
    if (_selectedSuggestionIndex >= 0) {
      _selectSuggestion(_selectedSuggestionIndex);
    } else if (value.trim().isNotEmpty) {
      _createNewTag(value.trim());
    }
  }

  void _selectSuggestion(int index) {
    if (index < _suggestions.length) {
      // Select existing tag
      final tag = _suggestions[index];
      widget.onTagSelected(tag);
    } else {
      // Create new tag
      _createNewTag(_controller.text.trim());
    }
    
    _clearText();
  }

  void _createNewTag(String tagName) {
    widget.onTagCreated(tagName);
  }

  void _clearText() {
    _controller.clear();
    setState(() {
      _suggestions.clear();
      _showSuggestions = false;
      _selectedSuggestionIndex = -1;
    });
  }

  bool _canCreateNewTag() {
    final query = _controller.text.trim();
    if (query.isEmpty) return false;
    
    // Check if exact match exists
    final exactMatch = _suggestions.any((tag) => 
        tag.name.toLowerCase() == query.toLowerCase());
    
    return !exactMatch;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  Color _getTagColor(String tagName) {
    final hash = tagName.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[hash.abs() % colors.length];
  }
}