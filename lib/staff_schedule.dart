import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color figmaBrown1 = Color(0xFF6D4C41);
const Color figmaNudeBG = Color(0xFFFDF6F0);

class StaffSchedulePage extends StatefulWidget {
  final String staffName;
  const StaffSchedulePage({super.key, required this.staffName});

  @override
  State<StaffSchedulePage> createState() => _StaffSchedulePageState();
}

class _StaffSchedulePageState extends State<StaffSchedulePage> {
  final List<String> daysOfWeek = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];

  // Helper to format TimeOfDay to String (e.g., "09:30 AM")
  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return "${dt.hour > 12 ? dt.hour - 12 : dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}";
  }

  // --- LOGIC: SHOW EDIT DIALOG ---
  void _editDaySchedule(
    BuildContext context,
    String docId,
    String dayKey,
    Map<String, dynamic> currentData,
  ) {
    // Defaults if data missing
    bool isWorking = currentData['isWorking'] ?? true;

    // Parse start time (default 9:00 AM)
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    if (currentData['start'] != null) {
      final parts = (currentData['start'] as String).split(":");
      startTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    // Parse end time (default 6:00 PM)
    TimeOfDay endTime = const TimeOfDay(hour: 18, minute: 0);
    if (currentData['end'] != null) {
      final parts = (currentData['end'] as String).split(":");
      endTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text("Edit $dayKey"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Working Toggle
                SwitchListTile(
                  title: const Text("Working this day?"),
                  value: isWorking,
                  activeColor: Colors.green,
                  onChanged: (val) => setStateDialog(() => isWorking = val),
                ),
                const SizedBox(height: 10),

                // 2. Time Pickers (Only if working)
                if (isWorking) ...[
                  ListTile(
                    title: const Text("Start Time"),
                    trailing: Text(
                      _formatTime(startTime),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (picked != null)
                        setStateDialog(() => startTime = picked);
                    },
                  ),
                  ListTile(
                    title: const Text("End Time"),
                    trailing: Text(
                      _formatTime(endTime),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: endTime,
                      );
                      if (picked != null)
                        setStateDialog(() => endTime = picked);
                    },
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: figmaBrown1,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  // Save to Firestore
                  // We save time as "HH:mm" (24h format) for easy sorting later
                  final startStr = "${startTime.hour}:${startTime.minute}";
                  final endStr = "${endTime.hour}:${endTime.minute}";

                  await FirebaseFirestore.instance
                      .collection('stylists')
                      .doc(docId)
                      .set(
                        {
                          'weeklySchedule': {
                            dayKey: {
                              'isWorking': isWorking,
                              'start': startStr,
                              'end': endStr,
                            },
                          },
                        },
                        SetOptions(merge: true),
                      ); // Merge ensures we don't delete other days

                  if (mounted) Navigator.pop(ctx);
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: figmaNudeBG,
      appBar: AppBar(
        title: const Text("Weekly Schedule"),
        backgroundColor: figmaBrown1,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stylists')
            .where('name', isEqualTo: widget.staffName)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Profile not found."));
          }

          final doc = snapshot.data!.docs.first;
          final stylistData = doc.data() as Map<String, dynamic>;

          // Get the schedule map (or empty if not set yet)
          final Map<String, dynamic> schedule =
              stylistData['weeklySchedule'] ?? {};

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: daysOfWeek.length,
            separatorBuilder: (c, i) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final dayName = daysOfWeek[index];
              final dayData = schedule[dayName] as Map<String, dynamic>? ?? {};

              // Defaults
              final bool isWorking = dayData['isWorking'] ?? true;
              final String start =
                  dayData['start'] ?? "9:30"; // default db format
              final String end = dayData['end'] ?? "18:30";

              // Pretty Display Strings
              String timeDisplay = "Day Off";
              if (isWorking) {
                // Quick hack to format DB string "9:0" -> "9:00 AM" for display
                try {
                  final s = TimeOfDay(
                    hour: int.parse(start.split(':')[0]),
                    minute: int.parse(start.split(':')[1]),
                  );
                  final e = TimeOfDay(
                    hour: int.parse(end.split(':')[0]),
                    minute: int.parse(end.split(':')[1]),
                  );
                  timeDisplay = "${_formatTime(s)} - ${_formatTime(e)}";
                } catch (_) {
                  timeDisplay = "9:30 AM - 6:30 PM";
                }
              }

              return Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: figmaBrown1.withOpacity(0.2)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 5,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: isWorking ? figmaBrown1 : Colors.grey[300],
                    child: Text(
                      dayName.substring(0, 1), // "M", "T", "W"
                      style: TextStyle(
                        color: isWorking ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    dayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    timeDisplay,
                    style: TextStyle(
                      color: isWorking ? Colors.black87 : Colors.red,
                      fontWeight: isWorking ? FontWeight.w500 : FontWeight.bold,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.grey),
                    onPressed: () =>
                        _editDaySchedule(context, doc.id, dayName, dayData),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
