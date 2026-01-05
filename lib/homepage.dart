import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'servicepage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Theme Colors
const Color figmaBrown1 = Color(0xFF6D4C41);
const Color figmaBrown2 = Color(0xFF8D6E63);
const Color figmaNudeBG = Color(0xFFFDF6F0);
const Color figmaWhite = Colors.white;

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // SOCIAL LINKS
  final String whatsappLink = "https://wa.me/60108329147?text=Hi%20Fiqah!";
  final String facebookLink =
      'https://www.facebook.com/share/1BibezMdb1/?mibextid=wwXIfr';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: figmaNudeBG,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. HEADER SECTION ---
              _buildHeader(user),

              const SizedBox(height: 25),

              // --- 2. REWARDS CARD ---
              _buildRewardsCard(user),

              const SizedBox(height: 30),

              // --- 3. SERVICES SECTION ---
              const Text(
                "Our Services",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: figmaBrown1,
                ),
              ),
              const SizedBox(height: 15),
              _buildServicesGrid(context),

              const SizedBox(height: 30),

              // --- 4. CONNECT SECTION ---
              const Text(
                "Connect with us",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: figmaBrown1,
                ),
              ),
              const SizedBox(height: 15),
              _buildSocials(context),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeader(User? user) {
    // 1. Safety check: If user is null (logged out), show nothing or a placeholder
    if (user == null) {
      return const SizedBox(height: 60);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String name = "Guest";
        String avatarPath = 'assets/default_avatar.png'; // Default fallback

        // 2. Check if data exists
        if (snapshot.hasData &&
            snapshot.data!.exists &&
            snapshot.data!.data() != null) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['name'] ?? "User";

          // 3. Fetch Avatar Logic
          if (data['avatar'] != null && data['avatar'].toString().isNotEmpty) {
            avatarPath = data['avatar'];
          }
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome back,",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: figmaBrown1,
                  ),
                ),
              ],
            ),
            // ✅ AVATAR DISPLAY
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: figmaBrown1.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage(avatarPath),
                onBackgroundImageError: (_, __) {
                  // If asset is missing, it stays white/transparent
                  // This prevents the red "X" crash screen
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRewardsCard(User? user) {
    if (user == null) return const SizedBox();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        int points = 0;
        if (snapshot.hasData &&
            snapshot.data!.exists &&
            snapshot.data!.data() != null) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          points = data['points'] ?? 0;
        }

        // Logic
        double progress = (points / 400).clamp(0.0, 1.0);
        String nextGoalText = points >= 400
            ? "Max Reward Unlocked! (20% OFF)"
            : points >= 300
            ? "Next: 20% at 400 pts"
            : points >= 200
            ? "Next: 15% at 300 pts"
            : points >= 100
            ? "Next: 10% at 200 pts"
            : "Reach 100 pts for 5% OFF";

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [figmaBrown1, figmaBrown2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: figmaBrown1.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "LOYALTY POINTS",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.stars_rounded,
                    color: Colors.amber.shade300,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "$points",
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              const Text(
                "Total Points",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 25),

              // Progress Bar
              Stack(
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  nextGoalText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServicesGrid(BuildContext context) {
    // 2x2 Grid Layout for cleaner look
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4, // Wider rectangles
      children: [
        _serviceCard(Icons.content_cut, "Hair", context),
        _serviceCard(Icons.face_retouching_natural, "Beauty", context),
        _serviceCard(Icons.spa, "Body", context),
        _serviceCard(Icons.self_improvement, "Massage", context),
      ],
    );
  }

  Widget _serviceCard(IconData icon, String name, BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ServicePage(category: name)),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: figmaBrown1.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: figmaBrown1),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocials(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _socialButton(
            icon: FontAwesomeIcons.whatsapp,
            label: "WhatsApp",
            color: Colors.white,
            bgColor: const Color(0xFF25D366),
            url: whatsappLink,
            context: context,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _socialButton(
            icon: Icons.facebook,
            label: "Facebook",
            color: Colors.white,
            bgColor: const Color(0xFF1877F2),
            url: facebookLink,
            context: context,
          ),
        ),
      ],
    );
  }

  Widget _socialButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required String url,
    required BuildContext context,
  }) {
    return ElevatedButton.icon(
      onPressed: () async {
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Could not open link")),
            );
          }
        }
      },
      icon: Icon(icon, color: color, size: 20),
      label: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
      ),
    );
  }
}
