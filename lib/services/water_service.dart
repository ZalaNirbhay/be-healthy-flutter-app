import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WaterService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const int _incrementMl = 200;
  static const int _defaultGoalMl = 3000;

  /// Get today's date string in YYYY-MM-DD format
  static String _todayDateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Get reference to today's water document
  static DocumentReference _todayDoc() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');

    return _firestore
        .collection('water_logs')
        .doc(uid)
        .collection('daily')
        .doc(_todayDateKey());
  }

  /// Log 200ml of water (atomic increment)
  static Future<Map<String, dynamic>> logWater() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final docRef = _todayDoc();
      final doc = await docRef.get();

      if (doc.exists) {
        // Document exists → atomic increment
        await docRef.update({
          'total_ml': FieldValue.increment(_incrementMl),
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        // Document doesn't exist → create new
        await docRef.set({
          'total_ml': _incrementMl,
          'goal_ml': _defaultGoalMl,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': 'Failed to log water'};
    }
  }

  /// Get today's water data
  static Future<Map<String, dynamic>> getTodayWaterData() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        return {'total_ml': 0, 'goal_ml': _defaultGoalMl};
      }

      final doc = await _todayDoc().get();

      if (!doc.exists) {
        return {'total_ml': 0, 'goal_ml': _defaultGoalMl};
      }

      final data = doc.data() as Map<String, dynamic>;
      return {
        'total_ml': data['total_ml'] ?? 0,
        'goal_ml': data['goal_ml'] ?? _defaultGoalMl,
      };
    } catch (e) {
      return {'total_ml': 0, 'goal_ml': _defaultGoalMl};
    }
  }

  /// Get water display string (e.g. "1.5L" or "800ml")
  static String formatWater(int totalMl) {
    if (totalMl >= 1000) {
      double liters = totalMl / 1000.0;
      return '${liters.toStringAsFixed(1)}L';
    }
    return '${totalMl}ml';
  }

  /// Get progress percentage (0.0 to 1.0, capped at 1.0)
  static double getProgress(int totalMl, int goalMl) {
    if (goalMl <= 0) return 0.0;
    double progress = totalMl / goalMl;
    return progress > 1.0 ? 1.0 : progress;
  }
}
