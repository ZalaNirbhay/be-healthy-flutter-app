import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'bmi_calculator.dart';
import 'food_tracker.dart';
import 'progress.dart';
import 'profile_setting.dart';
import '../widgets/custom_top_bar.dart';
import '../widgets/bottom_nav.dart';
import '../services/calorie_service.dart';
import '../services/auth_service.dart';
import '../services/plan_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

class WeightLoose extends StatefulWidget {
  const WeightLoose({super.key});

  @override
  State<WeightLoose> createState() => _WeightLooseState();
}

class _WeightLooseState extends State<WeightLoose> {
  double selectedGoal = 0.5; // kg/week
  int currentIndex = 2;
  int targetCalories = 0;
  double currentWeight = 0;
  bool isLoading = true;
  bool isGenerating = false;
  String dietType = 'non_veg';
  String? planFeedback;

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
    final calorieData = await CalorieService.calculateFromProfile();
    final profile = await AuthService.getUserDocument();
    final feedback = await PlanService.getPlanFeedback();

    if (mounted) {
      setState(() {
        if (calorieData['success'] == true) {
          final tdee = calorieData['tdee'] ?? 2000;
          targetCalories = (tdee - (selectedGoal * 1100)).round().clamp(1200, 9999);
        }
        if (profile != null) {
          final w = profile['weight_kg'];
          currentWeight = (w is int) ? w.toDouble() : (w ?? 0.0);
        }
        planFeedback = feedback;
        isLoading = false;
      });
    }
  }

  void _recalculate() {
    setState(() => isLoading = true);
    _loadData();
  }

  Future<void> _startPlan() async {
    if (isGenerating) return;
    setState(() => isGenerating = true);

    final totalWeightChange = selectedGoal * 8; // 8 weeks
    final result = await PlanService.generatePlan(
      goalType: 'weight_loss',
      targetWeightChange: totalWeightChange,
      dietType: dietType,
    );

    setState(() => isGenerating = false);

    if (!mounted) return;

    if (result['success'] == true) {
      _showPlanSheet(result['plan']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to generate plan')),
      );
    }
  }

  void _showPlanSheet(Map<String, dynamic> plan) {
    final meals = List<Map<String, dynamic>>.from(plan['suggested_meals'] ?? []);
    final exercises = List<Map<String, dynamic>>.from(plan['exercises'] ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: ThemeService.bottomSheetColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Your Weight Loss Plan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(children: [
                    Text("${plan['calorie_target']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const Text("kcal/day", style: TextStyle(fontSize: 12)),
                  ]),
                  Column(children: [
                    Text("${plan['weeks_estimate']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const Text("weeks", style: TextStyle(fontSize: 12)),
                  ]),
                  Column(children: [
                    Text(dietType == 'veg' ? '🥬' : '🍗', style: const TextStyle(fontSize: 18)),
                    Text(dietType == 'veg' ? 'Veg' : 'Non-Veg', style: const TextStyle(fontSize: 12)),
                  ]),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text("🍽 Diet Plan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...meals.map((meal) {
                    final foods = List<Map<String, dynamic>>.from(meal['foods'] ?? []);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ThemeService.solidCardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${meal['meal_type']} — ${meal['target_calories']} kcal",
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                          ...foods.map((f) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text("  • ${f['name']} (${f['serving_g']}g — ${f['calories']} kcal)",
                              style: const TextStyle(fontSize: 13)),
                          )),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  const Text("🏋️ Exercise Plan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...exercises.map((ex) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ThemeService.solidCardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ex['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text("${ex['duration']} • ${ex['frequency']}", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text("${ex['type']}", style: TextStyle(fontSize: 11, color: Colors.orange.shade700)),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

                buildTopBar(context, "Weight Loss Planner"),

                const SizedBox(height: 20),

                const Text(
                  "Weekly Goal Selector",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                buildGoalSelector(),

                const SizedBox(height: 15),

                // 🔥 Diet Type Selector
                _buildDietTypeSelector(),

                const SizedBox(height: 20),

                // 🔥 Plan feedback
                if (planFeedback != null && planFeedback!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(planFeedback!, style: const TextStyle(fontSize: 13)),
                    ),
                  ),

                buildCaloriesCard(),

                const SizedBox(height: 25),

                buildProgressCard(),

                const SizedBox(height: 25),

                buildTipCard(),

                const SizedBox(height: 30),

                buildStartButton(),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  // Top Bar removed, moved to custom_top_bar.dart

  // 🔹 GOAL SELECTOR
  Widget buildGoalSelector() {
    List<double> goals = [0.25, 0.5, 1];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: ThemeService.selectorBackground,
        borderRadius: AppRadius.xxlBorder,
      ),

      child: Row(
        children: goals.map((goal) {
          bool isSelected = selectedGoal == goal;

          return Expanded(
            child: GestureDetector(
               onTap: () {
                setState(() {
                  selectedGoal = goal;
                });
                _recalculate();
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
                    "$goal kg",
                    style: TextStyle(
                      color: isSelected ? ThemeService.accent : ThemeService.chipUnselectedText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 🔹 CALORIES CARD
  Widget buildCaloriesCard() {
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
            "TARGET CALORIES",
            style: TextStyle(color: ThemeService.textSecondary),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Text(
                isLoading ? "--" : "${targetCalories.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},' )}",
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              const Text("kcal/day"),
            ],
          ),
        ],
      ),
    );
  }

  // 🔹 PROGRESS CARD
  Widget buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),

      decoration: BoxDecoration(
        color: ThemeService.cardColor,
        borderRadius: AppRadius.xlBorder,
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              Text(
                "Projected Progress",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: ThemeService.textPrimary,
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: ThemeService.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "-${selectedGoal}kg/wk",
                  style: TextStyle(color: ThemeService.accent),
                ),
              )
            ],
          ),

          const SizedBox(height: 20),

          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Colors.green, Colors.blue],
              ),
            ),
          ),

          const SizedBox(height: 10),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Week 1"),
              Text("Week 4"),
              Text("Week 8"),
            ],
          )
        ],
      ),
    );
  }

  // 🔹 TIP CARD
  Widget buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),

      decoration: BoxDecoration(
        color: ThemeService.cardColorStrong,
        borderRadius: AppRadius.xlBorder,
      ),

      child: Row(
        children: [

          CircleAvatar(
            backgroundColor: Colors.green.shade200,
            child: const Icon(Icons.lightbulb, color: Colors.green),
          ),

          const SizedBox(width: 15),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tip of the day",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  "Consistency is key. Small daily wins lead to big results!",
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // 🔹 DIET TYPE SELECTOR
  Widget _buildDietTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => dietType = 'veg'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: dietType == 'veg' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    "🥬 Vegetarian",
                    style: TextStyle(
                      color: dietType == 'veg' ? Colors.green : Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => dietType = 'non_veg'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: dietType == 'non_veg' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    "🍗 Non-Veg",
                    style: TextStyle(
                      color: dietType == 'non_veg' ? Colors.green : Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 BUTTON — now generates plan
  Widget buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: isGenerating ? null : _startPlan,
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeService.accent,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.xxlBorder,
          ),
        ),
        child: isGenerating
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                "Start Plan →",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
      ),
    );
  }

  // 🔹 BOTTOM NAV
  Widget buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0, // This page doesn't strictly have a unique main index 
                       // but generally acts under the Dashboard tools context.
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,

      onTap: (index) {
        if (index == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Dashboard()));
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
}