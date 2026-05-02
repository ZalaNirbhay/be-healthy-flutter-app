import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'water_service.dart';
import 'food_service.dart';

/// Progress Tracking Service — Daily snapshots + trend analysis
///
/// STORAGE: progress_logs/{uid}/entries/{YYYY-MM-DD}
///
/// Each day gets ONE document (upserted, not duplicated).
/// Stores: weight, calories consumed, water intake, health score, date.
class ProgressService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String _todayDateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ═══════════════════════════════════════════════
  //  DAILY SNAPSHOT
  // ═══════════════════════════════════════════════

  /// Save/update today's progress snapshot
  static Future<void> saveDailySnapshot({
    required int caloriesConsumed,
    required int waterMl,
    required int healthScore,
    double? weight,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final dateKey = _todayDateKey();

      final data = {
        'calories_consumed': caloriesConsumed,
        'water_intake': waterMl,
        'health_score': healthScore,
        'date': dateKey,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (weight != null) {
        data['weight'] = weight;
      }

      await _firestore
          .collection('progress_logs')
          .doc(uid)
          .collection('entries')
          .doc(dateKey)
          .set(data, SetOptions(merge: true));
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════
  //  HISTORY & TRENDS
  // ═══════════════════════════════════════════════

  /// Get last N days of progress entries
  static Future<List<Map<String, dynamic>>> getRecentEntries({int days = 7}) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return [];

      final snapshot = await _firestore
          .collection('progress_logs')
          .doc(uid)
          .collection('entries')
          .orderBy('date', descending: true)
          .limit(days)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Calculate weekly summary
  static Future<Map<String, dynamic>> getWeeklySummary() async {
    final entries = await getRecentEntries(days: 7);

    if (entries.isEmpty) {
      return {
        'avg_calories': 0,
        'avg_water': 0,
        'avg_score': 0,
        'total_days_tracked': 0,
        'calorie_trend': 'stable',
        'weight_change': 0.0,
        'consistency_score': 0,
      };
    }

    int totalCal = 0;
    int totalWater = 0;
    int totalScore = 0;
    double? firstWeight;
    double? lastWeight;

    for (var entry in entries) {
      totalCal += (entry['calories_consumed'] ?? 0) as int;
      totalWater += (entry['water_intake'] ?? 0) as int;
      totalScore += (entry['health_score'] ?? 0) as int;

      final w = entry['weight'];
      if (w != null) {
        lastWeight ??= (w is int) ? w.toDouble() : w;
        firstWeight = (w is int) ? w.toDouble() : w;
      }
    }

    final int count = entries.length;
    final int avgCal = count > 0 ? (totalCal / count).round() : 0;
    final int avgWater = count > 0 ? (totalWater / count).round() : 0;
    final int avgScore = count > 0 ? (totalScore / count).round() : 0;

    // Weight trend
    double weightChange = 0.0;
    if (firstWeight != null && lastWeight != null) {
      weightChange = lastWeight - firstWeight;
    }

    // Calorie trend (compare first half vs second half)
    String calorieTrend = 'stable';
    if (count >= 4) {
      final half = count ~/ 2;
      int firstHalfCal = 0;
      int secondHalfCal = 0;
      for (int i = 0; i < count; i++) {
        final cal = (entries[i]['calories_consumed'] ?? 0) as int;
        if (i < half) {
          firstHalfCal += cal;
        } else {
          secondHalfCal += cal;
        }
      }
      final avgFirst = firstHalfCal / half;
      final avgSecond = secondHalfCal / (count - half);
      if (avgSecond > avgFirst * 1.1) {
        calorieTrend = 'increasing';
      } else if (avgSecond < avgFirst * 0.9) {
        calorieTrend = 'decreasing';
      }
    }

    // Consistency score (how many days out of 7 were tracked)
    final int consistencyScore = ((count / 7) * 100).round().clamp(0, 100);

    return {
      'avg_calories': avgCal,
      'avg_water': avgWater,
      'avg_score': avgScore,
      'total_days_tracked': count,
      'calorie_trend': calorieTrend,
      'weight_change': weightChange,
      'consistency_score': consistencyScore,
      'entries': entries,
    };
  }

  /// Auto-save today's progress (call from dashboard)
  static Future<void> autoSaveToday({
    required int calories,
    required int water,
    required int healthScore,
  }) async {
    // Get weight from profile
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final userDoc = await _firestore.collection('users').doc(uid).get();
      double? weight;
      if (userDoc.exists) {
        final w = userDoc.data()?['weight_kg'];
        if (w != null) {
          weight = (w is int) ? w.toDouble() : w;
        }
      }

      await saveDailySnapshot(
        caloriesConsumed: calories,
        waterMl: water,
        healthScore: healthScore,
        weight: weight,
      );
    } catch (_) {}
  }

  /// Generate progress insights
  static List<String> generateInsights(Map<String, dynamic> summary) {
    List<String> insights = [];

    final int daysTracked = summary['total_days_tracked'] ?? 0;
    final int avgScore = summary['avg_score'] ?? 0;
    final String trend = summary['calorie_trend'] ?? 'stable';
    final double weightChange = summary['weight_change'] ?? 0.0;
    final int consistency = summary['consistency_score'] ?? 0;

    if (daysTracked == 0) {
      insights.add("Start tracking to see your progress trends!");
      return insights;
    }

    // Consistency
    if (consistency >= 80) {
      insights.add("🔥 Great consistency! You tracked $daysTracked out of 7 days.");
    } else if (consistency >= 50) {
      insights.add("📊 You tracked $daysTracked days this week. Try to be more consistent!");
    } else {
      insights.add("⚠️ Only $daysTracked days tracked. Consistency is key!");
    }

    // Weight trend
    if (weightChange < -0.3) {
      insights.add("📉 Your weight is trending down (${weightChange.toStringAsFixed(1)}kg). Keep it up!");
    } else if (weightChange > 0.3) {
      insights.add("📈 Your weight increased by ${weightChange.toStringAsFixed(1)}kg this week.");
    }

    // Calorie trend
    if (trend == 'decreasing') {
      insights.add("🥗 Your calorie intake is decreasing — great for weight loss goals.");
    } else if (trend == 'increasing') {
      insights.add("🍔 Your calorie intake is trending up this week.");
    }

    // Health score
    if (avgScore >= 70) {
      insights.add("🌟 Average health score: $avgScore/100 — Excellent!");
    } else if (avgScore >= 40) {
      insights.add("💪 Average health score: $avgScore/100 — Room for improvement.");
    }

    return insights;
  }
}
