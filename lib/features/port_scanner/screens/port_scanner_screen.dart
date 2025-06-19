import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/models/network_entity.dart';
import '../../../core/utils/constants.dart';
// Removed duplicate import since it's already imported above
import '../../../shared/widgets/feature_screen.dart';
import '../models/port_scan_config.dart';
import '../providers/port_scanner_provider.dart';
import '../widgets/port_scan_result_item.dart';

class PortScannerScreen extends StatefulWidget {
  final String? initialIpAddress;

  const PortScannerScreen({super.key, this.initialIpAddress});

  @override
  State<PortScannerScreen> createState() => _PortScannerScreenState();
}

class _PortScannerScreenState extends State<PortScannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ipAddressController = TextEditingController();
  final _portRangeController = TextEditingController(text: '1-1024');
  final _timeoutController = TextEditingController(text: '3000');
  final _threadCountController = TextEditingController(text: '50');
  
  final _provider = PortScannerProvider();
  bool _isCustomRange = false;
  String _scanMode = 'common';
  
  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }
  
  Future<void> _initializeScreen() async {
    if (widget.initialIpAddress != null) {
      _ipAddressController.text = widget.initialIpAddress!;
    } else {
      // In a real app, this would get the local IP address
      _ipAddressController.text = '192.168.1.1';
    }
    
    await _provider.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _ipAddressController.dispose();
    _portRangeController.dispose();
    _timeoutController.dispose();
    _threadCountController.dispose();
    _provider.dispose();
    super.dispose();
  }

  void _startScan() {
    if (_formKey.currentState?.validate() ?? false) {
      // Hide keyboard
      FocusScope.of(context).unfocus();
      
      List<int> portsToScan = [];
      
      if (_scanMode == 'common') {
        portsToScan = AppConstants.commonPorts;
      } else if (_scanMode == 'all') {
        portsToScan = List.generate(1024, (index) => index + 1);
      } else if (_scanMode == 'custom') {
        final rangeText = _portRangeController.text;
        if (rangeText.contains('-')) {
          final parts = rangeText.split('-');
          if (parts.length == 2) {
            final start = int.tryParse(parts[0].trim()) ?? 1;
            final end = int.tryParse(parts[1].trim()) ?? 1024;
            portsToScan = List.generate(end - start + 1, (index) => index + start);
          }
        } else if (rangeText.contains(',')) {
          portsToScan = rangeText
              .split(',')
              .map((e) => int.tryParse(e.trim()))
              .where((e) => e != null)
              .map((e) => e!)
              .toList();
        } else {
          final singlePort = int.tryParse(rangeText);
          if (singlePort != null) {
            portsToScan = [singlePort];
          }
        }
      }
      
      if (portsToScan.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid port range')),
        );
        return;
      }
      
      final config = PortScanConfig(
        ipAddress: _ipAddressController.text,
        ports: portsToScan,
        timeout: int.tryParse(_timeoutController.text) ?? 3000,
        threadCount: int.tryParse(_threadCountController.text) ?? 50,
      );
      
      _provider.startScan(config);
    }
  }

  void _cancelScan() {
    _provider.cancelScan();
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScreen(
      title: 'Port Scanner',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScanForm(),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedBuilder(
                animation: _provider,
                builder: (context, _) {
                  if (_provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (_provider.isScanning) {
                    return _buildScanningView();
                  }
                  
                  if (_provider.scanResults.isNotEmpty) {
                    return _buildResultsView();
                  }
                  
                  return _buildEmptyState();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _ipAddressController,
            decoration: const InputDecoration(
              labelText: 'IP Address or Hostname',
              hintText: 'e.g., 192.168.1.1 or example.com',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.text,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an IP address or hostname';
              }
              if (!AppHelpers.isValidIpAddress(value) && !AppHelpers.isValidDomain(value)) {
                return 'Invalid IP address or hostname';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Scan Mode',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Common Ports'),
                selected: _scanMode == 'common',
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _scanMode = 'common';
                      _isCustomRange = false;
                    });
                  }
                },
              ),
              ChoiceChip(
                label: const Text('All Ports (1-1024)'),
                selected: _scanMode == 'all',
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _scanMode = 'all';
                      _isCustomRange = false;
                    });
                  }
                },
              ),
              ChoiceChip(
                label: const Text('Custom Range'),
                selected: _scanMode == 'custom',
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _scanMode = 'custom';
                      _isCustomRange = true;
                    });
                  }
                },
              ),
            ],
          ),
          if (_isCustomRange) ...[  
            const SizedBox(height: 16),
            TextFormField(
              controller: _portRangeController,
              decoration: const InputDecoration(
                labelText: 'Port Range',
                hintText: 'e.g., 80,443 or 1-1024',
                border: OutlineInputBorder(),
                helperText: 'Comma-separated list or range (e.g., 80,443 or 1-1024)',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter port range';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _timeoutController,
                  decoration: const InputDecoration(
                    labelText: 'Timeout (ms)',
                    hintText: 'e.g., 3000',
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
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _threadCountController,
                  decoration: const InputDecoration(
                    labelText: 'Threads',
                    hintText: 'e.g., 50',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    final threads = int.tryParse(value);
                    if (threads == null || threads < 1 || threads > 200) {
                      return 'Between 1-200';
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
                if (_provider.isScanning) {
                  return ElevatedButton(
                    onPressed: _cancelScan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Cancel Scan'),
                    ),
                  );
                }
                
                return ElevatedButton(
                  onPressed: _startScan,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Start Scan'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningView() {
    final progress = _provider.progress;
    final scannedCount = _provider.scannedCount;
    final totalCount = _provider.totalCount;
    final openPorts = _provider.scanResults.where((r) => r.status == ServiceStatus.open).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionHeader(
              title: 'Scanning Ports...',
              subtext: 'Checking port status',
            ),
            Text(
              '${openPorts.length} open ports found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
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
        const SizedBox(height: 16),
        if (openPorts.isNotEmpty) ...[  
          const SectionHeader(
            title: 'Open Ports',
            subtext: 'Ports that accepted connections',
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: openPorts.length,
              itemBuilder: (context, index) {
                return PortScanResultItem(
                  result: openPorts[index],
                );
              },
            ),
          ),
        ] else ...[  
          const Expanded(
            child: Center(
              child: Text('Scanning... No open ports found yet.'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResultsView() {
    final openPorts = _provider.scanResults.where((r) => r.status == ServiceStatus.open).toList();
    final closedPorts = _provider.scanResults.where((r) => r.status != ServiceStatus.open).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SectionHeader(
              title: 'Scan Results - Target: ${_provider.lastScanConfig?.ipAddress}',
              subtext: 'Completed scan results',
// Remove this line since subtext is already specified above
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _provider.clearResults();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('New Scan'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildInfoChip(
              context,
              '${openPorts.length} open',
              Icons.check_circle_outline,
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            _buildInfoChip(
              context,
              '${closedPorts.length} closed',
              Icons.cancel_outlined,
              color: Colors.red,
            ),
            const SizedBox(width: 8),
            _buildInfoChip(
              context,
              'Completed in ${_provider.scanDuration?.inSeconds ?? 0}s',
              Icons.timer_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (openPorts.isEmpty) ...[  
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.security,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Open Ports Found',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'All scanned ports appear to be closed or filtered',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ] else ...[  
          const SectionHeader(
            title: 'Open Ports',
            subtext: 'Ports that accepted connections',
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: openPorts.length,
              itemBuilder: (context, index) {
                return PortScanResultItem(
                  result: openPorts[index],
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.security_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Port Scanner',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Scan for open ports on a target device',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure the scan parameters above and press Start Scan',
            textAlign: TextAlign.center,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
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
}