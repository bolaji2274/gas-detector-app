// // ==================== QUICK_STATS.DART ====================
// // lib/widgets/quick_stats.dart

// import 'package:flutter/material.dart';
// import '../models/sensor_data_model.dart';
// import '../utils/theme.dart';

// class QuickStats extends StatelessWidget {
//   final SensorData sensorData;

//   const QuickStats({
//     super.key,
//     required this.sensorData,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: _buildStatCard(
//             context,
//             icon: Icons.local_fire_department,
//             label: 'LPG',
//             value: '${sensorData.lpg.toStringAsFixed(0)}',
//             unit: 'PPM',
//             color: _getColorForValue(sensorData.lpg, 'lpg'),
//           ),
//         ),

//         const SizedBox(width: 12),

//         Expanded(
//           child: _buildStatCard(
//             context,
//             icon: Icons.air,
//             label: 'CO',
//             value: '${sensorData.co.toStringAsFixed(0)}',
//             unit: 'PPM',
//             color: _getColorForValue(sensorData.co, 'co'),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildStatCard(
//     BuildContext context, {
//     required IconData icon,
//     required String label,
//     required String value,
//     required String unit,
//     required Color color,
//   }) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Icon(icon, size: 32, color: color),
//             const SizedBox(height: 8),
//             Text(
//               label,
//               style: Theme.of(context).textTheme.bodySmall,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               value,
//               style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                     color: color,
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),
//             Text(
//               unit,
//               style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                     color: Colors.grey,
//                   ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Color _getColorForValue(double value, String type) {
//     if (type == 'lpg') {
//       if (value < 300) return AppTheme.safeColor;
//       if (value < 1000) return AppTheme.warningStatusColor;
//       if (value < 2500) return AppTheme.dangerStatusColor;
//       return AppTheme.criticalStatusColor;
//     } else {
//       // CO
//       if (value < 30) return AppTheme.safeColor;
//       if (value < 100) return AppTheme.warningStatusColor;
//       if (value < 200) return AppTheme.dangerStatusColor;
//       return AppTheme.criticalStatusColor;
//     }
//   }
// }

// ==================== UPDATED QUICK_STATS.DART ====================
// Show only LPG reading

import 'package:flutter/material.dart';
import '../models/sensor_data_model.dart';
import '../utils/theme.dart';

class QuickStats extends StatelessWidget {
  final SensorData sensorData;

  const QuickStats({
    super.key,
    required this.sensorData,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Icon
            Icon(
              Icons.local_fire_department,
              size: 48,
              color: _getColorForValue(sensorData.lpg),
            ),

            const SizedBox(height: 12),

            // Label
            Text(
              'LPG/Gas Level',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 8),

            // Value
            Text(
              '${sensorData.lpg.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: _getColorForValue(sensorData.lpg),
                    fontWeight: FontWeight.bold,
                  ),
            ),

            // Unit
            Text(
              'PPM',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
            ),

            const SizedBox(height: 12),

            // Status Text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getColorForValue(sensorData.lpg).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getStatusText(sensorData.lpg),
                style: TextStyle(
                  color: _getColorForValue(sensorData.lpg),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForValue(double value) {
    if (value < 200) return AppTheme.safeColor;
    if (value < 500) return AppTheme.warningStatusColor;
    if (value < 1000) return AppTheme.dangerStatusColor;
    return AppTheme.criticalStatusColor;
  }

  String _getStatusText(double value) {
    if (value < 200) return 'Safe';
    if (value < 500) return 'Elevated';
    if (value < 1000) return 'High';
    return 'Critical';
  }
}
