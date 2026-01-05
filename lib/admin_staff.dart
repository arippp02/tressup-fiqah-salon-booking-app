import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

const Color figmaBrown1 = Color(0xFF6D4C41);
const Color figmaNudeBG = Color(0xFFFDF6F0);

class AdminStaffPage extends StatelessWidget {
  const AdminStaffPage({super.key});

  // LOGIC: CREATE ACCOUNT WITHOUT LOGGING OUT ADMIN
  Future<void> _createStaffAccount(
    String name,
    String email,
    String password,
    String specialty,
  ) async {
    FirebaseApp? tempApp;
    try {
      tempApp = await Firebase.initializeApp(
        name: 'temporaryRegister',
        options: Firebase.app().options,
      );

      UserCredential userCredential = await FirebaseAuth.instanceFor(
        app: tempApp,
      ).createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      // 3. Create the 'users' doc (For Login Role)
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'role': 'staff',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Create the 'stylists' doc (For Booking Page)
      await FirebaseFirestore.instance.collection('stylists').doc(uid).set({
        'name': name,
        'specialty': specialty,
        'available': true,
        'email': email,
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await tempApp.delete();
    } catch (e) {
      await tempApp?.delete();
      throw e;
    }
  }

  void _showStaffDialog(
    BuildContext context, {
    String? docId,
    Map<String, dynamic>? data,
  }) {
    final nameController = TextEditingController(text: data?['name'] ?? '');
    final specialtyController = TextEditingController(
      text: data?['specialty'] ?? '',
    );
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    bool isEditing = docId != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(isEditing ? "Edit Stylist" : "Add New Staff"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Full Name"),
              ),
              TextField(
                controller: specialtyController,
                decoration: const InputDecoration(labelText: "Specialty"),
              ),
              if (!isEditing) ...[
                const SizedBox(height: 15),
                const Text(
                  "Login Credentials",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Staff Email"),
                ),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: figmaBrown1),
            onPressed: () async {
              try {
                if (isEditing) {
                  await FirebaseFirestore.instance
                      .collection('stylists')
                      .doc(docId)
                      .update({
                        'name': nameController.text.trim(),
                        'specialty': specialtyController.text.trim(),
                      });

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(docId)
                      .update({'name': nameController.text.trim()});
                } else {
                  await _createStaffAccount(
                    nameController.text.trim(),
                    emailController.text.trim(),
                    passwordController.text.trim(),
                    specialtyController.text.trim(),
                  );
                }
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("Success!")));
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✅ UPDATED: Added Confirmation Dialog before deletion
  Future<void> _deleteStaff(
    BuildContext context,
    String uid,
    String name,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Staff Member?"),
        content: Text(
          "Are you sure you want to remove $name? This will delete their profile and login account.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('stylists')
            .doc(uid)
            .delete();
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$name removed successfully.")),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: figmaNudeBG,
      appBar: AppBar(
        title: const Text("Manage Staff"),
        backgroundColor: figmaBrown1,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('stylists').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No staff members added yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final isAvailable = data['available'] ?? true;
              final uid = docs[index].id;
              final name = data['name'] ?? "Unknown";

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isAvailable
                        ? Colors.green[100]
                        : Colors.grey[300],
                    child: Icon(
                      Icons.person,
                      color: isAvailable ? Colors.green : Colors.grey,
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(data['specialty'] ?? "Stylist"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.calendar_month,
                          color: Colors.orange,
                        ),
                        tooltip: "Manage Schedule",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminStaffSchedulePage(
                                staffId: uid,
                                staffName: name,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _showStaffDialog(context, docId: uid, data: data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteStaff(
                          context,
                          uid,
                          name,
                        ), // ✅ Pass context and name
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: figmaBrown1,
        label: const Text(
          "Add New Staff",
          style: TextStyle(color: Colors.white),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showStaffDialog(context),
      ),
    );
  }
}

// ==========================================
// NEW CLASS: ADMIN MANAGE SCHEDULE PAGE
// ==========================================
class AdminStaffSchedulePage extends StatefulWidget {
  final String staffId;
  final String staffName;

  const AdminStaffSchedulePage({
    super.key,
    required this.staffId,
    required this.staffName,
  });

  @override
  State<AdminStaffSchedulePage> createState() => _AdminStaffSchedulePageState();
}

class _AdminStaffSchedulePageState extends State<AdminStaffSchedulePage> {
  final List<String> daysOfWeek = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return "${dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour)}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}";
  }

  void _editDaySchedule(
    BuildContext context,
    String dayKey,
    Map<String, dynamic> currentData,
  ) {
    bool isWorking = currentData['isWorking'] ?? true;
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 18, minute: 0);

    if (currentData['start'] != null) {
      final parts = (currentData['start'] as String).split(":");
      startTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
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
            title: Text("Edit $dayKey for ${widget.staffName}"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text("Working this day?"),
                  value: isWorking,
                  activeColor: Colors.green,
                  onChanged: (val) => setStateDialog(() => isWorking = val),
                ),
                if (isWorking) ...[
                  ListTile(
                    title: const Text("Start Time"),
                    trailing: Text(
                      _formatTime(startTime),
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
                style: ElevatedButton.styleFrom(backgroundColor: figmaBrown1),
                onPressed: () async {
                  final startStr = "${startTime.hour}:${startTime.minute}";
                  final endStr = "${endTime.hour}:${endTime.minute}";

                  await FirebaseFirestore.instance
                      .collection('stylists')
                      .doc(widget.staffId)
                      .set({
                        'weeklySchedule': {
                          dayKey: {
                            'isWorking': isWorking,
                            'start': startStr,
                            'end': endStr,
                          },
                        },
                      }, SetOptions(merge: true));

                  if (mounted) Navigator.pop(ctx);
                },
                child: const Text(
                  "Save",
                  style: TextStyle(color: Colors.white),
                ),
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
        title: Text("Schedule: ${widget.staffName}"),
        backgroundColor: figmaBrown1,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stylists')
            .doc(widget.staffId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists)
            return const Center(child: CircularProgressIndicator());

          final stylistData = snapshot.data!.data() as Map<String, dynamic>;
          final Map<String, dynamic> schedule =
              stylistData['weeklySchedule'] ?? {};

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: daysOfWeek.length,
            separatorBuilder: (c, i) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final dayName = daysOfWeek[index];
              final dayData = schedule[dayName] as Map<String, dynamic>? ?? {};
              final bool isWorking = dayData['isWorking'] ?? true;

              String timeDisplay = "9:00 AM - 6:00 PM";
              if (isWorking && dayData['start'] != null) {
                try {
                  final s = dayData['start'].split(':');
                  final e = dayData['end'].split(':');
                  final st = TimeOfDay(
                    hour: int.parse(s[0]),
                    minute: int.parse(s[1]),
                  );
                  final et = TimeOfDay(
                    hour: int.parse(e[0]),
                    minute: int.parse(e[1]),
                  );
                  timeDisplay = "${_formatTime(st)} - ${_formatTime(et)}";
                } catch (_) {}
              }

              return Card(
                color: Colors.white,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isWorking ? figmaBrown1 : Colors.grey[300],
                    child: Text(
                      dayName[0],
                      style: TextStyle(
                        color: isWorking ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ),
                  title: Text(
                    dayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    isWorking ? timeDisplay : "Day Off",
                    style: TextStyle(
                      color: isWorking ? Colors.black87 : Colors.red,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () =>
                        _editDaySchedule(context, dayName, dayData),
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
