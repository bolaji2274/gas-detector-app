// ==================== HELPERS.DART ====================
// lib/utils/helpers.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'theme.dart';
import 'constants.dart';

class Helpers {
  // Show SnackBar
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Show Alert Dialog
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(cancelText),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmText),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Show Loading Dialog
  static void showLoadingDialog(BuildContext context,
      {String message = 'Loading...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  // Hide Loading Dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  // Format Date
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // Format Time
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  // Format DateTime
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  // Validate Email
  static bool isValidEmail(String email) {
    return AppConstants.emailRegex.hasMatch(email);
  }

  // Validate Password
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  // Get Status Color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'safe':
        return AppTheme.safeColor;
      case 'warning':
        return AppTheme.warningStatusColor;
      case 'danger':
        return AppTheme.dangerStatusColor;
      case 'critical':
        return AppTheme.criticalStatusColor;
      case 'offline':
        return AppTheme.offlineColor;
      default:
        return Colors.grey;
    }
  }

  // Get Status Icon
  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'safe':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning_amber;
      case 'danger':
        return Icons.error;
      case 'critical':
        return Icons.dangerous;
      case 'offline':
        return Icons.cloud_off;
      default:
        return Icons.info;
    }
  }

  // Calculate Percentage
  static double calculatePercentage(double value, double max) {
    if (max == 0) return 0;
    return (value / max * 100).clamp(0, 100);
  }

  // Get WiFi Signal Icon
  static IconData getWiFiIcon(int signal) {
    if (signal >= -50) {
      return Icons.wifi;
    } else if (signal >= -60) {
      return Icons.wifi_2_bar;
    } else if (signal >= -70) {
      return Icons.wifi_1_bar;
    } else {
      return Icons.wifi_1_bar;
    }
    // return Icons.signal_wifi_4_bar;
    // } else if (signal >= -60) {
    //   return Icons.signal_wifi_3_bar;
    // } else if (signal >= -70) {
    //   return Icons.signal_wifi_2_bar;
    // } else {
    //   return Icons.signal_wifi_1_bar;
    // }
  }

  // Get Battery Icon
  static IconData getBatteryIcon(int level) {
    if (level >= 90) {
      return Icons.battery_full;
    } else if (level >= 60) {
      return Icons.battery_5_bar;
    } else if (level >= 30) {
      return Icons.battery_3_bar;
    } else {
      return Icons.battery_1_bar;
    }
  }

  // Launch URL
  static Future<void> launchURL(String url) async {
    // Implement with url_launcher package
    // final Uri uri = Uri.parse(url);
    // if (await canLaunchUrl(uri)) {
    //   await launchUrl(uri);
    // }
  }
}
