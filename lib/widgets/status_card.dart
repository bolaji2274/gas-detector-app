// ==================== STATUS_CARD.DART ====================
// lib/widgets/status_card.dart

import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../models/sensor_data_model.dart';
import '../utils/theme.dart';

class StatusCard extends StatelessWidget {
  final Device device;
  final SensorData? sensorData;

  const StatusCard({
    super.key,
    required this.device,
    this.sensorData,
  });

  @override
  Widget build(BuildContext context) {
    final status = sensorData?.status ?? 'offline';
    final statusColor = sensorData?.statusColor ?? AppTheme.offlineColor;

    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              statusColor.withOpacity(0.8),
              statusColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Status Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    sensorData?.statusEmoji ?? '•',
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Status Text
              Text(
                status.toUpperCase(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Device Name
              Text(
                device.name,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Last Updated
              Text(
                'Last updated: ${device.lastSeenFormatted}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
