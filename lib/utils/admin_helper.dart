import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHelper {
  /// Check if current user is an admin
  /// Admin status is stored in users/{userId}/isAdmin field
  static Future<bool> isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return false;

      final data = userDoc.data();
      return data?['isAdmin'] == true;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  /// Set admin status for a user (for initial setup)
  /// This should be done manually in Firebase Console or through a secure admin panel
  static Future<void> setAdminStatus(String userId, bool isAdmin) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
        'isAdmin': isAdmin,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error setting admin status: $e');
      rethrow;
    }
  }
}
