import 'package:flutter/material.dart';

import '../../../shared/widgets/feature_screen.dart';
import '../models/network_scan_result.dart';

class ScanResultSummary extends StatelessWidget {
  final NetworkScanResult result;

  const ScanResultSummary({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final deviceCount = result.devices.length;
    final onlineCount = result.onlineDeviceCount;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SectionHeader(
              title: 'Scan Results',
              subtext: result.status == ScanStatus.completed
                  ? 'Completed in ${_formatDuration(result.duration)}'
                  : 'Scan ${result.status.name}',
            ),
            if (result.status == ScanStatus.completed || result.status == ScanStatus.cancelled)
              TextButton.icon(
                onPressed: () {},  // This will be connected in the parent widget
                icon: const Icon(Icons.refresh),
                label: const Text('Scan Again'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildInfoChip(
              context,
              '$deviceCount ${deviceCount == 1 ? 'device' : 'devices'} found',
              Icons.devices,
            ),
            const SizedBox(width: 8),
            _buildInfoChip(
              context,
              '$onlineCount online',
              Icons.check_circle_outline,
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            _buildInfoChip(
              context,
              '${deviceCount - onlineCount} offline',
              Icons.offline_bolt_outlined,
              color: Colors.grey,
            ),
          ],
        ),
        if (result.networkRange.isNotEmpty) ...[  
          const SizedBox(height: 8),
          Text(
            'Range: ${result.networkRange}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, IconData icon, {Color? color}) {
    return Chip(
      label: Text(label),
      avatar: Icon(
        icon,
        size: 16,
        color: color,
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return 'N/A';
    
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}.${(duration.inMilliseconds % 1000) ~/ 100}s';
    }
  }
}