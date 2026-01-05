import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color figmaBrown1 = Color(0xFF6D4C41);
const Color figmaNudeBG = Color(0xFFFDF6F0);
const Color figmaCard = Colors.white;

class AdminReviewsPage extends StatelessWidget {
  const AdminReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: figmaNudeBG,
      appBar: AppBar(
        title: const Text("Performance & Feedback"),
        backgroundColor: figmaBrown1,
        foregroundColor: Colors.white,
      ),
      // We need two streams: 1. All Stylists (names), 2. All Reviews (ratings)
      // We use a StreamBuilder on Reviews first as it changes most often.
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reviews').snapshots(),
        builder: (context, reviewSnapshot) {
          if (reviewSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allReviews = reviewSnapshot.data?.docs ?? [];

          // --- 1. CALCULATE OVERALL SALON RATING ---
          double salonTotal = 0;
          if (allReviews.isNotEmpty) {
            for (var doc in allReviews) {
              salonTotal += (doc['rating'] as num).toDouble();
            }
          }
          final double salonAverage = allReviews.isNotEmpty
              ? salonTotal / allReviews.length
              : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- SECTION 1: OVERALL OPERATION ---
                const Text(
                  "Overall Operation",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: figmaBrown1,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: figmaBrown1,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Average Rating",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            salonAverage.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "${allReviews.length} Total Reviews",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      // Big Star Icon
                      const Icon(Icons.star, color: Colors.amber, size: 80),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // --- SECTION 2: STYLIST PERFORMANCE LIST ---
                const Text(
                  "Stylist Performance",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: figmaBrown1,
                  ),
                ),
                const SizedBox(height: 10),

                // Stream Stylists to build the list
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('stylists')
                      .snapshots(),
                  builder: (context, stylistSnapshot) {
                    if (!stylistSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final stylists = stylistSnapshot.data!.docs;

                    return ListView.builder(
                      shrinkWrap:
                          true, // Important inside SingleChildScrollView
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: stylists.length,
                      itemBuilder: (context, index) {
                        final stylistData =
                            stylists[index].data() as Map<String, dynamic>;
                        final String name = stylistData['name'] ?? "Unknown";

                        // Calculate specific average for this stylist
                        final stylistReviews = allReviews.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return data['stylistName'] == name;
                        }).toList();

                        double total = 0;
                        for (var r in stylistReviews) {
                          total += (r['rating'] as num).toDouble();
                        }
                        double avg = stylistReviews.isNotEmpty
                            ? total / stylistReviews.length
                            : 0.0;

                        return Card(
                          color: Colors.white,
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: figmaBrown1.withOpacity(0.1),
                              child: const Icon(
                                Icons.person,
                                color: figmaBrown1,
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              "${stylistReviews.length} Reviews",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      avg.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              // Navigate to Drill-down Detail Page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StylistReviewsDetailPage(
                                    stylistName: name,
                                    averageRating: avg,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// NEW CLASS: DETAIL PAGE FOR SPECIFIC STYLIST
// ==========================================
class StylistReviewsDetailPage extends StatelessWidget {
  final String stylistName;
  final double averageRating;

  const StylistReviewsDetailPage({
    super.key,
    required this.stylistName,
    required this.averageRating,
  });

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
        title: Text("$stylistName's Feedback"),
        backgroundColor: figmaBrown1,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header Summary
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: figmaBrown1,
                  ),
                ),
                const SizedBox(width: 10),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < averageRating.round()
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 30,
                    );
                  }),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Review List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .where('stylistName', isEqualTo: stylistName)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No reviews found."));
                }

                final reviews = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final data = reviews[index].data() as Map<String, dynamic>;
                    final double rating = (data['rating'] ?? 0).toDouble();
                    final String comment = data['comment'] ?? "";
                    final String userId = data['userId'] ?? "";

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Fetch User Name for this specific review
                                FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(userId)
                                      .get(),
                                  builder: (context, userSnap) {
                                    String userName = "Customer";
                                    if (userSnap.hasData &&
                                        userSnap.data!.exists) {
                                      userName =
                                          userSnap.data!.get('name') ??
                                          "Customer";
                                    }
                                    return Text(
                                      userName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    );
                                  },
                                ),
                                Text(
                                  _formatDate(data['createdAt']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: List.generate(5, (starIndex) {
                                return Icon(
                                  starIndex < rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 18,
                                  color: Colors.amber,
                                );
                              }),
                            ),
                            if (comment.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                comment,
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
