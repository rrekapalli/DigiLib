import 'package:flutter/material.dart';

/// Dialog for adjusting text scale factor
class TextScaleDialog extends StatefulWidget {
  final double currentScale;
  final ValueChanged<double> onScaleChanged;

  const TextScaleDialog({
    super.key,
    required this.currentScale,
    required this.onScaleChanged,
  });

  @override
  State<TextScaleDialog> createState() => _TextScaleDialogState();
}

class _TextScaleDialogState extends State<TextScaleDialog> {
  late double _scale;

  @override
  void initState() {
    super.initState();
    _scale = widget.currentScale;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Text Size'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sample text at ${(_scale * 100).round()}%',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: (theme.textTheme.bodyLarge?.fontSize ?? 16) * _scale,
            ),
          ),
          const SizedBox(height: 16),
          Slider(
            value: _scale,
            min: 0.8,
            max: 1.5,
            divisions: 14,
            label: '${(_scale * 100).round()}%',
            onChanged: (value) {
              setState(() {
                _scale = value;
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '80%',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                '150%',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onScaleChanged(_scale);
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}