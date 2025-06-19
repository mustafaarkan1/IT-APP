import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/network_entity.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/feature_screen.dart';
import '../providers/ping_provider.dart';
import '../widgets/ping_result_card.dart';
import '../widgets/ping_history_item.dart';

class PingScreen extends StatefulWidget {
  final String? initialTarget;

  const PingScreen({super.key, this.initialTarget});

  @override
  State<PingScreen> createState() => _PingScreenState();
}

class _PingScreenState extends State<PingScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _targetController = TextEditingController();
  final _countController = TextEditingController(text: '4');
  final _timeoutController = TextEditingController(text: '1000');
  final _provider = PingProvider();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    if (widget.initialTarget != null) {
      _targetController.text = widget.initialTarget!;
    }

    await _provider.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _targetController.dispose();
    _countController.dispose();
    _timeoutController.dispose();
    _tabController.dispose();
    _provider.dispose();
    super.dispose();
  }

  void _startPing() {
    if (_formKey.currentState?.validate() ?? false) {
      // Hide keyboard
      FocusScope.of(context).unfocus();

      final target = _targetController.text;
      final count = int.tryParse(_countController.text) ?? 4;
      final timeout = int.tryParse(_timeoutController.text) ?? 1000;

      _provider.startPing(target, count: count, timeout: timeout);
    }
  }

  void _stopPing() {
    _provider.stopPing();
  }

  void _clearResults() {
    _provider.clearCurrentResults();
  }

  void _showPingHistoryDetails(PingResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ping Results: ${result.host}'), // Changed from targetHost to host
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Target', result.host), // Changed from target to host
              _buildDetailRow('Status', result.isSuccess ? 'Success' : 'Failed'),
              if (result.ipAddress != null)
                _buildDetailRow('IP Address', result.ipAddress!),
              _buildDetailRow('Timestamp', _formatDateTime(result.timestamp)),
              _buildDetailRow('Packets Sent', '${result.packetsSent}'),
              _buildDetailRow('Packets Received', '${result.packetsReceived}'),
              _buildDetailRow('Packet Loss', '${result.packetLoss.toStringAsFixed(1)}%'),
              // Remove null checks as these are non-nullable properties
              _buildDetailRow('Min Response Time', '${result.minResponseTime} ms'),
              _buildDetailRow('Max Response Time', '${result.maxResponseTime} ms'),
              if (result.avgResponseTime != null)
                _buildDetailRow('Avg Response Time', '${result.avgResponseTime} ms'),
              const SizedBox(height: 16),
              Text(
                'Response Times',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (result.responseTimes.isEmpty)
                const Text('No responses received'),
              ...result.responseTimes.asMap().entries.map((entry) {
                final index = entry.key;
                final time = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    children: [
                      SizedBox(width: 24, child: Text('${index + 1}.')),
                      Text(time != null ? '$time ms' : 'Timeout'),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              _targetController.text = result.host; // Changed from target to host
              Navigator.pop(context);
              _startPing();
            },
            child: const Text('Ping Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScreen(
      title: 'Ping Tool',
      body: Column(
        children: [
          _buildPingForm(),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Current'),
              Tab(text: 'History'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCurrentTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPingForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _targetController,
              decoration: const InputDecoration(
                labelText: 'Target Host',
                hintText: 'IP Address or Domain (e.g., 192.168.1.1 or google.com)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a target host';
                }
                // Use the correct class name - AppHelpers
                if (!AppHelpers.isValidIpAddress(value) && !AppHelpers.isValidDomain(value)) {
                  return 'Invalid IP address or domain';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _countController,
                    decoration: const InputDecoration(
                      labelText: 'Count',
                      hintText: 'Number of pings',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final count = int.tryParse(value);
                      if (count == null || count < 1 || count > 100) {
                        return 'Between 1-100';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _timeoutController,
                    decoration: const InputDecoration(
                      labelText: 'Timeout (ms)',
                      hintText: 'e.g., 1000',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final timeout = int.tryParse(value);
                      if (timeout == null || timeout < 100 || timeout > 10000) {
                        return 'Between 100-10000';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: AnimatedBuilder(
                animation: _provider,
                builder: (context, _) {
                  if (_provider.isPinging) {
                    return ElevatedButton(
                      onPressed: _stopPing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Stop Ping'),
                      ),
                    );
                  }

                  return ElevatedButton(
                    onPressed: _startPing,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Start Ping'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AnimatedBuilder(
        animation: _provider,
        builder: (context, _) {
          if (_provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_provider.currentResult == null && !_provider.isPinging) {
            return _buildEmptyState();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _provider.isPinging ? 'Pinging...' : 'Ping Results',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (!_provider.isPinging && _provider.currentResult != null)
                    TextButton(
                      onPressed: _clearResults,
                      child: const Text('Clear'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_provider.currentResult != null) ...[  
                PingResultCard(
                  result: _provider.currentResult!,
                  isLive: _provider.isPinging,
                ),
              ],
              if (_provider.isPinging) ...[  
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text(
                  'Ping ${_provider.currentPingCount} of ${_provider.totalPingCount}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AnimatedBuilder(
        animation: _provider,
        builder: (context, _) {
          if (_provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_provider.pingHistory.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Ping History',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your ping history will appear here',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ping History',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: _provider.clearHistory,
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  // In the ListView.builder for ping history
                  itemCount: _provider.pingHistory.length,
                  itemBuilder: (context, index) {
                    final historyItem = _provider.pingHistory[index];
                    return PingHistoryItem(
                      result: historyItem,
                      onTap: () => _showPingHistoryDetails(historyItem),
                      // Remove onPingAgain parameter as it's not supported
                      onDelete: () => _provider.deleteHistoryItem(historyItem),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.network_ping,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Ping Tool',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter a target host and press Start Ping',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}