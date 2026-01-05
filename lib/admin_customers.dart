import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color figmaBrown1 = Color(0xFF6D4C41);
const Color figmaNudeBG = Color(0xFFFDF6F0);

class AdminCustomersPage extends StatefulWidget {
  const AdminCustomersPage({super.key});

  @override
  State<AdminCustomersPage> createState() => _AdminCustomersPageState();
}

class _AdminCustomersPageState extends State<AdminCustomersPage> {
  String _searchQuery = "";

  // --- 1. EDIT NOTE LOGIC ---
  void _editStaffNote(BuildContext context, String uid, String currentNote) {
    final TextEditingController noteController = TextEditingController(
      text: currentNote,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: figmaNudeBG,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Edit Staff Note",
          style: TextStyle(color: figmaBrown1, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: noteController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "Enter private notes (e.g. hair preferences)...",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: figmaBrown1),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .update({'staffNotes': noteController.text});
              if (context.mounted) {
                Navigator.pop(context); // Close Dialog
                Navigator.pop(context); // Close BottomSheet to refresh data
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Internal note updated")),
                );
              }
            },
            child: const Text(
              "Save Note",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: figmaNudeBG,
      appBar: AppBar(
        title: const Text("Customer Profiles"),
        backgroundColor: figmaBrown1,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search customer...",
                prefixIcon: const Icon(Icons.search, color: figmaBrown1),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.toLowerCase());
              },
            ),
          ),

          // --- CUSTOMER LIST ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'customer')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No customers found."));
                }

                final customers = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) ||
                      email.contains(_searchQuery);
                }).toList();

                if (customers.isEmpty) {
                  return const Center(child: Text("No matching customers."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final data =
                        customers[index].data() as Map<String, dynamic>;
                    final uid = customers[index].id;
                    final name = data['name'] ?? "User";
                    final email = data['email'] ?? "";

                    return Card(
                      color: Colors.white, // ✅ Card background set to White
                      elevation: 2, // Added slight elevation for depth
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                          color: Colors.grey.shade100,
                        ), // Subtle border
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: figmaBrown1.withOpacity(0.1),
                          child: const Icon(Icons.person, color: figmaBrown1),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(email),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showCustomerDetails(context, uid, data),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- BOTTOM SHEET: DETAILS & HISTORY ---
  void _showCustomerDetails(
    BuildContext context,
    String uid,
    Map<String, dynamic> userData,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: figmaNudeBG,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 1. PROFILE HEADER
              Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: figmaBrown1,
                    child: Icon(Icons.person, size: 35, color: Colors.white),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData['name'] ?? "Customer",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: figmaBrown1,
                          ),
                        ),
                        Text(
                          userData['email'] ?? "",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (userData['phone'] != null)
                          Text(
                            userData['phone'],
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),

              // 2. INTERNAL STAFF NOTES SECTION (Added Here)
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.sticky_note_2_rounded,
                              color: Colors.amber[800],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Internal Staff Notes",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[900],
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _editStaffNote(
                            context,
                            uid,
                            userData['staffNotes'] ?? "",
                          ),
                          color: Colors.amber[900],
                        ),
                      ],
                    ),
                    Text(
                      (userData['staffNotes'] == null ||
                              userData['staffNotes'] == "")
                          ? "No internal notes added yet."
                          : userData['staffNotes'],
                      style: TextStyle(fontSize: 14, color: Colors.brown[800]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                "Appointment History",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: figmaBrown1,
                ),
              ),
              const SizedBox(height: 15),

              // 3. APPOINTMENT HISTORY (TABBED)
              Expanded(
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        child: TabBar(
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(25.0),
                            color: figmaBrown1,
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey[600],
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: "Upcoming"),
                            Tab(text: "Completed"),
                            Tab(text: "Cancelled"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('appointments')
                              .where('userId', isEqualTo: uid)
                              .orderBy('date', descending: false)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Center(
                                child: Text("No booking history."),
                              );
                            }

                            final allDocs = snapshot.data!.docs;

                            final upcoming = allDocs.where((d) {
                              final s =
                                  (d.data()
                                      as Map<String, dynamic>)['status'] ??
                                  'upcoming';
                              return s == 'upcoming' || s == 'confirmed';
                            }).toList();

                            final completed = allDocs.where((d) {
                              final s =
                                  (d.data()
                                      as Map<String, dynamic>)['status'] ??
                                  'upcoming';
                              return s == 'completed';
                            }).toList();

                            final cancelled = allDocs.where((d) {
                              final s =
                                  (d.data()
                                      as Map<String, dynamic>)['status'] ??
                                  'upcoming';
                              return s == 'cancelled';
                            }).toList();

                            return TabBarView(
                              children: [
                                _buildHistoryList(
                                  upcoming,
                                  "No upcoming appointments.",
                                ),
                                _buildHistoryList(
                                  completed,
                                  "No completed appointments.",
                                ),
                                _buildHistoryList(
                                  cancelled,
                                  "No cancelled appointments.",
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<QueryDocumentSnapshot> docs, String emptyMsg) {
    if (docs.isEmpty) {
      return Center(
        child: Text(emptyMsg, style: const TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final booking = docs[index].data() as Map<String, dynamic>;

        String dateStr = booking['date'] ?? '';
        try {
          final dt = DateTime.parse(dateStr);
          dateStr = "${dt.day}/${dt.month}/${dt.year}";
        } catch (_) {}

        String status = booking['status'] ?? 'upcoming';

        return Card(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: figmaBrown1.withOpacity(0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      booking['service'] ?? 'Service',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: figmaBrown1,
                      ),
                    ),
                    Chip(
                      label: Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                      backgroundColor: status == 'completed'
                          ? Colors.green
                          : (status == 'cancelled' ? Colors.red : Colors.blue),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.cut, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      "With: ${booking['stylist'] ?? 'Unknown'}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Date: $dateStr",
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      "Time: ${booking['time']}",
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
