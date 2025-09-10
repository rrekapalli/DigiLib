import 'package:flutter/material.dart';

/// A tile widget for individual settings items
class SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: enabled ? null : colorScheme.onSurface.withValues(alpha: 0.38),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: enabled
                    ? colorScheme.onSurface.withValues(alpha: 0.6)
                    : colorScheme.onSurface.withValues(alpha: 0.38),
              ),
            )
          : null,
      leading: leading != null
          ? IconTheme(
              data: IconThemeData(
                color: enabled
                    ? colorScheme.onSurface.withValues(alpha: 0.6)
                    : colorScheme.onSurface.withValues(alpha: 0.38),
              ),
              child: leading!,
            )
          : null,
      trailing: trailing,
      onTap: enabled ? onTap : null,
      enabled: enabled,
    );
  }
}
