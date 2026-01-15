// ==================== DEVICE PAIRING SCREEN ====================
// lib/screens/device_pairing_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // ✅ UPDATED
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';

class DevicePairingScreen extends StatefulWidget {
  const DevicePairingScreen({super.key});

  @override
  State<DevicePairingScreen> createState() => _DevicePairingScreenState();
}

class _DevicePairingScreenState extends State<DevicePairingScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _deviceIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  
  // ✅ UPDATED: MobileScannerController instead of QRViewController
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );
  
  bool _isLoading = false;
  bool _isScanning = false;
  String? _scannedDeviceId;
  String? _deviceIpAddress;

  @override
  void initState() {
    super.initState();
    // ✅ ADDED: Lifecycle observer for Android 14 stability
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ✅ ADDED: Handle camera pause/resume to prevent crashes
    if (!_scannerController.value.isInitialized) return;
    
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        // Restart scanner when app comes back to foreground
        _scannerController.start();
      case AppLifecycleState.inactive:
        // Stop scanner when app goes background
        _scannerController.stop();
    }
  }

  @override
  void dispose() {
    // ✅ ADDED: Remove observer
    WidgetsBinding.instance.removeObserver(this);
    _deviceIdController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _scannerController.dispose(); // ✅ UPDATED
    super.dispose();
  }

  // ==================== PAIRING METHODS ====================
  
  /// Method 1: Manual Device ID Entry (UNCHANGED)
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
        'Failed to pair device. Check device ID and network.',
        isError: true,
      );
    }
  }
  
  /// Method 2: QR Code Scanning (UPDATED)
  void _scanQRCode() {
    setState(() => _isScanning = true);
    _scannerController.start(); // Ensure camera starts
  }
  
  // ✅ UPDATED: Callback for MobileScanner
  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      
      if (code != null) {
        _scannerController.stop(); // Pause camera immediately
        
        // Parse QR code data (format: GD_XXXXXXXX|IP_ADDRESS)
        final parts = code.split('|');
        final deviceId = parts[0];
        final ipAddress = parts.length > 1 ? parts[1] : null;
        
        setState(() {
          _scannedDeviceId = deviceId;
          _deviceIpAddress = ipAddress;
          _deviceIdController.text = deviceId;
          _isScanning = false;
        });
        
        // Auto-fetch device info if IP available
        if (ipAddress != null) {
          _fetchDeviceInfo(ipAddress);
        }
      }
    }
  }
  
  /// Method 3: Local Network Discovery (UNCHANGED)
  Future<void> _discoverDevices() async {
    setState(() => _isLoading = true);
    
    Helpers.showSnackBar(context, 'Scanning local network...');
    
    // Scan local network for devices
    final devices = await _scanLocalNetwork();
    
    setState(() => _isLoading = false);
    
    if (devices.isEmpty) {
      Helpers.showSnackBar(
        context,
        'No devices found. Ensure device is on same WiFi network.',
        isError: true,
      );
      return;
    }
    
    // Show device selection dialog
    _showDeviceSelectionDialog(devices);
  }
  
  // ==================== DEVICE PAIRING LOGIC (UNCHANGED) ====================
  
  Future<bool> _pairDevice(String deviceId, String name, String location) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    
    final user = authService.user;
    if (user == null) return false;
    
    try {
      // Step 1: Configure device via HTTP (if IP known)
      if (_deviceIpAddress != null) {
        await _configureDeviceViaHTTP(_deviceIpAddress!, deviceId, user);
      }
      
      // Step 2: Add device to user's account in Firebase
      final success = await firebaseService.addDevice(
        deviceId,
        name,
        location,
      );
      
      return success;
    } catch (e) {
      print('Error pairing device: $e');
      return false;
    }
  }
  
  Future<void> _configureDeviceViaHTTP(
    String ipAddress,
    String deviceId,
    User user,
  ) async {
    try {
      final firebaseFunctionUrl = dotenv.env['firebase_function_url'] ?? '';
      
      final authToken = await _generateDeviceAuthToken(deviceId, user.uid);
      
      final response = await http.post(
        Uri.parse('http://$ipAddress/api/configure'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firebaseUrl': firebaseFunctionUrl,
          'authToken': authToken,
          'deviceName': _nameController.text,
          'ownerUid': user.uid,
          'ownerEmail': user.email,
        }),
      );
      
      if (response.statusCode == 200) {
        print('✓ Device configured successfully');
      } else {
        print('❌ Failed to configure device: ${response.body}');
      }
    } catch (e) {
      print('Error configuring device: $e');
    }
  }
  
  Future<String> _generateDeviceAuthToken(String deviceId, String userId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'token_${deviceId}_${userId}_$timestamp'.hashCode.toString();
  }
  
  Future<void> _fetchDeviceInfo(String ipAddress) async {
    try {
      final response = await http.get(
        Uri.parse('http://$ipAddress/api/device'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _deviceIdController.text = data['deviceId'] ?? '';
          _nameController.text = data['deviceName'] ?? 'Gas Detector';
        });
        
        Helpers.showSnackBar(context, 'Device info loaded');
      }
    } catch (e) {
      print('Error fetching device info: $e');
    }
  }
  
  Future<List<Map<String, String>>> _scanLocalNetwork() async {
    List<Map<String, String>> devices = [];
    final subnet = '192.168.1';
    
    for (int i = 1; i <= 255; i++) {
      try {
        final ip = '$subnet.$i';
        final response = await http.get(
          Uri.parse('http://$ip/api/device'),
        ).timeout(const Duration(milliseconds: 500));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['deviceId'] != null) {
            devices.add({
              'deviceId': data['deviceId'],
              'deviceName': data['deviceName'] ?? 'Gas Detector',
              'ipAddress': ip,
            });
          }
        }
      } catch (e) {
        // Timeout or connection refused - continue
      }
    }
    
    return devices;
  }
  
  void _showDeviceSelectionDialog(List<Map<String, String>> devices) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Device'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return ListTile(
                leading: const Icon(Icons.sensors),
                title: Text(device['deviceName']!),
                subtitle: Text(device['deviceId']!),
                trailing: Text(device['ipAddress']!),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _deviceIdController.text = device['deviceId']!;
                    _deviceIpAddress = device['ipAddress'];
                    _nameController.text = device['deviceName']!;
                  });
                  _fetchDeviceInfo(device['ipAddress']!);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair New Device'),
      ),
      body: _isScanning ? _buildQRScanner() : _buildPairingForm(),
    );
  }
  
  Widget _buildPairingForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon
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

            const SizedBox(height: 32),

            Text(
              'Pair Your Gas Detector',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              'Choose a pairing method below',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Pairing Method Buttons
            ElevatedButton.icon(
              onPressed: _scanQRCode,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR Code'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _discoverDevices,
              icon: const Icon(Icons.wifi_find),
              label: const Text('Auto-Discover on Network'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
            ),

            const SizedBox(height: 24),

            const Divider(),
            
            const SizedBox(height: 24),

            Text(
              'Or Enter Manually',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Device ID Field
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

            // Name Field
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

            // Location Field
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

            const SizedBox(height: 32),

            // Pair Button
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

            const SizedBox(height: 32),

            // Help Card (UNCHANGED)
            Card(
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
                          'Pairing Instructions',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: AppTheme.primaryColor,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Power on your gas detector\n'
                      '2. Connect device to WiFi (first time setup)\n'
                      '3. Use QR code scan or auto-discovery\n'
                      '4. Device will be paired to your account\n'
                      '5. You can share access with family later',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // ✅ UPDATED: QR Scanner UI for MobileScanner
  Widget _buildQRScanner() {
    return Column(
      children: [
        Expanded(
          child: MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
            // Simple overlay using a Container with border
            overlayBuilder: (context, constraints) {
              return Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primaryColor, width: 4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.black.withOpacity(0.8), // Dark background for controls
          child: Column(
            children: [
              const Text(
                'Scan the QR code on your device',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Toggle Flash
                  IconButton(
                    icon: const Icon(Icons.flash_on, color: Colors.white),
                    onPressed: () => _scannerController.toggleTorch(),
                  ),
                  // Cancel Button
                  ElevatedButton(
                    onPressed: () {
                      _scannerController.stop();
                      setState(() => _isScanning = false);
                    },
                    child: const Text('Cancel'),
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