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
import '../widgets/bottom_nav.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/staggered_list.dart';
import '../services/water_service.dart';
import '../services/health_engine.dart';
import '../services/food_service.dart';
import '../services/progress_service.dart';
import '../services/notification_service.dart';
import '../services/goal_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Map<String, dynamic> snapshot = {};
  bool isLoading = true;
  bool isLoggingWater = false;
  int streak = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
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

  Future<void> _loadDashboard() async {
    await FoodService.seedFoodDatabase();

    final data = await HealthEngine.getDashboardSnapshot();
    final currentStreak = await GoalService.calculateStreak();

    if (mounted) {
      setState(() {
        snapshot = data;
        streak = currentStreak;
        isLoading = false;
      });

      // Auto-save daily progress
      ProgressService.autoSaveToday(
        calories: data['consumed'] ?? 0,
        water: data['water_ml'] ?? 0,
        healthScore: data['health_score'] ?? 0,
      );

      // Generate smart notifications
      NotificationService.generateSmartNotifications(
        consumed: data['consumed'] ?? 0,
        target: data['target_calories'] ?? 2000,
        waterMl: data['water_ml'] ?? 0,
        waterGoal: data['water_goal'] ?? 3000,
        healthScore: data['health_score'] ?? 0,
        protein: data['protein'] ?? 0,
        foodEntries: List<Map<String, dynamic>>.from(data['food_entries'] ?? []),
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

  // Getters
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: ThemeService.dashboardGradient,
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
                buildTopBar(context, "BeHealth", isDashboard: true),
                const SizedBox(height: AppSpacing.lg),

                Text(
                  "Welcome Back!",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: ThemeService.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                if (isLoading) ...[
                  const ShimmerCard(lineCount: 3),
                  const SizedBox(height: AppSpacing.lg),
                  const ShimmerCard(lineCount: 4),
                ] else ...[
                  _buildHealthScoreCard(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildProgressCard(),
                  const SizedBox(height: AppSpacing.lg),

                  if (feedback.isNotEmpty) ...[
                    _buildInsightsSection(),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  if (mealSuggestions.isNotEmpty) ...[
                    _buildMealSuggestions(),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  _buildToolsSection(context),
                  const SizedBox(height: AppSpacing.xl),
                  _buildQuickActions(),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  // ═══════════════════════════════════════════════
  //  HEALTH SCORE + STATUS CARD
  // ═══════════════════════════════════════════════

  Widget _buildHealthScoreCard() {
    final statusLabel = status['label'] ?? 'Loading';
    final statusColor = _getStatusColor(status['color']);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ThemeService.surfaceColor,
        borderRadius: AppRadius.xlBorder,
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: healthScore / 100,
                  strokeWidth: 6,
                  color: _getScoreColor(healthScore),
                  backgroundColor: ThemeService.cardColorLight,
                ),
              ),
              Text("$healthScore",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ThemeService.textPrimary)),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("Daily Health Score",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ThemeService.textPrimary)),
                    if (streak > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text("🔥 $streak", style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                const SizedBox(height: 4),
                Text("$consumed / $targetCalories kcal consumed",
                    style: TextStyle(fontSize: 12, color: ThemeService.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  PROGRESS CARD (BMI + Water)
  // ═══════════════════════════════════════════════

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: ThemeService.surfaceColor,
        borderRadius: AppRadius.xlBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Daily Progress",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: ThemeService.textPrimary)),
          Text("BMI and Hydration Tracking", style: TextStyle(color: ThemeService.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCircle(bmi > 0 ? bmi.toStringAsFixed(1) : "--", "BMI", Colors.green),
              Container(height: 80, width: 1, color: ThemeService.dividerColor),
              _buildCircle(WaterService.formatWater(waterMl), "WATER", Colors.blue),
            ],
          ),
          if (consumed > 0) ...[
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

  Widget _buildCircle(String value, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 6),
          ),
          child: Center(
            child: Text(value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThemeService.textPrimary)),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(color: ThemeService.textSecondary)),
      ],
    );
  }

  Widget _buildMacroChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text("$label $value",
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }

  // ═══════════════════════════════════════════════
  //  SMART INSIGHTS SECTION
  // ═══════════════════════════════════════════════

  Widget _buildInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Smart Insights",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ThemeService.textPrimary)),
        const SizedBox(height: 10),
        ...feedback.map((insight) {
          final type = insight['type'] ?? 'info';
          final color = type == 'warning'
              ? Colors.orange
              : type == 'success' ? Colors.green
              : type == 'nudge' ? Colors.blue
              : Colors.teal;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: AppRadius.lgBorder,
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(_getInsightIcon(insight['icon']), color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(child: Text(insight['message'] ?? '',
                    style: TextStyle(fontSize: 13, color: color))),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  //  SMART MEAL SUGGESTIONS
  // ═══════════════════════════════════════════════

  Widget _buildMealSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Suggested for $remaining kcal remaining",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThemeService.textPrimary)),
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
                  color: ThemeService.cardColor,
                  borderRadius: AppRadius.lgBorder,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(food['name'] ?? '',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: ThemeService.textPrimary),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text("${food['calories']} kcal",
                        style: TextStyle(color: ThemeService.accent, fontSize: 12, fontWeight: FontWeight.w600)),
                    Text("${food['serving']}g serving",
                        style: TextStyle(fontSize: 11, color: ThemeService.textSecondary)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  //  QUICK ACTIONS (Water + Food)
  // ═══════════════════════════════════════════════

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Quick Actions",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ThemeService.textPrimary)),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _logWater,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: ThemeService.cardColor,
                    borderRadius: AppRadius.xxlBorder,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      isLoggingWater
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue))
                          : Icon(Icons.water_drop, color: ThemeService.textPrimary),
                      const SizedBox(width: 5),
                      Text("Log Water", style: TextStyle(color: ThemeService.textPrimary)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodTracker()))
                      .then((_) => _loadDashboard());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: ThemeService.cardColor,
                    borderRadius: AppRadius.xxlBorder,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fastfood, color: ThemeService.textPrimary),
                      const SizedBox(width: 5),
                      Text("Add Food", style: TextStyle(color: ThemeService.textPrimary)),
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

  // ═══════════════════════════════════════════════
  //  TOOLS SECTION
  // ═══════════════════════════════════════════════

  Widget _buildToolsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Tools",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ThemeService.textPrimary)),
        const SizedBox(height: 15),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _buildToolCard(context, Icons.calculate, "BMI", "Calculator", const BmiCalculator()),
            _buildToolCard(context, Icons.restaurant, "Maintenance", "Calories", const MaintainCalories()),
            _buildToolCard(context, Icons.fastfood, "Food", "Tracker", const FoodTracker()),
            _buildToolCard(context, Icons.trending_down, "Weight Loss", "Planner", const WeightLoose()),
            _buildToolCard(context, Icons.trending_up, "Weight Gain", "Planner", const WeightGain()),
          ],
        ),
      ],
    );
  }

  Widget _buildToolCard(BuildContext context, IconData icon, String title, String subtitle, Widget page) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      borderRadius: AppRadius.lgBorder,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: ThemeService.cardColorLight,
          borderRadius: AppRadius.lgBorder,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: ThemeService.isDark ? const Color(0xFF2D4A6E) : Colors.white,
              child: Icon(icon, color: ThemeService.accent),
            ),
            const Spacer(),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: ThemeService.textPrimary)),
            Text(subtitle, style: TextStyle(color: ThemeService.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════

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
