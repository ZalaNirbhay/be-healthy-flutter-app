import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'calorie_service.dart';
import 'food_service.dart';

/// Weight Plan Engine — Generates personalized diet + exercise plans
///
/// STORAGE: user_plans/{uid}/plans/{planId}
///
/// Flow:
/// 1. Get user profile (age, gender, weight, height, activity_level, goal)
/// 2. Calculate calorie target (TDEE ± deficit/surplus)
/// 3. Generate meal plan from food database (veg/non-veg filtered)
/// 4. Generate exercise plan based on goal type
/// 5. Store plan in Firestore
class PlanService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ═══════════════════════════════════════════════
  //  PLAN GENERATION
  // ═══════════════════════════════════════════════

  /// Generate a complete weight plan
  static Future<Map<String, dynamic>> generatePlan({
    required String goalType, // 'weight_loss' or 'weight_gain'
    required double targetWeightChange, // kg to lose/gain
    required String dietType, // 'veg' or 'non_veg'
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return {'success': false, 'message': 'Not logged in'};

      // Step 1: Get TDEE
      final calorieData = await CalorieService.calculateFromProfile();
      if (calorieData['success'] != true) {
        return {'success': false, 'message': 'Complete your profile first'};
      }

      final int tdee = calorieData['tdee'] ?? 2000;

      // Step 2: Calculate calorie target
      int calorieTarget;
      if (goalType == 'weight_loss') {
        calorieTarget = (tdee - 500).clamp(1200, 9999);
      } else {
        calorieTarget = tdee + 500;
      }

      // Step 3: Generate meal plan
      final meals = await _generateMealPlan(
        calorieTarget: calorieTarget,
        dietType: dietType,
      );

      // Step 4: Generate exercise plan
      final exercises = _generateExercisePlan(goalType: goalType);

      // Step 5: Calculate duration estimate
      // ~0.5kg per week for safe weight change
      final int weeksEstimate = (targetWeightChange / 0.5).ceil();

      // Step 6: Store plan
      final planData = {
        'goal_type': goalType,
        'target_weight_change': targetWeightChange,
        'diet_type': dietType,
        'calorie_target': calorieTarget,
        'tdee': tdee,
        'suggested_meals': meals,
        'exercises': exercises,
        'weeks_estimate': weeksEstimate,
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
      };

      // Deactivate old plans
      await _deactivateOldPlans(uid);

      // Save new plan
      final docRef = await _firestore
          .collection('user_plans')
          .doc(uid)
          .collection('plans')
          .add(planData);

      planData['id'] = docRef.id;
      planData.remove('created_at'); // Remove FieldValue for return

      return {'success': true, 'plan': planData};
    } catch (e) {
      return {'success': false, 'message': 'Failed to generate plan'};
    }
  }

  /// Deactivate previous active plans
  static Future<void> _deactivateOldPlans(String uid) async {
    final activePlans = await _firestore
        .collection('user_plans')
        .doc(uid)
        .collection('plans')
        .where('is_active', isEqualTo: true)
        .get();

    final batch = _firestore.batch();
    for (var doc in activePlans.docs) {
      batch.update(doc.reference, {'is_active': false});
    }
    if (activePlans.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  /// Get current active plan
  static Future<Map<String, dynamic>?> getActivePlan() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;

      final snapshot = await _firestore
          .collection('user_plans')
          .doc(uid)
          .collection('plans')
          .where('is_active', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final data = snapshot.docs.first.data();
      data['id'] = snapshot.docs.first.id;
      return data;
    } catch (e) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════
  //  MEAL PLAN GENERATOR
  // ═══════════════════════════════════════════════

  static Future<List<Map<String, dynamic>>> _generateMealPlan({
    required int calorieTarget,
    required String dietType,
  }) async {
    // Get all food items
    final allFoods = await FoodService.searchFoodItems('');

    // Filter by diet type
    final filteredFoods = allFoods.where((food) {
      if (dietType == 'veg') {
        return !_isNonVeg(food['name'] ?? '');
      }
      return true;
    }).toList();

    // Distribute calories: Breakfast 25%, Lunch 35%, Snack 15%, Dinner 25%
    final breakfastCal = (calorieTarget * 0.25).round();
    final lunchCal = (calorieTarget * 0.35).round();
    final snackCal = (calorieTarget * 0.15).round();
    final dinnerCal = (calorieTarget * 0.25).round();

    List<Map<String, dynamic>> meals = [];

    meals.add(_pickMeal('Breakfast', breakfastCal, filteredFoods, ['Breakfast', 'Fruit', 'Beverage']));
    meals.add(_pickMeal('Lunch', lunchCal, filteredFoods, ['Lunch']));
    meals.add(_pickMeal('Snack', snackCal, filteredFoods, ['Snack', 'Fruit']));
    meals.add(_pickMeal('Dinner', dinnerCal, filteredFoods, ['Dinner', 'Lunch']));

    return meals;
  }

  static Map<String, dynamic> _pickMeal(
    String mealType,
    int targetCalories,
    List<Map<String, dynamic>> foods,
    List<String> preferredCategories,
  ) {
    // Filter foods by preferred categories
    var candidates = foods.where((f) {
      return preferredCategories.contains(f['category']);
    }).toList();

    if (candidates.isEmpty) candidates = foods;

    // Find foods that fit within target
    List<Map<String, dynamic>> selectedFoods = [];
    int remainingCal = targetCalories;

    for (var food in candidates) {
      if (remainingCal <= 50) break;

      final int calPer100g = food['calories_per_100g'] ?? 0;
      final int defaultServing = food['default_serving_g'] ?? 100;
      final int servingCal = ((calPer100g * defaultServing) / 100).round();

      if (servingCal > 0 && servingCal <= remainingCal + 50) {
        selectedFoods.add({
          'name': food['name'],
          'serving_g': defaultServing,
          'calories': servingCal,
          'category': food['category'],
        });
        remainingCal -= servingCal;

        if (selectedFoods.length >= 3) break;
      }
    }

    return {
      'meal_type': mealType,
      'target_calories': targetCalories,
      'foods': selectedFoods,
    };
  }

  static bool _isNonVeg(String foodName) {
    final nonVegKeywords = [
      'chicken', 'egg', 'salmon', 'fish', 'meat', 'beef',
      'pork', 'biryani', 'scrambled',
    ];
    final lower = foodName.toLowerCase();
    return nonVegKeywords.any((k) => lower.contains(k));
  }

  // ═══════════════════════════════════════════════
  //  EXERCISE PLAN GENERATOR
  // ═══════════════════════════════════════════════

  static List<Map<String, dynamic>> _generateExercisePlan({
    required String goalType,
  }) {
    if (goalType == 'weight_loss') {
      return [
        {'name': 'Brisk Walking', 'duration': '30 min', 'frequency': 'Daily', 'type': 'Cardio', 'calories_burned': 150},
        {'name': 'Jogging', 'duration': '20 min', 'frequency': '4x/week', 'type': 'Cardio', 'calories_burned': 200},
        {'name': 'Jump Rope', 'duration': '15 min', 'frequency': '3x/week', 'type': 'HIIT', 'calories_burned': 180},
        {'name': 'Cycling', 'duration': '30 min', 'frequency': '3x/week', 'type': 'Cardio', 'calories_burned': 250},
        {'name': 'Bodyweight Squats', 'duration': '15 min', 'frequency': '3x/week', 'type': 'Strength', 'calories_burned': 100},
        {'name': 'Plank Hold', 'duration': '5 min', 'frequency': 'Daily', 'type': 'Core', 'calories_burned': 30},
      ];
    } else {
      return [
        {'name': 'Push-ups', 'duration': '15 min', 'frequency': '4x/week', 'type': 'Strength', 'calories_burned': 80},
        {'name': 'Squats with Weight', 'duration': '20 min', 'frequency': '3x/week', 'type': 'Strength', 'calories_burned': 120},
        {'name': 'Deadlifts', 'duration': '20 min', 'frequency': '3x/week', 'type': 'Strength', 'calories_burned': 130},
        {'name': 'Bench Press', 'duration': '20 min', 'frequency': '3x/week', 'type': 'Strength', 'calories_burned': 110},
        {'name': 'Pull-ups', 'duration': '10 min', 'frequency': '3x/week', 'type': 'Strength', 'calories_burned': 90},
        {'name': 'Light Walking', 'duration': '15 min', 'frequency': 'Daily', 'type': 'Recovery', 'calories_burned': 60},
      ];
    }
  }

  // ═══════════════════════════════════════════════
  //  PLAN ADHERENCE
  // ═══════════════════════════════════════════════

  /// Calculate plan adherence score (0-100)
  static Future<int> calculateAdherenceScore() async {
    try {
      final plan = await getActivePlan();
      if (plan == null) return 0;

      final int target = plan['calorie_target'] ?? 2000;
      final entries = await FoodService.getTodayEntries();
      final totals = FoodService.calculateDailyTotals(entries);
      final int consumed = totals['calories'] ?? 0;

      if (consumed == 0) return 0;

      final double ratio = consumed / target;

      // Perfect adherence = within 10% of target
      if (ratio >= 0.9 && ratio <= 1.1) return 100;
      if (ratio >= 0.8 && ratio <= 1.2) return 80;
      if (ratio >= 0.7 && ratio <= 1.3) return 60;
      if (ratio >= 0.5) return 40;
      return 20;
    } catch (e) {
      return 0;
    }
  }

  /// Get plan feedback message
  static Future<String> getPlanFeedback() async {
    final plan = await getActivePlan();
    if (plan == null) return "No active plan. Create one to get started!";

    final int target = plan['calorie_target'] ?? 2000;
    final entries = await FoodService.getTodayEntries();
    final totals = FoodService.calculateDailyTotals(entries);
    final int consumed = totals['calories'] ?? 0;

    if (consumed == 0) return "Start logging food to track your plan!";

    final int diff = consumed - target;

    if (diff.abs() <= target * 0.1) {
      return "🎯 You are following your plan perfectly!";
    } else if (diff > 0) {
      return "⚠️ You exceeded your target by $diff kcal. Go easy on the next meal.";
    } else {
      return "📊 You have ${diff.abs()} kcal remaining for today.";
    }
  }
}
