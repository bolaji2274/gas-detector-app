// ==================== GAS_GAUGE.DART ====================
// // lib/widgets/gas_gauge.dart

// import 'package:flutter/material.dart';
// import 'package:syncfusion_flutter_gauges/gauges.dart';
// import '../utils/theme.dart';

// class GasGauge extends StatelessWidget {
//   final String title;
//   final double value;
//   final double maxValue;
//   final String unit;
//   final List<double> ranges;

//   const GasGauge({
//     super.key,
//     required this.title,
//     required this.value,
//     required this.maxValue,
//     this.unit = 'PPM',
//     this.ranges = const [300, 1000, 2500, 5000],
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Text(
//           title,
//           style: Theme.of(context).textTheme.titleLarge,
//         ),

//         const SizedBox(height: 16),

//         SizedBox(
//           height: 200,
//           child: SfRadialGauge(
//             axes: <RadialAxis>[
//               RadialAxis(
//                 minimum: 0,
//                 maximum: maxValue,
//                 ranges: <GaugeRange>[
//                   GaugeRange(
//                     startValue: 0,
//                     endValue: ranges[0],
//                     color: AppTheme.safeColor,
//                   ),
//                   GaugeRange(
//                     startValue: ranges[0],
//                     endValue: ranges[1],
//                     color: AppTheme.warningStatusColor,
//                   ),
//                   GaugeRange(
//                     startValue: ranges[1],
//                     endValue: ranges[2],
//                     color: AppTheme.dangerStatusColor,
//                   ),
//                   GaugeRange(
//                     startValue: ranges[2],
//                     endValue: maxValue,
//                     color: AppTheme.criticalStatusColor,
//                   ),
//                 ],
//                 pointers: <GaugePointer>[
//                   NeedlePointer(
//                     value: value,
//                     enableAnimation: true,
//                   ),
//                 ],
//                 annotations: <GaugeAnnotation>[
//                   GaugeAnnotation(
//                     widget: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(
//                           value.toStringAsFixed(0),
//                           style: Theme.of(context)
//                               .textTheme
//                               .headlineMedium
//                               ?.copyWith(
//                                 fontWeight: FontWeight.bold,
//                               ),
//                         ),
//                         Text(
//                           unit,
//                           style: Theme.of(context).textTheme.bodySmall,
//                         ),
//                       ],
//                     ),
//                     angle: 90,
//                     positionFactor: 0.5,
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// ==================== UPDATED GAS_GAUGE.DART ====================
// Single gauge for LPG only
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../utils/theme.dart';

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
    // ✅ ONLY UPDATE: Ensure the needle doesn't go off-screen if value > maxValue
    final displayValue = value > maxValue ? maxValue : value;

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
                    labelStyle:
                        const GaugeTextStyle(fontSize: 10, color: Colors.white),
                  ),
                  GaugeRange(
                    startValue: ranges[0],
                    endValue: ranges[1],
                    color: AppTheme.warningStatusColor,
                    label: 'Warning',
                    labelStyle:
                        const GaugeTextStyle(fontSize: 10, color: Colors.white),
                  ),
                  GaugeRange(
                    startValue: ranges[1],
                    endValue: ranges[2],
                    color: AppTheme.dangerStatusColor,
                    label: 'Danger',
                    labelStyle:
                        const GaugeTextStyle(fontSize: 10, color: Colors.white),
                  ),
                  GaugeRange(
                    startValue: ranges[2],
                    endValue: maxValue,
                    color: AppTheme.criticalStatusColor,
                    label: 'Critical',
                    labelStyle:
                        const GaugeTextStyle(fontSize: 10, color: Colors.white),
                  ),
                ],
                pointers: <GaugePointer>[
                  NeedlePointer(
                    value: displayValue, // ✅ Use the clamped value here
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
                          value.toStringAsFixed(
                              0), // ✅ Shows real value even if > 5000
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

        // Legend (Keep your original code)
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
