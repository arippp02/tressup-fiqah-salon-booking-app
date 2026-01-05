import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color figmaBrown1 = Color(0xFF6D4C41);
const Color figmaNudeBG = Color(0xFFFDF6F0);
const Color figmaCard = Colors.white;

class StaffReviewsPage extends StatelessWidget {
  final String staffName;
  const StaffReviewsPage({super.key, required this.staffName});

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "";
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: figmaNudeBG,
      appBar: AppBar(
        title: const Text(
          "My Reviews",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: figmaBrown1,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('stylistName', isEqualTo: staffName)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print("❌ Firestore Error: ${snapshot.error}");
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 50),
                  const SizedBox(height: 10),
                  const Text(
                    "Index Required",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Create the required index in Firebase console.",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: figmaBrown1),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_outline, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("No reviews yet."),
                ],
              ),
            );
          }

          final reviews = snapshot.data!.docs;

          // Calculate Average
          double totalRating = 0;
          for (var doc in reviews) {
            totalRating += (doc['rating'] as num).toDouble();
          }
          double avgRating = reviews.isNotEmpty
              ? totalRating / reviews.length
              : 0.0;

          return Column(
            children: [
              // Summary Header (Kept brown for professional emphasis)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 30,
                  horizontal: 20,
                ),
                decoration: const BoxDecoration(
                  color: figmaBrown1,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Icon(
                          index < avgRating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 28,
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Based on ${reviews.length} reviews",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Review List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final data = reviews[index].data() as Map<String, dynamic>;
                    final rating = (data['rating'] as num).toDouble();
                    final comment = data['comment'] ?? "";
                    final userId = data['userId'] ?? "";

                    return Card(
                      color: Colors.white, // ✅ Changed card background to White
                      elevation: 2, // Soft elevation
                      shadowColor: Colors.black12,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(userId)
                                      .get(),
                                  builder: (context, userSnap) {
                                    String name = "Customer";
                                    if (userSnap.hasData &&
                                        userSnap.data!.exists) {
                                      name =
                                          userSnap.data!.get('name') ??
                                          "Customer";
                                    }
                                    return Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: figmaBrown1, // Contrast color
                                      ),
                                    );
                                  },
                                ),
                                Text(
                                  _formatDate(data['createdAt']),
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < rating ? Icons.star : Icons.star_border,
                                  size: 18,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                            if (comment.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                comment,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  height: 1.4,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
