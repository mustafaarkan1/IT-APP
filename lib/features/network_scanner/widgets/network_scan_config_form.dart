import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/constants.dart';
// import '../../../core/utils/helpers.dart';  // Remove this line
import '../models/network_scan_result.dart';

class NetworkScanConfigForm extends StatefulWidget {
  final Function(NetworkScanConfig) onStartScan;

  const NetworkScanConfigForm({
    Key? key,
    required this.onStartScan,
  }) : super(key: key);

  @override
  State<NetworkScanConfigForm> createState() => _NetworkScanConfigFormState();
}

class _NetworkScanConfigFormState extends State<NetworkScanConfigForm> {
  final _formKey = GlobalKey<FormState>();
  final _networkRangeController = TextEditingController();
  final _timeoutController = TextEditingController(text: '5000');
  final _threadCountController = TextEditingController(text: '10');
  
  bool _scanPorts = false;
  final List<int> _selectedPorts = [80, 443, 22, 21];
  bool _resolveMacVendors = true;
  bool _resolveHostnames = true;
  bool _isLoading = true;
  String? _localNetworkRange;

  @override
  void initState() {
    super.initState();
    _detectLocalNetwork();
  }

  @override
  void dispose() {
    _networkRangeController.dispose();
    _timeoutController.dispose();
    _threadCountController.dispose();
    super.dispose();
  }

  Future<void> _detectLocalNetwork() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, this would use the NetworkService to get the local network range
      // For now, we'll just use a placeholder
      await Future.delayed(const Duration(milliseconds: 500));
      _localNetworkRange = '192.168.1.*';
      _networkRangeController.text = _localNetworkRange ?? '';
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final config = NetworkScanConfig(
        networkRange: _networkRangeController.text,
        timeout: int.tryParse(_timeoutController.text) ?? 5000,
        threadCount: int.tryParse(_threadCountController.text) ?? 10,
        scanPorts: _scanPorts,
        portsToScan: _selectedPorts,
        resolveMacVendors: _resolveMacVendors,
        resolveHostnames: _resolveHostnames,
      );

      widget.onStartScan(config);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Network Scan Configuration',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_isLoading) ...[  
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
            ] else ...[  
              _buildNetworkRangeField(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeoutField(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildThreadCountField(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildPortScanOptions(),
              const SizedBox(height: 16),
              _buildAdditionalOptions(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Start Scan'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkRangeField() {
    return TextFormField(
      controller: _networkRangeController,
      decoration: InputDecoration(
        labelText: 'Network Range',
        hintText: 'e.g., 192.168.1.* or 10.0.0.1-10.0.0.254',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: _showNetworkRangeInfo,
          tooltip: 'Network Range Format',
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a network range';
        }
        // Basic validation - a more comprehensive validation would be done in a real app
        if (!value.contains('.')) {
          return 'Invalid network range format';
        }
        return null;
      },
    );
  }

  Widget _buildTimeoutField() {
    return TextFormField(
      controller: _timeoutController,
      decoration: const InputDecoration(
        labelText: 'Timeout (ms)',
        hintText: 'e.g., 5000',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        final timeout = int.tryParse(value);
        if (timeout == null || timeout < 100 || timeout > 30000) {
          return 'Between 100-30000';
        }
        return null;
      },
    );
  }

  Widget _buildThreadCountField() {
    return TextFormField(
      controller: _threadCountController,
      decoration: const InputDecoration(
        labelText: 'Threads',
        hintText: 'e.g., 10',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        final threads = int.tryParse(value);
        if (threads == null || threads < 1 || threads > 100) {
          return 'Between 1-100';
        }
        return null;
      },
    );
  }

  Widget _buildPortScanOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Scan Common Ports'),
          subtitle: const Text('Check for open services on discovered devices'),
          value: _scanPorts,
          onChanged: (value) {
            setState(() {
              _scanPorts = value;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        if (_scanPorts) ...[  
          const SizedBox(height: 8),
          const Text('Ports to scan:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.commonPorts.map((port) {
              final isSelected = _selectedPorts.contains(port);
              return FilterChip(
                label: Text(port.toString()),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedPorts.add(port);
                    } else {
                      _selectedPorts.remove(port);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildAdditionalOptions() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Resolve MAC Vendors'),
          subtitle: const Text('Identify device manufacturers by MAC address'),
          value: _resolveMacVendors,
          onChanged: (value) {
            setState(() {
              _resolveMacVendors = value;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Resolve Hostnames'),
          subtitle: const Text('Attempt to get device names via DNS'),
          value: _resolveHostnames,
          onChanged: (value) {
            setState(() {
              _resolveHostnames = value;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  void _showNetworkRangeInfo() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Network Range Formats'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Supported formats:'),
                SizedBox(height: 8),
                Text('• Single IP: 192.168.1.1'),
                Text('• Wildcard: 192.168.1.*'),
                Text('• Range: 192.168.1.1-192.168.1.254'),
                Text('• CIDR: 192.168.1.0/24'),
                SizedBox(height: 16),
                Text(
                  'Note: Scanning large networks may take a long time and consume significant resources.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
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
}