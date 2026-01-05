import 'package:flutter/material.dart';

const Color figmaBrown1 = Color(0xFF6D4C41);
const Color figmaNudeBG = Color(0xFFFDF6F0);

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  SettingPageState createState() => SettingPageState();
}

class SettingPageState extends State<SettingPage> {
  // --- CUSTOMER NOTIFICATION PREFERENCES ---
  bool _bookingConfirmation = true;
  bool _bookingChanges = true;
  bool _loyaltyUpdates = true;
  bool _promotions = true;

  // Simulate saving to database
  void _saveNotificationPreference(String key, bool value) {
    setState(() {
      switch (key) {
        case 'confirmation':
          _bookingConfirmation = value;
          break;
        case 'changes':
          _bookingChanges = value;
          break;
        case 'loyalty':
          _loyaltyUpdates = value;
          break;
        case 'promo':
          _promotions = value;
          break;
      }
    });
    print("Updated preference $key to $value");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: figmaNudeBG,
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: figmaBrown1,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // 1. NOTIFICATIONS HEADER
          _buildHeader("Notification Preferences"),

          // a. Booking Confirmation
          SwitchListTile(
            activeColor: figmaBrown1,
            title: const Text("Booking Confirmation"),
            subtitle: const Text(
              "Get notified when your booking is confirmed.",
            ),
            secondary: const Icon(
              Icons.check_circle_outline,
              color: figmaBrown1,
            ),
            value: _bookingConfirmation,
            onChanged: (v) => _saveNotificationPreference('confirmation', v),
          ),

          // b. Booking Changes
          SwitchListTile(
            activeColor: figmaBrown1,
            title: const Text("Booking Changes"),
            subtitle: const Text("Alerts if your appointment is cancelled."),
            secondary: const Icon(Icons.edit_calendar, color: figmaBrown1),
            value: _bookingChanges,
            onChanged: (v) => _saveNotificationPreference('changes', v),
          ),

          // c. Loyalty Points
          SwitchListTile(
            activeColor: figmaBrown1,
            title: const Text("Loyalty Updates"),
            subtitle: const Text("Notifies when you earn points."),
            secondary: const Icon(Icons.star_border, color: figmaBrown1),
            value: _loyaltyUpdates,
            onChanged: (v) => _saveNotificationPreference('loyalty', v),
          ),

          // d. Promotions
          SwitchListTile(
            activeColor: figmaBrown1,
            title: const Text("Promotions & Offers"),
            subtitle: const Text("Receive exclusive discounts."),
            secondary: const Icon(
              Icons.local_offer_outlined,
              color: figmaBrown1,
            ),
            value: _promotions,
            onChanged: (v) => _saveNotificationPreference('promo', v),
          ),

          const Divider(height: 30),

          // 2. APP INFO HEADER
          _buildHeader("App Info"),

          ListTile(
            leading: const Icon(Icons.info_outline, color: figmaBrown1),
            title: const Text("About Fiqah Beauty"),
            subtitle: const Text("Version 1.0.0"),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: figmaBrown1,
        ),
      ),
    );
  }
}
