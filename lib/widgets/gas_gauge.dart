==================== GAS_GAUGE.DART ====================
// lib/widgets/gas_gauge.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../utils/theme.dart';

class GasGauge extends StatelessWidget {
  final String title;
  final double value;
  final double maxValue;
  final String unit;
  final List<double> ranges;

  const GasGauge({
    super.key,
    required this.title,
    required this.value,
    required this.maxValue,
    this.unit = 'PPM',
    this.ranges = const [300, 1000, 2500, 5000],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        
        const SizedBox(height: 16),
        
        SizedBox(
          height: 200,
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
                  ),
                  GaugeRange(
                    startValue: ranges[0],
                    endValue: ranges[1],
                    color: AppTheme.warningStatusColor,
                  ),
                  GaugeRange(
                    startValue: ranges[1],
                    endValue: ranges[2],
                    color: AppTheme.dangerStatusColor,
                  ),
                  GaugeRange(
                    startValue: ranges[2],
                    endValue: maxValue,
                    color: AppTheme.criticalStatusColor,
                  ),
                ],
                pointers: <GaugePointer>[
                  NeedlePointer(
                    value: value,
                    enableAnimation: true,
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
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          unit,
                          style: Theme.of(context).textTheme.bodySmall,
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
      ],
    );
  }
}