import 'package:flutter/material.dart';
import 'bmi_calculator.dart';
import 'sidebar.dart';
import 'food_tracker.dart';
import 'maintain_calories.dart';
import 'weight_loose.dart';
import 'weight_gain.dart';
import 'progress.dart';
import 'profile_setting.dart';
import '../widgets/custom_top_bar.dart';
import '../services/water_service.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // 🔥 Water tracking state
  int waterTotalMl = 0;
  int waterGoalMl = 3000;
  bool isLoggingWater = false;

  @override
  void initState() {
    super.initState();
    _loadWaterData();
  }

  Future<void> _loadWaterData() async {
    final data = await WaterService.getTodayWaterData();
    if (mounted) {
      setState(() {
        waterTotalMl = data['total_ml'] ?? 0;
        waterGoalMl = data['goal_ml'] ?? 3000;
      });
    }
  }

  Future<void> _logWater() async {
    if (isLoggingWater) return; // Prevent rapid clicks

    setState(() => isLoggingWater = true);

    final result = await WaterService.logWater();

    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          waterTotalMl += 200;
          isLoggingWater = false;
        });
      } else {
        setState(() => isLoggingWater = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to log water')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppSidebar(),
      backgroundColor: Colors.transparent,

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6FCF97), Color(0xFFDFF5EA)],
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
                buildTopBar(context, "BeHealth", isDashboard: true),
                const SizedBox(height: 20),

                const Text(
                  "Welcome Back!",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                _buildProgressCard(),

                const SizedBox(height: 25),

                buildToolsSection(context),

                const SizedBox(height: 25),

                _buildQuickActions(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: buildBottomNav(context),
    );
  }

  // 🔹 PROGRESS CARD — Now with dynamic water data
  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(25),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Daily Progress",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          const Text("BMI and Hydration Tracking"),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [

              buildCircle("22.5", "BMI", Colors.green),

              Container(
                height: 80,
                width: 1,
                color: Colors.white,
              ),

              // 🔥 Dynamic water display
              buildCircle(
                WaterService.formatWater(waterTotalMl),
                "WATER",
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔹 QUICK ACTIONS — Log Water is now functional
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        Row(
          children: [

            // 🔥 Log Water — functional
            Expanded(
              child: GestureDetector(
                onTap: _logWater,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),

                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(30),
                  ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      isLoggingWater
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.blue,
                              ),
                            )
                          : const Icon(Icons.water_drop),
                      const SizedBox(width: 5),
                      const Text("Log Water"),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),
            buildActionChip(Icons.fastfood, "Add Food"),
          ],
        ),
      ],
    );
  }
}

//////////////////// PROGRESS ////////////////////

Widget buildCircle(String value, String label, Color color) {
  return Column(
    children: [

      Container(
        width: 90,
        height: 90,

        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 6),
        ),

        child: Center(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      const SizedBox(height: 5),

      Text(label),
    ],
  );
}

//////////////////// TOOLS ////////////////////

Widget buildToolsSection(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const Text(
        "Tools",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 15),

      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,

        children: [

          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BmiCalculator(),
                ),
              );
            },
            child: buildToolCard(Icons.calculate, "BMI", "Calculator"),
          ),

          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MaintainCalories(),
                ),
              );
            },
            child: buildToolCard(Icons.restaurant, "Maintenance", "Calories"),
          ),

          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FoodTracker(),
                ),
              );
            },
            child: buildToolCard(Icons.fastfood, "Food", "Tracker"),
          ),

          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WeightLoose(),
                ),
              );
            },
            child: buildToolCard(Icons.trending_down, "Weight Loss", "Planner"),
          ),

          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WeightGain(),
                ),
              );
            },
            child: buildToolCard(Icons.trending_up, "Weight Gain", "Planner"),
          ),
        ],
      ),
    ],
  );
}

Widget buildToolCard(IconData icon, String title, String subtitle) {
  return Container(
    padding: const EdgeInsets.all(15),

    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.5),
      borderRadius: BorderRadius.circular(20),
    ),

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(icon, color: Colors.green),
        ),

        const Spacer(),

        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),

        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    ),
  );
}

//////////////////// QUICK ACTIONS ////////////////////

Widget buildActionChip(IconData icon, String text) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(30),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 5),
          Text(text),
        ],
      ),
    ),
  );
}

//////////////////// BOTTOM NAV ////////////////////

Widget buildBottomNav(BuildContext context) {
  return BottomNavigationBar(
    currentIndex: 0,
    type: BottomNavigationBarType.fixed,
    selectedItemColor: Colors.green,
    unselectedItemColor: Colors.grey,

    onTap: (index) {
      if (index == 0) return; // Already on dashboard
      if (index == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BmiCalculator()));
      if (index == 2) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FoodTracker()));
      if (index == 3) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const progress()));
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