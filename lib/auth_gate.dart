import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'loginpage.dart';
import 'mainnavigation.dart';
import 'admin_dashboard.dart';
import 'staff_dashboard.dart';

// Theme Color
const Color figmaBrown1 = Color(0xFF6D4C41);

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // 1. Listen to Auth State (Logged In vs Logged Out)
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // A. Loading state (checking auth)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: figmaBrown1)),
          );
        }

        // B. User is NOT logged in -> Show Login Page
        if (!snapshot.hasData) {
          return const LoginPage();
        }

        // C. User IS logged in -> Check Role in Firestore to decide Home Page
        final User user = snapshot.data!;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, userSnapshot) {
            // Loading role...
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: figmaBrown1),
                ),
              );
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              // Get user role
              final data = userSnapshot.data!.data() as Map<String, dynamic>;
              final String role = data['role'] ?? 'customer';

              // Route based on role
              if (role == 'admin') {
                return const AdminDashboardPage();
              } else if (role == 'staff') {
                return const StaffDashboardPage();
              } else {
                return const MainNavigation(); // Default Customer Home
              }
            }

            // Fallback if user exists in Auth but not in Firestore (rare error case)
            return const LoginPage();
          },
        );
      },
    );
  }
}
