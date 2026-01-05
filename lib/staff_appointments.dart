import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_sender.dart';
import 'database.dart';

const Color figmaBrown1 = Color(0xFF6D4C41);
const Color figmaNudeBG = Color(0xFFFDF6F0);

class StaffAppointmentsPage extends StatelessWidget {
  final String staffName;
  const StaffAppointmentsPage({super.key, required this.staffName});

  // --- 1. SMART DIALOG: Staff Inputs Price -> System Calculates ---
  void _showCompletionDialog(
    BuildContext context,
    String docId,
    String userId,
    String serviceName,
    int pointsRedeemed,
  ) {
    final TextEditingController billController = TextEditingController();

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
                            userId,
                            serviceName,
                            finalAmount.toStringAsFixed(2),
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

  Future<void> _updateStatus(
    BuildContext context,
    String docId,
    String status,
    String userId,
    String serviceName,
    String finalPriceString,
  ) async {
    try {
      String title = "";
      String body = "";

      if (status == 'completed') {
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(docId)
            .update({'status': status, 'price': "RM $finalPriceString"});

        double price = double.tryParse(finalPriceString) ?? 0.0;
        int earned = await DatabaseService(
          uid: userId,
        ).earnPoints(userId, price);

        title = "Service Completed! ✨";
        body = "You earned $earned points! Total paid: RM $finalPriceString.";
      } else {
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(docId)
            .update({'status': status});
        title = "Appointment Cancelled ❌";
        body = "Your booking for '$serviceName' has been cancelled.";
      }

      await NotificationSender.notifySpecificUser(
        userId: userId,
        title: title,
        body: body,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Status updated to $status."),
            backgroundColor: status == 'completed' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  String _formatDate(String dateIso) {
    try {
      final date = DateTime.parse(dateIso);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateIso;
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
            "My Appointments",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: figmaBrown1,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),
            _buildTabBar(),
            const SizedBox(height: 15),
            Expanded(child: _buildMainStream()),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
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
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: "Upcoming"),
            Tab(text: "Done"),
            Tab(text: "Cancelled"),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('stylist', isEqualTo: staffName)
          .orderBy('date', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final allDocs = snapshot.data!.docs;

        final upcoming = allDocs
            .where(
              (doc) =>
                  doc['status'] == 'upcoming' || doc['status'] == 'confirmed',
            )
            .toList();
        final completed = allDocs
            .where((doc) => doc['status'] == 'completed')
            .toList();
        final cancelled = allDocs
            .where((doc) => doc['status'] == 'cancelled')
            .toList();

        return TabBarView(
          children: [
            _buildAppointmentList(
              upcoming,
              emptyMsg: "No upcoming appointments.",
            ),
            _buildAppointmentList(
              completed,
              emptyMsg: "No completed appointments.",
            ),
            _buildAppointmentList(
              cancelled,
              emptyMsg: "No cancelled appointments.",
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppointmentList(
    List<QueryDocumentSnapshot> docs, {
    required String emptyMsg,
  }) {
    if (docs.isEmpty)
      return Center(
        child: Text(emptyMsg, style: const TextStyle(color: Colors.grey)),
      );

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final status = data['status'] ?? 'upcoming';
        final userId = data['userId'] ?? '';
        final serviceName = data['service'] ?? 'Service';
        final priceString = data['price']?.toString() ?? "Pending";
        final int pointsRedeemed = data['pointsRedeemed'] ?? 0;

        return Card(
          color: Colors.white, // ✅ White Card theme
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      serviceName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: figmaBrown1,
                      ),
                    ),
                    _statusChip(status),
                  ],
                ),
                const SizedBox(height: 10),

                // ✅ SAFE FUTUREBUILDER FOR CUSTOMER NAME
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .get(),
                  builder: (context, userSnapshot) {
                    String customerName = "Unknown Customer";
                    if (userSnapshot.connectionState == ConnectionState.done) {
                      if (userSnapshot.hasData && userSnapshot.data!.exists) {
                        final userData =
                            userSnapshot.data!.data() as Map<String, dynamic>?;
                        if (userData != null && userData.containsKey('name')) {
                          customerName = userData['name'];
                        }
                      }
                    } else {
                      return _iconRow(Icons.person, "Loading...", Colors.grey);
                    }
                    return _iconRow(
                      Icons.person,
                      "Customer: $customerName",
                      Colors.black87,
                    );
                  },
                ),

                const SizedBox(height: 8),
                _iconRow(
                  Icons.calendar_today,
                  "Date: ${_formatDate(data['date'])} | ${data['time']}",
                  Colors.grey[700]!,
                ),

                if (pointsRedeemed > 0 && status != 'completed')
                  _specialNote("⚠️ Customer using $pointsRedeemed points"),

                if (status == 'completed')
                  _specialNote("Paid: $priceString", isGreen: true),

                if (status == 'upcoming' || status == 'confirmed')
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _updateStatus(
                            context,
                            docs[index].id,
                            'cancelled',
                            userId,
                            serviceName,
                            "0",
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _showCompletionDialog(
                            context,
                            docs[index].id,
                            userId,
                            serviceName,
                            pointsRedeemed,
                          ),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text("Complete"),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusChip(String status) {
    Color color = status == 'completed'
        ? Colors.green
        : (status == 'cancelled' ? Colors.red : Colors.blue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _iconRow(IconData icon, String text, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
        ),
      ],
    );
  }

  Widget _specialNote(String text, {bool isGreen = false}) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(8),
      width: double.infinity,
      decoration: BoxDecoration(
        color: (isGreen ? Colors.green : Colors.orange).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isGreen ? Colors.green : Colors.orange[800],
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
