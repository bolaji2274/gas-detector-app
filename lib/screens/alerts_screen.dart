// ==================== ALERTS_SCREEN.DART ====================
// lib/screens/alerts_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../models/alert_model.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String _filter = 'all'; // all, critical, danger, warning

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _clearAllAlerts();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear All Alerts'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          _buildFilterChips(),

          // Alerts List
          Expanded(
            child: Consumer<FirebaseService>(
              builder: (context, service, child) {
                final alerts = _getFilteredAlerts(service.alerts);

                if (alerts.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    return _buildAlertCard(alert);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: _filter == 'all',
            onSelected: (selected) {
              if (selected) setState(() => _filter = 'all');
            },
          ),
          ChoiceChip(
            label: const Text('Critical'),
            selected: _filter == 'critical',
            selectedColor: AppTheme.criticalStatusColor.withOpacity(0.3),
            onSelected: (selected) {
              if (selected) setState(() => _filter = 'critical');
            },
          ),
          ChoiceChip(
            label: const Text('Danger'),
            selected: _filter == 'danger',
            selectedColor: AppTheme.dangerStatusColor.withOpacity(0.3),
            onSelected: (selected) {
              if (selected) setState(() => _filter = 'danger');
            },
          ),
          ChoiceChip(
            label: const Text('Warning'),
            selected: _filter == 'warning',
            selectedColor: AppTheme.warningStatusColor.withOpacity(0.3),
            onSelected: (selected) {
              if (selected) setState(() => _filter = 'warning');
            },
          ),
        ],
      ),
    );
  }

  List<AlertModel> _getFilteredAlerts(List<AlertModel> alerts) {
    if (_filter == 'all') return alerts;
    return alerts.where((alert) => alert.level == _filter).toList();
  }

  Widget _buildAlertCard(AlertModel alert) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showAlertDetails(alert),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Level Indicator
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: alert.levelColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    alert.levelEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Alert Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${alert.gas}: ${alert.value.toStringAsFixed(0)} PPM',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${alert.deviceName} • ${alert.timeFormatted}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),

              // Status Icon
              if (alert.acknowledged)
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.successColor,
                )
              else
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppTheme.errorColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Alerts',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'All systems are normal',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  void _showAlertDetails(AlertModel alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(alert.levelEmoji),
            const SizedBox(width: 8),
            Expanded(child: Text(alert.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Device', alert.deviceName),
            _buildDetailRow('Location', alert.location),
            _buildDetailRow('Gas Type', alert.gas),
            _buildDetailRow('Level', '${alert.value.toStringAsFixed(0)} PPM'),
            _buildDetailRow('Time', Helpers.formatDateTime(alert.dateTime)),
            if (alert.acknowledged) ...[
              const Divider(),
              const Text(
                '✓ Acknowledged',
                style: TextStyle(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!alert.acknowledged)
            ElevatedButton(
              onPressed: () async {
                final service =
                    Provider.of<FirebaseService>(context, listen: false);
                await service.acknowledgeAlert(alert.deviceId, alert.id);
                Navigator.pop(context);
                Helpers.showSnackBar(context, 'Alert acknowledged');
              },
              child: const Text('Acknowledge'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _clearAllAlerts() async {
    final confirm = await Helpers.showConfirmDialog(
      context,
      title: 'Clear All Alerts',
      message: 'Are you sure you want to clear all alerts?',
      confirmText: 'Clear',
    );

    if (confirm && mounted) {
      final service = Provider.of<FirebaseService>(context, listen: false);
      final deviceId = service.selectedDevice?.id;

      if (deviceId != null) {
        await service.clearAlerts(deviceId);
        Helpers.showSnackBar(context, 'All alerts cleared');
      }
    }
  }
}
