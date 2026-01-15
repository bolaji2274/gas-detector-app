// // ==================== DEVICE_DETAIL_SCREEN.DART ====================
// // lib/screens/device_detail_screen.dart

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:fl_chart/fl_chart.dart';
// import '../models/device_model.dart';
// import '../services/firebase_service.dart';
// import '../utils/theme.dart';
// import '../widgets/gas_gauge.dart';

// class DeviceDetailScreen extends StatefulWidget {
//   final Device device;

//   const DeviceDetailScreen({super.key, required this.device});

//   @override
//   State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
// }

// class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
//   int _selectedPeriod = 24; // hours

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.device.name),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.settings),
//             onPressed: () {
//               // Navigate to device settings
//             },
//           ),
//         ],
//       ),
//       body: Consumer<FirebaseService>(
//         builder: (context, service, child) {
//           final sensorData = service.currentSensorData;

//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Device Status
//                 _buildDeviceStatus(),

//                 const SizedBox(height: 24),

//                 // Gas Gauges
//                 Row(
//                   children: [
//                     Expanded(
//                       child: GasGauge(
//                         title: 'LPG',
//                         value: sensorData?.lpg ?? 0,
//                         maxValue: 5000,
//                         ranges: const [300, 1000, 2500, 5000],
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: GasGauge(
//                         title: 'CO',
//                         value: sensorData?.co ?? 0,
//                         maxValue: 500,
//                         ranges: const [30, 100, 200, 400],
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 24),

//                 // Period Selector
//                 _buildPeriodSelector(),

//                 const SizedBox(height: 16),

//                 // Historical Chart
//                 _buildHistoricalChart(service),

//                 const SizedBox(height: 24),

//                 // Device Info
//                 _buildDeviceInfo(),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildDeviceStatus() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   width: 12,
//                   height: 12,
//                   decoration: BoxDecoration(
//                     color: widget.device.isOnline
//                         ? AppTheme.successColor
//                         : AppTheme.offlineColor,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   widget.device.isOnline ? 'Online' : 'Offline',
//                   style: Theme.of(context).textTheme.titleMedium,
//                 ),
//                 const Spacer(),
//                 Text(
//                   widget.device.lastSeenFormatted,
//                   style: Theme.of(context).textTheme.bodySmall,
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _buildInfoItem(
//                   Icons.location_on,
//                   'Location',
//                   widget.device.location,
//                 ),
//                 _buildInfoItem(
//                   Icons.wifi,
//                   'Signal',
//                   widget.device.wifiSignalStrength,
//                 ),
//                 _buildInfoItem(
//                   Icons.battery_full,
//                   'Battery',
//                   '${widget.device.batteryLevel}%',
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoItem(IconData icon, String label, String value) {
//     return Column(
//       children: [
//         Icon(icon, color: AppTheme.primaryColor),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: Theme.of(context).textTheme.bodySmall,
//         ),
//         Text(
//           value,
//           style: Theme.of(context).textTheme.titleSmall,
//         ),
//       ],
//     );
//   }

//   Widget _buildPeriodSelector() {
//     return Row(
//       children: [
//         Text(
//           'History',
//           style: Theme.of(context).textTheme.titleLarge,
//         ),
//         const Spacer(),
//         SegmentedButton<int>(
//           segments: const [
//             ButtonSegment(value: 6, label: Text('6h')),
//             ButtonSegment(value: 24, label: Text('24h')),
//             ButtonSegment(value: 168, label: Text('7d')),
//           ],
//           selected: {_selectedPeriod},
//           onSelectionChanged: (Set<int> newSelection) {
//             setState(() {
//               _selectedPeriod = newSelection.first;
//             });
//             final service =
//                 Provider.of<FirebaseService>(context, listen: false);
//             service.loadHistoricalData(
//               widget.device.id,
//               hours: _selectedPeriod,
//             );
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildHistoricalChart(FirebaseService service) {
//     if (service.historicalData.isEmpty) {
//       return const Card(
//         child: Padding(
//           padding: EdgeInsets.all(32),
//           child: Center(
//             child: Text('No historical data available'),
//           ),
//         ),
//       );
//     }

//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: SizedBox(
//           height: 250,
//           child: LineChart(
//             LineChartData(
//               gridData: FlGridData(show: true),
//               titlesData: FlTitlesData(
//                 leftTitles: AxisTitles(
//                   axisNameWidget: const Text('PPM'),
//                   sideTitles: SideTitles(showTitles: true),
//                 ),
//                 bottomTitles: AxisTitles(
//                   sideTitles: SideTitles(showTitles: true),
//                 ),
//                 rightTitles: AxisTitles(
//                   sideTitles: SideTitles(showTitles: false),
//                 ),
//                 topTitles: AxisTitles(
//                   sideTitles: SideTitles(showTitles: false),
//                 ),
//               ),
//               borderData: FlBorderData(show: true),
//               lineBarsData: [
//                 // LPG Line
//                 LineChartBarData(
//                   spots: service.historicalData
//                       .asMap()
//                       .entries
//                       .map((e) => FlSpot(
//                             e.key.toDouble(),
//                             e.value.lpg,
//                           ))
//                       .toList(),
//                   isCurved: true,
//                   color: Colors.blue,
//                   barWidth: 2,
//                   dotData: FlDotData(show: false),
//                 ),
//                 // CO Line
//                 LineChartBarData(
//                   spots: service.historicalData
//                       .asMap()
//                       .entries
//                       .map((e) => FlSpot(
//                             e.key.toDouble(),
//                             e.value.co,
//                           ))
//                       .toList(),
//                   isCurved: true,
//                   color: Colors.orange,
//                   barWidth: 2,
//                   dotData: FlDotData(show: false),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDeviceInfo() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Device Information',
//               style: Theme.of(context).textTheme.titleLarge,
//             ),
//             const SizedBox(height: 16),
//             _buildInfoRow('Device ID', widget.device.id),
//             _buildInfoRow('Hardware Version', widget.device.hardwareVersion),
//             _buildInfoRow('Firmware Version', widget.device.firmwareVersion),
//             _buildInfoRow('Power Source', widget.device.powerSource),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label),
//           Text(
//             value,
//             style: const TextStyle(fontWeight: FontWeight.bold),
//           ),
//         ],
//       ),
//     );
//   }
// }

// ==================== UPDATED GAS_GAUGE.DART ====================
// Single gauge for LPG only

// ==================== UPDATED DEVICE_DETAIL_SCREEN.DART ====================
// lib/screens/device_details.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart'; // ✅ Ensure this is in pubspec.yaml
import '../models/device_model.dart';
import '../services/firebase_service.dart';
import '../utils/theme.dart';
// import '../widgets/gas_gauge.dart'; // ❌ REMOVED: Class is now inline below

// ✅ ADDED: GasGauge class integrated directly
class GasGauge extends StatelessWidget {
  final double value;
  final double maxValue;
  final List<double> ranges;

  const GasGauge({
    super.key,
    required this.value,
    this.maxValue = 5000,
    this.ranges = const [200, 500, 1000, 2000],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'LPG/Home Gas Level',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        
        const SizedBox(height: 16),
        
        SizedBox(
          height: 250,
          child: SfRadialGauge(
            axes: <RadialAxis>[
              RadialAxis(
                minimum: 0,
                maximum: maxValue,
                ranges: <GaugeRange>[
                  GaugeRange(
                    startValue: 0,
                    endValue: ranges[0],
                    color: AppTheme.safeColor,
                    label: 'Safe',
                    labelStyle: const GaugeTextStyle(fontSize: 10),
                  ),
                  GaugeRange(
                    startValue: ranges[0],
                    endValue: ranges[1],
                    color: AppTheme.warningStatusColor,
                    label: 'Warning',
                    labelStyle: const GaugeTextStyle(fontSize: 10),
                  ),
                  GaugeRange(
                    startValue: ranges[1],
                    endValue: ranges[2],
                    color: AppTheme.dangerStatusColor,
                    label: 'Danger',
                    labelStyle: const GaugeTextStyle(fontSize: 10),
                  ),
                  GaugeRange(
                    startValue: ranges[2],
                    endValue: maxValue,
                    color: AppTheme.criticalStatusColor,
                    label: 'Critical',
                    labelStyle: const GaugeTextStyle(fontSize: 10),
                  ),
                ],
                pointers: <GaugePointer>[
                  NeedlePointer(
                    value: value,
                    enableAnimation: true,
                    needleLength: 0.7,
                    needleStartWidth: 1,
                    needleEndWidth: 3,
                    knobStyle: const KnobStyle(
                      knobRadius: 0.08,
                      borderWidth: 0.02,
                    ),
                  ),
                ],
                annotations: <GaugeAnnotation>[
                  GaugeAnnotation(
                    widget: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          value.toStringAsFixed(0),
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'PPM',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    angle: 90,
                    positionFactor: 0.5,
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildLegendItem('Safe', AppTheme.safeColor, '0-200'),
            _buildLegendItem('Warning', AppTheme.warningStatusColor, '200-500'),
            _buildLegendItem('Danger', AppTheme.dangerStatusColor, '500-1000'),
            _buildLegendItem('Critical', AppTheme.criticalStatusColor, '1000+'),
          ],
        ),
      ],
    );
  }
  
  Widget _buildLegendItem(String label, Color color, String range) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text('$label ($range)', style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class DeviceDetailScreen extends StatefulWidget {
  final Device device;

  const DeviceDetailScreen({super.key, required this.device});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  // int _selectedPeriod = 24; // Unused in this snippet but kept if you need it

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to device settings
            },
          ),
        ],
      ),
      body: Consumer<FirebaseService>(
        builder: (context, service, child) {
          final sensorData = service.currentSensorData;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Device Status
                _buildDeviceStatus(),

                const SizedBox(height: 24),

                // Single Gas Gauge (LPG only)
                Center(
                  child: GasGauge(
                    value: sensorData?.lpg ?? 0,
                    maxValue: 5000,
                    ranges: const [200, 500, 1000, 2000],
                  ),
                ),

                const SizedBox(height: 24),

                // Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About MQ-6 Sensor',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'The MQ-6 sensor detects LPG, Propane, and Butane gases '
                          'commonly used in home cooking and heating. It provides '
                          'early warning of gas leaks to keep your home safe.',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '• Safe: Below 200 PPM\n'
                          '• Warning: 200-500 PPM\n'
                          '• Danger: 500-1000 PPM\n'
                          '• Critical: Above 1000 PPM',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Device Info
                _buildDeviceInfo(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeviceStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: widget.device.isOnline
                        ? AppTheme.successColor
                        : AppTheme.offlineColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.device.isOnline ? 'Online' : 'Offline',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  widget.device.lastSeenFormatted,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  Icons.location_on,
                  'Location',
                  widget.device.location,
                ),
                _buildInfoItem(
                  Icons.wifi,
                  'Signal',
                  widget.device.wifiSignalStrength,
                ),
                _buildInfoItem(
                  Icons.battery_full,
                  'Power',
                  widget.device.powerSource == 'mains' ? 'AC' : '${widget.device.batteryLevel}%',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }

  Widget _buildDeviceInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Device ID', widget.device.id),
            _buildInfoRow('Sensor Type', 'MQ-6 (Home Gas)'),
            _buildInfoRow('Hardware Version', widget.device.hardwareVersion),
            _buildInfoRow('Firmware Version', widget.device.firmwareVersion),
            _buildInfoRow('Power Source', widget.device.powerSource),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}