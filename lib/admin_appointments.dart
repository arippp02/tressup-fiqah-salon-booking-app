import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_sender.dart';
import 'database.dart';

const Color figmaBrown1 = Color(0xFF6D4C41);
const Color figmaNudeBG = Color(0xFFFDF6F0);

class AdminAppointmentsPage extends StatefulWidget {
  const AdminAppointmentsPage({super.key});

  @override
  State<AdminAppointmentsPage> createState() => _AdminAppointmentsPageState();
}

class _AdminAppointmentsPageState extends State<AdminAppointmentsPage> {
  // Helper to format date
  String _formatDate(DateTime d) {
    return "${d.day}/${d.month}/${d.year}";
  }

  // --- 1. SMART DIALOG: Admin Inputs Price -> System Calculates ---
  void _showCompletionDialog(
    BuildContext context,
    String docId,
    String userId,
    String serviceName,
    int pointsRedeemed,
  ) {
    final TextEditingController billController = TextEditingController();

    // Logic: 5% discount per 100 points, max 20%
    double discountPercent = (pointsRedeemed / 100).floor() * 0.05;
    if (discountPercent > 0.20) discountPercent = 0.20;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double inputBill = double.tryParse(billController.text) ?? 0.0;
            double discountAmount = inputBill * discountPercent;
            // Cap discount amount at RM 50
            if (discountAmount > 50.0) discountAmount = 50.0;
            double finalAmount = inputBill - discountAmount;

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Finalize Payment",
                style: TextStyle(
                  color: figmaBrown1,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Service: $serviceName",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: billController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: "Actual Price",
                      prefixText: "RM ",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  _billingRow("Subtotal", "RM ${inputBill.toStringAsFixed(2)}"),
                  if (pointsRedeemed > 0)
                    _billingRow(
                      "Discount (${(discountPercent * 100).toInt()}%)",
                      "- RM ${discountAmount.toStringAsFixed(2)}",
                      color: Colors.red,
                    ),
                  const Divider(),
                  _billingRow(
                    "TOTAL PAYABLE",
                    "RM ${finalAmount.toStringAsFixed(2)}",
                    isBold: true,
                    color: figmaBrown1,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: inputBill <= 0
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _updateStatus(
                            context,
                            docId,
                            'completed',
                            userId: userId,
                            serviceName: serviceName,
                            finalPriceString: finalAmount.toStringAsFixed(2),
                          );
                        },
                  child: const Text("Complete"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _billingRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: color)),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 18 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. STATUS UPDATE & NOTIFICATION LOGIC ---
  Future<void> _updateStatus(
    BuildContext context,
    String docId,
    String newStatus, {
    String? userId,
    String? serviceName,
    String? finalPriceString,
  }) async {
    try {
      String title = "";
      String body = "";

      if (newStatus == 'completed' && userId != null) {
        // 1. Update Booking
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(docId)
            .update({'status': newStatus, 'price': "RM $finalPriceString"});

        // 2. Grant Points
        double price = double.tryParse(finalPriceString ?? "0") ?? 0.0;
        int earned = await DatabaseService(
          uid: userId,
        ).earnPoints(userId, price);

        // 3. Prepare Notification
        title = "Service Completed! ✨";
        body = "You earned $earned points! Total paid: RM $finalPriceString.";
      } else {
        // Simple Status Update (Cancel/Reject)
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(docId)
            .update({'status': newStatus});

        if (newStatus == 'cancelled') {
          title = "Appointment Cancelled ❌";
          body = "Your booking for '$serviceName' has been cancelled by Admin.";
        }
      }

      // 4. Send Notification if User ID exists
      if (userId != null && title.isNotEmpty) {
        await NotificationSender.notifySpecificUser(
          userId: userId,
          title: title,
          body: body,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Status updated to $newStatus."),
            backgroundColor: newStatus == 'completed'
                ? Colors.green
                : Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  // --- RESCHEDULE LOGIC ---
  Future<void> _handleReschedule(
    String docId,
    DateTime currentBookingDate,
    String currentStylist,
  ) async {
    // 1. Pick Date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: currentBookingDate.isBefore(DateTime.now())
          ? DateTime.now()
          : currentBookingDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: figmaBrown1,
            onPrimary: Colors.white,
            onSurface: figmaBrown1,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedDate == null) return;

    // 2. Pick Time
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: figmaBrown1,
            onPrimary: Colors.white,
            onSurface: figmaBrown1,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedTime == null) return;

    final dt = DateTime(2022, 1, 1, pickedTime.hour, pickedTime.minute);
    final String timeStr =
        "${dt.hour > 12 ? dt.hour - 12 : dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}";

    final String newDateStr = pickedDate.toIso8601String().split('T').first;

    // 3. Confirm
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Reschedule"),
        content: Text("Move booking to $newDateStr at $timeStr?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: figmaBrown1),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(docId)
          .update({'date': newDateStr, 'time': timeStr, 'status': 'upcoming'});
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Booking rescheduled.")));
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: figmaNudeBG,
        appBar: AppBar(
          title: const Text(
            "All Bookings",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: figmaBrown1,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),

            // --- PILL SHAPED TAB BAR ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
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
            ),
            const SizedBox(height: 15),

            // --- TAB CONTENT ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('appointments')
                    .orderBy('date', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No bookings found."));
                  }

                  final allDocs = snapshot.data!.docs;

                  final upcoming = allDocs.where((d) {
                    final s =
                        (d.data() as Map<String, dynamic>)['status'] ?? '';
                    return s == 'upcoming' || s == 'confirmed';
                  }).toList();

                  final completed = allDocs.where((d) {
                    final s =
                        (d.data() as Map<String, dynamic>)['status'] ?? '';
                    return s == 'completed';
                  }).toList();

                  final cancelled = allDocs.where((d) {
                    final s =
                        (d.data() as Map<String, dynamic>)['status'] ?? '';
                    return s == 'cancelled';
                  }).toList();

                  return TabBarView(
                    children: [
                      _buildAppointmentList(
                        upcoming,
                        emptyMsg: "No upcoming bookings.",
                      ),
                      _buildAppointmentList(
                        completed,
                        emptyMsg: "No completed bookings.",
                      ),
                      _buildAppointmentList(
                        cancelled,
                        emptyMsg: "No cancelled bookings.",
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentList(
    List<QueryDocumentSnapshot> docs, {
    required String emptyMsg,
  }) {
    if (docs.isEmpty) {
      return Center(
        child: Text(emptyMsg, style: const TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final docId = docs[index].id;

        DateTime date = DateTime.now();
        try {
          date = DateTime.parse(data['date']);
        } catch (e) {
          /* ignore */
        }

        String status = data['status'] ?? 'upcoming';
        String service = data['service'] ?? 'Unknown Service';
        String stylist = data['stylist'] ?? 'Unknown';
        String time = data['time'] ?? '';
        String userId = data['userId'] ?? '';
        int pointsRedeemed = data['pointsRedeemed'] ?? 0;
        String? priceString = data['price']; // For completed ones

        return Card(
          color: Colors.white,
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      service,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: figmaBrown1,
                      ),
                    ),
                    Chip(
                      label: Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: _getStatusColor(status),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ✅ 2. Customer Name (Fetched via FutureBuilder)
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .get(),
                  builder: (context, userSnapshot) {
                    String customerName = "Loading...";
                    if (userSnapshot.connectionState == ConnectionState.done) {
                      if (userSnapshot.hasData && userSnapshot.data!.exists) {
                        final userData =
                            userSnapshot.data!.data() as Map<String, dynamic>?;
                        customerName = userData?['name'] ?? "Unknown Customer";
                      } else {
                        customerName = "Unknown Customer";
                      }
                    }
                    return Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.black87,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Customer: $customerName",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, // Highlighted
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 8),

                // 3. Info Rows
                Row(
                  children: [
                    const Icon(Icons.cut, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      "With: $stylist",
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Date: ${_formatDate(date)}",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      "Time: $time",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),

                // 4. Points Warning (if applicable)
                if (pointsRedeemed > 0 && status != 'completed')
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(8),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "⚠️ Customer using $pointsRedeemed points",
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),

                // 5. Completed Price (if applicable)
                if (status == 'completed' && priceString != null)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(8),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Paid: $priceString",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),

                const SizedBox(height: 12),
                const Divider(),

                // 6. Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Reschedule Action
                    if (status == 'upcoming')
                      TextButton.icon(
                        onPressed: () =>
                            _handleReschedule(docId, date, stylist),
                        icon: const Icon(
                          Icons.edit_calendar,
                          size: 18,
                          color: Colors.orange,
                        ),
                        label: const Text(
                          "Reschedule",
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),

                    // Status Actions
                    if (status == 'upcoming') ...[
                      TextButton(
                        onPressed: () => _updateStatus(
                          context,
                          docId,
                          'cancelled',
                          userId: userId,
                          serviceName: service,
                        ),
                        child: const Text(
                          "Reject",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () => _showCompletionDialog(
                          context,
                          docId,
                          userId,
                          service,
                          pointsRedeemed,
                        ),
                        child: const Text(
                          "Complete",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ] else ...[
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Icon(
                          Icons.check_circle_outline,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                      Text(
                        status == 'cancelled' ? "Cancelled" : "Completed",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
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
