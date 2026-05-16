import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Notification Service — Smart auto-generated notifications + CRUD
///
/// STORAGE: notifications/{uid}/items/{notificationId}
///
/// Auto-generates contextual notifications based on user activity.
/// Fetches, marks as read, and provides unread count.
class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> _userNotifications() {
    final uid = _auth.currentUser!.uid;
    return _firestore
        .collection('notifications')
        .doc(uid)
        .collection('items');
  }

  // ═══════════════════════════════════════════════
  //  FETCH
  // ═══════════════════════════════════════════════

  /// Get all notifications (newest first)
  static Future<List<Map<String, dynamic>>> getNotifications({int limit = 20}) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return [];

      final snapshot = await _userNotifications()
          .orderBy('created_at', descending: true)
          .limit(limit)
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

  /// Get unread count
  static Future<int> getUnreadCount() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return 0;

      final snapshot = await _userNotifications()
          .where('is_read', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // ═══════════════════════════════════════════════
  //  ACTIONS
  // ═══════════════════════════════════════════════

  /// Mark a notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _userNotifications().doc(notificationId).update({'is_read': true});
    } catch (_) {}
  }

  /// Mark all as read
  static Future<void> markAllAsRead() async {
    try {
      final unread = await _userNotifications()
          .where('is_read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in unread.docs) {
        batch.update(doc.reference, {'is_read': true});
      }
      if (unread.docs.isNotEmpty) await batch.commit();
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════
  //  CREATE NOTIFICATION
  // ═══════════════════════════════════════════════

  /// Create a notification
  static Future<void> create({
    required String title,
    required String message,
    required String type, // 'reminder', 'alert', 'suggestion', 'achievement'
  }) async {
    try {
      await _userNotifications().add({
        'title': title,
        'message': message,
        'type': type,
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════
  //  SMART AUTO-GENERATION
  // ═══════════════════════════════════════════════

  /// Generate smart notifications based on daily data
  /// Call this from Dashboard once per session
  static Future<void> generateSmartNotifications({
    required int consumed,
    required int target,
    required int waterMl,
    required int waterGoal,
    required int healthScore,
    required int protein,
    required List<Map<String, dynamic>> foodEntries,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      // Get today's date key to avoid duplicate notifications
      final now = DateTime.now();
      final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Check if we already generated today's notifications
      final existing = await _userNotifications()
          .where('date_key', isEqualTo: dateKey)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) return;

      // Generate contextual notifications
      List<Map<String, dynamic>> notifications = [];

      // Morning reminder if no food logged by afternoon
      if (now.hour >= 12 && foodEntries.isEmpty) {
        notifications.add({
          'title': 'Don\'t forget to eat!',
          'message': 'You haven\'t logged any food today. Start tracking to stay on goal.',
          'type': 'reminder',
        });
      }

      // Water reminder
      if (now.hour >= 10 && waterMl < waterGoal * 0.3) {
        notifications.add({
          'title': 'Stay Hydrated',
          'message': 'You\'ve only had ${_formatWater(waterMl)} water today. Your goal is ${_formatWater(waterGoal)}.',
          'type': 'reminder',
        });
      }

      // Calorie overshoot
      if (consumed > target * 1.15 && target > 0) {
        notifications.add({
          'title': 'Calorie Alert',
          'message': 'You\'ve exceeded your daily calorie target by ${consumed - target} kcal.',
          'type': 'alert',
        });
      }

      // Low protein
      if (protein < 25 && foodEntries.length >= 2) {
        notifications.add({
          'title': 'Protein Suggestion',
          'message': 'Your protein is only ${protein}g today. Add eggs, chicken, or yogurt for better recovery.',
          'type': 'suggestion',
        });
      }

      // Health score achievement
      if (healthScore >= 80) {
        notifications.add({
          'title': 'Great Day! 🌟',
          'message': 'Your health score is $healthScore/100 today. Keep up the amazing work!',
          'type': 'achievement',
        });
      }

      // Save notifications
      final batch = _firestore.batch();
      for (var notif in notifications) {
        batch.set(_userNotifications().doc(), {
          ...notif,
          'is_read': false,
          'date_key': dateKey,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      if (notifications.isNotEmpty) await batch.commit();
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════
  //  WELCOME NOTIFICATION
  // ═══════════════════════════════════════════════

  /// Create a welcome notification for new users
  static Future<void> createWelcome() async {
    await create(
      title: 'Welcome to BeHealth! 🎉',
      message: 'Start your health journey by logging your first meal and water intake.',
      type: 'suggestion',
    );
  }

  static String _formatWater(int ml) {
    if (ml >= 1000) return '${(ml / 1000).toStringAsFixed(1)}L';
    return '${ml}ml';
  }
}
