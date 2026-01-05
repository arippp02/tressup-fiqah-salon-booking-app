import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Theme Colors
const Color figmaBrown1 = Color(0xFF6D4C41);
const Color figmaNudeBG = Color(0xFFFDF6F0);

class ServicePage extends StatelessWidget {
  final String category;

  const ServicePage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: figmaNudeBG,
      appBar: AppBar(
        title: Text(
          "$category Services",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: figmaBrown1,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ✅ FETCH FROM FIRESTORE
        // We filter by 'category' so we only get relevant items (e.g., only "Hair")
        stream: FirebaseFirestore.instance
            .collection('services')
            .where('category', isEqualTo: category)
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: figmaBrown1),
            );
          }

          // 2. Error State
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // 3. Empty State
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.spa_outlined, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  Text(
                    "No services found for $category",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          // 4. Data List
          final services = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: services.length,
            separatorBuilder: (context, index) => const SizedBox(height: 15),
            itemBuilder: (context, index) {
              var data = services[index].data() as Map<String, dynamic>;
              String name = data['name'] ?? "Unknown Service";
              String price = data['price'] ?? "N/A";

              return _buildServiceCard(name, price);
            },
          );
        },
      ),
    );
  }

  Widget _buildServiceCard(String name, String price) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Optional: Navigate to booking with this service pre-selected
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Service Name
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3E2723), // Darker brown for text
                    ),
                  ),
                ),

                // Price Tag & Action
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: figmaBrown1.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: figmaBrown1.withOpacity(0.2)),
                      ),
                      child: Text(
                        price,
                        style: const TextStyle(
                          fontSize: 14,
                          color: figmaBrown1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
