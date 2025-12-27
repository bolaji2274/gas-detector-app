import 'package:flutter/material.dart';

class SensorData {
  final double lpg;
  final int lpgRaw;
  final double co;
  final int coRaw;
  final String status;
  final int statusCode;
  final int timestamp;
  final int? wifiSignal;
  final double? temperature;
  final double? humidity;

  SensorData({
    required this.lpg,
    required this.lpgRaw,
    required this.co,
    required this.coRaw,
    required this.status,
    required this.statusCode,
    required this.timestamp,
    this.wifiSignal,
    this.temperature,
    this.humidity,
  });

  factory SensorData.fromMap(Map<dynamic, dynamic> map) {
    return SensorData(
      lpg: (map['lpg'] ?? 0).toDouble(),
      lpgRaw: map['lpgRaw'] ?? 0,
      co: (map['co'] ?? 0).toDouble(),
      coRaw: map['coRaw'] ?? 0,
      status: map['status'] ?? 'safe',
      statusCode: map['statusCode'] ?? 0,
      timestamp: map['timestamp'] ?? 0,
      wifiSignal: map['wifiSignal'],
      temperature: map['temperature']?.toDouble(),
      humidity: map['humidity']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lpg': lpg,
      'lpgRaw': lpgRaw,
      'co': co,
      'coRaw': coRaw,
      'status': status,
      'statusCode': statusCode,
      'timestamp': timestamp,
      if (wifiSignal != null) 'wifiSignal': wifiSignal,
      if (temperature != null) 'temperature': temperature,
      if (humidity != null) 'humidity': humidity,
    };
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  String get timeFormatted {
    final time = dateTime;
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  String get dateFormatted {
    final date = dateTime;
    return '${date.day}/${date.month}/${date.year}';
  }

  Color get statusColor {
    switch (status) {
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

  String get statusEmoji {
    switch (status) {
      case 'safe':
        return '✓';
      case 'warning':
        return '⚠️';
      case 'danger':
        return '⚠️';
      case 'critical':
        return '🚨';
      default:
        return '•';
    }
  }
}