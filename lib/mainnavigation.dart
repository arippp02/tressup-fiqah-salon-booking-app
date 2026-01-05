import 'package:flutter/material.dart';
// Ensure these files exist in your lib folder:
import 'homepage.dart';
import 'bookingpage.dart';
import 'promotions_page.dart'; // ✅ Import the new Promotions Page
import 'customer_history.dart';
import 'aichatbotpage.dart';
import 'accountpage.dart';

const Color figmaBrown1 = Color(0xFF6D4C41);

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  // ✅ Added PromotionsPage to the list
  final List<Widget> screens = [
    const HomePage(),
    const BookingPage(),
    const PromotionsPage(), // 🏷️ New Tab
    const AiChatbotPage(),
    const CustomerHistoryPage(),
    const AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Keeps labels visible
        backgroundColor: Colors.white,
        currentIndex: currentIndex,
        selectedItemColor: figmaBrown1,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        onTap: (index) => setState(() => currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "Book",
          ),
          // ✅ New Offers Item
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: "Offers",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: "Chat",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
