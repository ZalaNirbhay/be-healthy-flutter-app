import 'package:flutter/material.dart';

class ProfileSetting extends StatefulWidget {
  const ProfileSetting({super.key});

  @override
  State<ProfileSetting> createState() => _ProfileSettingState();
}

class _ProfileSettingState extends State<ProfileSetting> {
  bool isDarkMode = false;
  int currentIndex = 3;

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

                buildTopBar(),

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

      bottomNavigationBar: buildBottomNav(),
    );
  }

  // 🔹 TOP BAR
  Widget buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [

        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back),
        ),

        const Text(
          "Profile & Settings",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(width: 30),
      ],
    );
  }

  // 🔹 PROFILE HEADER
  Widget buildProfileHeader() {
    return Column(
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
          child: const CircleAvatar(
            radius: 55,
            backgroundImage: AssetImage("assets/images/profile1.jpg"),
          ),
        ),

        const SizedBox(height: 15),

        const Text(
          "Zala Nirbhay",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          "nirbhay.zala@example.com",
          style: TextStyle(color: Colors.black54),
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

  // 🔹 LOGOUT BUTTON
  Widget buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,

      child: ElevatedButton(
        onPressed: () {},

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
  Widget buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: Colors.green,

      onTap: (index) {
        setState(() {
          currentIndex = index;
        });
      },

      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: "Workouts"),
        BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: "Progress"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}