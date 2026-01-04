import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // 1. Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );

    // 2. Request Permissions (especially for iOS & Android 13+)
    await _requestPermissions();

    // 3. Initialize Firebase Messaging
    await _configureFirebaseMessaging();
  }

  Future<void> _requestPermissions() async {
    // Local Notifications (Android 13+)
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    // Firebase (iOS & Android)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  Future<void> _configureFirebaseMessaging() async {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        showLocalNotification(
          title: message.notification!.title,
          body: message.notification!.body,
          payload: message.data.toString(),
        );
      }
    });

    // Background/Terminated handled by system or onBackgroundMessage handler in main.dart
  }

  Future<void> showLocalNotification({
    String? title,
    String? body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'high_importance_channel', // id
          'High Importance Notifications', // title
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<String?> getDeviceToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> showWelcomeNotification(String username) async {
    await showLocalNotification(
      title: 'Welcome Back, $username! 👋',
      body: 'Ready to scan and organize your documents?',
      payload: 'welcome_login',
    );
  }

  Future<void> showTaskCompleteNotification(
    String taskName,
    String resultPreview,
  ) async {
    await showLocalNotification(
      title: 'Task Completed: $taskName ✅',
      body: resultPreview.isNotEmpty
          ? 'Result: $resultPreview'
          : 'Your output is ready to view.',
      payload: 'task_complete_$taskName',
    );
  }
}
