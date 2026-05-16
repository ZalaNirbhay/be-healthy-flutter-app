import 'package:flutter/material.dart';
import 'package:be_healthy/services/auth_service.dart';
import 'package:be_healthy/services/theme_service.dart';
import 'package:be_healthy/services/notification_service.dart';
import 'package:be_healthy/services/goal_service.dart';
import 'dart:io';
import 'dashboard.dart';
import 'bmi_calculator.dart';
import 'food_tracker.dart';
import 'progress.dart';
import '../widgets/custom_top_bar.dart';

class ProfileSetting extends StatefulWidget {
  const ProfileSetting({super.key});

  @override
  State<ProfileSetting> createState() => _ProfileSettingState();
}

class _ProfileSettingState extends State<ProfileSetting> {
  int currentIndex = 3;

  // Dynamic user data
  String userName = "";
  String userEmail = "";
  String photoUrl = "";
  bool isLoading = true;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    ThemeService.themeMode.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    ThemeService.themeMode.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadUserData() async {
    try {
      final data = await AuthService.getUserDocument();
      if (data != null && mounted) {
        setState(() {
          userName = data['name'] ?? "";
          userEmail = data['email'] ?? "";
          photoUrl = data['photo_url'] ?? "";
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _uploadImage() async {
    setState(() => isUploading = true);
    final result = await AuthService.uploadProfileImage();
    setState(() => isUploading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      imageCache.clear();
      imageCache.clearLiveImages();
      setState(() => photoUrl = result['photoUrl']);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile image updated!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Upload failed')),
      );
    }
  }

  Future<void> _logout() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    // ThemeService accessed directly
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: ThemeService.pageGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                buildTopBar(context, "Profile Settings"),
                const SizedBox(height: 20),
                buildProfileHeader(),
                const SizedBox(height: 25),
                _buildOptionTile(Icons.person, "Edit Profile", _showEditProfileSheet),
                _buildOptionTile(Icons.track_changes, "Health Goals", _showGoalsSheet),
                _buildOptionTile(Icons.notifications, "Notifications", _showNotificationsSheet),
                _buildDarkModeToggle(),
                const SizedBox(height: 30),
                buildLogoutButton(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: buildBottomNav(context),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  PROFILE HEADER
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget buildProfileHeader() {
    // ThemeService accessed directly
    return Column(
      children: [
        GestureDetector(
          onTap: _uploadImage,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 15),
                  ],
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: ThemeService.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  backgroundImage: photoUrl.isNotEmpty
                      ? (AuthService.isLocalFile(photoUrl)
                          ? FileImage(File(photoUrl))
                          : NetworkImage(photoUrl)) as ImageProvider
                      : null,
                  child: photoUrl.isEmpty
                      ? Icon(Icons.person, size: 55, color: ThemeService.textSecondary)
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: ThemeService.isDark ? Colors.grey.shade800 : Colors.white, width: 2),
                  ),
                  child: isUploading
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        isLoading
            ? const SizedBox(width: 100, child: LinearProgressIndicator(color: Colors.green))
            : Text(userName.isNotEmpty ? userName : "User",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ThemeService.textPrimary)),
        const SizedBox(height: 5),
        isLoading
            ? const SizedBox(width: 150, child: LinearProgressIndicator(color: Colors.green))
            : Text(userEmail.isNotEmpty ? userEmail : "No email",
                style: TextStyle(color: ThemeService.textSecondary)),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text("Premium Member", style: TextStyle(color: Colors.green)),
        ),
      ],
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  OPTION TILES
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildOptionTile(IconData icon, String title, VoidCallback onTap) {
    // ThemeService accessed directly
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ThemeService.cardColor,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.green.withOpacity(0.2),
              child: Icon(icon, color: Colors.green),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: ThemeService.textPrimary)),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: ThemeService.textSecondary),
          ],
        ),
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  DARK MODE TOGGLE â€” Now functional
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildDarkModeToggle() {
    // ThemeService accessed directly
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ThemeService.cardColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: ThemeService.isDark ? Colors.yellow.shade700 : Colors.black87,
            child: Icon(ThemeService.isDark ? Icons.light_mode : Icons.dark_mode, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text("Dark Mode",
                style: TextStyle(fontSize: 16, color: ThemeService.textPrimary)),
          ),
          Switch(
            value: ThemeService.isDark,
            activeColor: Colors.green,
            onChanged: (value) {
              ThemeService.setDarkMode(value);
            },
          ),
        ],
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  EDIT PROFILE SHEET
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  void _showEditProfileSheet() async {
    final data = await AuthService.getUserDocument();
    if (data == null || !mounted) return;

    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final ageCtrl = TextEditingController(text: '${data['age'] ?? ''}');
    final heightCtrl = TextEditingController(text: '${data['height_cm'] ?? ''}');
    final weightCtrl = TextEditingController(text: '${data['weight_kg'] ?? ''}');

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: ThemeService.isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5FFF8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                Text("Edit Profile",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ThemeService.textPrimary)),
                const SizedBox(height: 20),
                _buildField("Name", nameCtrl),
                _buildField("Age", ageCtrl, isNumber: true),
                _buildField("Height (cm)", heightCtrl, isNumber: true),
                _buildField("Weight (kg)", weightCtrl, isNumber: true),
                // Email shown but not editable
                Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: ThemeService.cardColorLight,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.email, color: ThemeService.textSecondary),
                      const SizedBox(width: 10),
                      Text(data['email'] ?? '', style: TextStyle(color: ThemeService.textSecondary)),
                      const Spacer(),
                      Icon(Icons.lock, size: 16, color: ThemeService.textSecondary),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final updates = <String, dynamic>{};
                      if (nameCtrl.text.isNotEmpty) updates['name'] = nameCtrl.text;
                      if (ageCtrl.text.isNotEmpty) updates['age'] = int.tryParse(ageCtrl.text);
                      if (heightCtrl.text.isNotEmpty) updates['height_cm'] = double.tryParse(heightCtrl.text);
                      if (weightCtrl.text.isNotEmpty) updates['weight_kg'] = double.tryParse(weightCtrl.text);
                      updates.removeWhere((k, v) => v == null);

                      if (updates.isNotEmpty) {
                        await AuthService.updateUserDocument(updates);
                        if (mounted) {
                          setState(() {
                            userName = updates['name'] ?? userName;
                          });
                        }
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: const Text("Save Changes", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {bool isNumber = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: TextStyle(color: ThemeService.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: ThemeService.textSecondary),
          filled: true,
          fillColor: ThemeService.cardColorLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  HEALTH GOALS SHEET
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  void _showGoalsSheet() async {
    final goals = await GoalService.getGoals();
    if (!mounted) return;

    String selectedGoal = goals['goal'] ?? 'maintain';
    final targetWeightCtrl = TextEditingController(text: '${goals['target_weight'] ?? ''}');
    final calorieCtrl = TextEditingController(text: '${goals['daily_calorie_target'] ?? ''}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: BoxDecoration(
            color: ThemeService.isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5FFF8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 16),
                  Text("Health Goals",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ThemeService.textPrimary)),
                  const SizedBox(height: 20),
                  Text("Goal Type", style: TextStyle(color: ThemeService.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: ['weight_loss', 'maintain', 'weight_gain'].map((g) {
                      final isSelected = selectedGoal == g;
                      final label = g == 'weight_loss' ? 'Lose' : g == 'weight_gain' ? 'Gain' : 'Maintain';
                      return Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            setSheetState(() => selectedGoal = g);
                            final rec = await GoalService.calculateRecommendedCalories(g);
                            setSheetState(() => calorieCtrl.text = '$rec');
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.green : ThemeService.cardColorLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(label,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : ThemeService.textPrimary,
                                    fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  _buildField("Target Weight (kg)", targetWeightCtrl, isNumber: true),
                  _buildField("Daily Calorie Target", calorieCtrl, isNumber: true),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        await GoalService.updateGoals(
                          goal: selectedGoal,
                          targetWeight: double.tryParse(targetWeightCtrl.text),
                          dailyCalorieTarget: int.tryParse(calorieCtrl.text),
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text("Save Goals", style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  NOTIFICATIONS SHEET
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  void _showNotificationsSheet() async {
    final notifications = await NotificationService.getNotifications();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: ThemeService.isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5FFF8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Notifications",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ThemeService.textPrimary)),
                  TextButton(
                    onPressed: () async {
                      await NotificationService.markAllAsRead();
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text("Mark all read", style: TextStyle(color: Colors.green)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: notifications.isEmpty
                  ? Center(child: Text("No notifications yet",
                      style: TextStyle(color: ThemeService.textSecondary)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notif = notifications[index];
                        final isRead = notif['is_read'] ?? false;
                        final type = notif['type'] ?? 'info';
                        final icon = type == 'reminder' ? Icons.alarm
                            : type == 'alert' ? Icons.warning_amber
                            : type == 'achievement' ? Icons.star
                            : Icons.lightbulb_outline;
                        final color = type == 'alert' ? Colors.orange
                            : type == 'achievement' ? Colors.amber
                            : type == 'reminder' ? Colors.blue
                            : Colors.green;

                        return GestureDetector(
                          onTap: () {
                            if (!isRead) {
                              NotificationService.markAsRead(notif['id']);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isRead
                                  ? ThemeService.cardColorLight
                                  : color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: isRead ? null : Border.all(color: color.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: color.withOpacity(0.2),
                                  child: Icon(icon, color: color, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(notif['title'] ?? '',
                                          style: TextStyle(
                                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                            color: ThemeService.textPrimary)),
                                      const SizedBox(height: 2),
                                      Text(notif['message'] ?? '',
                                          style: TextStyle(fontSize: 12, color: ThemeService.textSecondary)),
                                    ],
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8, height: 8,
                                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  LOGOUT BUTTON
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: const Text("Logout", style: TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  BOTTOM NAV
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 4,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      backgroundColor: ThemeService.isDark ? const Color(0xFF1A1A2E) : Colors.white,
      onTap: (index) {
        if (index == 4) return;
        if (index == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Dashboard()));
        if (index == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BmiCalculator()));
        if (index == 2) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FoodTracker()));
        if (index == 3) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const progress()));
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.monitor_weight), label: "BMI"),
        BottomNavigationBarItem(icon: Icon(Icons.local_fire_department), label: "Calories"),
        BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: "Progress"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}
