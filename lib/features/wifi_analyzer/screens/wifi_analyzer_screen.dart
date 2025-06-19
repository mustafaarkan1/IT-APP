import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/network_entity.dart';
import '../../../shared/widgets/feature_screen.dart';
import '../providers/wifi_analyzer_provider.dart';
import '../widgets/wifi_network_item.dart';
import '../widgets/wifi_signal_chart.dart';

class WifiAnalyzerScreen extends StatefulWidget {
  const WifiAnalyzerScreen({Key? key}) : super(key: key);

  @override
  State<WifiAnalyzerScreen> createState() => _WifiAnalyzerScreenState();
}

class _WifiAnalyzerScreenState extends State<WifiAnalyzerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WifiAnalyzerProvider(),
      child: FeatureScreen(
        title: 'WiFi Analyzer',
        body: Consumer<WifiAnalyzerProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Networks'),
                    Tab(text: 'Channel Graph'),
                  ],
                  labelColor: Theme.of(context).colorScheme.primary,
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNetworksList(context, provider),
                      _buildChannelGraph(context, provider),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: Consumer<WifiAnalyzerProvider>(
          builder: (context, provider, _) {
            return FloatingActionButton(
              onPressed: provider.isLoading ? null : provider.scanWifiNetworks,
              tooltip: 'Scan WiFi Networks',
              child: provider.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Icon(Icons.refresh),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNetworksList(BuildContext context, WifiAnalyzerProvider provider) {
    if (provider.isLoading) {
      return const LoadingIndicator(message: 'Scanning WiFi networks...');
    }

    if (provider.error != null) {
      return ErrorView(
        message: provider.error!,
        onRetry: provider.scanWifiNetworks,
      );
    }

    if (provider.networks.isEmpty) {
      return const Center(
        child: Text('No WiFi networks found. Tap the refresh button to scan.'),
      );
    }

    return FeatureContentPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Found ${provider.networks.length} networks',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  'Last scan: ${provider.lastScanTime}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: provider.networks.length,
              itemBuilder: (context, index) {
                final network = provider.networks[index];
                return WifiNetworkItem(
                  network: network,
                  onTap: () => _showNetworkDetails(context, network),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelGraph(BuildContext context, WifiAnalyzerProvider provider) {
    if (provider.isLoading) {
      return const LoadingIndicator(message: 'Scanning WiFi networks...');
    }

    if (provider.error != null) {
      return ErrorView(
        message: provider.error!,
        onRetry: provider.scanWifiNetworks,
      );
    }

    if (provider.networks.isEmpty) {
      return const Center(
        child: Text('No WiFi networks found. Tap the refresh button to scan.'),
      );
    }

    return FeatureContentPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '2.4 GHz Channels',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  'Last scan: ${provider.lastScanTime}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: WifiSignalChart(
              networks: provider.networks
                  .where((network) => int.parse(network.frequency) < 5000)
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              '5 GHz Channels',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Expanded(
            child: WifiSignalChart(
              networks: provider.networks
                  .where((network) => int.parse(network.frequency) >= 5000)
                  .toList(),
              is5GHz: true,
            ),
          ),
        ],
      ),
    );
  }

  void _showNetworkDetails(BuildContext context, WifiNetwork network) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(network.ssid.isEmpty ? 'Hidden Network' : network.ssid),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('BSSID', network.bssid),
              _buildDetailRow('Signal Strength', '${network.signalStrength} dBm'),
              _buildDetailRow('Channel', '${network.channel}'),
              _buildDetailRow('Frequency', '${network.frequency} MHz'),
              _buildDetailRow('Security', network.securityType),
              _buildDetailRow('Band', int.parse(network.frequency) >= 5000 ? '5 GHz' : '2.4 GHz'),
              _buildDetailRow('Vendor', network.metadata['vendor'] ?? 'Unknown'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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