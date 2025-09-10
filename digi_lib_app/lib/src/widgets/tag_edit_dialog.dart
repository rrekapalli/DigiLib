import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/tag.dart';
import '../providers/tag_provider.dart';

/// Dialog for editing an existing tag
class TagEditDialog extends ConsumerStatefulWidget {
  final Tag tag;

  const TagEditDialog({
    super.key,
    required this.tag,
  });

  @override
  ConsumerState<TagEditDialog> createState() => _TagEditDialogState();
}

class _TagEditDialogState extends ConsumerState<TagEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  Color _selectedColor = Colors.blue;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tag.name);
    _selectedColor = _getDefaultTagColor(widget.tag.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('Edit Tag'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tag name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tag Name',
                hintText: 'Enter tag name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a tag name';
                }
                if (value.trim().length < 2) {
                  return 'Tag name must be at least 2 characters';
                }
                if (value.trim().length > 50) {
                  return 'Tag name must be less than 50 characters';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            
            const SizedBox(height: 24),
            
            // Color selection
            Text(
              'Tag Color',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            
            _buildColorPicker(),
            
            const SizedBox(height: 16),
            
            // Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    'Preview: ',
                    style: theme.textTheme.bodyMedium,
                  ),
                  _buildTagChip(_nameController.text.trim().isEmpty 
                      ? widget.tag.name 
                      : _nameController.text.trim()),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tag info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tag Information',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Created: ${_formatDate(widget.tag.createdAt)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    'ID: ${widget.tag.id}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUpdating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isUpdating ? null : _updateTag,
          child: _isUpdating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
      Colors.lime,
      Colors.amber,
      Colors.deepOrange,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((color) {
        final isSelected = color == _selectedColor;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    color: _getContrastColor(color),
                    size: 16,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTagChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _selectedColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selectedColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.label,
            size: 16,
            color: _selectedColor,
          ),
          const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              color: _selectedColor,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateTag() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newName = _nameController.text.trim();
    
    // Check if anything actually changed
    if (newName == widget.tag.name) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isUpdating = true);

    try {
      // Note: In a real implementation, we'd need an updateTag method in the service
      // For now, we'll simulate the update by deleting and recreating
      // This is not ideal but works for the demo
      
      await ref.read(tagProvider.notifier).deleteTag(widget.tag.id);
      await ref.read(tagProvider.notifier).createTag(newName);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tag updated to "$newName"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update tag: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getDefaultTagColor(String tagName) {
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

  Color _getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}