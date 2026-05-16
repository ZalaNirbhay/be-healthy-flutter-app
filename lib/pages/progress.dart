import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'bmi_calculator.dart';
import 'food_tracker.dart';
import 'profile_setting.dart';
import '../widgets/custom_top_bar.dart';
import '../services/health_engine.dart';
import '../services/water_service.dart';
import '../services/food_service.dart';
import '../services/progress_service.dart';
import '../services/plan_service.dart';
import '../services/theme_service.dart';

class progress extends StatefulWidget {
  const progress({super.key});

  @override
  State<progress> createState() => _progressState();
}

class _progressState extends State<progress> {
  int selectedTab = 0;
  int currentIndex = 2;
  bool isLoading = true;

  List<String> tabs = ["Weight", "BMI", "Calories"];

  // Dynamic data
  Map<String, dynamic> snapshot = {};
  Map<String, dynamic> weeklySummary = {};
  List<Map<String, dynamic>> activityLog = [];
  List<String> progressInsights = [];
  int planAdherence = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await HealthEngine.getDashboardSnapshot();
    final entries = data['food_entries'] as List<Map<String, dynamic>>? ?? [];

    // Auto-save today's progress snapshot
    await ProgressService.autoSaveToday(
      calories: data['consumed'] ?? 0,
      water: data['water_ml'] ?? 0,
      healthScore: data['health_score'] ?? 0,
    );

    // Fetch weekly summary + plan adherence
    final weekly = await ProgressService.getWeeklySummary();
    final adherence = await PlanService.calculateAdherenceScore();
    final insights = ProgressService.generateInsights(weekly);

    // Build dynamic activity log from today's real data
    List<Map<String, dynamic>> log = [];

    // Water activity
    final waterMl = data['water_ml'] ?? 0;
    if (waterMl > 0) {
      log.add({
        'icon': Icons.water_drop,
        'title': 'Logged ${WaterService.formatWater(waterMl)} Water',
        'time': 'Today',
        'color': Colors.blue,
      });
    }

    // Food entries
    for (var entry in entries) {
      log.add({
        'icon': FoodService.getMealIcon(entry['meal_type'] ?? 'Snack'),
        'title': 'Logged ${entry['meal_type']}: ${entry['food_name']}',
        'time': '${entry['calories'] ?? 0} kcal',
        'color': Colors.green,
      });
    }

    // Plan adherence
    if (adherence > 0) {
      log.add({
        'icon': Icons.assignment_turned_in,
        'title': 'Plan Adherence: $adherence%',
        'time': adherence >= 80 ? 'Great job!' : 'Keep going!',
        'color': adherence >= 80 ? Colors.green : Colors.orange,
      });
    }

    // Health score
    final score = data['health_score'] ?? 0;
    if (score > 0) {
      log.add({
        'icon': Icons.favorite,
        'title': 'Health Score: $score/100',
        'time': 'Today',
        'color': Colors.red,
      });
    }

    // If no activity
    if (log.isEmpty) {
      log.add({
        'icon': Icons.hourglass_empty,
        'title': 'No activity logged yet today',
        'time': 'Start tracking to see progress!',
        'color': Colors.grey,
      });
    }

    if (mounted) {
      setState(() {
        snapshot = data;
        weeklySummary = weekly;
        activityLog = log;
        progressInsights = insights;
        planAdherence = adherence;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildTopBar(context, "Progress"),
                const SizedBox(height: 20),

                buildTabs(),

                const SizedBox(height: 20),

                buildProgressCard(),

                const SizedBox(height: 20),

                // Weekly Summary Stats
                if (!isLoading && weeklySummary.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat("${weeklySummary['avg_calories'] ?? 0}", "Avg Cal"),
                        _buildStat("${weeklySummary['consistency_score'] ?? 0}%", "Consistency"),
                        _buildStat("${weeklySummary['total_days_tracked'] ?? 0}/7", "Days"),
                      ],
                    ),
                  ),

                const SizedBox(height: 15),

                // Progress Insights
                if (!isLoading && progressInsights.isNotEmpty) ...[
                  const Text("Insights", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...progressInsights.map((insight) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(insight, style: const TextStyle(fontSize: 13)),
                  )),
                  const SizedBox(height: 15),
                ],

                const Text(
                  "Activity Log",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                // 🔥 Dynamic activity log
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: Colors.green),
                    ),
                  )
                else
                  ...activityLog.map((item) => buildActivityItem(
                    item['icon'],
                    item['title'],
                    item['time'],
                    item['color'],
                  )),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: buildBottomNav(context),
    );
  }

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

  // 🔹 PROGRESS CARD — Dynamic based on selected tab
  Widget buildProgressCard() {
    String mainValue = "--";
    String subtitle = "";
    String progressLabel = "WEEKLY PROGRESS";

    if (!isLoading) {
      switch (selectedTab) {
        case 0: // Weight
          final weight = snapshot['weight_kg'] ?? (snapshot['user_name'] != null ? 0 : 0);
          final w = _getProfileField('weight_kg');
          mainValue = w != null ? "${w}kg" : "--";
          subtitle = "Current weight from profile";
          break;
        case 1: // BMI
          final bmi = (snapshot['bmi'] ?? 0.0).toDouble();
          mainValue = bmi > 0 ? bmi.toStringAsFixed(1) : "--";
          subtitle = _getBMIStatus(bmi);
          break;
        case 2: // Calories
          mainValue = "${snapshot['consumed'] ?? 0} kcal";
          subtitle = "of ${snapshot['target_calories'] ?? 2000} kcal target";
          progressLabel = "TODAY'S INTAKE";
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(25),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            progressLabel,
            style: const TextStyle(color: Colors.black54),
          ),

          const SizedBox(height: 10),

          isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                )
              : Text(
                  mainValue,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

          const SizedBox(height: 5),

          Text(
            subtitle,
            style: const TextStyle(color: Colors.green),
          ),

          const SizedBox(height: 20),

          // Progress bar
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Colors.green, Colors.teal],
              ),
            ),
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Health Score",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "${snapshot['health_score'] ?? 0}/100",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getScoreLabel(snapshot['health_score'] ?? 0),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
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

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
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

  // Helpers
  dynamic _getProfileField(String field) {
    // Try to get from snapshot indirectly
    return null; // Will come from profile data
  }

  String _getBMIStatus(double bmi) {
    if (bmi == 0) return "Calculate your BMI";
    if (bmi < 18.5) return "Underweight";
    if (bmi < 25) return "Normal — Great!";
    if (bmi < 30) return "Overweight";
    return "Obese";
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return "Excellent";
    if (score >= 60) return "Good";
    if (score >= 40) return "Fair";
    if (score > 0) return "Needs Improvement";
    return "Start Tracking!";
  }

  // 🔹 BOTTOM NAV
  Widget buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 3,
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