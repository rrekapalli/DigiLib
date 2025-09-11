import 'package:flutter/material.dart';
import '../models/entities/account_settings.dart';

/// Dialog for selecting data sharing level
class DataSharingDialog extends StatelessWidget {
  final DataSharingLevel currentLevel;
  final ValueChanged<DataSharingLevel> onLevelChanged;

  const DataSharingDialog({
    super.key,
    required this.currentLevel,
    required this.onLevelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Data Sharing Level'),
      content: RadioGroup<DataSharingLevel>(
        onChanged: (value) {
          if (value != null) {
            onLevelChanged(value);
            Navigator.of(context).pop();
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: DataSharingLevel.values.map((level) {
            return RadioListTile<DataSharingLevel>(
              title: Text(_getLevelTitle(level)),
              subtitle: Text(_getLevelDescription(level)),
              value: level,
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

  String _getLevelTitle(DataSharingLevel level) {
    switch (level) {
      case DataSharingLevel.none:
        return 'None';
      case DataSharingLevel.minimal:
        return 'Minimal';
      case DataSharingLevel.standard:
        return 'Standard';
      case DataSharingLevel.full:
        return 'Full';
    }
  }

  String _getLevelDescription(DataSharingLevel level) {
    switch (level) {
      case DataSharingLevel.none:
        return 'No data sharing';
      case DataSharingLevel.minimal:
        return 'Essential data only';
      case DataSharingLevel.standard:
        return 'Standard usage data';
      case DataSharingLevel.full:
        return 'All available data';
    }
  }
}
