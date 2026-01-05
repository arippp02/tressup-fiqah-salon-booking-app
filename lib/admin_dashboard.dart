import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'loginpage.dart';
import 'admin_appointments.dart';
import 'admin_services.dart';
import 'admin_staff.dart';
import 'admin_customers.dart';
import 'admin_insights.dart';
import 'admin_reviews.dart';
import 'admin_notifications.dart';

const Color figmaBrown1 = Color(0xFF6D4C41);
const Color figmaNudeBG = Color(0xFFFDF6F0);
const Color figmaCard = Colors.white;

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  void _handleLogout(BuildContext context) async {
    // 1. Show Confirmation Dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: figmaNudeBG,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Confirm logout",
            style: TextStyle(color: figmaBrown1, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to logout of the admin panel?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // Return false
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true), // Return true
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    // 2. If user confirmed (true), then sign out
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: figmaNudeBG,
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: figmaBrown1,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _handleLogout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Business Overview",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: figmaBrown1,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildAdminCard(
                    context,
                    icon: Icons.calendar_today,
                    title: "Bookings",
                    color: Colors.blue,
                    page: const AdminAppointmentsPage(),
                  ),
                  _buildAdminCard(
                    context,
                    icon: Icons.cut,
                    title: "Services",
                    color: Colors.purple,
                    page: const AdminServicesPage(),
                  ),
                  _buildAdminCard(
                    context,
                    icon: Icons.people,
                    title: "Staff",
                    color: Colors.orange,
                    page: const AdminStaffPage(),
                  ),
                  _buildAdminCard(
                    context,
                    icon: Icons.person_search,
                    title: "Customers",
                    color: Colors.green,
                    page: const AdminCustomersPage(),
                  ),
                  _buildAdminCard(
                    context,
                    icon: Icons.bar_chart,
                    title: "Insights",
                    color: Colors.teal,
                    page: const AdminInsightsPage(),
                  ),
                  _buildAdminCard(
                    context,
                    icon: Icons.star_rate,
                    title: "Reviews",
                    color: Colors.amber,
                    page: const AdminReviewsPage(),
                  ),
                  // ✅ NEW "SEND ALERTS" CARD ADDED HERE
                  _buildAdminCard(
                    context,
                    icon: Icons.notifications_active,
                    title: "Send Alerts",
                    color: Colors.deepOrange,
                    page: const AdminNotificationsPage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required Widget page,
  }) {
    return GestureDetector(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        decoration: BoxDecoration(
          color: figmaCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: figmaBrown1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
