import 'package:flutter/material.dart';

import '../../../core/models/network_entity.dart';
import '../../../core/utils/helpers.dart';

class DeviceListItem extends StatelessWidget {
  final NetworkDevice device;
  final VoidCallback? onTap;

  const DeviceListItem({
    Key? key,
    required this.device,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              _buildDeviceIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.ipAddress ?? 'Unknown IP',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    if (device.macAddress != null) ...[  
                      const SizedBox(height: 2),
                      Text(
                        device.macAddress!,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildDeviceDetails(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceIcon() {
    IconData iconData;
    Color iconColor;

    switch (device.deviceType) {
      case DeviceType.router:
        iconData = Icons.router;
        iconColor = Colors.blue;
        break;
      case DeviceType.networkSwitch:
        iconData = Icons.settings_ethernet;
        iconColor = Colors.indigo;
        break;
      case DeviceType.server:
        iconData = Icons.dns;
        iconColor = Colors.amber;
        break;
      case DeviceType.desktop:
        iconData = Icons.desktop_windows;
        iconColor = Colors.green;
        break;
      case DeviceType.laptop:
        iconData = Icons.laptop;
        iconColor = Colors.teal;
        break;
      case DeviceType.mobile:
        iconData = Icons.smartphone;
        iconColor = Colors.purple;
        break;
      case DeviceType.iot:
        iconData = Icons.devices_other;
        iconColor = Colors.orange;
        break;
      case DeviceType.printer:
        iconData = Icons.print;
        iconColor = Colors.brown;
        break;
      case DeviceType.camera:
        iconData = Icons.camera_alt;
        iconColor = Colors.red;
        break;
      case DeviceType.unknown:
      default:
        iconData = Icons.devices;
        iconColor = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  Widget _buildDeviceDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Online status indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: device.isOnline ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            device.isOnline ? 'Online' : 'Offline',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Response time if available
        if (device.metadata.containsKey('responseTime') && device.metadata['responseTime'] != null) ...[  
          Text(
            '${AppHelpers.formatDuration(device.metadata['responseTime'].toInt())} ms',
            style: const TextStyle(fontSize: 12),
          ),
        ],
        // Open ports if available
        if (device.metadata.containsKey('openPorts')) ...[  
          const SizedBox(height: 4),
          Text(
            '${(device.metadata['openPorts'] as List).length} ports open',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ],
    );
  }
}