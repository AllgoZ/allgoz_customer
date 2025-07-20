import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // 🔔 Call this once in your app's initState
  static Future<void> initialize(BuildContext context) async {
    await Firebase.initializeApp();

    // ✅ Request permissions (Android 13+ and iOS)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notification permission granted');
    } else {
      print('❌ Notification permission declined');
    }

    // ✅ Get and print FCM token
    String? token = await _messaging.getToken();
    print('📱 FCM Token: $token');
    // Optionally: Save token to Firestore under user ID

    // ✅ Foreground handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        print('📩 Foreground: ${message.notification!.title}');
        // Optionally show local notification here
        _showSimpleDialog(context, message.notification!.title ?? '', message.notification!.body ?? '');
      }
    });

    // ✅ When app is opened via notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🚀 Opened from notification: ${message.notification?.title}');
      // Optional: Navigate to a specific page
    });
  }

  // 🔕 Background handler (called from main.dart)
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    print('🔕 BG Message: ${message.notification?.title}');
    // Optional: Save to local DB or trigger actions
  }

  // ✅ Helper to show basic dialog on foreground notification
  static void _showSimpleDialog(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }
}
