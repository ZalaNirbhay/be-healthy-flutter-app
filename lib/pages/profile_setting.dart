import 'package:flutter/material.dart';
import 'package:be_healthy/services/auth_service.dart';
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
  bool isDarkMode = false;
  int currentIndex = 3;

  // 🔥 Dynamic user data
  String userName = "";
  String userEmail = "";
  String photoUrl = "";
  bool isLoading = true;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 🔥 TASK 3: Fetch user data from Firestore
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
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // 🔥 TASK 5: Upload profile image
  Future<void> _uploadImage() async {
    setState(() => isUploading = true);

    final result = await AuthService.uploadProfileImage();

    setState(() => isUploading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      // Clear Flutter's image cache so the new photo loads immediately
      imageCache.clear();
      imageCache.clearLiveImages();

      setState(() {
        photoUrl = result['photoUrl'];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile image updated!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Upload failed')),
      );
    }
  }

  // 🔥 TASK 8: Logout
  Future<void> _logout() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFDFF5EA), Color(0xFFB7E4C7)],
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

                buildOption(Icons.person, "Edit Profile"),
                buildOption(Icons.track_changes, "Health Goals"),
                buildOption(Icons.notifications, "Notifications"),

                buildDarkModeToggle(),

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

  // 🔹 PROFILE HEADER — Now dynamic with Firestore data
  Widget buildProfileHeader() {
    return Column(
      children: [

        // 🔥 TASK 4: Profile image handling
        GestureDetector(
          onTap: _uploadImage,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: photoUrl.isNotEmpty
                      ? (AuthService.isLocalFile(photoUrl)
                          ? FileImage(File(photoUrl))
                          : NetworkImage(photoUrl)) as ImageProvider
                      : null,
                  child: photoUrl.isEmpty
                      ? const Icon(Icons.person, size: 55, color: Colors.grey)
                      : null,
                ),
              ),

              // Upload indicator / camera icon
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        // 🔥 TASK 3: Dynamic name
        isLoading
            ? const SizedBox(
                width: 100,
                child: LinearProgressIndicator(color: Colors.green),
              )
            : Text(
                userName.isNotEmpty ? userName : "User",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

        const SizedBox(height: 5),

        // 🔥 TASK 3: Dynamic email
        isLoading
            ? const SizedBox(
                width: 150,
                child: LinearProgressIndicator(color: Colors.green),
              )
            : Text(
                userEmail.isNotEmpty ? userEmail : "No email",
                style: const TextStyle(color: Colors.black54),
              ),

        const SizedBox(height: 15),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            "Premium Member",
            style: TextStyle(color: Colors.green),
          ),
        ),
      ],
    );
  }

  // 🔹 OPTION TILE
  Widget buildOption(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
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
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

  // 🔹 DARK MODE
  Widget buildDarkModeToggle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(25),
      ),

      child: Row(
        children: [

          CircleAvatar(
            backgroundColor: Colors.black87,
            child: const Icon(Icons.dark_mode, color: Colors.white),
          ),

          const SizedBox(width: 15),

          const Expanded(
            child: Text(
              "Dark Mode",
              style: TextStyle(fontSize: 16),
            ),
          ),

          Switch(
            value: isDarkMode,
            onChanged: (value) {
              setState(() {
                isDarkMode = value;
              });
            },
          )
        ],
      ),
    );
  }

  // 🔹 LOGOUT BUTTON — Now functional
  Widget buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,

      child: ElevatedButton(
        onPressed: _logout,

        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),

        child: const Text(
          "Logout",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }

  // 🔹 BOTTOM NAV
  Widget buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 4, // Profile is index 4
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,

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