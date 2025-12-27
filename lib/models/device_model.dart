// ==================== DEVICE MODEL ====================

class Device {
  final String id;
  final String name;
  final String location;
  final String userId;
  final String status; // online, offline
  final int lastSeen;
  final String hardwareVersion;
  final String firmwareVersion;
  final int wifiSignal;
  final String powerSource; // mains, battery
  final int batteryLevel;

  Device({
    required this.id,
    required this.name,
    required this.location,
    required this.userId,
    required this.status,
    required this.lastSeen,
    this.hardwareVersion = '1.0',
    this.firmwareVersion = '1.0.0',
    this.wifiSignal = -50,
    this.powerSource = 'mains',
    this.batteryLevel = 100,
  });

  factory Device.fromMap(Map<dynamic, dynamic> map, String id) {
    return Device(
      id: id,
      name: map['name'] ?? 'Unknown Device',
      location: map['location'] ?? 'Unknown',
      userId: map['userId'] ?? '',
      status: map['status'] ?? 'offline',
      lastSeen: map['lastSeen'] ?? 0,
      hardwareVersion: map['hardwareVersion'] ?? '1.0',
      firmwareVersion: map['firmwareVersion'] ?? '1.0.0',
      wifiSignal: map['wifiSignal'] ?? -50,
      powerSource: map['powerSource'] ?? 'mains',
      batteryLevel: map['batteryLevel'] ?? 100,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'userId': userId,
      'status': status,
      'lastSeen': lastSeen,
      'hardwareVersion': hardwareVersion,
      'firmwareVersion': firmwareVersion,
      'wifiSignal': wifiSignal,
      'powerSource': powerSource,
      'batteryLevel': batteryLevel,
    };
  }

  bool get isOnline => status == 'online';
  
  String get lastSeenFormatted {
    final now = DateTime.now();
    final lastSeenDate = DateTime.fromMillisecondsSinceEpoch(lastSeen);
    final difference = now.difference(lastSeenDate);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
  
  String get wifiSignalStrength {
    if (wifiSignal >= -50) return 'Excellent';
    if (wifiSignal >= -60) return 'Good';
    if (wifiSignal >= -70) return 'Fair';
    return 'Poor';
  }
}


