import 'package:flutter/material.dart';
import '../models/entities/app_settings.dart';

/// Dialog for configuring quiet hours for notifications
class QuietHoursDialog extends StatefulWidget {
  final NotificationSettings currentSettings;
  final ValueChanged<NotificationSettings> onSettingsChanged;

  const QuietHoursDialog({
    super.key,
    required this.currentSettings,
    required this.onSettingsChanged,
  });

  @override
  State<QuietHoursDialog> createState() => _QuietHoursDialogState();
}

class _QuietHoursDialogState extends State<QuietHoursDialog> {
  late bool _enableQuietHours;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    _enableQuietHours = widget.currentSettings.enableQuietHours;
    _startTime = _parseTime(widget.currentSettings.quietHoursStart);
    _endTime = _parseTime(widget.currentSettings.quietHoursEnd);
  }

  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quiet Hours'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Enable Quiet Hours'),
            subtitle: const Text('Disable notifications during specified hours'),
            value: _enableQuietHours,
            onChanged: (value) {
              setState(() {
                _enableQuietHours = value;
              });
            },
          ),
          const SizedBox(height: 16),
          if (_enableQuietHours) ...[
            ListTile(
              title: const Text('Start Time'),
              subtitle: Text(_startTime.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () => _selectTime(context, true),
            ),
            ListTile(
              title: const Text('End Time'),
              subtitle: Text(_endTime.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () => _selectTime(context, false),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final updatedSettings = widget.currentSettings.copyWith(
              enableQuietHours: _enableQuietHours,
              quietHoursStart: _formatTime(_startTime),
              quietHoursEnd: _formatTime(_endTime),
            );
            widget.onSettingsChanged(updatedSettings);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }
}