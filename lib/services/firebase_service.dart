// ==================== COMPLETE FIREBASE SERVICE ====================
// lib/services/firebase_service.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/device_model.dart';
import '../models/sensor_data_model.dart';
import '../models/alert_model.dart';

class FirebaseService with ChangeNotifier {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current user's devices
  List<Device> _devices = [];
  List<Device> get devices => _devices;

  // Selected device data
  Device? _selectedDevice;
  Device? get selectedDevice => _selectedDevice;

  SensorData? _currentSensorData;
  SensorData? get currentSensorData => _currentSensorData;

  List<SensorData> _historicalData = [];
  List<SensorData> get historicalData => _historicalData;

  List<AlertModel> _alerts = [];
  List<AlertModel> get alerts => _alerts;

  // Connection status
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  // Listeners
  DatabaseReference? _devicesRef;
  DatabaseReference? _sensorDataRef;
  DatabaseReference? _alertsRef;

  // Initialize service
  Future<void> initialize() async {
    await _setupConnectionListener();
    await loadUserDevices();
  }

  // Setup connection status listener
  Future<void> _setupConnectionListener() async {
    DatabaseReference connectedRef = _database.ref('.info/connected');
    connectedRef.onValue.listen((event) {
      _isConnected = event.snapshot.value == true;
      notifyListeners();
    });
  }

  // ==================== DEVICE MANAGEMENT ====================

  /// Load all devices for current user
  Future<void> loadUserDevices() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get user's device list
      final userDevicesRef = _database.ref('users/${user.uid}/devices');
      final snapshot = await userDevicesRef.get();

      if (!snapshot.exists) {
        _devices = [];
        notifyListeners();
        return;
      }

      List<String> deviceIds = [];
      for (var child in snapshot.children) {
        deviceIds.add(child.key!);
      }

      // Load each device details
      List<Device> loadedDevices = [];
      for (String deviceId in deviceIds) {
        final deviceRef = _database.ref('devices/$deviceId');
        final deviceSnapshot = await deviceRef.get();

        if (deviceSnapshot.exists) {
          loadedDevices.add(Device.fromMap(
            deviceSnapshot.value as Map<dynamic, dynamic>,
            deviceId,
          ));
        }
      }

      _devices = loadedDevices;
      notifyListeners();

      // Auto-select first device if none selected
      if (_selectedDevice == null && _devices.isNotEmpty) {
        selectDevice(_devices[0].id);
      }
    } catch (e) {
      print('Error loading devices: $e');
    }
  }

  /// Select a device to monitor
  void selectDevice(String deviceId) {
    _selectedDevice = _devices.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => _devices[0],
    );

    // Setup listeners for this device
    _setupDeviceListeners(deviceId);

    // Load historical data
    loadHistoricalData(deviceId);

    // Load alerts
    loadAlerts(deviceId);

    notifyListeners();
  }

  /// Setup real-time listeners for selected device
  void _setupDeviceListeners(String deviceId) {
    // Cancel previous listeners
    _devicesRef?.onValue.drain();
    _sensorDataRef?.onValue.drain();
    _alertsRef?.onValue.drain();

    // Device status listener
    _devicesRef = _database.ref('devices/$deviceId');
    _devicesRef!.onValue.listen((event) {
      if (event.snapshot.exists) {
        _selectedDevice = Device.fromMap(
          event.snapshot.value as Map<dynamic, dynamic>,
          deviceId,
        );
        notifyListeners();
      }
    });

    // Sensor data listener
    _sensorDataRef = _database.ref('sensor_data/$deviceId/current');
    _sensorDataRef!.onValue.listen((event) {
      if (event.snapshot.exists) {
        _currentSensorData = SensorData.fromMap(
          event.snapshot.value as Map<dynamic, dynamic>,
        );
        notifyListeners();
      }
    });

    // Alerts listener
    _alertsRef = _database.ref('alerts/$deviceId');
    _alertsRef!.onValue.listen((event) {
      if (event.snapshot.exists) {
        List<AlertModel> loadedAlerts = [];
        for (var child in event.snapshot.children) {
          loadedAlerts.add(AlertModel.fromMap(
            child.value as Map<dynamic, dynamic>,
            child.key!,
          ));
        }

        // Sort by timestamp (newest first)
        loadedAlerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        _alerts = loadedAlerts;
        notifyListeners();
      }
    });
  }

  /// Get unclaimed devices (NEW - For auto-pairing)
  Future<List<Map<String, dynamic>>> getUnclaimedDevices() async {
    try {
      final devicesRef = _database.ref('devices');
      final snapshot = await devicesRef.get();

      if (!snapshot.exists) return [];

      List<Map<String, dynamic>> unclaimedDevices = [];

      for (var child in snapshot.children) {
        final deviceData = child.value as Map<dynamic, dynamic>;
        final deviceId = child.key!;
        
        // Check if device is unclaimed (no userId or userId is null/empty)
        final userId = deviceData['userId'];
        
        if (userId == null || userId == '') {
          // Get gas level from sensor data
          int gasLevel = 0;
          try {
            final sensorRef = _database.ref('sensor_data/$deviceId/current');
            final sensorSnap = await sensorRef.get();
            if (sensorSnap.exists) {
              final sensorData = sensorSnap.value as Map<dynamic, dynamic>;
              gasLevel = sensorData['lpg'] ?? 0;
            }
          } catch (e) {
            print('Error getting sensor data for $deviceId: $e');
          }
          
          unclaimedDevices.add({
            'deviceId': deviceId,
            'deviceName': deviceData['name'] ?? 'Gas Detector',
            'status': deviceData['status'] ?? 'offline',
            'lastSeen': deviceData['lastSeen'],
            'ipAddress': deviceData['ipAddress'],
            'gasLevel': gasLevel,
          });
        }
      }

      // Sort by last seen (most recent first)
      unclaimedDevices.sort((a, b) {
        final aTime = a['lastSeen'] ?? 0;
        final bTime = b['lastSeen'] ?? 0;
        return bTime.compareTo(aTime);
      });

      return unclaimedDevices;
    } catch (e) {
      print('Error getting unclaimed devices: $e');
      return [];
    }
  }

  /// Claim a device (NEW - For auto-pairing)
  Future<bool> claimDevice(
    String deviceId,
    String userId,
    String deviceName,
    String location,
  ) async {
    try {
      // Update device with user ID and custom name/location
      await _database.ref('devices/$deviceId').update({
        'userId': userId,
        'name': deviceName,
        'location': location,
        'pairedAt': ServerValue.timestamp,
      });

      // Add device to user's device list
      await _database.ref('users/$userId/devices/$deviceId').set(true);

      // Create default settings for this device (if not exists)
      final settingsRef = _database.ref('device_settings/$deviceId');
      final settingsSnapshot = await settingsRef.get();
      
      if (!settingsSnapshot.exists) {
        await settingsRef.set({
          'thresholds': {
            'lpg': {
              'safe': 300,
              'warning': 1000,
              'danger': 2500,
              'critical': 5000,
            },
            'co': {
              'safe': 30,
              'warning': 100,
              'danger': 200,
              'critical': 400,
            },
          },
          'alerts': {
            'pushEnabled': true,
            'emailEnabled': true,
            'buzzerEnabled': true,
            'relayEnabled': true,
          },
          'notifications': {
            'safeToWarning': true,
            'warningToDanger': true,
            'dangerToCritical': true,
            'backToSafe': true,
            'offline': true,
            'batteryLow': true,
          },
        });
      }

      // Reload user devices
      await loadUserDevices();

      return true;
    } catch (e) {
      print('Error claiming device: $e');
      return false;
    }
  }

  /// Add new device to user account (UPDATED to use claim)
  Future<bool> addDevice(String deviceId, String name, String location) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check if device exists
      final deviceRef = _database.ref('devices/$deviceId');
      final snapshot = await deviceRef.get();

      if (!snapshot.exists) {
        // Create new device as unclaimed first
        await deviceRef.set({
          'name': name,
          'location': location,
          'userId': null, // Unclaimed
          'status': 'offline',
          'lastSeen': ServerValue.timestamp,
          'hardwareVersion': '1.0',
          'firmwareVersion': '1.0.0',
        });

        // Create default settings
        await _database.ref('device_settings/$deviceId').set({
          'thresholds': {
            'lpg': {
              'safe': 300,
              'warning': 1000,
              'danger': 2500,
              'critical': 5000,
            },
            'co': {
              'safe': 30,
              'warning': 100,
              'danger': 200,
              'critical': 400,
            },
          },
          'alerts': {
            'pushEnabled': true,
            'emailEnabled': true,
            'buzzerEnabled': true,
            'relayEnabled': true,
          },
          'notifications': {
            'safeToWarning': true,
            'warningToDanger': true,
            'dangerToCritical': true,
            'backToSafe': true,
            'offline': true,
            'batteryLow': true,
          },
        });
      }

      // Claim the device
      return await claimDevice(deviceId, user.uid, name, location);
    } catch (e) {
      print('Error adding device: $e');
      return false;
    }
  }

  /// Remove device from user account
  Future<bool> removeDevice(String deviceId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Remove device from user's list
      await _database.ref('users/${user.uid}/devices/$deviceId').remove();
      
      // Set device as unclaimed (don't delete it)
      await _database.ref('devices/$deviceId').update({
        'userId': null,
        'name': 'Gas Detector',
        'location': 'Unknown',
      });
      
      await loadUserDevices();

      return true;
    } catch (e) {
      print('Error removing device: $e');
      return false;
    }
  }

  // ==================== SENSOR DATA ====================

  /// Load historical sensor data
  Future<void> loadHistoricalData(String deviceId, {int hours = 24}) async {
    try {
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final startTime = endTime - (hours * 60 * 60 * 1000);

      final ref = _database.ref('sensor_history/$deviceId/hourly');
      final snapshot = await ref
          .orderByChild('timestamp')
          .startAt(startTime)
          .endAt(endTime)
          .get();

      if (snapshot.exists) {
        List<SensorData> data = [];
        for (var child in snapshot.children) {
          data.add(SensorData.fromMap(
            child.value as Map<dynamic, dynamic>,
          ));
        }

        // Sort by timestamp
        data.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        _historicalData = data;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading historical data: $e');
    }
  }

  // ==================== ALERTS ====================

  /// Load alerts for device
  Future<void> loadAlerts(String deviceId, {int limit = 50}) async {
    try {
      final ref = _database.ref('alerts/$deviceId');
      final snapshot = await ref.limitToLast(limit).get();

      if (snapshot.exists) {
        List<AlertModel> loadedAlerts = [];
        for (var child in snapshot.children) {
          loadedAlerts.add(AlertModel.fromMap(
            child.value as Map<dynamic, dynamic>,
            child.key!,
          ));
        }

        // Sort by timestamp (newest first)
        loadedAlerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        _alerts = loadedAlerts;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading alerts: $e');
    }
  }

  /// Acknowledge an alert
  Future<void> acknowledgeAlert(String deviceId, String alertId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _database.ref('alerts/$deviceId/$alertId').update({
        'acknowledged': true,
        'acknowledgedAt': ServerValue.timestamp,
        'acknowledgedBy': user.uid,
      });

      await loadAlerts(deviceId);
    } catch (e) {
      print('Error acknowledging alert: $e');
    }
  }

  /// Clear all alerts for device
  Future<void> clearAlerts(String deviceId) async {
    try {
      await _database.ref('alerts/$deviceId').remove();
      _alerts = [];
      notifyListeners();
    } catch (e) {
      print('Error clearing alerts: $e');
    }
  }

  // ==================== SETTINGS ====================

  /// Update device thresholds
  Future<void> updateThresholds(
    String deviceId,
    Map<String, Map<String, int>> thresholds,
  ) async {
    try {
      await _database
          .ref('device_settings/$deviceId/thresholds')
          .set(thresholds);
    } catch (e) {
      print('Error updating thresholds: $e');
    }
  }

  /// Update alert settings
  Future<void> updateAlertSettings(
    String deviceId,
    Map<String, bool> settings,
  ) async {
    try {
      await _database.ref('device_settings/$deviceId/alerts').update(settings);
    } catch (e) {
      print('Error updating alert settings: $e');
    }
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences(
    String deviceId,
    Map<String, bool> preferences,
  ) async {
    try {
      await _database
          .ref('device_settings/$deviceId/notifications')
          .update(preferences);
    } catch (e) {
      print('Error updating notification preferences: $e');
    }
  }

  /// Get device settings
  Future<Map<String, dynamic>?> getDeviceSettings(String deviceId) async {
    try {
      final snapshot = await _database.ref('device_settings/$deviceId').get();

      if (snapshot.exists) {
        return Map<String, dynamic>.from(
          snapshot.value as Map<dynamic, dynamic>,
        );
      }
      return null;
    } catch (e) {
      print('Error getting device settings: $e');
      return null;
    }
  }

  // ==================== STATISTICS ====================

  /// Get device statistics
  Future<Map<String, dynamic>> getDeviceStatistics(String deviceId,
      {int days = 7}) async {
    try {
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final startTime = endTime - (days * 24 * 60 * 60 * 1000);

      // Get historical data
      final ref = _database.ref('sensor_history/$deviceId/hourly');
      final snapshot = await ref
          .orderByChild('timestamp')
          .startAt(startTime)
          .endAt(endTime)
          .get();

      if (!snapshot.exists) {
        return {
          'avgLpg': 0.0,
          'maxLpg': 0.0,
          'avgCo': 0.0,
          'maxCo': 0.0,
          'alertCount': 0,
        };
      }

      double totalLpg = 0;
      double totalCo = 0;
      double maxLpg = 0;
      double maxCo = 0;
      int count = 0;

      for (var child in snapshot.children) {
        final data = child.value as Map<dynamic, dynamic>;
        final lpg = (data['lpgAvg'] ?? 0).toDouble();
        final co = (data['coAvg'] ?? 0).toDouble();

        totalLpg += lpg;
        totalCo += co;
        maxLpg = lpg > maxLpg ? lpg : maxLpg;
        maxCo = co > maxCo ? co : maxCo;
        count++;
      }

      // Get alert count
      final alertsSnapshot = await _database
          .ref('alerts/$deviceId')
          .orderByChild('timestamp')
          .startAt(startTime)
          .get();

      int alertCount =
          alertsSnapshot.exists ? alertsSnapshot.children.length : 0;

      return {
        'avgLpg': count > 0 ? totalLpg / count : 0.0,
        'maxLpg': maxLpg,
        'avgCo': count > 0 ? totalCo / count : 0.0,
        'maxCo': maxCo,
        'alertCount': alertCount,
        'dataPoints': count,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {};
    }
  }

  // ==================== CLEANUP ====================

  @override
  void dispose() {
    _devicesRef?.onValue.drain();
    _sensorDataRef?.onValue.drain();
    _alertsRef?.onValue.drain();
    super.dispose();
  }
}