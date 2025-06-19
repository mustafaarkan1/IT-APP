import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/widgets/feature_screen.dart';
import '../models/network_scan_result.dart';
import '../../../core/models/network_entity.dart';
import 'device_list_item.dart';

class ScanResultsView extends StatelessWidget {
  final NetworkScanResult? scanResult;
  final bool isScanning;
  final VoidCallback? onScanAgain;
  final VoidCallback? onCancelScan;
  final Function(NetworkDevice) onDeviceTap;

  const ScanResultsView({
    super.key, // تحويل Key? key إلى super.key
    this.scanResult,
    required this.isScanning,
    this.onScanAgain,
    this.onCancelScan,
    required this.onDeviceTap,
  });

  @override
  Widget build(BuildContext context) {
    if (scanResult == null && !isScanning) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isScanning) _buildScanningHeader(context),
        if (scanResult != null) _buildResultsHeader(context),
        const SizedBox(height: 16),
        if (isScanning) _buildProgressIndicator(context),
        if (scanResult != null && scanResult!.devices.isNotEmpty)
          _buildDeviceList(context),
        if (scanResult != null && scanResult!.devices.isEmpty && !isScanning)
          _buildNoDevicesFound(context),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_find,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Scan Results',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Configure and start a network scan to discover devices',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onScanAgain,
            child: const Text('Start Scan'),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SectionHeader(
          title: 'Scanning Network...',
          subtext: 'Looking for devices on your network',
        ),
        TextButton.icon(
          onPressed: onCancelScan,
          icon: const Icon(Icons.cancel),
          label: const Text('Cancel'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }

  Widget _buildResultsHeader(BuildContext context) {
    final result = scanResult!;
    final deviceCount = result.devices.length;
    final onlineCount = result.devices.where((d) => d.isOnline).length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SectionHeader(
              subtext: 'Scan details and statistics',
              title: result.status == ScanStatus.completed
                  ? 'Scan Results - Completed in ${_formatDuration(result.duration)}'
                  : 'Scan Results - ${result.status.name}',
            ),
            if (result.status == ScanStatus.completed || result.status == ScanStatus.cancelled)
              TextButton.icon(
                onPressed: onScanAgain,
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
        ...[  // إزالة الشرط result.networkRange != null
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: result.networkRange)); // إزالة ! بعد networkRange
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Network range copied to clipboard')),
              );
            },
            child: Row(
              children: [
                Text(
                  'Range: ${result.networkRange}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.copy,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
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

  Widget _buildProgressIndicator(BuildContext context) {
    // استخدام قيم افتراضية أو حساب القيم من البيانات المتاحة
    final progress = scanResult?.status == ScanStatus.inProgress ? 0.5 : 0.0; // قيمة تقريبية للتقدم
    final scannedCount = scanResult?.devices.length ?? 0;
    final totalCount = scanResult?.metadata['totalHosts'] as int? ?? 100; // افتراض أن totalHosts مخزن في metadata
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progress > 0 ? progress : null,
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Scanned: $scannedCount / $totalCount',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        if (scanResult?.devices.isNotEmpty == true) ...[  
          const SizedBox(height: 16),
          const SectionHeader(
            title: 'Devices Found So Far',
            subtext: 'Devices discovered during the ongoing scan',
          ),
        ],
      ],
    );
  }

  Widget _buildDeviceList(BuildContext context) {
    final devices = scanResult!.devices;
    final onlineDevices = devices.where((d) => d.isOnline).toList();
    final offlineDevices = devices.where((d) => !d.isOnline).toList();
    
    return Expanded(
      child: ListView(
        children: [
          if (onlineDevices.isNotEmpty) ...[  
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Online Devices', 
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...onlineDevices.map((device) => DeviceListItem(
                  device: device,
                  onTap: () => onDeviceTap(device),
                )),
          ],
          if (offlineDevices.isNotEmpty) ...[  
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Offline Devices', 
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...offlineDevices.map((device) => DeviceListItem(
                  device: device,
                  onTap: () => onDeviceTap(device),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildNoDevicesFound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.device_unknown,
            size: 64,
            color: Theme.of(context).colorScheme.error.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'No Devices Found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Try scanning a different network range or check your connection',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onScanAgain,
            child: const Text('Try Again'),
          ),
        ],
      ),
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