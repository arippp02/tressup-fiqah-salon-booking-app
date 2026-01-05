import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database.dart';
import 'notification_sender.dart';

// Theme Colors
const Color figmaBrown1 = Color(0xFF6D4C41);
const Color figmaBrown2 = Color(0xFF8D6E63);
const Color figmaNudeBG = Color(0xFFFDF6F0);
const Color figmaWhite = Colors.white;
const Color figmaDisabled = Color(0xFFE0E0E0);

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage>
    with SingleTickerProviderStateMixin {
  // --- STATE VARIABLES ---
  int pageIndex = 0;
  bool isBooking = false;
  bool isLoadingSlots = false;

  // Selected Data
  String? selectedService;
  String? selectedServicePrice;
  String? selectedStylist;
  DateTime? selectedDate;
  String? selectedTime;

  // Points Redemption State
  int _userTotalPoints = 0;
  int _pointsToRedeem = 0;

  // Schedule Constraints
  List<String> _bookedSlots = [];
  String _currentStartShift = "09:00";
  String _currentEndShift = "18:00";
  bool _isDayOff = false;

  final List<String> categories = ["Hair", "Beauty", "Body", "Massage"];
  late TabController _tabController;

  final List<String> timeSlots = const [
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
    _tabController = TabController(length: categories.length, vsync: this);
    _fetchUserPoints();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- HELPERS ---
  void nextPage() => setState(() => pageIndex++);
  void prevPage() => setState(() => pageIndex--);

  String _getDayName(DateTime date) => [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ][date.weekday - 1];

  bool _isTimeWithinShift(String slot, String start, String end) {
    try {
      int toMins(String t, {bool isSlot = false}) {
        final parts = t.split(isSlot ? ' ' : ':');
        final timeParts = (isSlot ? parts[0] : t).split(':');
        int h = int.parse(timeParts[0]);
        int m = int.parse(timeParts[1]);
        if (isSlot && parts[1] == "PM" && h != 12) h += 12;
        if (isSlot && parts[1] == "AM" && h == 12) h = 0;
        return h * 60 + m;
      }

      int slotM = toMins(slot, isSlot: true);
      return slotM >= toMins(start) && slotM < toMins(end);
    } catch (_) {
      return true;
    }
  }

  // --- DATA FETCHING ---
  Future<void> _fetchUserPoints() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _userTotalPoints = (doc.data()?['points'] ?? 0) as int;
        });
      }
    }
  }

  Future<void> _checkStylistSchedule(DateTime date) async {
    if (selectedStylist == null) return;
    setState(() => isLoadingSlots = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('stylists')
          .where('name', isEqualTo: selectedStylist)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final schedule =
            snap.docs.first.data()['weeklySchedule'] as Map<String, dynamic>?;
        final dayData = schedule?[_getDayName(date)] as Map<String, dynamic>?;
        setState(() {
          selectedDate = date;
          _isDayOff = !(dayData?['isWorking'] ?? true);
          _currentStartShift = dayData?['start'] ?? "09:00";
          _currentEndShift = dayData?['end'] ?? "18:00";
        });
        if (!_isDayOff) await _fetchBookedSlots();
      }
    } catch (_) {}
    if (mounted) setState(() => isLoadingSlots = false);
  }

  Future<void> _fetchBookedSlots() async {
    if (selectedStylist == null || selectedDate == null) return;
    try {
      final targetDate = selectedDate!.toIso8601String().split('T').first;
      final snap = await FirebaseFirestore.instance
          .collection('appointments')
          .where('stylist', isEqualTo: selectedStylist)
          .get();
      final busy = snap.docs
          .where((doc) {
            final d = doc.data();
            if (d['status'] == 'cancelled') return false;
            return (d['date'].toString().split('T')[0] == targetDate);
          })
          .map((doc) => doc['time'] as String)
          .toList();
      if (mounted) {
        setState(() {
          _bookedSlots = busy;
          selectedTime = null;
        });
      }
    } catch (_) {}
  }

  // --- SUBMIT BOOKING ---
  Future<void> _submitBooking() async {
    setState(() => isBooking = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        String customerName = "A customer";
        if (userDoc.exists) {
          customerName =
              (userDoc.data() as Map<String, dynamic>)['name'] ?? "A customer";
        }

        if (_pointsToRedeem > 0) {
          await DatabaseService(
            uid: user.uid,
          ).usePoints(user.uid, _pointsToRedeem);
        }

        await DatabaseService(uid: user.uid).bookAppointment(
          selectedService!,
          selectedStylist!,
          selectedDate!,
          selectedTime!,
          price: "Pending",
          pointsRedeemed: _pointsToRedeem,
        );

        NotificationSender.notifyAllStaff(
          title: "New Booking Received! 📅",
          body:
              "New appointment: $selectedService for $customerName at $selectedTime.",
        );

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Booking Successful!")));
          setState(() {
            pageIndex = 0;
            selectedService = null;
            selectedServicePrice = null;
            selectedStylist = null;
            selectedDate = null;
            selectedTime = null;
            isBooking = false;
            _bookedSlots.clear();
            _pointsToRedeem = 0;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isBooking = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: figmaNudeBG,
      appBar: AppBar(
        backgroundColor: figmaBrown1,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Book Appointment",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: pageIndex > 0
            ? IconButton(
                onPressed: prevPage,
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              )
            : null,
      ),
      body: Column(
        children: [
          // ✅ FIXED: High Contrast Progress Bar
          LinearProgressIndicator(
            value: (pageIndex + 1) / 4,
            backgroundColor:
                Colors.grey[400], // Darker grey for clear visibility
            color: figmaBrown1,
            minHeight: 6,
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Expanded(child: _buildCurrentStep()),
                  if (pageIndex != 0 && pageIndex != 3) ...[
                    const SizedBox(height: 20),
                    _nextButton(
                      (pageIndex == 1 && selectedStylist != null) ||
                          (pageIndex == 2 &&
                              selectedDate != null &&
                              selectedTime != null),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (pageIndex) {
      case 0:
        return _buildServiceStep();
      case 1:
        return _buildStylistStep();
      case 2:
        return _buildDateTimeStep();
      case 3:
        return _buildConfirmationStep();
      default:
        return const SizedBox();
    }
  }

  // ---- STEP 1: SERVICE ----
  Widget _buildServiceStep() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('services').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: figmaBrown1),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No services available."));
        }

        final allServices = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Service",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: figmaBrown1,
              ),
            ),
            const SizedBox(height: 20),

            Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
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
                tabs: categories.map((c) => Tab(text: c)).toList(),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: categories.map((cat) {
                  final services = allServices
                      .where((d) => d['category'] == cat)
                      .toList();
                  if (services.isEmpty) {
                    return Center(
                      child: Text(
                        "No $cat services yet.",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: services.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final data = services[i].data() as Map<String, dynamic>;
                      final name = data['name'] ?? 'Unknown';
                      final price = data['price'] != null
                          ? "${data['price']}"
                          : '';
                      bool active = selectedService == name;

                      return GestureDetector(
                        onTap: () => setState(() {
                          selectedService = name;
                          selectedServicePrice = price;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: active ? figmaBrown1 : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: active
                                  ? figmaBrown1
                                  : Colors.grey.shade200,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: active
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: active
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (price.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? Colors.white.withOpacity(0.2)
                                        : figmaBrown1.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    price,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: active
                                          ? Colors.white
                                          : figmaBrown1,
                                    ),
                                  ),
                                ),
                              if (active) ...[
                                const SizedBox(width: 10),
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            _nextButton(selectedService != null),
          ],
        );
      },
    );
  }

  // ---- STEP 2: STYLIST ----
  Widget _buildStylistStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Choose Expert",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: figmaBrown1,
          ),
        ),
        const SizedBox(height: 15),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('stylists')
                .where('available', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(
                  child: CircularProgressIndicator(color: figmaBrown1),
                );

              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  String name = data['name'] ?? 'Unknown';
                  bool active = selectedStylist == name;

                  return GestureDetector(
                    onTap: () => setState(() => selectedStylist = name),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: active ? figmaBrown1 : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: active ? figmaBrown1 : Colors.grey.shade200,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: active
                                ? Colors.white24
                                : figmaBrown1.withOpacity(0.1),
                            child: Icon(
                              Icons.person,
                              color: active ? Colors.white : figmaBrown1,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: active ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                data['specialty'] ?? 'Stylist',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: active ? Colors.white70 : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (active)
                            const Icon(Icons.check_circle, color: Colors.white),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---- STEP 3: DATE & TIME ----
  Widget _buildDateTimeStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Date",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: figmaBrown1,
            ),
          ),
          const SizedBox(height: 10),

          // ✅ FIXED: FORCE CALENDAR THEME FOR VISIBILITY
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Theme(
              data: ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(
                  primary: figmaBrown1, // Brown Circle for selected day
                  onPrimary: Colors.white, // White text inside selected circle
                  surface: Colors.white, // Calendar background
                  onSurface: Colors.black, // Default text color
                ),
                // Ensure text inside buttons/days is visible
                textTheme: const TextTheme(
                  bodyLarge: TextStyle(color: Colors.black87),
                  bodyMedium: TextStyle(color: Colors.black87),
                ),
              ),
              child: CalendarDatePicker(
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
                onDateChanged: (d) => _checkStylistSchedule(d),
              ),
            ),
          ),

          const SizedBox(height: 25),
          if (selectedDate != null) ...[
            Text(
              _isDayOff ? "Unavailable" : "Available Slots",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _isDayOff ? Colors.red : figmaBrown1,
              ),
            ),
            const SizedBox(height: 15),
            if (isLoadingSlots)
              const Center(child: CircularProgressIndicator(color: figmaBrown1))
            else if (!_isDayOff)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: timeSlots.length,
                itemBuilder: (_, i) {
                  final t = timeSlots[i];
                  bool booked = _bookedSlots.contains(t);
                  bool outside = !_isTimeWithinShift(
                    t,
                    _currentStartShift,
                    _currentEndShift,
                  );
                  bool disabled = _isDayOff || booked || outside;
                  bool active = selectedTime == t;

                  return GestureDetector(
                    onTap: disabled
                        ? null
                        : () => setState(() => selectedTime = t),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: disabled
                            ? figmaDisabled
                            : (active ? figmaBrown1 : Colors.white),
                        borderRadius: BorderRadius.circular(
                          30,
                        ), // Pill/Chip shape
                        border: Border.all(
                          color: disabled
                              ? Colors.transparent
                              : figmaBrown1.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: disabled
                              ? Colors.grey
                              : (active ? Colors.white : figmaBrown1),
                          decoration: disabled
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  // ---- STEP 4: CONFIRMATION ----
  Widget _buildConfirmationStep() {
    return Center(
      child: isBooking
          ? const CircularProgressIndicator(color: figmaBrown1)
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Receipt Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 60,
                          color: figmaBrown1,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Review Booking",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: figmaBrown1,
                          ),
                        ),
                        const SizedBox(height: 30),

                        _confirmRow("Service", selectedService!),
                        _confirmRow(
                          "Est. Price",
                          selectedServicePrice ?? "Pending",
                        ),
                        _confirmRow("Stylist", selectedStylist!),
                        _confirmRow(
                          "Date",
                          selectedDate?.toLocal().toString().split(' ')[0] ??
                              '',
                        ),
                        _confirmRow("Time", selectedTime!),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(thickness: 1, color: Colors.grey),
                        ),

                        // Loyalty Dropdown
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Loyalty Points",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: figmaNudeBG,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: figmaBrown1.withOpacity(0.2),
                            ),
                          ),
                          child: DropdownButton<int>(
                            value: _pointsToRedeem,
                            isExpanded: true,
                            underline: const SizedBox(),
                            dropdownColor: Colors.white,
                            items: [0, 100, 200, 300, 400]
                                .where((p) => p <= _userTotalPoints || p == 0)
                                .map((int value) {
                                  String label = value == 0
                                      ? "No discount used"
                                      : "Redeem $value Pts (${(value / 100 * 5).toInt()}% OFF)";
                                  return DropdownMenuItem<int>(
                                    value: value,
                                    child: Text(
                                      label,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                })
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _pointsToRedeem = val!),
                          ),
                        ),

                        if (_pointsToRedeem > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.local_offer,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "Discount Applied: ${(_pointsToRedeem / 100 * 5).toInt()}%",
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: figmaBrown1,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 5,
                      shadowColor: figmaBrown1.withOpacity(0.4),
                    ),
                    onPressed: _submitBooking,
                    child: const Text(
                      "Confirm Appointment",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Payment will be collected at the salon.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 15)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _nextButton(bool enabled) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: figmaBrown1,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey[300],
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: enabled ? 3 : 0,
      ),
      onPressed: enabled ? nextPage : null,
      child: const Text(
        "Next Step",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
