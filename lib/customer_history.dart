import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_sender.dart';

// Theme Colors
const Color figmaBrown1 = Color(0xFF6D4C41);
const Color figmaNudeBG = Color(0xFFFDF6F0);
const Color figmaWhite = Colors.white;
const Color figmaErrorRed = Color(0xFFFFCDD2);
const Color figmaErrorText = Color(0xFFC62828);
const Color figmaDisabledGrey = Color(0xFFEEEEEE);
final Color figmaAvailableGreen = Colors.green.withOpacity(0.2);
const Color figmaAvailableText = Color(0xFF2E7D32);

class CustomerHistoryPage extends StatefulWidget {
  const CustomerHistoryPage({super.key});

  @override
  State<CustomerHistoryPage> createState() => _CustomerHistoryPageState();
}

class _CustomerHistoryPageState extends State<CustomerHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> _bookedSlots = [];
  bool isLoadingSlots = false;

  final List<String> timeSlots = [
    "09:30 AM",
    "10:30 AM",
    "11:30 AM",
    "12:30 PM",
    "01:30 PM",
    "02:30 PM",
    "03:30 PM",
    "04:30 PM",
    "05:30 PM",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  String _getDayName(DateTime date) => [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ][date.weekday - 1];

  bool _isTimeWithinShift(String slot, String startShift, String endShift) {
    try {
      final parts = slot.split(' ');
      final timeParts = parts[0].split(':');
      int h = int.parse(timeParts[0]);
      int m = int.parse(timeParts[1]);
      if (parts[1] == "PM" && h != 12) h += 12;
      if (parts[1] == "AM" && h == 12) h = 0;
      int slotMinutes = h * 60 + m;

      final startParts = startShift.split(':');
      int startMinutes =
          int.parse(startParts[0]) * 60 + int.parse(startParts[1]);

      final endParts = endShift.split(':');
      int endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

      return slotMinutes >= startMinutes && slotMinutes < endMinutes;
    } catch (e) {
      return true;
    }
  }

  Future<void> _fetchBookedSlots(String stylistName, DateTime date) async {
    setState(() {
      isLoadingSlots = true;
      _bookedSlots.clear();
    });

    try {
      final String targetDateStr = date.toIso8601String().split('T').first;
      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('stylist', isEqualTo: stylistName)
          .get();

      final List<String> busyTimes = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'cancelled') continue;

        String dbDateString = data['date'].toString();
        String formattedDbDate = "";
        try {
          formattedDbDate = DateTime.parse(
            dbDateString,
          ).toIso8601String().split('T').first;
        } catch (_) {
          continue;
        }

        if (formattedDbDate == targetDateStr)
          busyTimes.add(data['time'] as String);
      }

      if (mounted)
        setState(() {
          _bookedSlots = busyTimes;
          isLoadingSlots = false;
        });
    } catch (e) {
      if (mounted) setState(() => isLoadingSlots = false);
    }
  }

  Future<List<String>> _fetchAllStylists() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stylists')
          .where('available', isEqualTo: true)
          .get();
      return snapshot.docs.map((doc) => doc['name'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  Future<String?> _showTimeSlotPicker(
    BuildContext context,
    String stylistName,
    String startShift,
    String endShift,
  ) async {
    return await showModalBottomSheet<String>(
      context: context,
      backgroundColor: figmaNudeBG,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            if (isLoadingSlots)
              return const Center(
                child: CircularProgressIndicator(color: figmaBrown1),
              );

            return Column(
              children: [
                const SizedBox(height: 15),
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Select Time for $stylistName",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: figmaBrown1,
                  ),
                ),
                const SizedBox(height: 10),
                // Legend
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.circle, size: 10, color: figmaErrorRed),
                    SizedBox(width: 4),
                    Text("Busy  ", style: TextStyle(fontSize: 12)),
                    Icon(Icons.circle, size: 10, color: Colors.grey),
                    SizedBox(width: 4),
                    Text("Closed  ", style: TextStyle(fontSize: 12)),
                    Icon(Icons.circle, size: 10, color: Colors.green),
                    SizedBox(width: 4),
                    Text("Open", style: TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: timeSlots.length,
                    itemBuilder: (context, index) {
                      final t = timeSlots[index];
                      bool isBooked = _bookedSlots.contains(t);
                      bool isOutsideShift = !_isTimeWithinShift(
                        t,
                        startShift,
                        endShift,
                      );
                      bool isUnavailable = isBooked || isOutsideShift;

                      return GestureDetector(
                        onTap: () {
                          if (isBooked) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text("$stylistName is busy at $t."),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } else if (isOutsideShift) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "$stylistName is not working at this time.",
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          } else {
                            Navigator.pop(ctx, t);
                          }
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isBooked
                                ? figmaErrorRed
                                : (isOutsideShift
                                      ? figmaDisabledGrey
                                      : figmaAvailableGreen),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isUnavailable
                                  ? Colors.transparent
                                  : Colors.green,
                            ),
                          ),
                          child: Text(
                            t,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isBooked
                                  ? figmaErrorText
                                  : (isOutsideShift
                                        ? Colors.grey
                                        : figmaAvailableText),
                              decoration: isUnavailable
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _getStylistScheduleForDate(
    String stylistName,
    DateTime date,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stylists')
          .where('name', isEqualTo: stylistName)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      final data = snapshot.docs.first.data();
      final schedule = data['weeklySchedule'] as Map<String, dynamic>?;
      if (schedule == null) return null;
      String dayName = _getDayName(date);
      return schedule[dayName] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  Future<void> _handleReschedule(
    String docId,
    DateTime currentDate,
    String stylistName,
  ) async {
    final appointmentDoc = await FirebaseFirestore.instance
        .collection('appointments')
        .doc(docId)
        .get();
    final appointmentData = appointmentDoc.data();
    final String serviceName = appointmentData?['service'] ?? 'Appointment';

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: currentDate.isBefore(DateTime.now())
          ? DateTime.now()
          : currentDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
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

    final List<String> allStylists = await _fetchAllStylists();
    if (allStylists.isEmpty) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No stylists found.")));
      return;
    }

    String? selectedStylist;
    if (mounted) {
      selectedStylist = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text("Select Stylist"),
          children: allStylists
              .map(
                (name) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, name),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(name, style: const TextStyle(fontSize: 16)),
                  ),
                ),
              )
              .toList(),
        ),
      );
    }

    if (selectedStylist == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) =>
          const Center(child: CircularProgressIndicator(color: figmaBrown1)),
    );

    final daySchedule = await _getStylistScheduleForDate(
      selectedStylist,
      pickedDate,
    );
    await _fetchBookedSlots(selectedStylist, pickedDate);

    if (!mounted) return;
    Navigator.pop(context);

    bool isWorking = true;
    String startShift = "09:00";
    String endShift = "18:00";

    if (daySchedule != null) {
      isWorking = daySchedule['isWorking'] ?? true;
      startShift = daySchedule['start'] ?? "09:00";
      endShift = daySchedule['end'] ?? "18:00";
    }

    if (!isWorking) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Stylist Unavailable"),
          content: Text(
            "$selectedStylist is not working on ${_getDayName(pickedDate)}s.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    final String? pickedTimeStr = await _showTimeSlotPicker(
      context,
      selectedStylist,
      startShift,
      endShift,
    );
    if (pickedTimeStr == null) return;

    final String newDateStr = pickedDate.toIso8601String().split('T').first;
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Reschedule"),
        content: Text(
          "Move appointment to $newDateStr at $pickedTimeStr\nWith $selectedStylist?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: figmaBrown1),
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final user = FirebaseAuth.instance.currentUser;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      String customerName = userDoc.exists ? userDoc['name'] : "A customer";

      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(docId)
          .update({
            'date': newDateStr,
            'time': pickedTimeStr,
            'stylist': selectedStylist,
            'status': 'upcoming',
          });

      NotificationSender.notifyAllStaff(
        title: "Booking Rescheduled 🔄",
        body:
            "$customerName moved their $serviceName to $newDateStr at $pickedTimeStr with $selectedStylist.",
      );

      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Appointment rescheduled successfully."),
          ),
        );
    }
  }

  Future<void> _handleCancel(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cancel Appointment"),
        content: const Text("Are you sure you want to cancel this booking?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Yes, Cancel",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final user = FirebaseAuth.instance.currentUser;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      String customerName = userDoc.exists ? userDoc['name'] : "A customer";

      final appointmentDoc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(docId)
          .get();
      final appointmentData = appointmentDoc.data();
      final String serviceName = appointmentData?['service'] ?? 'appointment';
      final String dateStr = appointmentData?['date'] ?? '';
      final String timeStr = appointmentData?['time'] ?? '';

      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(docId)
          .update({'status': 'cancelled'});

      NotificationSender.notifyAllStaff(
        title: "Booking Cancelled ❌",
        body:
            "$customerName cancelled their $serviceName on $dateStr at $timeStr.",
      );

      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Appointment cancelled successfully.")),
        );
    }
  }

  void _showReviewDialog(
    BuildContext context,
    String appointmentId,
    String stylistName,
  ) {
    final commentController = TextEditingController();
    double rating = 5.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("Rate $stylistName"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("How was your experience?"),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 30,
                      ),
                      onPressed: () =>
                          setDialogState(() => rating = index + 1.0),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    labelText: "Write a review (optional)",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;
                  await FirebaseFirestore.instance.collection('reviews').add({
                    'appointmentId': appointmentId,
                    'stylistName': stylistName,
                    'userId': user.uid,
                    'rating': rating,
                    'comment': commentController.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  await FirebaseFirestore.instance
                      .collection('appointments')
                      .doc(appointmentId)
                      .update({'hasReview': true});
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Thank you for your feedback!"),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: figmaBrown1,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Submit"),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(String dateIso) {
    try {
      final date = DateTime.parse(dateIso);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateIso;
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text("Please login")));

    return Scaffold(
      backgroundColor: figmaNudeBG,
      appBar: AppBar(
        title: const Text(
          "My Appointments",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true, // ✅ CENTERED TITLE
        backgroundColor: figmaBrown1,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // --- PILL TABS ---
          Container(
            height: 45,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: figmaBrown1,
                boxShadow: [
                  BoxShadow(
                    color: figmaBrown1.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('date', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(
                    child: CircularProgressIndicator(color: figmaBrown1),
                  );
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return const Center(
                    child: Text(
                      "No bookings found.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );

                final allDocs = snapshot.data!.docs;
                final upcoming = allDocs.where((d) {
                  final s =
                      (d.data() as Map<String, dynamic>)['status'] ??
                      'upcoming';
                  return s == 'upcoming' || s == 'confirmed';
                }).toList();
                final completed = allDocs
                    .where(
                      (d) =>
                          (d.data() as Map<String, dynamic>)['status'] ==
                          'completed',
                    )
                    .toList();
                final cancelled = allDocs
                    .where(
                      (d) =>
                          (d.data() as Map<String, dynamic>)['status'] ==
                          'cancelled',
                    )
                    .toList();

                return TabBarView(
                  controller: _tabController,
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
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(20),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        String status = data['status'] ?? 'upcoming';
        String service = data['service'] ?? 'Unknown Service';
        String stylist = data['stylist'] ?? 'Unknown';
        String time = data['time'] ?? '';
        String dateStr = data['date'] ?? '';
        bool hasReview = data['hasReview'] ?? false;

        DateTime parsedDate = DateTime.now();
        try {
          parsedDate = DateTime.parse(dateStr);
        } catch (_) {}

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      service,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: figmaBrown1,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Stylist: $stylist",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${_formatDate(dateStr)} at $time",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),

              if (status == 'upcoming' ||
                  (status == 'completed' && !hasReview)) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Colors.grey),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (status == 'upcoming') ...[
                      TextButton(
                        onPressed: () =>
                            _handleReschedule(doc.id, parsedDate, stylist),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                        child: const Text("Reschedule"),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () => _handleCancel(doc.id),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text("Cancel"),
                      ),
                    ],
                    if (status == 'completed' && !hasReview)
                      OutlinedButton.icon(
                        onPressed: () =>
                            _showReviewDialog(context, doc.id, stylist),
                        icon: const Icon(Icons.star, size: 16),
                        label: const Text("Rate Service"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber[800],
                          side: BorderSide(color: Colors.amber.shade800),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
