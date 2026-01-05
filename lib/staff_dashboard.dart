import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'loginpage.dart';
import 'staff_appointments.dart';
import 'staff_schedule.dart';
import 'staff_customer_info.dart';
import 'staff_reviews.dart';
import 'staff_service_catalogue.dart';

const Color figmaBrown1 = Color(0xFF6D4C41);
const Color figmaNudeBG = Color(0xFFFDF6F0);
const Color figmaCard = Colors.white;

class StaffDashboardPage extends StatefulWidget {
  const StaffDashboardPage({super.key});

  @override
  State<StaffDashboardPage> createState() => _StaffDashboardPageState();
}

class _StaffDashboardPageState extends State<StaffDashboardPage> {
  String staffName = "Staff";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStaffProfile();
  }

  Future<void> _fetchStaffProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          staffName = doc.data()?['name'] ?? "Staff";
          isLoading = false;
        });
      }
    }
  }

  void _handleLogout() async {
    // 1. Show the confirmation dialog
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: figmaNudeBG,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Logout Confirmation",
            style: TextStyle(color: figmaBrown1, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to logout? You will need to log in again to see your schedule.",
          ),
          actions: [
            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            // Confirm Button
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
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

    // 2. If the user tapped 'Logout' (true), proceed with sign out
    if (confirmLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
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
        title: Text("Hello, $staffName"),
        backgroundColor: figmaBrown1,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _handleLogout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ NEW: URGENCY ALERT (Replaces Local Notifications)
                  _buildUrgentAlert(),

                  _buildTodaySummary(),
                  const SizedBox(height: 25),
                  const Text(
                    "My Operations",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: figmaBrown1,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        // 1. Appointments
                        _buildMenuCard(
                          icon: Icons.calendar_today,
                          title: "My Appointments",
                          color: Colors.blue,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  StaffAppointmentsPage(staffName: staffName),
                            ),
                          ),
                        ),
                        // 2. Schedule
                        _buildMenuCard(
                          icon: Icons.access_time,
                          title: "My Schedule",
                          color: Colors.orange,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  StaffSchedulePage(staffName: staffName),
                            ),
                          ),
                        ),
                        // 3. Customer Info
                        _buildMenuCard(
                          icon: Icons.people,
                          title: "Customer Info",
                          color: Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    StaffCustomerInfoPage(staffName: staffName),
                              ),
                            );
                          },
                        ),
                        // 4. My Reviews
                        _buildMenuCard(
                          icon: Icons.star,
                          title: "My Reviews",
                          color: Colors.amber,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    StaffReviewsPage(staffName: staffName),
                              ),
                            );
                          },
                        ),
                        // 5. Service Catalogue
                        _buildMenuCard(
                          icon: Icons.menu_book_rounded,
                          title: "Service Catalogue",
                          color: Colors.purple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const StaffServiceCataloguePage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // LOGIC: Checks for appointments in the next 45 minutes
  Widget _buildUrgentAlert() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('stylist', isEqualTo: staffName)
          .where('status', isEqualTo: 'upcoming')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        bool hasUrgent = false;
        DateTime now = DateTime.now();
        String serviceName = "";
        String urgentTime = "";

        for (var doc in snapshot.data!.docs) {
          try {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            // Parse Date
            DateTime date = DateTime.parse(data['date']);

            // Check if it is TODAY
            if (date.year == now.year &&
                date.month == now.month &&
                date.day == now.day) {
              // Parse Time "10:30 AM"
              String timeStr = data['time'];
              List<String> parts = timeStr.split(RegExp(r'[: ]'));
              int h = int.parse(parts[0]);
              int m = int.parse(parts[1]);
              if (timeStr.contains("PM") && h != 12) h += 12;
              if (timeStr.contains("AM") && h == 12) h = 0;

              DateTime apptTime = DateTime(
                date.year,
                date.month,
                date.day,
                h,
                m,
              );

              // Check if within next 45 mins (or slightly late by 15 mins)
              Duration diff = apptTime.difference(now);
              if (diff.inMinutes >= -15 && diff.inMinutes <= 45) {
                hasUrgent = true;
                serviceName = data['service'] ?? "Service";
                urgentTime = timeStr;
                break;
              }
            }
          } catch (e) {
            // Ignore parsing errors
          }
        }

        if (!hasUrgent) return const SizedBox();

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            border: Border.all(color: Colors.red),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 32,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "CLIENT ARRIVING SOON!",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$serviceName at $urgentTime",
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Text(
                      "Check your schedule immediately.",
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodaySummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('stylist', isEqualTo: staffName)
          .where('status', isEqualTo: 'upcoming')
          .snapshots(),
      builder: (context, snapshot) {
        int count = snapshot.data?.docs.length ?? 0;
        return Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [figmaBrown1, Color(0xFF8D6E63)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Upcoming Tasks",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                "$count Appointments",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Keep up the great work!",
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: figmaCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
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
