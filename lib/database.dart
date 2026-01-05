import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  // Collection References
  final CollectionReference userCollection = FirebaseFirestore.instance
      .collection('users');
  final CollectionReference appointmentCollection = FirebaseFirestore.instance
      .collection('appointments');

  // 1. Create/Update User Profile
  Future<void> updateUserData(String name, String email, String phone) async {
    return await userCollection.doc(uid).set({
      'name': name,
      'email': email,
      'phone': phone,
      'role': 'customer',
      'points': 0, // Start with 0 points
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 2. Create Appointment (Updated to accept pointsRedeemed)
  Future<void> bookAppointment(
    String service,
    String stylist,
    DateTime date,
    String time, {
    String? price,
    int pointsRedeemed = 0, // ✅ NEW: Track points used for this booking
  }) async {
    await appointmentCollection.add({
      'userId': uid,
      'service': service,
      'stylist': stylist,
      'date': date.toIso8601String(),
      'time': time,
      'price': price ?? "0",
      'pointsRedeemed': pointsRedeemed, // ✅ Save to DB
      'status': 'upcoming',
      'bookedAt': FieldValue.serverTimestamp(),
    });
  }

  // 3. Get Appointment List (Stream)
  Stream<QuerySnapshot> get myAppointments {
    return appointmentCollection
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: false)
        .snapshots();
  }

  // 4. ✅ EARN POINTS: RM 10 = 1 Point
  Future<int> earnPoints(String userId, double amountSpent) async {
    try {
      DocumentReference userRef = userCollection.doc(userId);

      // Logic: 1 Point for every RM 10 spent
      int pointsEarned = (amountSpent / 10).floor();

      if (pointsEarned <= 0) return 0;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userRef);

        if (!snapshot.exists) return;

        int currentPoints =
            (snapshot.data() as Map<String, dynamic>)['points'] ?? 0;

        transaction.update(userRef, {
          'points': currentPoints + pointsEarned,
          'totalPointsEarned': FieldValue.increment(pointsEarned),
        });
      });

      return pointsEarned;
    } catch (e) {
      print("Error earning points: $e");
      return 0;
    }
  }

  // 5. ✅ REDEEM POINTS: Deduct points
  Future<void> usePoints(String userId, int pointsToRedeem) async {
    try {
      if (pointsToRedeem <= 0) return;

      await userCollection.doc(userId).update({
        'points': FieldValue.increment(-pointsToRedeem),
      });
    } catch (e) {
      print("Error using points: $e");
    }
  }
}
