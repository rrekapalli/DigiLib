import 'package:flutter/material.dart';

/// Dialog for selecting sync interval
class SyncIntervalDialog extends StatelessWidget {
  final int currentInterval;
  final ValueChanged<int> onIntervalChanged;

  const SyncIntervalDialog({
    super.key,
    required this.currentInterval,
    required this.onIntervalChanged,
  });

  static const List<int> _intervals = [5, 10, 15, 30, 60, 120, 240];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sync Interval'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _intervals.map((interval) {
          return RadioListTile<int>(
            title: Text(_getIntervalText(interval)),
            value: interval,
            groupValue: currentInterval,
            onChanged: (value) {
              if (value != null) {
                onIntervalChanged(value);
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

  String _getIntervalText(int minutes) {
    if (minutes < 60) {
      return '$minutes minutes';
    } else {
      final hours = minutes ~/ 60;
      return '$hours ${hours == 1 ? 'hour' : 'hours'}';
    }
  }
}