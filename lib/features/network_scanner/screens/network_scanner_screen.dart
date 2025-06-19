import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/network_entity.dart'; // Add this import for NetworkDevice
import '../../../core/utils/constants.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/feature_screen.dart';
import '../models/network_scan_result.dart';
import '../providers/network_scanner_provider.dart';
import '../widgets/device_list_item.dart';
import '../widgets/network_scan_config_form.dart';
import '../widgets/scan_result_summary.dart';

class NetworkScannerScreen extends StatelessWidget {
  const NetworkScannerScreen({super.key}); // Fix the super.key parameter

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NetworkScannerProvider(),
      child: const _NetworkScannerScreenContent(),
    );
  }
}

class _NetworkScannerScreenContent extends StatefulWidget {
  const _NetworkScannerScreenContent();

  @override
  State<_NetworkScannerScreenContent> createState() => _NetworkScannerScreenContentState();
}

class _NetworkScannerScreenContentState extends State<_NetworkScannerScreenContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NetworkScannerProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkScannerProvider>(
      builder: (context, provider, child) {
        return FeatureScreen(
          title: AppConstants.networkScanner,
          body: Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Scanner'),
                  Tab(text: 'History'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildScannerTab(provider),
                    _buildHistoryTab(provider),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: provider.isScanning
              ? FloatingActionButton(
                  onPressed: () => provider.cancelScan(),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.stop),
                )
              : FloatingActionButton(
                  onPressed: () => _showScanConfigDialog(context, provider),
                  child: const Icon(Icons.wifi_find),
                ),
        );
      },
    );
  }

  Widget _buildScannerTab(NetworkScannerProvider provider) {
    if (provider.isLoading) {
      return const LoadingIndicator(message: 'Initializing scanner...');
    }

    if (provider.error != null) {
      return ErrorView(
        message: provider.error!,
        onRetry: () => provider.initialize(),
      );
    }

    if (provider.isScanning) {
      return _buildScanInProgressView(provider);
    }

    if (provider.lastScanResult != null) {
      return _buildScanResultView(provider);
    }

    return Center(
      child: FeatureContentPadding(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_find,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            Text(
              'Network Scanner',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Discover devices on your network',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showScanConfigDialog(context, provider),
              icon: const Icon(Icons.search),
              label: const Text('Start Scan'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanInProgressView(NetworkScannerProvider provider) {
    final scanProgress = provider.currentScanProgress;
    final progress = scanProgress?.metadata['progress'] as double? ?? 0.0;
    final scannedHosts = scanProgress?.metadata['scannedHosts'] as int? ?? 0;
    final totalHosts = scanProgress?.metadata['totalHosts'] as int? ?? 0;
    final deviceCount = scanProgress?.devices.length ?? 0;

    return FeatureContentPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Scan in Progress',
            subtext: 'Scanning network for devices...',
          ),
          LinearProgressIndicator(value: progress / 100),
          const SizedBox(height: 8),
          Text('Scanning $scannedHosts of $totalHosts hosts (${progress.toStringAsFixed(1)}%)'),
          const SizedBox(height: 16),
          Text(
            'Discovered Devices: $deviceCount',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: deviceCount > 0
                ? ListView.builder(
                    itemCount: scanProgress!.devices.length,
                    itemBuilder: (context, index) {
                      final device = scanProgress.devices[index];
                      return DeviceListItem(device: device);
                    },
                  )
                : const Center(
                    child: Text('No devices discovered yet...'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanResultView(NetworkScannerProvider provider) {
    final result = provider.lastScanResult!;
    
    return FeatureContentPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScanResultSummary(result: result),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Discovered Devices (${result.devices.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _showScanConfigDialog(context, provider),
                tooltip: 'New Scan',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: result.devices.isNotEmpty
                ? ListView.builder(
                    itemCount: result.devices.length,
                    itemBuilder: (context, index) {
                      final device = result.devices[index];
                      return DeviceListItem(
                        device: device,
                        onTap: () => _showDeviceDetailsDialog(context, device),
                      );
                    },
                  )
                : const Center(
                    child: Text('No devices discovered'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(NetworkScannerProvider provider) {
    if (provider.isLoadingHistory) {
      return const LoadingIndicator(message: 'Loading scan history...');
    }

    if (provider.scanHistory.isEmpty) {
      return const Center(
        child: Text('No scan history available'),
      );
    }

    return FeatureContentPadding(
      child: ListView.builder(
        itemCount: provider.scanHistory.length,
        itemBuilder: (context, index) {
          final scan = provider.scanHistory[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text('Scan: ${scan.networkRange}'),
              subtitle: Text(
                '${scan.devices.length} devices | ${AppHelpers.formatDateTime(scan.startTime)}',
              ),
              trailing: Text(
                scan.status == ScanStatus.completed ? 'Completed' : scan.status.toString().split('.').last,
                style: TextStyle(
                  color: scan.status == ScanStatus.completed
                      ? Colors.green
                      : scan.status == ScanStatus.failed
                          ? Colors.red
                          : Colors.orange,
                ),
              ),
              onTap: () => provider.setLastScanResult(scan),
            ),
          );
        },
      ),
    );
  }

  void _showScanConfigDialog(BuildContext context, NetworkScannerProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: NetworkScanConfigForm(
            onStartScan: (config) {
              Navigator.pop(context);
              provider.startScan(config);
            },
          ),
        );
      },
    );
  }

  void _showDeviceDetailsDialog(BuildContext context, NetworkDevice device) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(device.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('IP Address', device.ipAddress ?? 'Unknown'),
                _buildDetailRow('MAC Address', device.macAddress ?? 'Unknown'),
                _buildDetailRow('Manufacturer', device.manufacturer ?? 'Unknown'),
                _buildDetailRow('Status', device.isOnline ? 'Online' : 'Offline'),
                _buildDetailRow('Discovered', AppHelpers.formatDateTime(device.discoveredAt)),
                if (device.metadata.containsKey('openPorts')) ...[  
                  const Divider(),
                  const Text(
                    'Open Ports:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: (device.metadata['openPorts'] as List<dynamic>).map((port) {
                      final service = (device.metadata['services'] as Map<String, dynamic>?)?[port.toString()];
                      return Chip(
                        label: Text('$port ${service != null ? "($service)" : ""}'),
                        backgroundColor: Colors.blue.withOpacity(0.1),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}