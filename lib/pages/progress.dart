import 'package:flutter/material.dart';
import '../widgets/custom_top_bar.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/shimmer_loading.dart';
import '../services/health_engine.dart';
import '../services/water_service.dart';
import '../services/food_service.dart';
import '../services/progress_service.dart';
import '../services/plan_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

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
            padding: const EdgeInsets.all(AppSpacing.lg),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildTopBar(context, "Progress"),
                const SizedBox(height: AppSpacing.lg),

                buildTabs(),

                const SizedBox(height: AppSpacing.lg),

                if (isLoading) ...[
                  const ShimmerCard(lineCount: 4),
                  const SizedBox(height: AppSpacing.lg),
                  const ShimmerCard(lineCount: 2),
                  const SizedBox(height: AppSpacing.lg),
                  const ShimmerList(count: 3),
                ] else ...[
                  buildProgressCard(),

                  const SizedBox(height: AppSpacing.lg),

                  // Weekly Summary Stats
                  if (weeklySummary.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: ThemeService.cardColor,
                        borderRadius: AppRadius.lgBorder,
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

                  const SizedBox(height: AppSpacing.base),

                  // Progress Insights
                  if (progressInsights.isNotEmpty) ...[
                    Text("Insights",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThemeService.textPrimary)),
                    const SizedBox(height: 10),
                    ...progressInsights.map((insight) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ThemeService.cardColorLight,
                        borderRadius: AppRadius.mdBorder,
                      ),
                      child: Text(insight,
                          style: TextStyle(fontSize: 13, color: ThemeService.textPrimary)),
                    )),
                    const SizedBox(height: AppSpacing.base),
                  ],

                  Text(
                    "Activity Log",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ThemeService.textPrimary,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.base),

                  // 🔥 Dynamic activity log
                  ...activityLog.map((item) => buildActivityItem(
                    item['icon'],
                    item['title'],
                    item['time'],
                    item['color'],
                  )),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  // 🔹 TABS
  Widget buildTabs() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: ThemeService.selectorBackground,
        borderRadius: AppRadius.xxlBorder,
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

              child: AnimatedContainer(
                duration: AppDurations.fast,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? ThemeService.chipSelectedColor : Colors.transparent,
                  borderRadius: AppRadius.xlBorder,
                ),

                child: Center(
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      color: isSelected ? ThemeService.accent : ThemeService.chipUnselectedText,
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

    switch (selectedTab) {
      case 0: // Weight
        mainValue = "--";
        subtitle = "Current weight from profile";
        break;
      case 1: // BMI
        final bmiVal = (snapshot['bmi'] ?? 0.0).toDouble();
        mainValue = bmiVal > 0 ? bmiVal.toStringAsFixed(1) : "--";
        subtitle = _getBMIStatus(bmiVal);
        break;
      case 2: // Calories
        mainValue = "${snapshot['consumed'] ?? 0} kcal";
        subtitle = "of ${snapshot['target_calories'] ?? 2000} kcal target";
        progressLabel = "TODAY'S INTAKE";
        break;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),

      decoration: BoxDecoration(
        color: ThemeService.cardColor,
        borderRadius: AppRadius.xlBorder,
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            progressLabel,
            style: TextStyle(color: ThemeService.textSecondary),
          ),

          const SizedBox(height: 10),

          Text(
            mainValue,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: ThemeService.textPrimary,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            subtitle,
            style: TextStyle(color: ThemeService.accent),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Progress bar
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: AppRadius.lgBorder,
              gradient: LinearGradient(
                colors: [ThemeService.accent, Colors.teal],
              ),
            ),
            child: Center(
              child: Column(
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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final day in ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"])
                Text(day, style: TextStyle(color: ThemeService.textSecondary, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: ThemeService.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: ThemeService.textSecondary)),
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
        color: ThemeService.cardColor,
        borderRadius: AppRadius.lgBorder,
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
                    style: TextStyle(fontWeight: FontWeight.bold, color: ThemeService.textPrimary)),
                Text(time, style: TextStyle(color: ThemeService.textSecondary)),
              ],
            ),
          ),

          Icon(Icons.arrow_forward_ios, size: 14, color: ThemeService.textSecondary),
        ],
      ),
    );
  }

  // Helpers
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
}