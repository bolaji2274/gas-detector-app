import 'package:flutter/material.dart';

class AlertModel {
  final String id;
  final String deviceId;
  final String deviceName;
  final String location;
  final String level;
  final int levelCode;
  final String gas;
  final double value;
  final int timestamp;
  final bool acknowledged;
  final int? acknowledgedAt;
  final String? acknowledgedBy;
  final String? message;

  AlertModel({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.location,
    required this.level,
    required this.levelCode,
    required this.gas,
    required this.value,
    required this.timestamp,
    this.acknowledged = false,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.message,
  });

  factory AlertModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return AlertModel(
      id: id,
      deviceId: map['deviceId'] ?? '',
      deviceName: map['deviceName'] ?? 'Unknown Device',
      location: map['location'] ?? 'Unknown',
      level: map['level'] ?? 'warning',
      levelCode: map['levelCode'] ?? 2,
      gas: map['gas'] ?? '',
      value: (map['value'] ?? 0).toDouble(),
      timestamp: map['timestamp'] ?? 0,
      acknowledged: map['acknowledged'] ?? false,
      acknowledgedAt: map['acknowledgedAt'],
      acknowledgedBy: map['acknowledgedBy'],
      message: map['message'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'location': location,
      'level': level,
      'levelCode': levelCode,
      'gas': gas,
      'value': value,
      'timestamp': timestamp,
      'acknowledged': acknowledged,
      if (acknowledgedAt != null) 'acknowledgedAt': acknowledgedAt,
      if (acknowledgedBy != null) 'acknowledgedBy': acknowledgedBy,
      if (message != null) 'message': message,
    };
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  String get timeFormatted {
    final time = dateTime;
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  Color get levelColor {
    switch (level) {
      case 'safe':
        return const Color(0xFF4CAF50);
      case 'warning':
        return const Color(0xFF2196F3);
      case 'danger':
        return const Color(0xFFFF9800);
      case 'critical':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String get levelEmoji {
    switch (level) {
      case 'safe':
        return '✓';
      case 'warning':
        return '⚠️';
      case 'danger':
        return '⚠️';
      case 'critical':
        return '🚨';
      case 'test':
        return '🔧';
      default:
        return '•';
    }
  }

  String get title {
    switch (level) {
      case 'safe':
        return 'Normal Levels';
      case 'warning':
        return 'Warning: Elevated Gas';
      case 'danger':
        return 'DANGER: High Gas Level';
      case 'critical':
        return 'CRITICAL: Gas Leak!';
      case 'test':
        return 'System Test';
      default:
        return 'Alert';
    }
  }

  String get description {
    if (message != null) return message!;

    return '$gas detected at ${value.toStringAsFixed(0)} PPM in $deviceName ($location)';
  }
}
