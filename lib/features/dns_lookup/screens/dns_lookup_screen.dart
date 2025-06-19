import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/feature_screen.dart';
import '../providers/dns_lookup_provider.dart';

class DnsLookupScreen extends StatefulWidget {
  const DnsLookupScreen({super.key});

  @override
  State<DnsLookupScreen> createState() => _DnsLookupScreenState();
}

class _DnsLookupScreenState extends State<DnsLookupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _domainController = TextEditingController();
  final _recordTypeController = TextEditingController(text: 'A');
  bool _isAdvancedMode = false;

  @override
  void dispose() {
    _domainController.dispose();
    _recordTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DnsLookupProvider(),
      child: FeatureScreen(
        title: 'DNS Lookup',
        body: Consumer<DnsLookupProvider>(
          builder: (context, provider, _) {
            return FeatureContentPadding(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildForm(context, provider),
                  const SizedBox(height: 16),
                  _buildResults(context, provider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, DnsLookupProvider provider) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Domain Lookup',
            subtext: 'Enter a domain name or IP address to lookup DNS records',
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _domainController,
            decoration: const InputDecoration(
              labelText: 'Domain or IP Address',
              hintText: 'example.com or 8.8.8.8',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.language),
            ),
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a domain or IP address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: provider.isLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            provider.performLookup(
                              _domainController.text,
                              _isAdvancedMode ? _recordTypeController.text : 'A',
                            );
                          }
                        },
                  icon: const Icon(Icons.search),
                  label: const Text('Lookup'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(_isAdvancedMode
                    ? Icons.expand_less
                    : Icons.expand_more),
                onPressed: () {
                  setState(() {
                    _isAdvancedMode = !_isAdvancedMode;
                  });
                },
                tooltip: _isAdvancedMode
                    ? 'Hide advanced options'
                    : 'Show advanced options',
              ),
            ],
          ),
          if (_isAdvancedMode) ...[  
            const SizedBox(height: 16),
            const Text('Record Type'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _recordTypeController.text,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'A', child: Text('A (IPv4 Address)')),
                DropdownMenuItem(value: 'AAAA', child: Text('AAAA (IPv6 Address)')),
                DropdownMenuItem(value: 'MX', child: Text('MX (Mail Exchange)')),
                DropdownMenuItem(value: 'NS', child: Text('NS (Name Server)')),
                DropdownMenuItem(value: 'TXT', child: Text('TXT (Text)')),
                DropdownMenuItem(value: 'CNAME', child: Text('CNAME (Canonical Name)')),
                DropdownMenuItem(value: 'SOA', child: Text('SOA (Start of Authority)')),
                DropdownMenuItem(value: 'PTR', child: Text('PTR (Pointer)')),
                DropdownMenuItem(value: 'SRV', child: Text('SRV (Service)')),
                DropdownMenuItem(value: 'CAA', child: Text('CAA (Certification Authority Authorization)')),
              ],
              onChanged: (value) {
                if (value != null) {
                  _recordTypeController.text = value;
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, DnsLookupProvider provider) {
    if (provider.isLoading) {
      return const LoadingIndicator(message: 'Looking up DNS records...');
    }

    if (provider.error != null) {
      return ErrorView(
        message: provider.error!,
        onRetry: () {
          if (_formKey.currentState!.validate()) {
            provider.performLookup(
              _domainController.text,
              _isAdvancedMode ? _recordTypeController.text : 'A',
            );
          }
        },
      );
    }

    if (provider.results.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionHeader(
              title: 'Results',
              subtext: 'DNS lookup results for the specified domain',
            ),
            if (provider.results.isNotEmpty)
              TextButton.icon(
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy All'),
                onPressed: () {
                  final text = provider.results.entries
                      .map((e) => '${e.key}: ${e.value.join(", ")}')
                      .join('\n');
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Results copied to clipboard')),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...provider.results.entries.map((entry) {
          return ResultCard(
            title: entry.key,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entry.value.map((value) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          value,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: value));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Value copied to clipboard')),
                          );
                        },
                        tooltip: 'Copy value',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ],
    );
  }
}