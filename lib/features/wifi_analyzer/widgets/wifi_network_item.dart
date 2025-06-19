import 'package:flutter/material.dart';

import '../../../core/models/network_entity.dart';

class WifiNetworkItem extends StatelessWidget {
  final WifiNetwork network;
  final VoidCallback? onTap;

  const WifiNetworkItem({
    super.key,
    required this.network,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSignalIcon(context),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      network.ssid.isEmpty ? 'Hidden Network' : network.ssid,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      network.bssid,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(
                          context,
                          '${network.signalStrength} dBm',
                          Icons.signal_cellular_alt,
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          context,
                          'Ch ${network.channel}',
                          Icons.settings_input_antenna,
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          context,
                          // Parse the frequency string to a number for comparison
                          int.tryParse(network.frequency) != null && int.parse(network.frequency) >= 5000 ? '5 GHz' : '2.4 GHz',
                          Icons.wifi,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildSecurityBadge(context),
                  const SizedBox(height: 8),
                  Text(
                    network.metadata['vendor'] ?? 'Unknown',
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignalIcon(BuildContext context) {
    IconData iconData;
    Color iconColor;

    // Signal strength is in dBm, typically between -30 (excellent) and -90 (poor)
    if (network.signalStrength >= -55) {
      iconData = Icons.signal_wifi_4_bar;
      iconColor = Colors.green;
    } else if (network.signalStrength >= -70) {
      iconData = Icons.network_wifi; // Replace with appropriate icon
      iconColor = Colors.lightGreen;
    } else if (network.signalStrength >= -80) {
      iconData = Icons.network_wifi; // Replace with appropriate icon
      iconColor = Colors.orange;
    } else {
      iconData = Icons.network_wifi; // Replace with appropriate icon
      iconColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityBadge(BuildContext context) {
    IconData securityIcon;
    String securityLabel;
    Color securityColor;

    if (network.securityType.contains('WPA3')) {
      securityIcon = Icons.lock;
      securityLabel = 'WPA3';
      securityColor = Colors.green;
    } else if (network.securityType.contains('WPA2')) {
      securityIcon = Icons.lock;
      securityLabel = 'WPA2';
      securityColor = Colors.blue;
    } else if (network.securityType.contains('WPA')) {
      securityIcon = Icons.lock_outline;
      securityLabel = 'WPA';
      securityColor = Colors.orange;
    } else if (network.securityType.contains('WEP')) {
      securityIcon = Icons.lock_open;
      securityLabel = 'WEP';
      securityColor = Colors.red;
    } else {
      securityIcon = Icons.no_encryption;
      securityLabel = 'Open';
      securityColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: securityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            securityIcon,
            size: 14,
            color: securityColor,
          ),
          const SizedBox(width: 4),
          Text(
            securityLabel,
            style: TextStyle(
              fontSize: 12,
              color: securityColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}