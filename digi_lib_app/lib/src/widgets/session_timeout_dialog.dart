import 'package:flutter/material.dart';

/// Dialog for setting session timeout
class SessionTimeoutDialog extends StatelessWidget {
  final int currentTimeout;
  final ValueChanged<int> onTimeoutChanged;

  const SessionTimeoutDialog({
    super.key,
    required this.currentTimeout,
    required this.onTimeoutChanged,
  });

  static const List<int> _timeouts = [15, 30, 60, 120, 240, 480];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Session Timeout'),
      content: RadioGroup<int>(
        onChanged: (value) {
          if (value != null) {
            onTimeoutChanged(value);
            Navigator.of(context).pop();
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _timeouts.map((timeout) {
            return RadioListTile<int>(
              title: Text(_getTimeoutText(timeout)),
              value: timeout,
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  String _getTimeoutText(int minutes) {
    if (minutes < 60) {
      return '$minutes minutes';
    } else {
      final hours = minutes ~/ 60;
      return '$hours ${hours == 1 ? 'hour' : 'hours'}';
    }
  }
}
