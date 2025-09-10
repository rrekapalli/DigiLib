import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/library.dart';
import '../models/entities/tag.dart';
import '../services/search_service.dart';
import '../providers/library_provider.dart';
import '../providers/tag_provider.dart';
import '../utils/constants.dart';

/// Panel for search filters including library, tags, and content type
class SearchFiltersPanel extends ConsumerStatefulWidget {
  final SearchFilters? filters;
  final ValueChanged<SearchFilters?> onFiltersChanged;

  const SearchFiltersPanel({
    super.key,
    this.filters,
    required this.onFiltersChanged,
  });

  @override
  ConsumerState<SearchFiltersPanel> createState() => _SearchFiltersPanelState();
}

class _SearchFiltersPanelState extends ConsumerState<SearchFiltersPanel> {
  String? _selectedLibraryId;
  List<String> _selectedTags = [];
  List<String> _selectedFileTypes = [];
  List<String> _selectedAuthors = [];
  DateTimeRange? _dateRange;

  final List<String> _availableFileTypes = [
    'pdf',
    'epub',
    'docx',
    'txt',
    'mobi',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFromFilters();
  }

  void _initializeFromFilters() {
    final filters = widget.filters;
    if (filters != null) {
      _selectedLibraryId = filters.libraryId;
      _selectedTags = List.from(filters.tags ?? []);
      _selectedFileTypes = List.from(filters.fileTypes ?? []);
      _selectedAuthors = List.from(filters.authors ?? []);
      
      if (filters.dateFrom != null && filters.dateTo != null) {
        _dateRange = DateTimeRange(
          start: filters.dateFrom!,
          end: filters.dateTo!,
        );
      }
    }
  }

  void _updateFilters() {
    SearchFilters? filters;
    
    if (_selectedLibraryId != null ||
        _selectedTags.isNotEmpty ||
        _selectedFileTypes.isNotEmpty ||
        _selectedAuthors.isNotEmpty ||
        _dateRange != null) {
      filters = SearchFilters(
        libraryId: _selectedLibraryId,
        tags: _selectedTags.isNotEmpty ? _selectedTags : null,
        fileTypes: _selectedFileTypes.isNotEmpty ? _selectedFileTypes : null,
        authors: _selectedAuthors.isNotEmpty ? _selectedAuthors : null,
        dateFrom: _dateRange?.start,
        dateTo: _dateRange?.end,
      );
    }
    
    widget.onFiltersChanged(filters);
  }

  void _clearAllFilters() {
    setState(() {
      _selectedLibraryId = null;
      _selectedTags.clear();
      _selectedFileTypes.clear();
      _selectedAuthors.clear();
      _dateRange = null;
    });
    _updateFilters();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Row(
              children: [
                Text(
                  'Filters',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),

          // Filter content
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Library filter
                _buildLibraryFilter(),
                const SizedBox(height: 16),

                // Tags filter
                _buildTagsFilter(),
                const SizedBox(height: 16),

                // File type filter
                _buildFileTypeFilter(),
                const SizedBox(height: 16),

                // Date range filter
                _buildDateRangeFilter(),
                const SizedBox(height: AppConstants.defaultPadding),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryFilter() {
    final librariesAsync = ref.watch(librariesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Library',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        librariesAsync.when(
          data: (libraries) => _buildLibraryDropdown(libraries),
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Error loading libraries: $error'),
        ),
      ],
    );
  }

  Widget _buildLibraryDropdown(List<Library> libraries) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedLibraryId,
      decoration: const InputDecoration(
        hintText: 'All libraries',
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('All libraries'),
        ),
        ...libraries.map((library) => DropdownMenuItem<String>(
          value: library.id,
          child: Text(library.name),
        )),
      ],
      onChanged: (value) {
        setState(() {
          _selectedLibraryId = value;
        });
        _updateFilters();
      },
    );
  }

  Widget _buildTagsFilter() {
    final tagsAsync = ref.watch(tagsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        tagsAsync.when(
          data: (tags) => _buildTagsSelection(tags),
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Error loading tags: $error'),
        ),
      ],
    );
  }

  Widget _buildTagsSelection(List<Tag> tags) {
    if (tags.isEmpty) {
      return const Text('No tags available');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: tags.map((tag) {
        final isSelected = _selectedTags.contains(tag.id);
        return FilterChip(
          label: Text(tag.name),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedTags.add(tag.id);
              } else {
                _selectedTags.remove(tag.id);
              }
            });
            _updateFilters();
          },
        );
      }).toList(),
    );
  }

  Widget _buildFileTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'File Type',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _availableFileTypes.map((fileType) {
            final isSelected = _selectedFileTypes.contains(fileType);
            return FilterChip(
              label: Text(fileType.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedFileTypes.add(fileType);
                  } else {
                    _selectedFileTypes.remove(fileType);
                  }
                });
                _updateFilters();
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.date_range),
                label: Text(
                  _dateRange != null
                      ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                      : 'Select date range',
                ),
              ),
            ),
            if (_dateRange != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() {
                    _dateRange = null;
                  });
                  _updateFilters();
                },
                icon: const Icon(Icons.clear),
                tooltip: 'Clear date range',
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      _updateFilters();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}