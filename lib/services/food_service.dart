import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Industry-level Food Tracking Service
///
/// DATABASE DESIGN:
///
/// 1. `food_items` (global collection — shared food database)
///    - Flat structure, one document per food item
///    - Searchable by name (case-insensitive via search_name)
///    - Contains nutrition per 100g for scalable quantity calculation
///
/// 2. `food_logs/{userId}/daily/{date}` (per-user daily logs)
///    - Sub-collection `entries` holds individual food entries
///    - Each entry = one food consumed at a specific meal
///    - Daily totals computed dynamically from entries (no stale data)
///
/// DESIGN JUSTIFICATION:
/// - `food_items` is global (not per-user) → scalable for future admin panel
/// - Per-100g storage → allows any quantity calculation
/// - Daily sub-collection → efficient queries (only fetch today's data)
/// - No redundant summary doc → totals computed from entries (always accurate)
/// - search_name field → enables case-insensitive prefix search
class FoodService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── Date Helper ───
  static String _todayDateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ═══════════════════════════════════════════════
  //  FOOD ITEMS DATABASE
  // ═══════════════════════════════════════════════

  /// Seed initial food items (call once or from admin)
  static Future<void> seedFoodDatabase() async {
    final collection = _firestore.collection('food_items');

    // Check if already seeded
    final existing = await collection.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _firestore.batch();

    final foods = [
      // Breakfast Items
      {'name': 'Oatmeal', 'category': 'Breakfast', 'calories_per_100g': 68, 'protein_per_100g': 2.4, 'carbs_per_100g': 12.0, 'fat_per_100g': 1.4, 'default_serving_g': 250, 'icon': 'free_breakfast'},
      {'name': 'Scrambled Eggs', 'category': 'Breakfast', 'calories_per_100g': 149, 'protein_per_100g': 10.0, 'carbs_per_100g': 1.6, 'fat_per_100g': 11.0, 'default_serving_g': 150, 'icon': 'egg'},
      {'name': 'Whole Wheat Toast', 'category': 'Breakfast', 'calories_per_100g': 247, 'protein_per_100g': 13.0, 'carbs_per_100g': 41.0, 'fat_per_100g': 3.4, 'default_serving_g': 60, 'icon': 'bakery_dining'},
      {'name': 'Banana', 'category': 'Fruit', 'calories_per_100g': 89, 'protein_per_100g': 1.1, 'carbs_per_100g': 23.0, 'fat_per_100g': 0.3, 'default_serving_g': 120, 'icon': 'nutrition'},
      {'name': 'Black Coffee', 'category': 'Beverage', 'calories_per_100g': 1, 'protein_per_100g': 0.1, 'carbs_per_100g': 0.0, 'fat_per_100g': 0.0, 'default_serving_g': 240, 'icon': 'coffee'},

      // Lunch Items
      {'name': 'Grilled Chicken Breast', 'category': 'Lunch', 'calories_per_100g': 165, 'protein_per_100g': 31.0, 'carbs_per_100g': 0.0, 'fat_per_100g': 3.6, 'default_serving_g': 200, 'icon': 'lunch_dining'},
      {'name': 'Brown Rice', 'category': 'Lunch', 'calories_per_100g': 112, 'protein_per_100g': 2.3, 'carbs_per_100g': 24.0, 'fat_per_100g': 0.8, 'default_serving_g': 200, 'icon': 'rice_bowl'},
      {'name': 'Caesar Salad', 'category': 'Lunch', 'calories_per_100g': 127, 'protein_per_100g': 4.6, 'carbs_per_100g': 7.0, 'fat_per_100g': 9.3, 'default_serving_g': 250, 'icon': 'eco'},
      {'name': 'Grilled Chicken Salad', 'category': 'Lunch', 'calories_per_100g': 110, 'protein_per_100g': 14.0, 'carbs_per_100g': 5.0, 'fat_per_100g': 4.0, 'default_serving_g': 300, 'icon': 'lunch_dining'},
      {'name': 'Dal (Lentils)', 'category': 'Lunch', 'calories_per_100g': 116, 'protein_per_100g': 9.0, 'carbs_per_100g': 20.0, 'fat_per_100g': 0.4, 'default_serving_g': 200, 'icon': 'soup_kitchen'},
      {'name': 'Roti (Chapati)', 'category': 'Lunch', 'calories_per_100g': 297, 'protein_per_100g': 9.0, 'carbs_per_100g': 50.0, 'fat_per_100g': 7.5, 'default_serving_g': 40, 'icon': 'bakery_dining'},

      // Snack Items
      {'name': 'Greek Yogurt', 'category': 'Snack', 'calories_per_100g': 59, 'protein_per_100g': 10.0, 'carbs_per_100g': 3.6, 'fat_per_100g': 0.7, 'default_serving_g': 200, 'icon': 'icecream'},
      {'name': 'Almonds', 'category': 'Snack', 'calories_per_100g': 579, 'protein_per_100g': 21.0, 'carbs_per_100g': 22.0, 'fat_per_100g': 50.0, 'default_serving_g': 30, 'icon': 'nutrition'},
      {'name': 'Apple', 'category': 'Fruit', 'calories_per_100g': 52, 'protein_per_100g': 0.3, 'carbs_per_100g': 14.0, 'fat_per_100g': 0.2, 'default_serving_g': 180, 'icon': 'nutrition'},
      {'name': 'Protein Bar', 'category': 'Snack', 'calories_per_100g': 350, 'protein_per_100g': 20.0, 'carbs_per_100g': 40.0, 'fat_per_100g': 12.0, 'default_serving_g': 60, 'icon': 'fastfood'},
      {'name': 'Mixed Berries', 'category': 'Fruit', 'calories_per_100g': 57, 'protein_per_100g': 1.0, 'carbs_per_100g': 14.0, 'fat_per_100g': 0.3, 'default_serving_g': 150, 'icon': 'nutrition'},

      // Dinner Items
      {'name': 'Salmon Fillet', 'category': 'Dinner', 'calories_per_100g': 208, 'protein_per_100g': 20.0, 'carbs_per_100g': 0.0, 'fat_per_100g': 13.0, 'default_serving_g': 200, 'icon': 'set_meal'},
      {'name': 'Pasta (Cooked)', 'category': 'Dinner', 'calories_per_100g': 131, 'protein_per_100g': 5.0, 'carbs_per_100g': 25.0, 'fat_per_100g': 1.1, 'default_serving_g': 250, 'icon': 'dinner_dining'},
      {'name': 'Paneer (Cottage Cheese)', 'category': 'Dinner', 'calories_per_100g': 265, 'protein_per_100g': 18.0, 'carbs_per_100g': 1.2, 'fat_per_100g': 21.0, 'default_serving_g': 100, 'icon': 'dinner_dining'},
      {'name': 'Steamed Vegetables', 'category': 'Dinner', 'calories_per_100g': 35, 'protein_per_100g': 2.0, 'carbs_per_100g': 7.0, 'fat_per_100g': 0.3, 'default_serving_g': 200, 'icon': 'eco'},

      // Beverages
      {'name': 'Milk (Whole)', 'category': 'Beverage', 'calories_per_100g': 61, 'protein_per_100g': 3.2, 'carbs_per_100g': 4.8, 'fat_per_100g': 3.3, 'default_serving_g': 250, 'icon': 'local_drink'},
      {'name': 'Orange Juice', 'category': 'Beverage', 'calories_per_100g': 45, 'protein_per_100g': 0.7, 'carbs_per_100g': 10.0, 'fat_per_100g': 0.2, 'default_serving_g': 250, 'icon': 'local_drink'},
      {'name': 'Protein Shake', 'category': 'Beverage', 'calories_per_100g': 80, 'protein_per_100g': 15.0, 'carbs_per_100g': 3.0, 'fat_per_100g': 1.0, 'default_serving_g': 300, 'icon': 'local_drink'},
      {'name': 'Green Tea', 'category': 'Beverage', 'calories_per_100g': 1, 'protein_per_100g': 0.0, 'carbs_per_100g': 0.0, 'fat_per_100g': 0.0, 'default_serving_g': 240, 'icon': 'coffee'},

      // Common Indian Foods
      {'name': 'Chicken Biryani', 'category': 'Lunch', 'calories_per_100g': 150, 'protein_per_100g': 7.0, 'carbs_per_100g': 18.0, 'fat_per_100g': 5.0, 'default_serving_g': 350, 'icon': 'rice_bowl'},
      {'name': 'Idli', 'category': 'Breakfast', 'calories_per_100g': 58, 'protein_per_100g': 2.0, 'carbs_per_100g': 12.0, 'fat_per_100g': 0.2, 'default_serving_g': 120, 'icon': 'bakery_dining'},
      {'name': 'Dosa', 'category': 'Breakfast', 'calories_per_100g': 168, 'protein_per_100g': 4.0, 'carbs_per_100g': 26.0, 'fat_per_100g': 5.0, 'default_serving_g': 100, 'icon': 'bakery_dining'},
      {'name': 'Poha', 'category': 'Breakfast', 'calories_per_100g': 130, 'protein_per_100g': 2.5, 'carbs_per_100g': 22.0, 'fat_per_100g': 3.5, 'default_serving_g': 200, 'icon': 'rice_bowl'},
      {'name': 'Rajma (Kidney Beans)', 'category': 'Lunch', 'calories_per_100g': 127, 'protein_per_100g': 8.7, 'carbs_per_100g': 22.0, 'fat_per_100g': 0.5, 'default_serving_g': 200, 'icon': 'soup_kitchen'},
      {'name': 'White Rice', 'category': 'Lunch', 'calories_per_100g': 130, 'protein_per_100g': 2.7, 'carbs_per_100g': 28.0, 'fat_per_100g': 0.3, 'default_serving_g': 200, 'icon': 'rice_bowl'},
    ];

    for (var food in foods) {
      final docRef = collection.doc();
      batch.set(docRef, {
        ...food,
        'search_name': (food['name'] as String).toLowerCase(),
        'created_at': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// Search food items by name (case-insensitive prefix search)
  static Future<List<Map<String, dynamic>>> searchFoodItems(String query) async {
    try {
      if (query.trim().isEmpty) {
        // Return all items (limited)
        final snapshot = await _firestore
            .collection('food_items')
            .orderBy('name')
            .limit(30)
            .get();

        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      }

      final searchTerm = query.toLowerCase().trim();
      final snapshot = await _firestore
          .collection('food_items')
          .where('search_name', isGreaterThanOrEqualTo: searchTerm)
          .where('search_name', isLessThanOrEqualTo: '$searchTerm\uf8ff')
          .limit(20)
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

  /// Get food items grouped by category
  static Future<Map<String, List<Map<String, dynamic>>>> getFoodsByCategory() async {
    try {
      final snapshot = await _firestore
          .collection('food_items')
          .orderBy('category')
          .get();

      Map<String, List<Map<String, dynamic>>> grouped = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final category = data['category'] ?? 'Other';

        grouped.putIfAbsent(category, () => []);
        grouped[category]!.add(data);
      }

      return grouped;
    } catch (e) {
      return {};
    }
  }

  // ═══════════════════════════════════════════════
  //  NUTRITION CALCULATION ENGINE
  // ═══════════════════════════════════════════════

  /// Calculate nutrition for a given quantity
  static Map<String, int> calculateNutrition(
      Map<String, dynamic> foodItem, int quantityGrams) {
    final double factor = quantityGrams / 100.0;

    return {
      'calories': ((foodItem['calories_per_100g'] ?? 0) * factor).round(),
      'protein': ((foodItem['protein_per_100g'] ?? 0) * factor).round(),
      'carbs': ((foodItem['carbs_per_100g'] ?? 0) * factor).round(),
      'fat': ((foodItem['fat_per_100g'] ?? 0) * factor).round(),
    };
  }

  // ═══════════════════════════════════════════════
  //  FOOD LOG OPERATIONS
  // ═══════════════════════════════════════════════

  /// Add a food entry to today's log
  static Future<Map<String, dynamic>> addFoodEntry({
    required String foodName,
    required String mealType,
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    required int quantityGrams,
    String? foodItemId,
    String iconName = 'fastfood',
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final dateKey = _todayDateKey();

      await _firestore
          .collection('food_logs')
          .doc(uid)
          .collection('daily')
          .doc(dateKey)
          .collection('entries')
          .add({
        'food_name': foodName,
        'meal_type': mealType,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'quantity_grams': quantityGrams,
        'food_item_id': foodItemId,
        'icon': iconName,
        'created_at': FieldValue.serverTimestamp(),
      });

      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': 'Failed to save food entry'};
    }
  }

  /// Quick add food entry (custom food with just name + calories)
  static Future<Map<String, dynamic>> quickAddFood({
    required String foodName,
    required int calories,
    String mealType = 'Snack',
  }) async {
    return addFoodEntry(
      foodName: foodName,
      mealType: mealType,
      calories: calories,
      protein: 0,
      carbs: 0,
      fat: 0,
      quantityGrams: 0,
      iconName: 'fastfood',
    );
  }

  /// Get today's food log entries
  static Future<List<Map<String, dynamic>>> getTodayEntries() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return [];

      final dateKey = _todayDateKey();

      final snapshot = await _firestore
          .collection('food_logs')
          .doc(uid)
          .collection('daily')
          .doc(dateKey)
          .collection('entries')
          .orderBy('created_at', descending: false)
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

  /// Delete a food entry
  static Future<bool> deleteEntry(String entryId) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return false;

      final dateKey = _todayDateKey();

      await _firestore
          .collection('food_logs')
          .doc(uid)
          .collection('daily')
          .doc(dateKey)
          .collection('entries')
          .doc(entryId)
          .delete();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Calculate daily totals from entries (computed, not stored)
  static Map<String, int> calculateDailyTotals(
      List<Map<String, dynamic>> entries) {
    int totalCalories = 0;
    int totalProtein = 0;
    int totalCarbs = 0;
    int totalFat = 0;

    for (var entry in entries) {
      totalCalories += (entry['calories'] ?? 0) as int;
      totalProtein += (entry['protein'] ?? 0) as int;
      totalCarbs += (entry['carbs'] ?? 0) as int;
      totalFat += (entry['fat'] ?? 0) as int;
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
    };
  }

  /// Get icon data from icon name string
  static IconData getIconFromName(String? iconName) {
    const iconMap = {
      'free_breakfast': 0xe154,
      'egg': 0xeacc,
      'bakery_dining': 0xea53,
      'nutrition': 0xe532,
      'coffee': 0xefef,
      'lunch_dining': 0xe54a,
      'rice_bowl': 0xf1f5,
      'eco': 0xea35,
      'soup_kitchen': 0xf151,
      'icecream': 0xe2e8,
      'fastfood': 0xe22f,
      'set_meal': 0xf1ef,
      'dinner_dining': 0xea57,
      'local_drink': 0xe389,
    };

    if (iconName == null) return const IconData(0xe22f, fontFamily: 'MaterialIcons');

    final codePoint = iconMap[iconName];
    if (codePoint != null) {
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    }

    return const IconData(0xe22f, fontFamily: 'MaterialIcons'); // fastfood fallback
  }

  /// Get meal type icon
  static IconData getMealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return const IconData(0xe154, fontFamily: 'MaterialIcons'); // free_breakfast
      case 'lunch':
        return const IconData(0xe54a, fontFamily: 'MaterialIcons'); // lunch_dining
      case 'dinner':
        return const IconData(0xea57, fontFamily: 'MaterialIcons'); // dinner_dining
      case 'snack':
        return const IconData(0xe2e8, fontFamily: 'MaterialIcons'); // icecream
      default:
        return const IconData(0xe22f, fontFamily: 'MaterialIcons'); // fastfood
    }
  }
}
