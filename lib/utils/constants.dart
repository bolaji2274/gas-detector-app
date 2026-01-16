// ==================== CONSTANTS.DART ====================
// lib/utils/constants.dart

class AppConstants {
  // App Info
  static const String appName = 'Gas Detector';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Smart Home Gas Detection System';

  // Firebase
  static const String firebaseProjectId = 'gas-detection-system';

  // Gas Thresholds (PPM)
  static const int lpgSafeThreshold = 300;
  static const int lpgWarningThreshold = 1000;
  static const int lpgDangerThreshold = 2500;
  static const int lpgCriticalThreshold = 5000;

  static const int coSafeThreshold = 30;
  static const int coWarningThreshold = 100;
  static const int coDangerThreshold = 200;
  static const int coCriticalThreshold = 400;

  // Update Intervals
  static const int sensorUpdateInterval = 5000; // 5 seconds
  static const int heartbeatInterval = 30000; // 30 seconds
  static const int settingsSyncInterval = 60000; // 1 minute

  // Chart Settings
  static const int defaultChartHours = 24;
  static const int maxDataPoints = 288; // 24 hours at 5-min intervals

  // Alert Settings
  static const int maxAlertsDisplay = 50;
  static const int alertRetentionDays = 30;

  // Storage Keys (SharedPreferences)
  static const String keyRememberMe = 'remember_me';
  static const String keyLastEmail = 'last_email';
  static const String keyThemeMode = 'theme_mode';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keySelectedDeviceId = 'selected_device_id';

  // Notification Channels
  static const String channelCriticalId = 'critical_alerts';
  static const String channelCriticalName = 'Critical Gas Alerts';
  static const String channelAlertsId = 'gas_alerts';
  static const String channelAlertsName = 'Gas Alerts';
  static const String channelGeneralId = 'general';
  static const String channelGeneralName = 'General Notifications';

  // Status Messages
  static const Map<String, String> statusMessages = {
    'safe': 'Air quality is normal',
    'warning': 'Elevated gas levels detected',
    'danger': 'High gas concentration - Take action!',
    'critical': 'CRITICAL - Evacuate immediately!',
    'offline': 'Device is offline',
  };

  // Gas Types
  static const Map<String, String> gasTypes = {
    'lpg': 'LPG (Liquefied Petroleum Gas)',
    'co': 'CO (Carbon Monoxide)',
    'natural_gas': 'Natural Gas',
    'methane': 'Methane',
  };

  // Gas Info
  static const Map<String, String> gasInfo = {
    'lpg':
        'LPG is heavier than air and accumulates near the floor. Common in cooking gas leaks.',
    'co':
        'CO is colorless, odorless, and deadly. Produced by incomplete combustion.',
  };

  // Safety Guidelines
  static const List<String> safetyGuidelines = [
    'If alarm sounds, evacuate immediately',
    'Do not use electrical switches or phones',
    'Open windows and doors if safe to do so',
    'Call emergency services from a safe distance',
    'Do not re-enter until professionals clear the area',
    'Regular maintenance and testing is essential',
  ];

  // Installation Guidelines
  static const List<String> installationGuidelines = [
    'Mount 6-12 inches below ceiling for LPG detection',
    'Keep away from windows and exhaust fans',
    'Install within 20 feet of gas appliances',
    'Avoid humid areas like bathrooms',
    'Test monthly using the test button',
    'Replace sensors every 2-3 years',
  ];

  // API Endpoints (if using custom backend)
  static const String apiBaseUrl = 'https://your-api.com/api/v1';
  static const String apiSensorData = '/sensor-data';
  static const String apiAlerts = '/alerts';
  static const String apiDevices = '/devices';

  // Error Messages
  static const String errorNoInternet = 'No internet connection';
  static const String errorDeviceOffline = 'Device is offline';
  static const String errorLoadingData = 'Failed to load data';
  static const String errorSavingSettings = 'Failed to save settings';
  static const String errorInvalidCredentials = 'Invalid email or password';

  // Success Messages
  static const String successSettingsSaved = 'Settings saved successfully';
  static const String successDeviceAdded = 'Device added successfully';
  static const String successAlertAcknowledged = 'Alert acknowledged';

  // Regex Patterns
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp passwordRegex = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{6,}$',
  );

  // Device ID Pattern
  static final RegExp deviceIdRegex = RegExp(r'^device_[0-9]{3}$');

  // Format Helpers
  static String formatPPM(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  static String formatTimestamp(int timestamp) {
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final DateTime now = DateTime.now();
    final Duration diff = now.difference(date);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  static String getStatusMessage(String status) {
    return statusMessages[status] ?? 'Unknown status';
  }
}
