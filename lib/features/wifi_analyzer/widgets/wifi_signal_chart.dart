import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/models/network_entity.dart';

class WifiSignalChart extends StatelessWidget {
  final List<WifiNetwork> networks;
  final bool is5GHz;

  const WifiSignalChart({

    Key? key,
    required this.networks,
    this.is5GHz = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (networks.isEmpty) {
      return const Center(
        child: Text('No networks found in this frequency band'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _WifiChannelPainter(
            networks: networks,
            is5GHz: is5GHz,
          ),
          child: _buildNetworkLabels(context),
        );
      },
    );
  }

  Widget _buildNetworkLabels(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40), // Space for the chart axis
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: networks.map((network) {
                final signalQuality = _calculateSignalQuality(network.signalStrength);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getNetworkColor(network, networks),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      network.ssid.isEmpty ? 'Hidden Network' : network.ssid,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getNetworkColor(network, networks),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${network.signalStrength} dBm (${(signalQuality * 100).toInt()}%)',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  double _calculateSignalQuality(int signalStrength) {
    // Convert dBm to quality percentage (0.0 to 1.0)
    // Typical values: -30 dBm (excellent) to -90 dBm (unusable)
    const int EXCELLENT_SIGNAL = -50;
    const int UNUSABLE_SIGNAL = -90;
    
    if (signalStrength >= EXCELLENT_SIGNAL) return 1.0;
    if (signalStrength <= UNUSABLE_SIGNAL) return 0.0;
    
    return (signalStrength - UNUSABLE_SIGNAL) / (EXCELLENT_SIGNAL - UNUSABLE_SIGNAL);
  }

  Color _getNetworkColor(WifiNetwork network, List<WifiNetwork> allNetworks) {
    // Generate a unique color for each network
    final List<Color> colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];
    
    final index = allNetworks.indexOf(network) % colors.length;
    return colors[index];
  }
}

class _WifiChannelPainter extends CustomPainter {
  final List<WifiNetwork> networks;
  final bool is5GHz;

  _WifiChannelPainter({
    required this.networks,
    required this.is5GHz,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.grey;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Draw horizontal axis
    canvas.drawLine(
      Offset(0, 40),
      Offset(size.width, 40),
      paint,
    );

    // Draw channel markers
    final channels = is5GHz ? _get5GHzChannels() : _get24GHzChannels();
    final channelWidth = size.width / (channels.length + 1);

    for (int i = 0; i < channels.length; i++) {
      final x = channelWidth * (i + 1);
      
      // Draw channel tick
      canvas.drawLine(
        Offset(x, 40),
        Offset(x, 45),
        paint,
      );

      // Draw channel number
      textPainter.text = TextSpan(
        text: channels[i].toString(),
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, 45),
      );
    }

    // Draw signal strength scale on the left
    final signalLevels = [
      {'label': '-30 dBm', 'value': -30},
      {'label': '-50 dBm', 'value': -50},
      {'label': '-70 dBm', 'value': -70},
      {'label': '-90 dBm', 'value': -90},
    ];

    for (final level in signalLevels) {
      final y = _mapSignalToY(level['value'] as int, size.height);
      
      // Draw horizontal guide line
      final dashPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = Colors.grey.withOpacity(0.5);
      
      // Draw dashed line
      final dashWidth = 5.0;
      const dashSpace = 3.0;
      double startX = 0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, y),
          Offset(startX + dashWidth, y),
          dashPaint,
        );
        startX += dashWidth + dashSpace;
      }

      // Draw signal level text
      textPainter.text = TextSpan(
        text: level['label'] as String,
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(0, y - textPainter.height / 2),
      );
    }

    // Draw network signals
    for (final network in networks) {
      final channelIndex = channels.indexOf(network.channel);
      if (channelIndex == -1) continue; // Skip if channel not in our list
      
      final x = channelWidth * (channelIndex + 1);
      final y = _mapSignalToY(network.signalStrength, size.height);
      final signalQuality = _calculateSignalQuality(network.signalStrength);
      final networkColor = _getNetworkColor(network, networks);
      
      // Draw signal curve
      final curvePaint = Paint()
        ..style = PaintingStyle.fill
        ..color = networkColor.withOpacity(0.2);
      
      final path = Path();
      final curveWidth = channelWidth * 1.5; // Width of the curve
      
      path.moveTo(x - curveWidth, 40); // Start at x-width on the axis
      
      // Draw the bell curve
      for (double i = -curveWidth; i <= curveWidth; i += 2) {
        final curveX = x + i;
        final normalizedDistance = i / curveWidth; // -1 to 1
        final bellCurveY = signalQuality * _bellCurve(normalizedDistance);
        final curveY = 40 - bellCurveY * (40 - y);
        
        if (i == -curveWidth) {
          path.moveTo(curveX, 40);
        } else {
          path.lineTo(curveX, curveY);
        }
      }
      
      path.lineTo(x + curveWidth, 40); // End at x+width on the axis
      path.close();
      
      canvas.drawPath(path, curvePaint);
      
      // Draw peak point
      final peakPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = networkColor;
      
      canvas.drawCircle(Offset(x, y), 4, peakPaint);
    }
  }

  double _bellCurve(double x) {
    // Simple bell curve function: e^(-x²)
    return Math.exp(-4 * x * x);
  }

  double _mapSignalToY(int signalStrength, double height) {
    // Map signal strength (dBm) to Y coordinate
    // -30 dBm (excellent) at the top, -90 dBm (poor) near the bottom
    const int EXCELLENT_SIGNAL = -30;
    const int POOR_SIGNAL = -90;
    
    // Constrain signal strength to our range
    final constrainedSignal = signalStrength.clamp(POOR_SIGNAL, EXCELLENT_SIGNAL);
    
    // Calculate percentage (0.0 to 1.0) where 1.0 is excellent
    final percentage = (constrainedSignal - POOR_SIGNAL) / (EXCELLENT_SIGNAL - POOR_SIGNAL);
    
    // Map to Y coordinate (leave space at top and bottom)
    const double TOP_MARGIN = 50.0;
    const double BOTTOM_MARGIN = 10.0;
    final availableHeight = height - TOP_MARGIN - BOTTOM_MARGIN;
    
    return height - BOTTOM_MARGIN - (percentage * availableHeight);
  }

  List<int> _get24GHzChannels() {
    // Return the standard 2.4 GHz channels
    return [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];
  }

  List<int> _get5GHzChannels() {
    // Return common 5 GHz channels
    return [36, 40, 44, 48, 52, 56, 60, 64, 100, 104, 108, 112, 116, 120, 124, 128, 132, 136, 140, 144, 149, 153, 157, 161, 165];
  }

  Color _getNetworkColor(WifiNetwork network, List<WifiNetwork> allNetworks) {
    // Generate a unique color for each network
    final List<Color> colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];
    
    final index = allNetworks.indexOf(network) % colors.length;
    return colors[index];
  }

  double _calculateSignalQuality(int signalStrength) {
    // Convert dBm to quality percentage (0.0 to 1.0)
    const int EXCELLENT_SIGNAL = -50;
    const int UNUSABLE_SIGNAL = -90;
    
    if (signalStrength >= EXCELLENT_SIGNAL) return 1.0;
    if (signalStrength <= UNUSABLE_SIGNAL) return 0.0;
    
    return (signalStrength - UNUSABLE_SIGNAL) / (EXCELLENT_SIGNAL - UNUSABLE_SIGNAL);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// Math utilities
class Math {
  static double exp(double x) {
    return double.parse(math.exp(x).toStringAsFixed(10));
  }
}

// Import dart:math with a prefix to avoid conflicts
