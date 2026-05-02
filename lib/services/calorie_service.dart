import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalorieService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Activity level multipliers for TDEE calculation
  static const Map<String, double> _activityMultipliers = {
    // Profile setup values
    'Sedentary': 1.2,
    'Light Exercise': 1.375,
    'Moderate Exercise': 1.55,
    'Heavy Exercise': 1.725,
    'Athlete': 1.9,
    // Maintenance calories page dropdown values
    'Sedentary (little or no exercise)': 1.2,
    'Lightly Active (1-3 days/week)': 1.375,
    'Moderately Active (3-5 days/week)': 1.55,
    'Very Active (6-7 days/week)': 1.725,
    'Athlete (2x training)': 1.9,
  };

  /// Fetch user profile data from Firestore
  static Future<Map<String, dynamic>?> _getUserData() async {
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

  /// Calculate BMR using Mifflin-St Jeor equation
  static double calculateBMR({
    required double weight,
    required double height,
    required int age,
    required String gender,
  }) {
    if (gender.toLowerCase() == 'male') {
      return 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      return 10 * weight + 6.25 * height - 5 * age - 161;
    }
  }

  /// Get activity multiplier from string
  static double getMultiplier(String activityLevel) {
    return _activityMultipliers[activityLevel] ?? 1.55; // Default moderate
  }

  /// Calculate TDEE (maintenance calories)
  static double calculateTDEE({
    required double bmr,
    required String activityLevel,
  }) {
    return bmr * getMultiplier(activityLevel);
  }

  /// Full calculation from Firestore user data
  /// Returns: {tdee, bmr, weight_loss, weight_gain, activity_level}
  static Future<Map<String, dynamic>> calculateFromProfile({
    String? overrideActivityLevel,
  }) async {
    try {
      final userData = await _getUserData();

      if (userData == null) {
        return {'success': false, 'message': 'User data not found'};
      }

      // Extract and validate fields
      final age = userData['age'];
      final gender = userData['gender'];
      final heightCm = userData['height_cm'];
      final weightKg = userData['weight_kg'];
      final activityLevel = overrideActivityLevel ?? userData['activity_level'];

      if (age == null || gender == null || heightCm == null || weightKg == null) {
        return {
          'success': false,
          'message': 'Please complete your profile setup first',
        };
      }

      // Convert to required types
      final double weight = (weightKg is int) ? weightKg.toDouble() : weightKg;
      final double height = (heightCm is int) ? heightCm.toDouble() : heightCm;
      final int ageVal = (age is double) ? age.toInt() : age;

      // Step 1: BMR
      final double bmr = calculateBMR(
        weight: weight,
        height: height,
        age: ageVal,
        gender: gender,
      );

      // Step 2: TDEE
      final double tdee = calculateTDEE(
        bmr: bmr,
        activityLevel: activityLevel ?? 'Moderate Exercise',
      );

      // Step 3: Derived values
      final double weightLoss = tdee - 500;
      final double weightGain = tdee + 500;

      return {
        'success': true,
        'bmr': bmr.round(),
        'tdee': tdee.round(),
        'weight_loss_calories': weightLoss.round(),
        'weight_gain_calories': weightGain.round(),
        'activity_level': activityLevel,
      };
    } catch (e) {
      return {'success': false, 'message': 'Calculation failed'};
    }
  }

  /// Save calculation to history (optional tracking)
  static Future<void> saveCalculationHistory({
    required int tdee,
    required String type,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      await _firestore.collection('calculation_history').add({
        'user_id': uid,
        'type': type,
        'result': tdee,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Silent fail — history is optional
    }
  }

  /// Map the maintain_calories dropdown value to profile activity_level
  static String mapDropdownToProfileLevel(String dropdownValue) {
    const mapping = {
      'Sedentary (little or no exercise)': 'Sedentary',
      'Lightly Active (1-3 days/week)': 'Light Exercise',
      'Moderately Active (3-5 days/week)': 'Moderate Exercise',
      'Very Active (6-7 days/week)': 'Heavy Exercise',
      'Athlete (2x training)': 'Athlete',
    };
    return mapping[dropdownValue] ?? dropdownValue;
  }
}
