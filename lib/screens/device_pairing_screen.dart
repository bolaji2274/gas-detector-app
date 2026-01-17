// ==================== SIMPLIFIED DEVICE PAIRING SCREEN ====================
// lib/screens/device_pairing_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';

class DevicePairingScreen extends StatefulWidget {
  const DevicePairingScreen({super.key});

  @override
  State<DevicePairingScreen> createState() => _DevicePairingScreenState();
}

class _DevicePairingScreenState extends State<DevicePairingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deviceIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isLoading = false;
  bool _isScanning = false;
  List<Map<String, dynamic>> _availableDevices = [];
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    // Auto-scan for available devices on load
    Future.delayed(Duration.zero, () => _scanForAvailableDevices());
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _scanTimer?.cancel();
    super.dispose();
  }

  // ==================== PAIRING METHODS ====================

  /// Method 1: Scan for Available (Unclaimed) Devices from Firebase
  Future<void> _scanForAvailableDevices() async {
    setState(() => _isScanning = true);

    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      
      // Get all unclaimed devices from Firebase
      final devices = await firebaseService.getUnclaimedDevices();
      
      setState(() {
        _availableDevices = devices;
        _isScanning = false;
      });

      if (devices.isEmpty) {
        Helpers.showSnackBar(
          context,
          'No available devices found. Please configure your device first.',
        );
      }
    } catch (e) {
      setState(() => _isScanning = false);
      Helpers.showSnackBar(
        context,
        'Error scanning for devices: $e',
        isError: true,
      );
    }
  }

  /// Method 2: Claim/Pair an Available Device
  Future<void> _claimDevice(Map<String, dynamic> device) async {
    // Show name/location dialog
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _DeviceClaimDialog(
        deviceId: device['deviceId'],
        defaultName: device['deviceName'] ?? 'Gas Detector',
      ),
    );

    if (result == null) return;

    setState(() => _isLoading = true);

    final success = await _pairDevice(
      device['deviceId'],
      result['name']!,
      result['location']!,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Helpers.showSnackBar(context, 'Device paired successfully!');
      Navigator.pop(context);
    } else {
      Helpers.showSnackBar(
        context,
        'Failed to pair device. Please try again.',
        isError: true,
      );
    }
  }

  /// Method 3: Manual Device ID Entry
  Future<void> _pairManually() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final deviceId = _deviceIdController.text.trim();
    final name = _nameController.text.trim();
    final location = _locationController.text.trim();

    final success = await _pairDevice(deviceId, name, location);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Helpers.showSnackBar(context, 'Device paired successfully!');
      Navigator.pop(context);
    } else {
      Helpers.showSnackBar(
        context,
        'Failed to pair device. Check device ID.',
        isError: true,
      );
    }
  }

  // ==================== DEVICE PAIRING LOGIC ====================

  Future<bool> _pairDevice(String deviceId, String name, String location) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);

    final user = authService.user;
    if (user == null) return false;

    try {
      // Add device to user's account in Firebase
      final success = await firebaseService.claimDevice(
        deviceId,
        user.uid,
        name,
        location,
      );

      return success;
    } catch (e) {
      print('Error pairing device: $e');
      return false;
    }
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair New Device'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _scanForAvailableDevices,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _scanForAvailableDevices,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _buildHeader(),
            
            const SizedBox(height: 32),

            // Available Devices Section
            _buildAvailableDevicesSection(),

            const SizedBox(height: 32),
            
            const Divider(),
            
            const SizedBox(height: 24),

            // Manual Entry Section
            _buildManualEntrySection(),

            const SizedBox(height: 32),

            // Help Card
            _buildHelpCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.add_circle_outline,
            size: 50,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Pair Your Gas Detector',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Select from available devices or enter manually',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAvailableDevicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available Devices',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (_isScanning)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_availableDevices.isEmpty && !_isScanning)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.devices_other,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No devices found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Make sure your device is configured\nand connected to WiFi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _scanForAvailableDevices,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Scan Again'),
                  ),
                ],
              ),
            ),
          )
        else if (_availableDevices.isNotEmpty)
          ..._availableDevices.map((device) => _buildDeviceCard(device)).toList(),
      ],
    );
  }

  Widget _buildDeviceCard(Map<String, dynamic> device) {
    final deviceId = device['deviceId'] ?? 'Unknown';
    final deviceName = device['deviceName'] ?? 'Gas Detector';
    final status = device['status'] ?? 'offline';
    final gasLevel = device['gasLevel'] ?? 0;
    final lastSeen = device['lastSeen'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Helpers.getStatusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.sensors,
            color: Helpers.getStatusColor(status),
            size: 28,
          ),
        ),
        title: Text(
          deviceName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              deviceId,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Helpers.getStatusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Helpers.getStatusColor(status),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$gasLevel PPM',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            if (lastSeen != null)
              Text(
                'Last seen: ${_formatLastSeen(lastSeen)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _claimDevice(device),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Pair'),
        ),
      ),
    );
  }

  Widget _buildManualEntrySection() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Or Enter Manually',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _deviceIdController,
            decoration: const InputDecoration(
              labelText: 'Device ID',
              prefixIcon: Icon(Icons.qr_code),
              hintText: 'GD_XXXXXXXX',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter device ID';
              }
              if (!value.startsWith('GD_')) {
                return 'Device ID must start with GD_';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Device Name',
              prefixIcon: Icon(Icons.label),
              hintText: 'Kitchen Detector',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter device name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Location',
              prefixIcon: Icon(Icons.location_on),
              hintText: 'Kitchen',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter location';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          ElevatedButton(
            onPressed: _isLoading ? null : _pairManually,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Pair Device'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard() {
    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.help_outline,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Setup Instructions',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Power on your gas detector\n'
              '2. Connect to "GasDetector_XXXXXX" WiFi network\n'
              '   (Password: 12345678)\n'
              '3. Configure WiFi in the captive portal\n'
              '4. Wait for device to connect to your network\n'
              '5. Return to app and select your device from the list above\n'
              '6. Or enter Device ID manually',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastSeen(dynamic lastSeen) {
    if (lastSeen == null) return 'Unknown';
    
    try {
      DateTime dateTime;
      if (lastSeen is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(lastSeen);
      } else {
        return 'Unknown';
      }
      
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}

// ==================== DEVICE CLAIM DIALOG ====================
class _DeviceClaimDialog extends StatefulWidget {
  final String deviceId;
  final String defaultName;

  const _DeviceClaimDialog({
    required this.deviceId,
    required this.defaultName,
  });

  @override
  State<_DeviceClaimDialog> createState() => _DeviceClaimDialogState();
}

class _DeviceClaimDialogState extends State<_DeviceClaimDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.defaultName);
    _locationController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Claim Device'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.deviceId,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Device Name',
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on),
                hintText: 'Kitchen, Bedroom, etc.',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a location';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text.trim(),
                'location': _locationController.text.trim(),
              });
            }
          },
          child: const Text('Pair'),
        ),
      ],
    );
  }
}