import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'bmi_calculator.dart';
import 'food_tracker.dart';
import 'profile_setting.dart';
import '../widgets/custom_top_bar.dart';

class progress extends StatefulWidget {
  const progress({super.key});

  @override
  State<progress> createState() => _progressState();
}

class _progressState extends State<progress> {
  int selectedTab = 0;
  int currentIndex = 2;

  List<String> tabs = ["Weight", "BMI", "Calories"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFDFF5EA), Color(0xFF6FCF97)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildTopBar(context, "Progress"),
                const SizedBox(height: 20),

                buildTabs(),

                const SizedBox(height: 20),

                buildProgressCard(),

                const SizedBox(height: 25),

                const Text(
                  "Activity Log",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                buildActivityItem(
                  Icons.water_drop,
                  "Logged 500ml Water",
                  "Today, 10:30 AM",
                  Colors.blue,
                ),

                buildActivityItem(
                  Icons.monitor_weight,
                  "Updated Weight: 70kg",
                  "Today, 8:00 AM",
                  Colors.green,
                ),

                buildActivityItem(
                  Icons.directions_walk,
                  "Goal Completed: 10k Steps",
                  "Yesterday, 6:45 PM",
                  Colors.orange,
                ),

                buildActivityItem(
                  Icons.restaurant,
                  "Logged Lunch: 650 kcal",
                  "Yesterday, 1:15 PM",
                  Colors.purple,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: buildBottomNav(context),
    );
  }

  // Top Bar removed, moved to custom_top_bar.dart

  // 🔹 TABS
  Widget buildTabs() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
      ),

      child: Row(
        children: List.generate(tabs.length, (index) {
          bool isSelected = selectedTab == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedTab = index;
                });
              },

              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),

                child: Center(
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      color: isSelected ? Colors.green : Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // 🔹 PROGRESS CARD
  Widget buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(25),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "WEEKLY PROGRESS",
            style: TextStyle(color: Colors.black54),
          ),

          const SizedBox(height: 10),

          const Text(
            "Current: 70kg",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            "-1.5kg this week",
            style: TextStyle(color: Colors.green),
          ),

          const SizedBox(height: 20),

          // Fake Graph
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Colors.green, Colors.teal],
              ),
            ),
          ),

          const SizedBox(height: 10),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Mon"),
              Text("Tue"),
              Text("Wed"),
              Text("Thu"),
              Text("Fri"),
              Text("Sat"),
              Text("Sun"),
            ],
          )
        ],
      ),
    );
  }

  // 🔹 ACTIVITY ITEM
  Widget buildActivityItem(
      IconData icon, String title, String time, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        children: [

          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(time, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),

          const Icon(Icons.arrow_forward_ios, size: 14),
        ],
      ),
    );
  }

  // 🔹 BOTTOM NAV
  Widget buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 3, // Progress is index 3
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,

      onTap: (index) {
        if (index == 3) return;
        if (index == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Dashboard()));
        if (index == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BmiCalculator()));
        if (index == 2) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FoodTracker()));
        if (index == 4) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileSetting()));
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