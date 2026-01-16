// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../models/device_model.dart';
import '../models/sensor_data_model.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';
import '../widgets/device_card.dart';
import '../widgets/status_card.dart';
import '../widgets/quick_stats.dart';
import 'device_detail_screen.dart';
import 'alerts_screen.dart';
import 'settings_screen.dart';
import 'add_device_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    await firebaseService.loadUserDevices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gas Detector'),
        actions: [
          // Connection Indicator
          Consumer<FirebaseService>(
            builder: (context, service, child) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: Icon(
                  service.isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: service.isConnected ? Colors.white : Colors.red[300],
                ),
              );
            },
          ),

          // Notifications
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AlertsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _selectedIndex == 0
          ? _buildHomeTab()
          : _selectedIndex == 1
              ? const AlertsScreen()
              : const SettingsScreen(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddDeviceScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Consumer<FirebaseService>(
        builder: (context, firebaseService, child) {
          if (firebaseService.devices.isEmpty) {
            return _buildEmptyState();
          }

          final selectedDevice = firebaseService.selectedDevice;
          final sensorData = firebaseService.currentSensorData;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Device Selector
                _buildDeviceSelector(firebaseService),

                const SizedBox(height: 20),

                // Current Status Card
                if (selectedDevice != null)
                  StatusCard(
                    device: selectedDevice,
                    sensorData: sensorData,
                  ),

                const SizedBox(height: 20),

                // Quick Stats
                if (sensorData != null) QuickStats(sensorData: sensorData),

                const SizedBox(height: 20),

                // Recent Alerts Section
                _buildRecentAlertsSection(firebaseService),

                const SizedBox(height: 20),

                // All Devices List
                Text(
                  'All Devices',
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                const SizedBox(height: 12),

                ...firebaseService.devices.map(
                  (device) => DeviceCard(
                    device: device,
                    onTap: () {
                      firebaseService.selectDevice(device.id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DeviceDetailScreen(
                            device: device,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeviceSelector(FirebaseService firebaseService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.devices, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Device',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: firebaseService.selectedDevice?.id,
                    underline: const SizedBox(),
                    items: firebaseService.devices.map((device) {
                      return DropdownMenuItem(
                        value: device.id,
                        child: Text(
                          device.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      );
                    }).toList(),
                    onChanged: (deviceId) {
                      if (deviceId != null) {
                        firebaseService.selectDevice(deviceId);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAlertsSection(FirebaseService firebaseService) {
    final recentAlerts = firebaseService.alerts.take(3).toList();

    if (recentAlerts.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Alerts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AlertsScreen(),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...recentAlerts.map(
          (alert) => Card(
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: alert.levelColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    alert.levelEmoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              title: Text(alert.title),
              subtitle: Text(
                '${alert.timeFormatted} • ${alert.deviceName}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: !alert.acknowledged
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.errorColor,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
              onTap: () {
                _showAlertDetails(alert);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices_other,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Devices Added',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Add your first gas detector to start monitoring your home',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddDeviceScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Device'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  fontSize: 40,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            accountName: Text(user?.displayName ?? 'User'),
            accountEmail: Text(user?.email ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _selectedIndex = 0;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Alerts'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _selectedIndex = 1;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _selectedIndex = 2;
              });
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.pop(context);
              Helpers.showSnackBar(context, 'Help coming soon');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.errorColor),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: AppTheme.errorColor),
            ),
            onTap: () async {
              final confirm = await Helpers.showConfirmDialog(
                context,
                title: 'Sign Out',
                message: 'Are you sure you want to sign out?',
                confirmText: 'Sign Out',
              );

              if (confirm && mounted) {
                await authService.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAlertDetails(alert) {
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
            Text('Device: ${alert.deviceName}'),
            Text('Location: ${alert.location}'),
            Text('Gas Type: ${alert.gas}'),
            Text('Level: ${alert.value.toStringAsFixed(0)} PPM'),
            Text('Time: ${alert.timeFormatted}'),
            if (alert.acknowledged) ...[
              const SizedBox(height: 8),
              const Text(
                '✓ Acknowledged',
                style: TextStyle(color: AppTheme.successColor),
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
                final firebaseService =
                    Provider.of<FirebaseService>(context, listen: false);
                await firebaseService.acknowledgeAlert(
                  alert.deviceId,
                  alert.id,
                );
                Navigator.pop(context);
                Helpers.showSnackBar(context, 'Alert acknowledged');
              },
              child: const Text('Acknowledge'),
            ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Gas Detector',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.science,
        size: 48,
        color: AppTheme.primaryColor,
      ),
      children: const [
        Text('Smart Home Gas Detection System'),
        SizedBox(height: 16),
        Text('Monitor LPG and CO levels in real-time with instant alerts.'),
      ],
    );
  }
}
