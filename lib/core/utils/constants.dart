class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // App information
  static const String appName = 'IT Toolkit Pro';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'A comprehensive IT toolkit for network engineers and IT professionals';

  // Navigation routes
  static const String homeRoute = '/';
  static const String networkScannerRoute = '/network-scanner';
  static const String portScannerRoute = '/port-scanner';
  static const String pingToolRoute = '/ping-tool';
  static const String wifiAnalyzerRoute = '/wifi-analyzer';
  static const String dnsLookupRoute = '/dns-lookup';
  static const String whoisLookupRoute = '/whois-lookup';
  static const String tracerouteRoute = '/traceroute';
  static const String speedTestRoute = '/speed-test';
  static const String sshTerminalRoute = '/ssh-terminal';
  static const String qrGeneratorRoute = '/qr-generator';
  static const String reportGeneratorRoute = '/report-generator';
  static const String settingsRoute = '/settings';

  // Feature names
  static const String networkScanner = 'Network Scanner';
  static const String portScanner = 'Port Scanner';
  static const String pingTool = 'Ping Tool';
  static const String wifiAnalyzer = 'WiFi Analyzer';
  static const String dnsLookup = 'DNS Lookup';
  static const String whoisLookup = 'WHOIS Lookup';
  static const String traceroute = 'Traceroute';
  static const String speedTest = 'Speed Test';
  static const String sshTerminal = 'SSH Terminal';
  static const String qrGenerator = 'QR Generator';
  static const String reportGenerator = 'Report Generator';
  static const String settings = 'Settings';

  // Storage keys
  static const String themePreferenceKey = 'theme_preference';
  static const String languagePreferenceKey = 'language_preference';
  static const String userSettingsKey = 'user_settings';
  static const String scanHistoryKey = 'scan_history';
  static const String savedConnectionsKey = 'saved_connections';

  // Default values
  static const int defaultPingCount = 4;
  static const int defaultTimeout = 5000; // milliseconds
  static const int defaultPortScanTimeout = 3000; // milliseconds
  static const int defaultThreadCount = 10;
  static const int maxSavedHistory = 50;

  // Common port ranges
  static const int minPort = 1;
  static const int maxPort = 65535;
  static const List<int> commonPorts = [21, 22, 23, 25, 53, 80, 110, 123, 143, 443, 465, 587, 993, 995, 3306, 3389, 5900, 8080];

  // Error messages
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String timeoutErrorMessage = 'Request timed out. Please try again.';
  static const String permissionDeniedMessage = 'Permission denied. Please grant the required permissions.';
  static const String unknownErrorMessage = 'An unknown error occurred. Please try again.';
}