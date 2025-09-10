import 'package:flutter/material.dart';

/// Dialog for selecting app theme mode
class ThemeSelectionDialog extends StatelessWidget {
  final ThemeMode currentTheme;
  final ValueChanged<ThemeMode> onThemeChanged;

  const ThemeSelectionDialog({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Theme'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<ThemeMode>(
            title: const Text('System'),
            subtitle: const Text('Follow system theme'),
            value: ThemeMode.system,
            groupValue: currentTheme,
            onChanged: (value) {
              if (value != null) {
                onThemeChanged(value);
                Navigator.of(context).pop();
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            subtitle: const Text('Light theme'),
            value: ThemeMode.light,
            groupValue: currentTheme,
            onChanged: (value) {
              if (value != null) {
                onThemeChanged(value);
                Navigator.of(context).pop();
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            subtitle: const Text('Dark theme'),
            value: ThemeMode.dark,
            groupValue: currentTheme,
            onChanged: (value) {
              if (value != null) {
                onThemeChanged(value);
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}