import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Auth

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // --- INITIALIZE ---
  static Future<void> init() async {
    // 1. Request Permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Local Notifications Setup
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(initSettings);

    // 3. Foreground Message Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showForegroundNotification(message);
    });

    // 4. Print Token (Debug)
    String? token = await _firebaseMessaging.getToken();
    print("🔥 FCM Token: $token");

    // 5. AUTO-SAVE TOKEN (If user is already logged in when app starts)
    // This handles the "Auto-Login" scenario
    saveTokenToFirestore();
  }

  // --- NEW: SAVE TOKEN TO FIRESTORE ---
  static Future<void> saveTokenToFirestore() async {
    try {
      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;
      // Get the token
      String? token = await _firebaseMessaging.getToken();

      // Only save if we have both a user and a token
      if (user != null && token != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token, // The critical field for sending messages
          'lastActive':
              FieldValue.serverTimestamp(), // Optional: track activity
        }, SetOptions(merge: true)); // MERGE = Don't delete existing data!

        print("✅ FCM Token saved to Firestore for user: ${user.uid}");
      }
    } catch (e) {
      print("❌ Error saving FCM token: $e");
    }
  }

  // --- SHOW NOTIFICATION ---
  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  }
}

// --- BACKGROUND HANDLER ---
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}
