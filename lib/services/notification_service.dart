import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;

class NotificationService with ChangeNotifier {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  bool _notificationsEnabled = false;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> initialize() async {
    try {
      await _requestPermissions();
      await _initializeLocalNotifications();
      _fcmToken = await _messaging.getToken();
      print('FCM Token: $_fcmToken');
      _setupMessageHandlers();

      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        notifyListeners();
      });
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      _notificationsEnabled =
          settings.authorizationStatus == AuthorizationStatus.authorized;

      notifyListeners();
    } catch (e) {
      print('Error requesting permissions: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: (response) {
          _handleNotificationTap(response.payload);
        },
      );

      await _createNotificationChannels();
    } catch (e) {
      print('Error initializing local notifications: $e');
    }
  }

  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    try {
      const AndroidNotificationChannel criticalChannel =
          AndroidNotificationChannel(
        'critical_alerts',
        'Critical Gas Alerts',
        description: 'Critical gas detection alerts',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      );

      const AndroidNotificationChannel alertsChannel =
          AndroidNotificationChannel(
        'gas_alerts',
        'Gas Alerts',
        description: 'Gas detection alerts and warnings',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(criticalChannel);

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(alertsChannel);
    } catch (e) {
      print('Error creating notification channels: $e');
    }
  }

  void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message.data['deviceId']);
    });

    _checkInitialMessage();
  }

  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      _handleNotificationTap(initialMessage.data['deviceId']);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      RemoteNotification? notification = message.notification;

      if (notification != null) {
        String channelId = 'gas_alerts';
        if (message.data['alertLevel'] == 'critical') {
          channelId = 'critical_alerts';
        }

        await _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              channelId == 'critical_alerts'
                  ? 'Critical Gas Alerts'
                  : 'Gas Alerts',
              channelDescription: notification.body,
              importance: channelId == 'critical_alerts'
                  ? Importance.max
                  : Importance.high,
              priority:
                  channelId == 'critical_alerts' ? Priority.max : Priority.high,
              icon: '@mipmap/ic_launcher',
              playSound: true,
              enableVibration: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data['deviceId'],
        );
      }
    } catch (e) {
      print('Error handling foreground message: $e');
    }
  }

  void _handleNotificationTap(String? deviceId) {
    if (deviceId != null) {
      print('Navigate to device: $deviceId');
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'general',
    bool isUrgent = false,
  }) async {
    try {
      await _localNotifications.show(
        DateTime.now().millisecond,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelId == 'critical_alerts'
                ? 'Critical Gas Alerts'
                : channelId == 'gas_alerts'
                    ? 'Gas Alerts'
                    : 'General Notifications',
            importance: isUrgent ? Importance.max : Importance.high,
            priority: isUrgent ? Priority.max : Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: isUrgent,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  Future<bool> checkNotificationPermissions() async {
    try {
      NotificationSettings settings =
          await _messaging.getNotificationSettings();
      _notificationsEnabled =
          settings.authorizationStatus == AuthorizationStatus.authorized;
      notifyListeners();
      return _notificationsEnabled;
    } catch (e) {
      print('Error checking notification permissions: $e');
      return false;
    }
  }
}
