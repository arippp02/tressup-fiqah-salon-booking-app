import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

const Color figmaBrown1 = Color(0xFF6D4C41);
const Color figmaNudeBG = Color(0xFFFDF6F0);

class PromotionsPage extends StatelessWidget {
  const PromotionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: figmaNudeBG,
      appBar: AppBar(
        title: const Text(
          "Exclusive Offers",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: figmaBrown1,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('promotions')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: figmaBrown1),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          var docs = snapshot.data!.docs;
          DateTime now = DateTime.now();

          // ✅ CLIENT-SIDE FILTERING (Safest way to avoid index errors)
          // Filter out documents where expiryDate is BEFORE now
          var validPromos = docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            if (data['expiryDate'] == null) return true; // Keep if no date set
            Timestamp expiry = data['expiryDate'];
            return expiry.toDate().isAfter(now); // Keep if expiry is in future
          }).toList();

          if (validPromos.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: validPromos.length,
            itemBuilder: (context, index) {
              var data = validPromos[index].data() as Map<String, dynamic>;
              return _buildPromoCard(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildPromoCard(Map<String, dynamic> data) {
    String title = data['title'] ?? 'Special Offer';
    String body = data['body'] ?? 'Limited time discount!';

    // Format Expiry Date
    String expiryText = "Limited Time";
    if (data['expiryDate'] != null) {
      Timestamp ts = data['expiryDate'];
      expiryText = "Expires ${DateFormat('dd MMM').format(ts.toDate())}";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: figmaBrown1.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.verified,
              size: 40,
              color: figmaBrown1.withOpacity(0.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "LIMITED TIME",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // ✅ Show Expiry Date
                    Text(
                      expiryText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: figmaBrown1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 80,
            color: figmaBrown1.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            "No Active Promotions",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 5),
          const Text(
            "Check back later!",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
