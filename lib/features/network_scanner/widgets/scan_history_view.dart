import 'package:flutter/material.dart';

import '../../../shared/widgets/feature_screen.dart';
import '../models/network_scan_result.dart';

class ScanHistoryView extends StatelessWidget {
  final List<NetworkScanResult> scanHistory;
  final Function(NetworkScanResult) onHistoryItemTap;
  final Function(NetworkScanResult) onDeleteHistoryItem;
  final VoidCallback onClearHistory;

  const ScanHistoryView({
    Key? key,
    required this.scanHistory,
    required this.onHistoryItemTap,
    required this.onDeleteHistoryItem,
    required this.onClearHistory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (scanHistory.isEmpty) {
      return _buildEmptyHistory(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionHeader(
              title: 'Scan History',
              subtext: 'Previous network scan results',
            ),
            TextButton.icon(
              onPressed: scanHistory.isEmpty ? null : onClearHistory,
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Clear All'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: scanHistory.length,
            itemBuilder: (context, index) {
              final historyItem = scanHistory[index];
              return _buildHistoryItem(context, historyItem);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyHistory(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Scan History',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Your completed network scans will appear here',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, NetworkScanResult historyItem) {
    final timestamp = historyItem.startTime;
    final deviceCount = historyItem.devices.length;
    final onlineCount = historyItem.devices.where((d) => d.isOnline).length;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => onHistoryItemTap(historyItem),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          historyItem.networkRange,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(timestamp),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => onDeleteHistoryItem(historyItem),
                    tooltip: 'Delete from history',
                    color: Theme.of(context).colorScheme.error,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildHistoryChip(
                    context,
                    '$deviceCount ${deviceCount == 1 ? 'device' : 'devices'}',
                    Icons.devices,
                  ),
                  const SizedBox(width: 8),
                  _buildHistoryChip(
                    context,
                    '$onlineCount online',
                    Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                  ...[
                    const SizedBox(width: 8),
                    _buildHistoryChip(
                      context,
                      _formatDuration(historyItem.duration),
                      Icons.timer_outlined,
                    ),
                  ],
                ],
              ),
              if (historyItem.status != ScanStatus.completed) ...[  
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(context, historyItem.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    historyItem.status.name.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(context, historyItem.status),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryChip(BuildContext context, String label, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'Unknown time';
    
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}.${(duration.inMilliseconds % 1000) ~/ 100}s';
    }
  }

  Color _getStatusColor(BuildContext context, ScanStatus status) {
    switch (status) {
      case ScanStatus.unknown:
        return Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
      case ScanStatus.completed:
        return Colors.green;
      case ScanStatus.cancelled:
        return Colors.orange;
      case ScanStatus.failed:
        return Theme.of(context).colorScheme.error;
      case ScanStatus.inProgress:
        return Theme.of(context).colorScheme.primary;
      case ScanStatus.notStarted:
        return Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
      case ScanStatus.completed:
        return Colors.green;
      case ScanStatus.cancelled:
        return Colors.orange;
      case ScanStatus.failed:
        return Theme.of(context).colorScheme.error;
      case ScanStatus.inProgress:
        return Theme.of(context).colorScheme.primary;
    }
  }
}