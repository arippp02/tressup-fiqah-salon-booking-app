import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color figmaBrown1 = Color(0xFF6D4C41);
const Color figmaNudeBG = Color(0xFFFDF6F0);

class AdminInsightsPage extends StatelessWidget {
  const AdminInsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: figmaNudeBG,
      appBar: AppBar(
        title: const Text(
          "Business Insights",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: figmaBrown1,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Performance Summary",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: figmaBrown1,
              ),
            ),
            const SizedBox(height: 15),

            // --- 1. Appointment Metrics ---
            _buildMetricsGrid(),

            const SizedBox(height: 30),

            // --- 2. Top Performing Staff ---
            const Text(
              "Top Performing Staff",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: figmaBrown1,
              ),
            ),
            const SizedBox(height: 12),
            _buildStaffLeaderboard(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('appointments').snapshots(),
      builder: (context, snapshot) {
        int total = 0;
        int completed = 0;
        int cancelled = 0;

        if (snapshot.hasData) {
          total = snapshot.data!.docs.length;
          completed = snapshot.data!.docs
              .where((d) => d['status'] == 'completed')
              .length;
          cancelled = snapshot.data!.docs
              .where((d) => d['status'] == 'cancelled')
              .length;
        }

        return Column(
          children: [
            _buildPolishedCard(
              "Total Revenue Potential",
              "RM ${(total * 50)}",
              Icons.payments_outlined,
              Colors.teal,
              isFullWidth: true,
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _buildPolishedCard(
                  "Bookings",
                  total.toString(),
                  Icons.calendar_month_outlined,
                  Colors.blue,
                ),
                _buildPolishedCard(
                  "Finished",
                  completed.toString(),
                  Icons.check_circle_outline,
                  Colors.green,
                ),
                _buildPolishedCard(
                  "Cancelled",
                  cancelled.toString(),
                  Icons.cancel_outlined,
                  Colors.red,
                ),
                StreamBuilder<AggregateQuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'customer')
                      .count()
                      .get()
                      .asStream(),
                  builder: (context, snap) {
                    final count = snap.data?.count ?? 0;
                    return _buildPolishedCard(
                      "Customers",
                      count.toString(),
                      Icons.people_outline,
                      Colors.orange,
                    );
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStaffLeaderboard() {
    return StreamBuilder<QuerySnapshot>(
      // 1. Fetch only ACTIVE staff members first
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'staff')
          .snapshots(),
      builder: (context, staffSnapshot) {
        if (!staffSnapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        // Create a list of currently active staff names
        List<String> activeStaffNames = staffSnapshot.data!.docs
            .map(
              (doc) =>
                  (doc.data() as Map<String, dynamic>)['name']?.toString() ??
                  '',
            )
            .toList();

        return StreamBuilder<QuerySnapshot>(
          // 2. Fetch completed appointments
          stream: FirebaseFirestore.instance
              .collection('appointments')
              .where('status', isEqualTo: 'completed')
              .snapshots(),
          builder: (context, apptSnapshot) {
            if (!apptSnapshot.hasData) return const SizedBox();

            Map<String, int> staffPerformance = {};

            for (var doc in apptSnapshot.data!.docs) {
              String stylist = doc['stylist'] ?? 'Unknown';

              // ✅ ONLY add to leaderboard if the stylist exists in the active staff list
              if (activeStaffNames.contains(stylist)) {
                staffPerformance[stylist] =
                    (staffPerformance[stylist] ?? 0) + 1;
              }
            }

            // Also ensure staff with 0 appointments still show up (optional)
            for (var name in activeStaffNames) {
              if (!staffPerformance.containsKey(name)) {
                staffPerformance[name] = 0;
              }
            }

            var sortedEntries = staffPerformance.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedEntries.length,
              itemBuilder: (context, index) {
                final entry = sortedEntries[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: figmaBrown1.withOpacity(0.1),
                      child: Text(
                        "#${index + 1}",
                        style: const TextStyle(
                          color: figmaBrown1,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: figmaBrown1,
                      ),
                    ),
                    subtitle: Text("${entry.value} Appointments Completed"),
                    trailing: const Icon(
                      Icons.trending_up,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPolishedCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: isFullWidth
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: figmaBrown1,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
