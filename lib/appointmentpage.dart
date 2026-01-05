import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'database.dart'; // We will use direct Firestore calls to fix the sorting issue

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  // Helper to format date string
  String _formatDate(DateTime d) {
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  // --- FIREBASE ACTIONS ---

  Future<void> _cancelAppointment(String docId) async {
    // Update status to 'cancelled' in Firestore
    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(docId)
        .update({'status': 'cancelled'});
  }

  Future<void> _reschedule(
    BuildContext context,
    String docId,
    DateTime currentDate,
  ) async {
    // Pick new Date
    DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: currentDate.isBefore(DateTime.now())
          ? DateTime.now()
          : currentDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030), // Allow booking up to 2030
    );

    if (newDate == null) return;
    if (!mounted) return;

    // Pick new Time
    String? newTime = await showModalBottomSheet<String>(
      context: context,
      builder: (_) {
        final times = ["10:00 AM", "12:00 PM", "2:00 PM", "5:00 PM"];
        return ListView(
          shrinkWrap: true,
          children: times
              .map(
                (t) => ListTile(
                  title: Text(t),
                  onTap: () => Navigator.pop(context, t),
                ),
              )
              .toList(),
        );
      },
    );

    if (newTime == null) return;

    // Update Firestore
    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(docId)
        .update({
          'date': newDate.toIso8601String(),
          'time': newTime,
          'status': 'upcoming',
        });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        title: const Text("My Appointments"),
        centerTitle: true,
        backgroundColor: const Color(0xFF6D4C41),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // FIXED: Removed .orderBy('date') from here to prevent "Missing Index" error.
        // We will sort the data manually in the builder below.
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('userId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Error Handling
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // 2. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 3. Empty State
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: _emptyText("No appointments yet."));
          }

          // --- SORTING LOGIC ---
          // Convert to a list we can modify
          var docs = snapshot.data!.docs.toList();

          // Sort by Date manually
          docs.sort((a, b) {
            try {
              final dateA = DateTime.parse(a['date']);
              final dateB = DateTime.parse(b['date']);
              return dateA.compareTo(dateB); // Ascending order (Oldest first)
            } catch (e) {
              return 0;
            }
          });

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          // 4. Separate into Upcoming & Past
          List<DocumentSnapshot> upcoming = [];
          List<DocumentSnapshot> past = [];

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;

            DateTime date = DateTime.now();
            try {
              date = DateTime.parse(data['date']);
            } catch (e) {
              // keep default
            }

            String status = data['status'] ?? 'upcoming';
            // A date is "past" if it is strictly before today (00:00:00)
            bool isPastDate = date.isBefore(today);

            if (isPastDate || status == 'completed' || status == 'cancelled') {
              past.add(doc);
            } else {
              upcoming.add(doc);
            }
          }

          // 5. Build the List UI
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // --- UPCOMING SECTION ---
              const Text(
                "UPCOMING",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6D4C41),
                ),
              ),
              const SizedBox(height: 10),

              if (upcoming.isEmpty) _emptyText("No upcoming appointments"),

              ...upcoming.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                DateTime date =
                    DateTime.tryParse(data['date'] ?? '') ?? DateTime.now();
                return _buildUpcomingCard(context, doc.id, data, date);
              }),

              const SizedBox(height: 24),

              // --- PAST SECTION ---
              const Text(
                "PAST APPOINTMENTS",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6D4C41),
                ),
              ),
              const SizedBox(height: 10),

              if (past.isEmpty) _emptyText("No past appointments yet"),

              ...past.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                DateTime date =
                    DateTime.tryParse(data['date'] ?? '') ?? DateTime.now();
                return _buildPastTile(data, date);
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _emptyText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: const TextStyle(color: Colors.grey)),
    );
  }

  // --- UPCOMING CARD WIDGET ---
  Widget _buildUpcomingCard(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
    DateTime date,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['service'] ?? 'Service',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text("${_formatDate(date)} · ${data['time']}"),
          Text("With ${data['stylist']}"),

          const SizedBox(height: 12),

          Row(
            children: [
              OutlinedButton(
                onPressed: () => _reschedule(context, docId, date),
                child: const Text("Reschedule"),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => _cancelAppointment(docId),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- PAST TILE WIDGET ---
  Widget _buildPastTile(Map<String, dynamic> data, DateTime date) {
    String status = data['status'] ?? 'completed';

    // Visual tweak: if it's "upcoming" but in the past, show as completed
    if (status == 'upcoming' &&
        date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      status = 'completed';
    }

    final isCancelled = status == 'cancelled';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isCancelled ? Icons.cancel : Icons.check_circle,
          color: isCancelled ? Colors.red : Colors.green,
        ),
        title: Text(data['service'] ?? ''),
        subtitle: Text("${_formatDate(date)} · ${data['stylist']}"),
        trailing: Text(
          isCancelled ? "Cancelled" : "Completed",
          style: TextStyle(
            color: isCancelled ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
