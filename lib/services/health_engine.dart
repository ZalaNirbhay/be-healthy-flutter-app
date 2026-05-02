import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'water_service.dart';
import 'food_service.dart';
import 'calorie_service.dart';

/// Smart Health Engine — Intelligent insights, scoring, and meal suggestions
///
/// This is the BRAIN of the app. It aggregates data from all services
/// and generates actionable insights for the user.
class HealthEngine {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ═══════════════════════════════════════════════
  //  DAILY DASHBOARD SNAPSHOT
  // ═══════════════════════════════════════════════

  /// Fetch complete dashboard data in ONE call (efficient)
  static Future<Map<String, dynamic>> getDashboardSnapshot() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return _emptySnapshot();

      // Parallel fetches for efficiency
      final results = await Future.wait([
        CalorieService.calculateFromProfile(),     // 0: TDEE data
        WaterService.getTodayWaterData(),           // 1: Water data
        FoodService.getTodayEntries(),              // 2: Food entries
        _getUserProfile(),                         // 3: User profile
      ]);

      final calorieData = results[0] as Map<String, dynamic>;
      final waterData = results[1] as Map<String, dynamic>;
      final foodEntries = results[2] as List<Map<String, dynamic>>;
      final userProfile = results[3] as Map<String, dynamic>?;

      // Calculate totals
      final foodTotals = FoodService.calculateDailyTotals(foodEntries);

      final int targetCalories = _getTargetCalories(calorieData, userProfile);
      final int consumed = foodTotals['calories'] ?? 0;
      final int remaining = (targetCalories - consumed).clamp(0, 99999);
      final int waterMl = waterData['total_ml'] ?? 0;
      final int waterGoal = waterData['goal_ml'] ?? 3000;

      // Generate insights
      final status = _getDailyStatus(consumed, targetCalories);
      final feedback = _generateFeedback(
        consumed: consumed,
        target: targetCalories,
        protein: foodTotals['protein'] ?? 0,
        carbs: foodTotals['carbs'] ?? 0,
        fat: foodTotals['fat'] ?? 0,
        waterMl: waterMl,
        waterGoal: waterGoal,
        foodEntries: foodEntries,
      );
      final healthScore = _calculateHealthScore(
        consumed: consumed,
        target: targetCalories,
        waterMl: waterMl,
        waterGoal: waterGoal,
        protein: foodTotals['protein'] ?? 0,
        foodEntries: foodEntries,
      );
      final mealSuggestions = await _getMealSuggestions(remaining);

      return {
        'target_calories': targetCalories,
        'consumed': consumed,
        'remaining': remaining,
        'protein': foodTotals['protein'] ?? 0,
        'carbs': foodTotals['carbs'] ?? 0,
        'fat': foodTotals['fat'] ?? 0,
        'water_ml': waterMl,
        'water_goal': waterGoal,
        'bmi': _calculateBMI(userProfile),
        'food_entries': foodEntries,
        'status': status,
        'feedback': feedback,
        'health_score': healthScore,
        'meal_suggestions': mealSuggestions,
        'user_name': userProfile?['name'] ?? 'User',
        'goal': userProfile?['goal'] ?? 'maintain',
      };
    } catch (e) {
      return _emptySnapshot();
    }
  }

  // ═══════════════════════════════════════════════
  //  TARGET CALORIES (Based on goal)
  // ═══════════════════════════════════════════════

  static int _getTargetCalories(
      Map<String, dynamic> calorieData, Map<String, dynamic>? profile) {
    if (calorieData['success'] != true) return 2000;

    final int tdee = calorieData['tdee'] ?? 2000;
    final String goal = profile?['goal'] ?? 'maintain';

    switch (goal.toLowerCase()) {
      case 'weight_loss':
      case 'lose':
      case 'weight loss':
        return tdee - 500;
      case 'weight_gain':
      case 'gain':
      case 'weight gain':
        return tdee + 500;
      default:
        return tdee;
    }
  }

  // ═══════════════════════════════════════════════
  //  DAILY STATUS INDICATOR
  // ═══════════════════════════════════════════════

  static Map<String, dynamic> _getDailyStatus(int consumed, int target) {
    if (target <= 0) {
      return {'label': 'No Goal Set', 'color': 'grey', 'icon': 'info'};
    }

    final double ratio = consumed / target;

    if (consumed == 0) {
      return {
        'label': 'Not Started',
        'color': 'grey',
        'icon': 'hourglass_empty',
      };
    } else if (ratio < 0.5) {
      return {
        'label': 'Behind',
        'color': 'orange',
        'icon': 'warning',
      };
    } else if (ratio >= 0.5 && ratio <= 1.1) {
      return {
        'label': 'On Track',
        'color': 'green',
        'icon': 'check_circle',
      };
    } else {
      return {
        'label': 'Over Limit',
        'color': 'red',
        'icon': 'error',
      };
    }
  }

  // ═══════════════════════════════════════════════
  //  SMART FEEDBACK GENERATOR
  // ═══════════════════════════════════════════════

  static List<Map<String, dynamic>> _generateFeedback({
    required int consumed,
    required int target,
    required int protein,
    required int carbs,
    required int fat,
    required int waterMl,
    required int waterGoal,
    required List<Map<String, dynamic>> foodEntries,
  }) {
    List<Map<String, dynamic>> insights = [];

    // 1. No food logged
    if (foodEntries.isEmpty) {
      insights.add({
        'message': "You haven't logged any food today. Start tracking!",
        'type': 'nudge',
        'icon': 'restaurant',
      });
      return insights;
    }

    // 2. Calorie status
    final double ratio = target > 0 ? consumed / target : 0;

    if (ratio > 1.15) {
      insights.add({
        'message': 'You exceeded your calorie goal by ${consumed - target} kcal. Consider lighter meals.',
        'type': 'warning',
        'icon': 'warning',
      });
    } else if (ratio < 0.4 && foodEntries.length >= 2) {
      insights.add({
        'message': 'You are under-eating today. You still have ${target - consumed} kcal remaining.',
        'type': 'info',
        'icon': 'info',
      });
    } else if (ratio >= 0.8 && ratio <= 1.05) {
      insights.add({
        'message': "Great job! You're right on track with your calorie goal.",
        'type': 'success',
        'icon': 'thumb_up',
      });
    }

    // 3. Protein check (target: ~0.8g per kg, approximate 50-80g minimum)
    if (protein < 30 && foodEntries.length >= 2) {
      insights.add({
        'message': 'Your protein intake is low ($protein g). Add chicken, eggs, or yogurt.',
        'type': 'suggestion',
        'icon': 'fitness_center',
      });
    }

    // 4. Water check
    final double waterRatio = waterGoal > 0 ? waterMl / waterGoal : 0;
    if (waterRatio < 0.3) {
      insights.add({
        'message': "You've only had ${WaterService.formatWater(waterMl)} water. Stay hydrated!",
        'type': 'nudge',
        'icon': 'water_drop',
      });
    } else if (waterRatio >= 1.0) {
      insights.add({
        'message': "You've reached your water goal! Keep it up!",
        'type': 'success',
        'icon': 'water_drop',
      });
    }

    // 5. Meal balance check
    final mealTypes = foodEntries.map((e) => e['meal_type']?.toString().toLowerCase()).toSet();
    if (!mealTypes.contains('breakfast') && DateTime.now().hour > 10) {
      insights.add({
        'message': "You haven't logged breakfast. Skipping meals can slow metabolism.",
        'type': 'nudge',
        'icon': 'free_breakfast',
      });
    }

    return insights;
  }

  // ═══════════════════════════════════════════════
  //  DAILY HEALTH SCORE (0-100)
  // ═══════════════════════════════════════════════

  static int _calculateHealthScore({
    required int consumed,
    required int target,
    required int waterMl,
    required int waterGoal,
    required int protein,
    required List<Map<String, dynamic>> foodEntries,
  }) {
    if (foodEntries.isEmpty && waterMl == 0) return 0;

    int score = 0;

    // 1. Calorie adherence (max 40 points)
    if (target > 0) {
      final double ratio = consumed / target;
      if (ratio >= 0.85 && ratio <= 1.1) {
        score += 40; // Perfect range
      } else if (ratio >= 0.7 && ratio <= 1.2) {
        score += 30; // Good
      } else if (ratio >= 0.5) {
        score += 20; // Decent
      } else if (consumed > 0) {
        score += 10; // At least something
      }
    }

    // 2. Water intake (max 25 points)
    if (waterGoal > 0) {
      final double waterRatio = waterMl / waterGoal;
      if (waterRatio >= 1.0) {
        score += 25;
      } else if (waterRatio >= 0.7) {
        score += 20;
      } else if (waterRatio >= 0.4) {
        score += 12;
      } else if (waterMl > 0) {
        score += 5;
      }
    }

    // 3. Meal variety (max 20 points)
    final mealTypes = foodEntries.map((e) => e['meal_type']).toSet();
    score += (mealTypes.length * 5).clamp(0, 20);

    // 4. Protein intake (max 15 points)
    if (protein >= 50) {
      score += 15;
    } else if (protein >= 30) {
      score += 10;
    } else if (protein > 0) {
      score += 5;
    }

    return score.clamp(0, 100);
  }

  // ═══════════════════════════════════════════════
  //  SMART MEAL SUGGESTIONS
  // ═══════════════════════════════════════════════

  static Future<List<Map<String, dynamic>>> _getMealSuggestions(
      int remainingCalories) async {
    if (remainingCalories <= 50) return [];

    try {
      // Find foods that fit within remaining calories
      final allFoods = await FoodService.searchFoodItems('');

      List<Map<String, dynamic>> suggestions = [];

      for (var food in allFoods) {
        final int calPer100g = food['calories_per_100g'] ?? 0;
        final int defaultServing = food['default_serving_g'] ?? 100;
        final int servingCalories = ((calPer100g * defaultServing) / 100).round();

        if (servingCalories > 0 && servingCalories <= remainingCalories) {
          suggestions.add({
            'name': food['name'],
            'calories': servingCalories,
            'serving': defaultServing,
            'category': food['category'],
            'icon': food['icon'],
          });
        }
      }

      // Sort by how well they fit the remaining calories (closest first)
      suggestions.sort((a, b) {
        final diffA = (remainingCalories - (a['calories'] as int)).abs();
        final diffB = (remainingCalories - (b['calories'] as int)).abs();
        return diffA.compareTo(diffB);
      });

      return suggestions.take(5).toList();
    } catch (e) {
      return [];
    }
  }

  // ═══════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════

  static Future<Map<String, dynamic>?> _getUserProfile() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  static double _calculateBMI(Map<String, dynamic>? profile) {
    if (profile == null) return 0;
    final h = profile['height_cm'];
    final w = profile['weight_kg'];
    if (h == null || w == null || h == 0) return 0;
    final double height = (h is int) ? h.toDouble() : h;
    final double weight = (w is int) ? w.toDouble() : w;
    return weight / ((height / 100) * (height / 100));
  }

  static Map<String, dynamic> _emptySnapshot() {
    return {
      'target_calories': 2000,
      'consumed': 0,
      'remaining': 2000,
      'protein': 0,
      'carbs': 0,
      'fat': 0,
      'water_ml': 0,
      'water_goal': 3000,
      'bmi': 0.0,
      'food_entries': <Map<String, dynamic>>[],
      'status': {'label': 'Not Started', 'color': 'grey', 'icon': 'info'},
      'feedback': <Map<String, dynamic>>[],
      'health_score': 0,
      'meal_suggestions': <Map<String, dynamic>>[],
      'user_name': 'User',
      'goal': 'maintain',
    };
  }
}
