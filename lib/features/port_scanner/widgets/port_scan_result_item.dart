import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/network_entity.dart';

class PortScanResultItem extends StatelessWidget {
  final PortScanResult result;

  const PortScanResultItem({
    Key? key,
    required this.result,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showPortDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: result.status == ServiceStatus.open
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    result.status == ServiceStatus.open ? Icons.check_circle_outline : Icons.cancel_outlined,
                    color: result.status == ServiceStatus.open ? Colors.green : Colors.red,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Port ${result.port}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(width: 8),
                        if (result.status == ServiceStatus.open && result.serviceName != null) ...[  
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              result.serviceName!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getPortDescription(result.port, result.serviceName),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    ...[
                      const SizedBox(height: 4),
                      Text(
                        'Response time: ${result.scanDuration} ms',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Copy port number',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: result.port.toString()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Port number copied to clipboard')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPortDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Port ${result.port} Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(context, 'Status', result.status == ServiceStatus.open ? 'Open' : 'Closed'),
              const SizedBox(height: 8),
              _buildDetailRow(
                context,
                'Service',
                result.serviceName ?? _getCommonServiceName(result.port) ?? 'Unknown',
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 8),
              _buildDetailRow(context, 'Response Time', '${result.scanDuration} ms'),
              const SizedBox(height: 8),
              _buildDetailRow(context, 'Description', _getPortDescription(result.port, result.serviceName)),
              const SizedBox(height: 16),
              Text(
                'Common Usage',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(_getPortUsage(result.port)),
            ],
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

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  String? _getCommonServiceName(int port) {
    switch (port) {
      case 21:
        return 'FTP';
      case 22:
        return 'SSH';
      case 23:
        return 'Telnet';
      case 25:
        return 'SMTP';
      case 53:
        return 'DNS';
      case 80:
        return 'HTTP';
      case 110:
        return 'POP3';
      case 143:
        return 'IMAP';
      case 443:
        return 'HTTPS';
      case 445:
        return 'SMB';
      case 3389:
        return 'RDP';
      case 8080:
        return 'HTTP-ALT';
      default:
        return null;
    }
  }

  String _getPortDescription(int port, String? serviceName) {
    final service = serviceName ?? _getCommonServiceName(port);
    
    if (service == null) {
      return 'Unknown service';
    }
    
    switch (service.toUpperCase()) {
      case 'FTP':
        return 'File Transfer Protocol';
      case 'SSH':
        return 'Secure Shell';
      case 'TELNET':
        return 'Telnet Remote Login Service';
      case 'SMTP':
        return 'Simple Mail Transfer Protocol';
      case 'DNS':
        return 'Domain Name System';
      case 'HTTP':
        return 'Hypertext Transfer Protocol';
      case 'POP3':
        return 'Post Office Protocol v3';
      case 'IMAP':
        return 'Internet Message Access Protocol';
      case 'HTTPS':
        return 'HTTP Secure';
      case 'SMB':
        return 'Server Message Block';
      case 'RDP':
        return 'Remote Desktop Protocol';
      case 'HTTP-ALT':
        return 'Alternative HTTP Port';
      default:
        return '$service service';
    }
  }

  String _getPortUsage(int port) {
    switch (port) {
      case 21:
        return 'Used for file transfers between a client and server.';
      case 22:
        return 'Provides secure remote login and other secure network services.';
      case 23:
        return 'Legacy protocol for remote login to network devices (insecure).';
      case 25:
        return 'Used for email routing between mail servers.';
      case 53:
        return 'Translates domain names to IP addresses.';
      case 80:
        return 'Used for unencrypted web browsing.';
      case 110:
        return 'Used by email clients to retrieve emails from a mail server.';
      case 143:
        return 'Used by email clients to retrieve emails with more features than POP3.';
      case 443:
        return 'Used for secure web browsing with SSL/TLS encryption.';
      case 445:
        return 'Used for file sharing in Windows networks.';
      case 3389:
        return 'Allows remote desktop connections to Windows computers.';
      case 8080:
        return 'Commonly used as an alternative to port 80 for web servers and proxies.';
      default:
        return 'This port may be used by various applications or services.';
    }
  }
}
