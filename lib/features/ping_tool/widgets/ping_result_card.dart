import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/network_entity.dart';

class PingResultCard extends StatelessWidget {
  final PingResult result;
  final bool isLive;

  const PingResultCard({
    super.key,
    required this.result,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    final receivedCount = result.packetsReceived;
    final sentCount = result.packetsSent;
    final lossPercentage = result.packetLoss;
    final isSuccess = result.isSuccess;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                      if (result.ipAddress != null) ...[  
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              result.ipAddress!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: result.ipAddress!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('IP address copied to clipboard')),
                                );
                              },
                              child: Icon(
                                Icons.copy,
                                size: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(context, isSuccess).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSuccess ? Icons.check_circle : Icons.error_outline,
                        size: 16,
                        color: _getStatusColor(context, isSuccess),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSuccess ? 'Success' : 'Failed',
                        style: TextStyle(
                          color: _getStatusColor(context, isSuccess),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  context,
                  'Sent',
                  '$sentCount',
                  Icons.upload_outlined,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  context,
                  'Received',
                  '$receivedCount',
                  Icons.download_outlined,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  context,
                  'Loss',
                  '${lossPercentage.toStringAsFixed(1)}%',
                  Icons.signal_cellular_connected_no_internet_4_bar,
                  valueColor: lossPercentage > 0 ? Colors.orange : Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (result.avgResponseTime != null) ...[  
              Row(
                children: [
                  _buildStatCard(
                    context,
                    'Min',
                    '${result.minResponseTime} ms',
                    Icons.arrow_downward,
                  ),
                  const SizedBox(width: 8),
                  _buildStatCard(
                    context,
                    'Avg',
                    '${result.avgResponseTime!.toStringAsFixed(1)} ms',
                    Icons.speed,
                  ),
                  const SizedBox(width: 8),
                  _buildStatCard(
                    context,
                    'Max',
                    '${result.maxResponseTime} ms',
                    Icons.arrow_upward,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Response Times',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: _buildResponseTimesChart(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, {Color? valueColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
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
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: valueColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseTimesChart(BuildContext context) {
    final responseTimes = result.responseTimes;
    if (responseTimes.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final barWidth = width / (responseTimes.length * 2 - 1);

        // Find the maximum response time for scaling
        final maxTime = responseTimes
            .where((time) => time != null)
            .map((time) => time!)
            .fold(0, (max, time) => time > max ? time : max);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(responseTimes.length * 2 - 1, (index) {
            // Only show bars at even indices
            if (index % 2 == 1) {
              return SizedBox(width: barWidth);
            }

            final responseIndex = index ~/ 2;
            final responseTime = responseTimes[responseIndex];

            if (responseTime == null) {
              // Timeout bar
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: barWidth,
                    height: height * 0.8,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          'Timeout',
                          style: TextStyle(fontSize: 10, color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${responseIndex + 1}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            }

            // Calculate bar height based on response time
            final barHeight = maxTime > 0
                ? (responseTime / maxTime) * height * 0.8
                : height * 0.1;

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: barWidth,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: _getResponseTimeColor(responseTime),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${responseIndex + 1}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          }),
        );
      },
    );
  }

  Color _getStatusColor(BuildContext context, bool isSuccess) {
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