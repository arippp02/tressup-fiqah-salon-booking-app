import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'loginpage.dart';
import 'editprofilepage.dart';
import 'settingpage.dart';

// Theme Colors
const Color figmaBrown1 = Color(0xFF6D4C41);
const Color figmaNudeBG = Color(0xFFFDF6F0);
const Color figmaCardWhite = Colors.white;

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  // Avatar Selection State
  String selectedAvatar = 'assets/default_avatar.png'; // Default
  String displayName = "User Name";
  String displayEmail = "Loading...";
  String staffNotes = "";

  // PRESET AVATARS LIST
  final List<String> avatarOptions = [
    'assets/hijab.png',
    'assets/nonhijab.png',
  ];

  // --- ACTIONS ---

  // 1. Show Avatar Picker
  void _changeProfilePicture() {
    showModalBottomSheet(
      context: context,
      backgroundColor: figmaNudeBG,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Choose Your Look",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: figmaBrown1,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  itemCount: avatarOptions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemBuilder: (context, index) {
                    final avatar = avatarOptions[index];
                    final isSelected = selectedAvatar == avatar;
                    return GestureDetector(
                      onTap: () {
                        // Update Local State & Firestore
                        _updateAvatar(avatar);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? figmaBrown1
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundImage: AssetImage(avatar),
                          backgroundColor: Colors.white,
                          onBackgroundImageError:
                              (_, __) {}, // Handle missing assets
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 2. Update Avatar in Firestore
  Future<void> _updateAvatar(String newAvatarPath) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'avatar': newAvatarPath},
      );
      // The StreamBuilder will automatically refresh the UI
    }
  }

  void _handleLogout() async {
    // 1. Show Confirmation Dialog
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: figmaNudeBG,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Logout",
          style: TextStyle(color: figmaBrown1, fontWeight: FontWeight.bold),
        ),
        content: const Text("Are you sure you want to logout of your account?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Cancel
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // Confirm
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    // 2. If user confirmed, proceed with sign out
    if (confirmLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please login")));
    }

    return Scaffold(
      backgroundColor: figmaNudeBG,
      appBar: AppBar(
        title: const Text(
          "My Account",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: figmaBrown1,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.data() != null) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            displayName = data['name'] ?? data['username'] ?? "User Name";
            displayEmail = user.email ?? "";
            staffNotes = data['staffNotes'] ?? "";

            // ✅ Load Avatar from Firestore (default fallback)
            selectedAvatar = data['avatar'] ?? 'assets/default_avatar.png';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              children: [
                // --- 1. PROFILE HEADER ---
                _buildProfileHeader(),

                const SizedBox(height: 25),

                // --- 2. STAFF NOTES (Conditional) ---
                if (staffNotes.isNotEmpty) ...[
                  _buildStaffNoteCard(),
                  const SizedBox(height: 20),
                ],

                // --- 3. MENU OPTIONS CARD ---
                Container(
                  decoration: _cardDecoration(),
                  child: Column(
                    children: [
                      _buildListTile(
                        icon: Icons.edit_outlined,
                        title: "Edit Profile",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfilePage(),
                          ),
                        ),
                      ),
                      _buildDivider(),
                      _buildListTile(
                        icon: Icons.settings_outlined,
                        title: "Settings",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --- 4. FAQ SECTION ---
                Container(
                  decoration: _cardDecoration(),
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: figmaBrown1.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.help_outline,
                          color: figmaBrown1,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        "FAQ & Help",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      childrenPadding: const EdgeInsets.only(bottom: 10),
                      children: _buildFaqChildren(),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- 5. LOGOUT BUTTON ---
                Container(
                  decoration: _cardDecoration(),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.logout,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      "Logout",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: _handleLogout,
                  ),
                ),

                const SizedBox(height: 40),
                const Text(
                  "Version 1.0.0",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.grey[300],
                // ✅ Display Selected Avatar Asset
                backgroundImage: AssetImage(selectedAvatar),
                onBackgroundImageError: (_, __) {},
              ),
            ),
            Positioned(
              bottom: 0,
              right: 4,
              child: InkWell(
                onTap: _changeProfilePicture, // Opens the Avatar Picker
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: figmaBrown1,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit, // Changed icon to Edit since we pick presets
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          displayName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: figmaBrown1,
          ),
        ),
        Text(
          displayEmail,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildStaffNoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1), // Light Amber
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_rounded, color: Colors.amber.shade800, size: 20),
              const SizedBox(width: 8),
              Text(
                "Message from Salon",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            staffNotes,
            style: TextStyle(fontSize: 14, color: Colors.brown.shade800),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: figmaBrown1.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: figmaBrown1, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 60, right: 20),
      child: Divider(color: Colors.grey.withOpacity(0.2), height: 1),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  List<Widget> _buildFaqChildren() {
    final headerStyle = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 14,
      color: Colors.grey[800],
    );
    final bodyStyle = const TextStyle(
      fontSize: 13,
      color: Colors.black87,
      height: 1.5,
    );

    return [
      _buildInnerExpansion(
        "How do I earn Loyalty Points?",
        Icons.stars,
        Colors.amber,
        "You earn points automatically after every completed appointment!\n\n• Rate: Earn 1 Point for every RM 10 spent.\n• Example: Spend RM 50 → Earn 5 Points.\n\nPoints are added once staff marks service as 'Completed'.",
        headerStyle,
        bodyStyle,
      ),
      _buildInnerExpansion(
        "How do I use my points?",
        Icons.discount,
        Colors.green,
        "Redeem points on the Booking Confirmation screen.\n\n• 100 Pts = 5% Off\n• 200 Pts = 10% Off\n• 300 Pts = 15% Off\n• 400 Pts = 20% Off Max (Capped at RM50)",
        headerStyle,
        bodyStyle,
      ),
      _buildInnerExpansion(
        "Can I cancel my appointment?",
        Icons.calendar_month,
        figmaBrown1,
        "Yes. Go to the 'History' tab, find your 'Upcoming' appointment, and click 'Cancel'.\n\nPlease cancel at least 2 hours in advance to allow others to book the slot.",
        headerStyle,
        bodyStyle,
      ),
      _buildInnerExpansion(
        "What if I am late?",
        Icons.access_time_filled,
        figmaBrown1,
        "We hold appointments for 15 minutes. If later, we may need to reschedule to avoid delaying other customers.",
        headerStyle,
        bodyStyle,
      ),
      _buildInnerExpansion(
        "How do I pay?",
        Icons.payment,
        figmaBrown1,
        "Payment is made manually at the salon counter after service. We accept Cash and QR Pay.",
        headerStyle,
        bodyStyle,
      ),
    ];
  }

  Widget _buildInnerExpansion(
    String title,
    IconData icon,
    Color iconColor,
    String content,
    TextStyle headerStyle,
    TextStyle bodyStyle,
  ) {
    return ExpansionTile(
      leading: Icon(icon, color: iconColor, size: 20),
      title: Text(title, style: headerStyle),
      shape: const Border(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(content, style: bodyStyle),
          ),
        ),
      ],
    );
  }
}
