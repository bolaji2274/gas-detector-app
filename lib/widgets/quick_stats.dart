// ==================== QUICK_STATS.DART ====================
// lib/widgets/quick_stats.dart

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
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.local_fire_department,
            label: 'LPG',
            value: '${sensorData.lpg.toStringAsFixed(0)}',
            unit: 'PPM',
            color: _getColorForValue(sensorData.lpg, 'lpg'),
          ),
        ),
        
        const SizedBox(width: 12),
        
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.air,
            label: 'CO',
            value: '${sensorData.co.toStringAsFixed(0)}',
            unit: 'PPM',
            color: _getColorForValue(sensorData.co, 'co'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              unit,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForValue(double value, String type) {
    if (type == 'lpg') {
      if (value < 300) return AppTheme.safeColor;
      if (value < 1000) return AppTheme.warningStatusColor;
      if (value < 2500) return AppTheme.dangerStatusColor;
      return AppTheme.criticalStatusColor;
    } else {
      // CO
      if (value < 30) return AppTheme.safeColor;
      if (value < 100) return AppTheme.warningStatusColor;
      if (value < 200) return AppTheme.dangerStatusColor;
      return AppTheme.criticalStatusColor;
    }
  }
}
