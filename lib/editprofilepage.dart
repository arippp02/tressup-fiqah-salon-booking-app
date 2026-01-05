import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Theme Colors
const Color figmaBrown1 = Color(0xFF6D4C41);
const Color figmaNudeBG = Color(0xFFFDF6F0);

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // Controllers for Profile Info
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  // Controllers for Password Change
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = true;

  // Avatar State
  String selectedAvatar = 'assets/default_avatar.png'; // Default fallback

  // 🎨 PRESET AVATARS LIST
  // Ensure these images exist in your assets/avatars/ folder
  final List<String> avatarOptions = [
    'assets/default_avatar.png',
    'assets/hijab.png',
    'assets/nonhijab.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 1. Load Data
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          usernameController.text = data['name'] ?? data['username'] ?? "";
          phoneController.text = data['phone'] ?? "";
          emailController.text = user.email ?? "";
          // Load saved avatar path or keep default
          selectedAvatar = data['avatar'] ?? 'assets/default_avatar.png';
          isLoading = false;
        });
      }
    }
  }

  // 2. Save Profile Data
  Future<void> _saveProfile() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'name': usernameController.text.trim(),
              'phone': phoneController.text.trim(),
              'avatar': selectedAvatar, // Save the string path
            });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profile Updated Successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
          setState(() => isLoading = false);
        }
      }
    }
  }

  // 3. UI: Show Avatar Picker Bottom Sheet
  void _showAvatarPicker() {
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
                        setState(() => selectedAvatar = avatar);
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
                          onBackgroundImageError: (_, __) {
                            // Handle missing assets gracefully
                          },
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

  // 4. UI: Change Password Sheet
  void _showChangePasswordSheet() {
    // Reset fields
    currentPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        bool obscureCurrent = true;
        bool obscureNew = true;
        bool obscureConfirm = true;
        String? sheetErrorMessage;
        bool isSheetLoading = false;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Future<void> handleSubmit() async {
              setModalState(() {
                sheetErrorMessage = null;
                isSheetLoading = true;
              });

              if (currentPasswordController.text.isEmpty ||
                  newPasswordController.text.isEmpty ||
                  confirmPasswordController.text.isEmpty) {
                setModalState(() {
                  sheetErrorMessage = "Please fill in all fields.";
                  isSheetLoading = false;
                });
                return;
              }

              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                setModalState(() {
                  sheetErrorMessage = "New passwords do not match.";
                  isSheetLoading = false;
                });
                return;
              }

              if (newPasswordController.text.length < 6) {
                setModalState(() {
                  sheetErrorMessage = "Password must be at least 6 characters.";
                  isSheetLoading = false;
                });
                return;
              }

              final user = FirebaseAuth.instance.currentUser;
              final cred = EmailAuthProvider.credential(
                email: user!.email!,
                password: currentPasswordController.text,
              );

              try {
                await user.reauthenticateWithCredential(cred);
                await user.updatePassword(newPasswordController.text);

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Password Changed Successfully!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } on FirebaseAuthException catch (e) {
                String msg = "Error changing password.";
                if (e.code == 'wrong-password' ||
                    e.code == 'invalid-credential') {
                  msg = "Current password is incorrect.";
                } else if (e.code == 'weak-password') {
                  msg = "New password is too weak.";
                }
                setModalState(() {
                  sheetErrorMessage = msg;
                  isSheetLoading = false;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Change Password",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: figmaBrown1,
                    ),
                  ),
                  const SizedBox(height: 15),

                  if (sheetErrorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              sheetErrorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),

                  _buildPasswordField(
                    "Current Password",
                    currentPasswordController,
                    obscureCurrent,
                    () => setModalState(() => obscureCurrent = !obscureCurrent),
                  ),
                  _buildPasswordField(
                    "New Password",
                    newPasswordController,
                    obscureNew,
                    () => setModalState(() => obscureNew = !obscureNew),
                  ),
                  _buildPasswordField(
                    "Confirm New Password",
                    confirmPasswordController,
                    obscureConfirm,
                    () => setModalState(() => obscureConfirm = !obscureConfirm),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: figmaBrown1,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isSheetLoading ? null : handleSubmit,
                      child: isSheetLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Update Password",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: figmaNudeBG,
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: figmaBrown1,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: figmaBrown1))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // AVATAR SECTION
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
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
                            radius: 60,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: AssetImage(selectedAvatar),
                            onBackgroundImageError: (_, __) {
                              // Fallback is handled by the initial state
                            },
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showAvatarPicker, // Open selector
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: figmaBrown1,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // FIELDS
                  _buildField(
                    "Full Name",
                    usernameController,
                    Icons.person_outline,
                  ),
                  _buildField(
                    "Email Address",
                    emailController,
                    Icons.email_outlined,
                    readOnly: true,
                  ),
                  _buildField(
                    "Phone Number",
                    phoneController,
                    Icons.phone_outlined,
                  ),

                  // CHANGE PASSWORD BUTTON
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _showChangePasswordSheet,
                      icon: const Icon(
                        Icons.lock_reset,
                        color: figmaBrown1,
                        size: 18,
                      ),
                      label: const Text(
                        "Change Password",
                        style: TextStyle(
                          color: figmaBrown1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: figmaBrown1,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: figmaBrown1.withOpacity(0.4),
                      ),
                      onPressed: _saveProfile,
                      child: const Text(
                        "Save Changes",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // --- WIDGETS ---

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool readOnly = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        style: TextStyle(
          color: readOnly ? Colors.grey[600] : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: figmaBrown1.withOpacity(0.7)),
          filled: true,
          fillColor: readOnly ? Colors.grey[100] : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: figmaBrown1, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    String hint,
    TextEditingController controller,
    bool isObscured,
    VoidCallback onToggle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: isObscured,
        decoration: InputDecoration(
          labelText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
          suffixIcon: IconButton(
            icon: Icon(
              isObscured ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }
}
