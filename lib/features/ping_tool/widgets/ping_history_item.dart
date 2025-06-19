import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/network_entity.dart';

class PingHistoryItem extends StatelessWidget {
  final PingResult result;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const PingHistoryItem({
    Key? key,
    required this.result,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy HH:mm');
    final formattedDate = dateFormat.format(result.timestamp);
    final receivedCount = result.packetsReceived;
    final sentCount = result.packetsSent;
    final lossPercentage = result.packetLoss;
    final isSuccess = result.isSuccess;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
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
                          result.host,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: onDelete,
                      tooltip: 'Delete from history',
                      color: Theme.of(context).colorScheme.error,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStat(
                    context,
                    'Sent',
                    '$sentCount',
                    Icons.upload_outlined,
                  ),
                  _buildStat(
                    context,
                    'Received',
                    '$receivedCount',
                    Icons.download_outlined,
                  ),
                  _buildStat(
                    context,
                    'Loss',
                    '${lossPercentage.toStringAsFixed(1)}%',
                    Icons.signal_cellular_connected_no_internet_4_bar,
                    valueColor: lossPercentage > 0 ? Colors.orange : Colors.green,
                  ),
                  if (result.avgResponseTime != null)
                    _buildStat(
                      context,
                      'Avg',
                      '${result.avgResponseTime!.toStringAsFixed(1)} ms',
                      Icons.speed,
                      valueColor: _getResponseTimeColor(result.avgResponseTime!.toInt()),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(isSuccess).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSuccess ? Icons.check_circle : Icons.error_outline,
                          size: 14,
                          color: _getStatusColor(isSuccess),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isSuccess ? 'Success' : 'Failed',
                          style: TextStyle(
                            color: _getStatusColor(isSuccess),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (result.ipAddress != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        result.ipAddress!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value, IconData icon, {Color? valueColor}) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: valueColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(bool isSuccess) {
    return isSuccess ? Colors.green : Colors.red;
  }

  Color _getResponseTimeColor(int responseTime) {
    if (responseTime < 50) {
      return Colors.green;
    } else if (responseTime < 100) {
      return Colors.lightGreen;
    } else if (responseTime < 200) {
      return Colors.yellow;
    } else if (responseTime < 500) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}