import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';

class NotificationSender {
  static const String _projectId = "fiqahbookingapp-86ce9";

  // --- 1. SEND ALERT TO ALL STAFF ---
  static Future<void> notifyAllStaff({
    required String title,
    required String body,
  }) async {
    try {
      String? accessToken = await _getAccessToken();
      if (accessToken == null) return;

      QuerySnapshot staffSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'staff')
          .where('fcmToken', isNull: false)
          .get();

      Set<String> staffTokens = {};
      for (var doc in staffSnapshot.docs) {
        final token = doc['fcmToken'];
        if (token != null && token.toString().isNotEmpty) {
          staffTokens.add(token.toString());
        }
      }

      for (String token in staffTokens) {
        await _sendPushMessage(token, title, body, accessToken);
      }
    } catch (e) {
      print("❌ Error notifying staff: $e");
    }
  }

  // --- 2. NEW: NOTIFY SPECIFIC CUSTOMER ---
  static Future<void> notifySpecificUser({
    required String userId,
    required String title,
    required String body,
  }) async {
    try {
      // Get Access Token
      String? accessToken = await _getAccessToken();
      if (accessToken == null) return;

      // Find specific user's token
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        String? token = (userDoc.data() as Map<String, dynamic>)['fcmToken'];
        if (token != null && token.isNotEmpty) {
          await _sendPushMessage(token, title, body, accessToken);
          print("✅ Notification sent to user: $userId");
        }
      }
    } catch (e) {
      print("❌ Error notifying user: $e");
    }
  }

  // --- HELPERS ---
  static Future<String?> _getAccessToken() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/service_account.json',
      );
      final accountCredentials = ServiceAccountCredentials.fromJson(jsonString);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(accountCredentials, scopes);
      return client.credentials.accessToken.data;
    } catch (e) {
      print("❌ Auth Error: $e");
      return null;
    }
  }

  static Future<void> _sendPushMessage(
    String token,
    String title,
    String body,
    String accessToken,
  ) async {
    try {
      final String url =
          'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';
      await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': token,
            'notification': {'title': title, 'body': body},
            'data': {'click_action': 'FLUTTER_NOTIFICATION_CLICK'},
          },
        }),
      );
    } catch (e) {
      print("❌ Network Error: $e");
    }
  }
}
