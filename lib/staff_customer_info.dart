import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color figmaBrown1 = Color(0xFF6D4C41);
const Color figmaNudeBG = Color(0xFFFDF6F0);

class StaffCustomerInfoPage extends StatefulWidget {
  final String staffName; // Added to filter history
  const StaffCustomerInfoPage({super.key, required this.staffName});

  @override
  State<StaffCustomerInfoPage> createState() => _StaffCustomerInfoPageState();
}

class _StaffCustomerInfoPageState extends State<StaffCustomerInfoPage> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: figmaNudeBG,
      appBar: AppBar(
        title: const Text("Customer Directory"),
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
                hintText: "Search customer name...",
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
                  return name.contains(_searchQuery);
                }).toList();

                if (customers.isEmpty) {
                  return const Center(child: Text("No matching customers."));
                }

                return ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final data =
                        customers[index].data() as Map<String, dynamic>;
                    final uid = customers[index].id;

                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: figmaBrown1.withOpacity(0.1),
                          child: const Icon(Icons.person, color: figmaBrown1),
                        ),
                        title: Text(
                          data['name'] ?? "Unknown",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(data['email'] ?? "No email"),
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

  // --- DETAIL VIEW: PROFILE, NOTES & HISTORY TABS ---
  void _showCustomerDetails(
    BuildContext context,
    String uid,
    Map<String, dynamic> userData,
  ) {
    final TextEditingController notesController = TextEditingController(
      text: userData['staffNotes'] ?? '',
    );

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
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
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

              // 2. STAFF NOTES SECTION
              const SizedBox(height: 10),
              const Text(
                "Internal Staff Notes",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: figmaBrown1,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                maxLines: 2,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Add notes (e.g., allergies, preferences)...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.save, color: figmaBrown1),
                    tooltip: "Save Note",
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .update({'staffNotes': notesController.text.trim()});

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Notes saved successfully!"),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 1),
                          ),
                        );
                        FocusScope.of(context).unfocus();
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(),

              // 3. APPOINTMENT HISTORY (TABBED)
              const Text(
                "Your Appointment History with Client",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: figmaBrown1,
                ),
              ),
              const SizedBox(height: 15),

              Expanded(
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      // --- BEAUTIFIED TAB BAR ---
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
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey[600],
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
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

                      // Tab Views
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('appointments')
                              .where('userId', isEqualTo: uid)
                              .where(
                                'stylist',
                                isEqualTo: widget.staffName,
                              ) // <--- FILTER BY STAFF NAME
                              .orderBy('date', descending: false)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Text(
                                    "Error: ${snapshot.error}. Check Indexes.",
                                  ),
                                ),
                              );
                            }

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Center(
                                child: Text("No booking history with you."),
                              );
                            }

                            final allDocs = snapshot.data!.docs;

                            // Filter locally for status
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

        // Parse Date
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
                // Header
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
                      backgroundColor: _getStatusColor(status),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Date
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

                // Time
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'upcoming':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
