import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'calorie_service.dart';

/// Goal Service — Health goal management with calorie engine sync
///
/// STORAGE: users/{uid} fields: goal, target_weight, daily_calorie_target
///
/// Goals sync with CalorieService, Dashboard, and HealthEngine.
class GoalService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ═══════════════════════════════════════════════
  //  GET GOALS
  // ═══════════════════════════════════════════════

  static Future<Map<String, dynamic>> getGoals() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return _defaultGoals();

      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return _defaultGoals();

      final data = doc.data()!;
      return {
        'goal': data['goal'] ?? 'maintain',
        'target_weight': data['target_weight'] ?? 0.0,
        'daily_calorie_target': data['daily_calorie_target'] ?? 0,
        'activity_level': data['activity_level'] ?? 'Moderate',
        'current_weight': data['weight_kg'] ?? 0.0,
      };
    } catch (e) {
      return _defaultGoals();
    }
  }

  // ═══════════════════════════════════════════════
  //  UPDATE GOALS
  // ═══════════════════════════════════════════════

  static Future<Map<String, dynamic>> updateGoals({
    String? goal,
    double? targetWeight,
    int? dailyCalorieTarget,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return {'success': false, 'message': 'Not logged in'};

      Map<String, dynamic> updates = {
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (goal != null) updates['goal'] = goal;
      if (targetWeight != null) updates['target_weight'] = targetWeight;
      if (dailyCalorieTarget != null) {
        updates['daily_calorie_target'] = dailyCalorieTarget;
      }

      await _firestore.collection('users').doc(uid).update(updates);

      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update goals'};
    }
  }

  // ═══════════════════════════════════════════════
  //  AUTO-CALCULATE TARGET
  // ═══════════════════════════════════════════════

  /// Calculate recommended daily calories based on goal
  static Future<int> calculateRecommendedCalories(String goal) async {
    final calorieData = await CalorieService.calculateFromProfile();
    if (calorieData['success'] != true) return 2000;

    final int tdee = calorieData['tdee'] ?? 2000;

    switch (goal.toLowerCase()) {
      case 'weight_loss':
      case 'lose':
        return (tdee - 500).clamp(1200, 9999);
      case 'weight_gain':
      case 'gain':
        return tdee + 500;
      default:
        return tdee;
    }
  }

  // ═══════════════════════════════════════════════
  //  STREAK TRACKER
  // ═══════════════════════════════════════════════

  /// Calculate current streak (consecutive days with food logs)
  static Future<int> calculateStreak() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return 0;

      // Check last 30 days of progress logs
      final snapshot = await _firestore
          .collection('progress_logs')
          .doc(uid)
          .collection('entries')
          .orderBy('date', descending: true)
          .limit(30)
          .get();

      if (snapshot.docs.isEmpty) return 0;

      int streak = 0;
      final now = DateTime.now();

      for (int i = 0; i < 30; i++) {
        final checkDate = now.subtract(Duration(days: i));
        final dateKey =
            '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';

        final hasEntry = snapshot.docs.any((doc) => doc.id == dateKey);

        if (hasEntry) {
          streak++;
        } else if (i > 0) {
          // Streak broken (skip today if no data yet)
          break;
        }
      }

      // Save streak to user profile for quick access
      await _firestore.collection('users').doc(uid).update({
        'current_streak': streak,
      });

      return streak;
    } catch (e) {
      return 0;
    }
  }

  static Map<String, dynamic> _defaultGoals() {
    return {
      'goal': 'maintain',
      'target_weight': 0.0,
      'daily_calorie_target': 2000,
      'activity_level': 'Moderate',
      'current_weight': 0.0,
    };
  }
}
