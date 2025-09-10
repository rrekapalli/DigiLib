import 'package:flutter/material.dart';

/// Dialog for managing trusted devices
class TrustedDevicesDialog extends StatelessWidget {
  final List<String> trustedDevices;
  final ValueChanged<String> onDeviceRemoved;

  const TrustedDevicesDialog({
    super.key,
    required this.trustedDevices,
    required this.onDeviceRemoved,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Trusted Devices'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trustedDevices.isEmpty)
              const Text('No trusted devices configured.')
            else
              ...trustedDevices.map((deviceId) => ListTile(
                leading: const Icon(Icons.devices),
                title: Text('Device ${deviceId.substring(0, 8)}...'),
                subtitle: const Text('Added on 01/01/2024'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeDevice(context, deviceId),
                ),
              )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  void _removeDevice(BuildContext context, String deviceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Trusted Device'),
        content: const Text('Are you sure you want to remove this trusted device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDeviceRemoved(deviceId);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}