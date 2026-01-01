// ==================== DEVICE SETTINGS MODEL ====================
// Import for Color
import 'package:flutter/material.dart';

class DeviceSettings {
  final GasThresholds lpgThresholds;
  // final GasThresholds coThresholds;
  final AlertSettings alertSettings;
  final NotificationPreferences notificationPreferences;
  final DataRetention dataRetention;

  DeviceSettings({
    required this.lpgThresholds,
    // required this.coThresholds,
    required this.alertSettings,
    required this.notificationPreferences,
    required this.dataRetention,
  });

  factory DeviceSettings.fromMap(Map<dynamic, dynamic> map) {
    return DeviceSettings(
      lpgThresholds: GasThresholds.fromMap(map['thresholds']['lpg']),
      // coThresholds: GasThresholds.fromMap(map['thresholds']['co']),
      alertSettings: AlertSettings.fromMap(map['alerts']),
      notificationPreferences: NotificationPreferences.fromMap(
        map['notifications'],
      ),
      dataRetention: DataRetention.fromMap(map['dataRetention']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'thresholds': {
        'lpg': lpgThresholds.toMap(),
        // 'co': coThresholds.toMap(),
      },
      'alerts': alertSettings.toMap(),
      'notifications': notificationPreferences.toMap(),
      'dataRetention': dataRetention.toMap(),
    };
  }
}

class GasThresholds {
  final int safe;
  final int warning;
  final int danger;
  final int critical;

  GasThresholds({
    required this.safe,
    required this.warning,
    required this.danger,
    required this.critical,
  });

  factory GasThresholds.fromMap(Map<dynamic, dynamic> map) {
    return GasThresholds(
      safe: map['safe'] ?? 200,
      warning: map['warning'] ?? 500,
      danger: map['danger'] ?? 1000,
      critical: map['critical'] ?? 2000,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'safe': safe,
      'warning': warning,
      'danger': danger,
      'critical': critical,
    };
  }
}

class AlertSettings {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final bool buzzerEnabled;
  final bool relayEnabled;

  AlertSettings({
    required this.pushEnabled,
    required this.emailEnabled,
    this.smsEnabled = false,
    required this.buzzerEnabled,
    required this.relayEnabled,
  });

  factory AlertSettings.fromMap(Map<dynamic, dynamic> map) {
    return AlertSettings(
      pushEnabled: map['pushEnabled'] ?? true,
      emailEnabled: map['emailEnabled'] ?? true,
      smsEnabled: map['smsEnabled'] ?? false,
      buzzerEnabled: map['buzzerEnabled'] ?? true,
      relayEnabled: map['relayEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pushEnabled': pushEnabled,
      'emailEnabled': emailEnabled,
      'smsEnabled': smsEnabled,
      'buzzerEnabled': buzzerEnabled,
      'relayEnabled': relayEnabled,
    };
  }
}

class NotificationPreferences {
  final bool safeToWarning;
  final bool warningToDanger;
  final bool dangerToCritical;
  final bool backToSafe;
  final bool offline;
  final bool batteryLow;

  NotificationPreferences({
    required this.safeToWarning,
    required this.warningToDanger,
    required this.dangerToCritical,
    required this.backToSafe,
    required this.offline,
    required this.batteryLow,
  });

  factory NotificationPreferences.fromMap(Map<dynamic, dynamic> map) {
    return NotificationPreferences(
      safeToWarning: map['safeToWarning'] ?? true,
      warningToDanger: map['warningToDanger'] ?? true,
      dangerToCritical: map['dangerToCritical'] ?? true,
      backToSafe: map['backToSafe'] ?? true,
      offline: map['offline'] ?? true,
      batteryLow: map['batteryLow'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'safeToWarning': safeToWarning,
      'warningToDanger': warningToDanger,
      'dangerToCritical': dangerToCritical,
      'backToSafe': backToSafe,
      'offline': offline,
      'batteryLow': batteryLow,
    };
  }
}

class DataRetention {
  final int hourly; // hours
  final int daily; // days

  DataRetention({
    required this.hourly,
    required this.daily,
  });

  factory DataRetention.fromMap(Map<dynamic, dynamic> map) {
    return DataRetention(
      hourly: map['hourly'] ?? 168, // 7 days default
      daily: map['daily'] ?? 365, // 1 year default
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hourly': hourly,
      'daily': daily,
    };
  }
}

