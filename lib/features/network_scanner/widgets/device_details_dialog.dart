import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/network_entity.dart';
import '../../../shared/widgets/feature_screen.dart';

class DeviceDetailsDialog extends StatelessWidget {
  final NetworkDevice device;


  // بعد التعديل
  const DeviceDetailsDialog({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildBasicInfo(context),
            const SizedBox(height: 16),
            if (device.openPorts.isNotEmpty) ...[  
              _buildPortsSection(context),
              const SizedBox(height: 16),
            ],
            _buildActionsSection(context),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getDeviceIcon(),
            size: 32,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                        
                // بعد التعديل
                device.name,
                style: Theme.of(context).textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: device.isOnline
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      device.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: device.isOnline ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  // Change this:                  
                  // بعد التعديل
                  if (device.deviceType != DeviceType.unknown) ...[  
                    const SizedBox(width: 8),
                    Text(
                      // Change this:

                      
                      // بعد التعديل
                      _getDeviceTypeString(device.deviceType),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildBasicInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Basic Information',
          subtext: '',
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          context,
          'IP Address',
          device.ipAddress ?? 'Unknown',  // Provide a default value if null
          canCopy: true,
        ),
        if (device.macAddress != null)
          _buildInfoRow(
            context,
            'MAC Address',
            device.macAddress!,
            canCopy: true,
          ),
        if (device.vendor != null)
          _buildInfoRow(context, 'Vendor', device.vendor!),
        if (device.hostname != null)
          _buildInfoRow(context, 'Hostname', device.hostname!),
        if (device.responseTime != null)
          _buildInfoRow(
            context,
            'Response Time',
            '${device.responseTime} ms',
          ),
      ],
    );
  }

  Widget _buildPortsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Open Ports', subtext: ''),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: device.openPorts.map((port) {
            final service = _getCommonServiceName(port);
            return Chip(
              label: Text('$port${service.isNotEmpty ? ' ($service)' : ''}'),
              avatar: const Icon(Icons.lan, size: 16),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Actions', subtext: ''),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildActionChip(
              context,
              'Ping',
              Icons.network_ping,
              onTap: () {
                // Navigate to ping tool with this IP
                Navigator.of(context).pop();
Navigator.of(context).pushNamed('/ping', arguments: device.ipAddress);
              },
            ),
            if (device.isOnline) ...[  
              _buildActionChip(
                context,
                'Port Scan',
                Icons.security,
                onTap: () {
                  // Navigate to port scanner with this IP
                  Navigator.of(context).pop();
Navigator.of(context).pushNamed('/port-scanner', arguments: device.ipAddress);
                },
              ),
              if (device.openPorts.contains(80) || device.openPorts.contains(443))
                _buildActionChip(
                  context,
                  'Open Web',
                  Icons.public,
                  onTap: () {
                    // Open web browser with this IP
                    Navigator.of(context).pop();
                    // TODO: Implement opening web browser
                  },
                ),
              if (device.openPorts.contains(22))
                _buildActionChip(
                  context,
                  'SSH',
                  Icons.terminal,
                  onTap: () {
                    // Open SSH client
                    Navigator.of(context).pop();
Navigator.of(context).pushNamed('/ssh', arguments: device.ipAddress);
                  },
                ),
            ],
          ],
        ),
      ],
    );
  }


  // بعد التعديل
  Widget _buildInfoRow(BuildContext context, String label, String? value, {bool canCopy = false}) {
  // استخدم value ?? '' في أي مكان يتطلب String غير قابلة للإرجاع كقيمة فارغة
  final displayValue = value ?? '';
  
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  displayValue,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              if (canCopy)
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value ?? ''));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$label copied to clipboard'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(BuildContext context, String label, IconData icon, {required VoidCallback onTap}) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onTap,
    );
  }

  IconData _getDeviceIcon() {
    // Change this:

    // بعد التعديل
    if (device.deviceType == DeviceType.unknown) {
      return device.isOnline ? Icons.devices : Icons.device_unknown;
    }

    switch (device.deviceType) {
      case DeviceType.router:
        return Icons.router;
      case DeviceType.printer:
        return Icons.print;
      case DeviceType.mobile:
        return Icons.smartphone;
      case DeviceType.computer:
        return Icons.computer;
      case DeviceType.iot:
        return Icons.home;
      case DeviceType.unknown:
      default:
        return Icons.devices;
    }
  }

  String _getDeviceTypeString(DeviceType type) {
    switch (type) {
      case DeviceType.router:
        return 'Router';
      case DeviceType.printer:
        return 'Printer';
      case DeviceType.mobile:
        return 'Mobile Device';
      case DeviceType.computer:
        return 'Computer';
      case DeviceType.iot:
        return 'IoT Device';
      case DeviceType.unknown:
      default:
        return 'Unknown';
    }
  }

  String _getCommonServiceName(int port) {
    switch (port) {
      case 21:
        return 'FTP';
      case 22:
        return 'SSH';
      case 23:
        return 'Telnet';
      case 25:
        return 'SMTP';
      case 53:
        return 'DNS';
      case 80:
        return 'HTTP';
      case 110:
        return 'POP3';
      case 143:
        return 'IMAP';
      case 443:
        return 'HTTPS';
      case 445:
        return 'SMB';
      case 3389:
        return 'RDP';
      case 8080:
        return 'HTTP-ALT';
      default:
        return '';
    }
  }
}