import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/constants.dart';
import 'core/services/storage_service.dart';

// Feature screens
import 'features/network_scanner/screens/network_scanner_screen.dart';
import 'features/port_scanner/screens/port_scanner_screen.dart';
import 'features/ping_tool/screens/ping_screen.dart';
import 'features/dns_lookup/screens/dns_lookup_screen.dart';
import 'features/wifi_analyzer/screens/wifi_analyzer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  await StorageService().init();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
      routes: {
        // AppConstants.homeRoute: (context) => const HomePage(),  // قم بإزالة أو تعليق هذا السطر
        AppConstants.networkScannerRoute: (context) => const NetworkScannerScreen(),
        AppConstants.portScannerRoute: (context) => const PortScannerScreen(),
        AppConstants.pingToolRoute: (context) => const PingScreen(),
        AppConstants.dnsLookupRoute: (context) => const DnsLookupScreen(),
        AppConstants.wifiAnalyzerRoute: (context) => const WifiAnalyzerScreen(),
        // Other routes will be added as we implement each feature
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings page
              // Will be implemented later
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'IT Tools',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildFeatureCard(
                    context,
                    AppConstants.networkScanner,
                    Icons.wifi_find,
                    AppConstants.networkScannerRoute,
                    Colors.blue,
                  ),
                  _buildFeatureCard(
                    context,
                    AppConstants.portScanner,
                    Icons.security,
                    AppConstants.portScannerRoute,
                    Colors.orange,
                  ),
                  _buildFeatureCard(
                    context,
                    AppConstants.pingTool,
                    Icons.network_ping,
                    AppConstants.pingToolRoute,
                    Colors.green,
                  ),
                  _buildFeatureCard(
                    context,
                    AppConstants.wifiAnalyzer,
                    Icons.wifi,
                    AppConstants.wifiAnalyzerRoute,
                    Colors.purple,
                  ),
                  _buildFeatureCard(
                    context,
                    AppConstants.dnsLookup,
                    Icons.dns,
                    AppConstants.dnsLookupRoute,
                    Colors.teal,
                  ),
                  _buildFeatureCard(
                    context,
                    AppConstants.whoisLookup,
                    Icons.search,
                    AppConstants.whoisLookupRoute,
                    Colors.indigo,
                  ),
                  _buildFeatureCard(
                    context,
                    AppConstants.traceroute,
                    Icons.route,
                    AppConstants.tracerouteRoute,
                    Colors.red,
                  ),
                  _buildFeatureCard(
                    context,
                    AppConstants.speedTest,
                    Icons.speed,
                    AppConstants.speedTestRoute,
                    Colors.amber,
                  ),
                  _buildFeatureCard(
                    context,
                    AppConstants.sshTerminal,
                    Icons.terminal,
                    AppConstants.sshTerminalRoute,
                    Colors.blueGrey,
                  ),
                  _buildFeatureCard(
                    context,
                    AppConstants.qrGenerator,
                    Icons.qr_code,
                    AppConstants.qrGeneratorRoute,
                    Colors.deepPurple,
                  ),
                  _buildFeatureCard(
                    context,
                    AppConstants.reportGenerator,
                    Icons.summarize,
                    AppConstants.reportGeneratorRoute,
                    Colors.brown,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, IconData icon, String route, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Navigate to the feature page
          Navigator.pushNamed(context, route);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
