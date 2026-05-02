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
import '../services/health_engine.dart';
import '../services/food_service.dart';
import '../services/progress_service.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // 🔥 Dashboard data from Health Engine
  Map<String, dynamic> snapshot = {};
  bool isLoading = true;
  bool isLoggingWater = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    // Seed food database on first launch
    await FoodService.seedFoodDatabase();

    final data = await HealthEngine.getDashboardSnapshot();
    if (mounted) {
      setState(() {
        snapshot = data;
        isLoading = false;
      });

      // Auto-save daily progress
      ProgressService.autoSaveToday(
        calories: data['consumed'] ?? 0,
        water: data['water_ml'] ?? 0,
        healthScore: data['health_score'] ?? 0,
      );
    }
  }

  Future<void> _logWater() async {
    if (isLoggingWater) return;
    setState(() => isLoggingWater = true);

    final result = await WaterService.logWater();
    if (mounted && result['success'] == true) {
      setState(() {
        snapshot['water_ml'] = (snapshot['water_ml'] ?? 0) + 200;
        isLoggingWater = false;
      });
    } else {
      setState(() => isLoggingWater = false);
    }
  }

  // Getters for cleaner code
  int get targetCalories => snapshot['target_calories'] ?? 2000;
  int get consumed => snapshot['consumed'] ?? 0;
  int get remaining => snapshot['remaining'] ?? 2000;
  int get waterMl => snapshot['water_ml'] ?? 0;
  int get waterGoal => snapshot['water_goal'] ?? 3000;
  int get protein => snapshot['protein'] ?? 0;
  int get carbs => snapshot['carbs'] ?? 0;
  int get fat => snapshot['fat'] ?? 0;
  double get bmi => (snapshot['bmi'] ?? 0.0).toDouble();
  int get healthScore => snapshot['health_score'] ?? 0;
  String get userName => snapshot['user_name'] ?? 'User';
  Map<String, dynamic> get status =>
      snapshot['status'] ?? {'label': 'Loading', 'color': 'grey'};
  List<Map<String, dynamic>> get feedback =>
      List<Map<String, dynamic>>.from(snapshot['feedback'] ?? []);
  List<Map<String, dynamic>> get mealSuggestions =>
      List<Map<String, dynamic>>.from(snapshot['meal_suggestions'] ?? []);

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

                // 🔥 Dynamic greeting
                Text(
                  "Welcome Back!",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // 🔥 Health Score + Status Card
                _buildHealthScoreCard(),

                const SizedBox(height: 20),

                // 🔥 Dynamic Progress Card
                _buildProgressCard(),

                const SizedBox(height: 20),

                // 🔥 Smart Insights
                if (!isLoading && feedback.isNotEmpty) ...[
                  _buildInsightsSection(),
                  const SizedBox(height: 20),
                ],

                // 🔥 Meal Suggestions
                if (!isLoading && mealSuggestions.isNotEmpty) ...[
                  _buildMealSuggestions(),
                  const SizedBox(height: 20),
                ],

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

  // ═══════════════════════════════════════════
  //  HEALTH SCORE + STATUS CARD
  // ═══════════════════════════════════════════

  Widget _buildHealthScoreCard() {
    final statusLabel = status['label'] ?? 'Loading';
    final statusColor = _getStatusColor(status['color']);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          // Health Score Circle
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: isLoading ? 0 : healthScore / 100,
                  strokeWidth: 6,
                  color: _getScoreColor(healthScore),
                  backgroundColor: Colors.white.withOpacity(0.3),
                ),
              ),
              isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.green,
                      ),
                    )
                  : Text(
                      "$healthScore",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ],
          ),

          const SizedBox(width: 18),

          // Status + Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Daily Health Score",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$consumed / $targetCalories kcal consumed",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  PROGRESS CARD (BMI + Water)
  // ═══════════════════════════════════════════

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
              buildCircle(
                bmi > 0 ? bmi.toStringAsFixed(1) : "--",
                "BMI",
                Colors.green,
              ),
              Container(height: 80, width: 1, color: Colors.white),
              buildCircle(
                WaterService.formatWater(waterMl),
                "WATER",
                Colors.blue,
              ),
            ],
          ),
          // Macro summary row
          if (!isLoading && consumed > 0) ...[
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroChip("Carbs", "${carbs}g", Colors.orange),
                _buildMacroChip("Protein", "${protein}g", Colors.blue),
                _buildMacroChip("Fat", "${fat}g", Colors.purple),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMacroChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        "$label $value",
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  SMART INSIGHTS SECTION
  // ═══════════════════════════════════════════

  Widget _buildInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Smart Insights",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...feedback.map((insight) {
          final type = insight['type'] ?? 'info';
          final color = type == 'warning'
              ? Colors.orange
              : type == 'success'
                  ? Colors.green
                  : type == 'nudge'
                      ? Colors.blue
                      : Colors.teal;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(_getInsightIcon(insight['icon']), color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    insight['message'] ?? '',
                    style: TextStyle(fontSize: 13, color: color.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════
  //  SMART MEAL SUGGESTIONS
  // ═══════════════════════════════════════════

  Widget _buildMealSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Suggested for $remaining kcal remaining",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: mealSuggestions.map((food) {
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      food['name'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${food['calories']} kcal",
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "${food['serving']}g serving",
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  //  QUICK ACTIONS (Water + Food)
  // ═══════════════════════════════════════════

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Actions",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
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
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.blue,
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
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FoodTracker()),
                  ).then((_) => _loadDashboard());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fastfood),
                      SizedBox(width: 5),
                      Text("Add Food"),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════

  Color _getStatusColor(String? colorName) {
    switch (colorName) {
      case 'green': return Colors.green;
      case 'orange': return Colors.orange;
      case 'red': return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.orange;
    return Colors.red.shade300;
  }

  IconData _getInsightIcon(String? iconName) {
    switch (iconName) {
      case 'warning': return Icons.warning_amber_rounded;
      case 'thumb_up': return Icons.thumb_up;
      case 'info': return Icons.info_outline;
      case 'water_drop': return Icons.water_drop;
      case 'fitness_center': return Icons.fitness_center;
      case 'restaurant': return Icons.restaurant;
      case 'free_breakfast': return Icons.free_breakfast;
      default: return Icons.lightbulb_outline;
    }
  }
}

//////////////////// PROGRESS ////////////////////

Widget buildCircle(String value, String label, Color color) {
  return Column(
    children: [
      Container(
        width: 90, height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 6),
        ),
        child: Center(
          child: Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BmiCalculator())),
            child: buildToolCard(Icons.calculate, "BMI", "Calculator"),
          ),
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MaintainCalories())),
            child: buildToolCard(Icons.restaurant, "Maintenance", "Calories"),
          ),
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodTracker())),
            child: buildToolCard(Icons.fastfood, "Food", "Tracker"),
          ),
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeightLoose())),
            child: buildToolCard(Icons.trending_down, "Weight Loss", "Planner"),
          ),
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeightGain())),
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

//////////////////// BOTTOM NAV ////////////////////

Widget buildBottomNav(BuildContext context) {
  return BottomNavigationBar(
    currentIndex: 0,
    type: BottomNavigationBarType.fixed,
    selectedItemColor: Colors.green,
    unselectedItemColor: Colors.grey,
    onTap: (index) {
      if (index == 0) return;
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