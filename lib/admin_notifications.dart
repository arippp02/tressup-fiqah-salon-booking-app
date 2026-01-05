import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:intl/intl.dart'; // ✅ Import Intl

const Color figmaBrown1 = Color(0xFF6D4C41);
const Color figmaNudeBG = Color(0xFFFDF6F0);

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  DateTime? _selectedExpiryDate; // ✅ New Variable
  bool _isLoading = false;

  final String _projectId = "fiqahbookingapp-86ce9";

  // --- 1. GET ACCESS TOKEN ---
  Future<String?> _getAccessToken() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/service_account.json',
      );
      final accountCredentials = ServiceAccountCredentials.fromJson(jsonString);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(accountCredentials, scopes);
      return client.credentials.accessToken.data;
    } catch (e) {
      print("Error generating Access Token: $e");
      return null;
    }
  }

  // --- 2. SAVE PROMOTION WITH EXPIRY ---
  Future<void> _savePromotionToDatabase(String title, String body) async {
    try {
      await FirebaseFirestore.instance.collection('promotions').add({
        'title': title,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(),
        // ✅ Save Expiry Date (default to 7 days if not selected)
        'expiryDate':
            _selectedExpiryDate ?? DateTime.now().add(const Duration(days: 7)),
        'createdBy': 'Admin',
      });
      print("✅ Promotion saved.");
    } catch (e) {
      print("❌ Error saving promotion: $e");
    }
  }

  Future<void> _sendToAllUsers() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter title and message")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Step A: Save to History
      await _savePromotionToDatabase(
        _titleController.text.trim(),
        _bodyController.text.trim(),
      );

      // Step B: Get Token
      String? accessToken = await _getAccessToken();
      if (accessToken == null) throw Exception("Access Token Failed");

      // Step C: Get Users
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('fcmToken', isNull: false)
          .get();

      if (snapshot.docs.isEmpty) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("No users found.")));
        setState(() => _isLoading = false);
        return;
      }

      Set<String> uniqueTokens = {};
      for (var doc in snapshot.docs) {
        if (doc['fcmToken'] != null) uniqueTokens.add(doc['fcmToken']);
      }

      // Step D: Send Messages
      int successCount = 0;
      for (String token in uniqueTokens) {
        bool success = await _sendPushMessage(
          token,
          _titleController.text,
          _bodyController.text,
          accessToken,
        );
        if (success) successCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sent to $successCount devices!"),
            backgroundColor: Colors.green,
          ),
        );
        _titleController.clear();
        _bodyController.clear();
        setState(() => _selectedExpiryDate = null); // Reset date
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _sendPushMessage(
    String token,
    String title,
    String body,
    String accessToken,
  ) async {
    try {
      final String url =
          'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': token,
            'notification': {'title': title, 'body': body},
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'status': 'done',
            },
          },
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ✅ PICK DATE FUNCTION
  Future<void> _pickExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: figmaBrown1,
              onPrimary: Colors.white,
              onSurface: figmaBrown1,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedExpiryDate) {
      setState(() {
        _selectedExpiryDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: figmaNudeBG,
      appBar: AppBar(
        title: const Text("Broadcast & Promotions"),
        backgroundColor: figmaBrown1,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Create Flash Sale",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: figmaBrown1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Set an expiration date so offers auto-hide.",
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Promo Title",
                hintText: "e.g., Weekend Sale!",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _bodyController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Promo Details",
                hintText: "e.g., 20% Off...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ✅ NEW: DATE PICKER UI
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, color: figmaBrown1),
                title: Text(
                  _selectedExpiryDate == null
                      ? "Select Expiration Date"
                      : "Expires: ${DateFormat('dd MMM yyyy').format(_selectedExpiryDate!)}",
                  style: TextStyle(
                    color: _selectedExpiryDate == null
                        ? Colors.grey
                        : Colors.black,
                    fontWeight: _selectedExpiryDate == null
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _pickExpiryDate,
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendToAllUsers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: figmaBrown1,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rocket_launch),
                          SizedBox(width: 10),
                          Text(
                            "PUBLISH & NOTIFY",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
