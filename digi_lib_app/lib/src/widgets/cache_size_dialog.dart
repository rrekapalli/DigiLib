import 'package:flutter/material.dart';

/// Dialog for setting cache size limits
class CacheSizeDialog extends StatelessWidget {
  final int currentSize;
  final String title;
  final ValueChanged<int> onSizeChanged;

  const CacheSizeDialog({
    super.key,
    required this.currentSize,
    required this.title,
    required this.onSizeChanged,
  });

  static const List<int> _sizes = [128, 256, 512, 1024, 2048, 4096];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _sizes.map((size) {
          return RadioListTile<int>(
            title: Text(_getSizeText(size)),
            value: size,
            groupValue: currentSize,
            onChanged: (value) {
              if (value != null) {
                onSizeChanged(value);
                Navigator.of(context).pop();
              }
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  String _getSizeText(int sizeMB) {
    if (sizeMB < 1024) {
      return '$sizeMB MB';
    } else {
      final sizeGB = sizeMB / 1024;
      return '${sizeGB.toStringAsFixed(sizeGB == sizeGB.round() ? 0 : 1)} GB';
    }
  }
}