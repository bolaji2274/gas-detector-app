// ==================== DEVICE_CARD.DART ====================
// lib/widgets/device_card.dart

import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onTap;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status Indicator
              Container(
                width: 12,
                height: 60,
                decoration: BoxDecoration(
                  color: device.isOnline
                      ? AppTheme.successColor
                      : AppTheme.offlineColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),

              const SizedBox(width: 16),

              // Device Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          device.location,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Online Status
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: device.isOnline
                                ? AppTheme.successColor.withOpacity(0.1)
                                : AppTheme.offlineColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            device.isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              color: device.isOnline
                                  ? AppTheme.successColor
                                  : AppTheme.offlineColor,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // WiFi Signal
                        Icon(
                          Helpers.getWiFiIcon(device.wifiSignal),
                          size: 16,
                          color: Colors.grey[600],
                        ),

                        const SizedBox(width: 8),

                        // Battery
                        if (device.powerSource == 'battery')
                          Icon(
                            Helpers.getBatteryIcon(device.batteryLevel),
                            size: 16,
                            color: device.batteryLevel < 20
                                ? AppTheme.errorColor
                                : Colors.grey[600],
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
