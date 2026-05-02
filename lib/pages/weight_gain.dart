import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'bmi_calculator.dart';
import 'food_tracker.dart';
import 'progress.dart';
import 'profile_setting.dart';
import '../widgets/custom_top_bar.dart';
import '../services/calorie_service.dart';
import '../services/auth_service.dart';
import '../services/plan_service.dart';

class WeightGain extends StatefulWidget {
  const WeightGain({super.key});

  @override
  State<WeightGain> createState() => _WeightGainState();
}

class _WeightGainState extends State<WeightGain> {
  double targetWeight = 75;
  double currentWeight = 68;
  int selectedMeals = 4;
  int currentIndex = 2;
  int tdee = 0;
  int surplusCalories = 0;
  bool isLoading = true;
  bool isGenerating = false;
  String dietType = 'non_veg';
  String? planFeedback;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final calorieData = await CalorieService.calculateFromProfile();
    final profile = await AuthService.getUserDocument();
    final feedback = await PlanService.getPlanFeedback();

    if (mounted) {
      setState(() {
        if (calorieData['success'] == true) {
          tdee = calorieData['tdee'] ?? 2000;
          surplusCalories = tdee + 500;
        }
        if (profile != null) {
          final w = profile['weight_kg'];
          currentWeight = (w is int) ? w.toDouble() : (w ?? 68.0);
        }
        planFeedback = feedback;
        isLoading = false;
      });
    }
  }

  Future<void> _startPlan() async {
    if (isGenerating) return;
    setState(() => isGenerating = true);

    final weightChange = targetWeight - currentWeight;
    final result = await PlanService.generatePlan(
      goalType: 'weight_gain',
      targetWeightChange: weightChange > 0 ? weightChange : 5,
      dietType: dietType,
    );

    setState(() => isGenerating = false);
    if (!mounted) return;

    if (result['success'] == true) {
      _showPlanSheet(result['plan']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed')),
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
        decoration: const BoxDecoration(
          color: Color(0xFFF5FFF8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Your Weight Gain Plan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(15)),
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
                    Text(dietType == 'veg' ? '\u{1F96C}' : '\u{1F357}', style: const TextStyle(fontSize: 18)),
                    Text(dietType == 'veg' ? 'Veg' : 'Non-Veg', style: const TextStyle(fontSize: 12)),
                  ]),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text("\u{1F37D} Diet Plan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...meals.map((meal) {
                    final foods = List<Map<String, dynamic>>.from(meal['foods'] ?? []);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${meal['meal_type']} \u2014 ${meal['target_calories']} kcal",
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                          ...foods.map((f) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text("  \u2022 ${f['name']} (${f['serving_g']}g \u2014 ${f['calories']} kcal)",
                              style: const TextStyle(fontSize: 13)),
                          )),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  const Text("\u{1F3CB}\uFE0F Exercise Plan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...exercises.map((ex) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ex['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text("${ex['duration']} \u2022 ${ex['frequency']}", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                          child: Text("${ex['type']}", style: TextStyle(fontSize: 11, color: Colors.blue.shade700)),
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
    double remaining = targetWeight - currentWeight;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                buildTopBar(context, "Weight Gain Planner"),

                const SizedBox(height: 25),

                buildTargetCard(remaining),

                const SizedBox(height: 25),

                const Text(
                  "Meal Frequency",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                buildMealSelector(),

                const SizedBox(height: 15),

                // Diet type selector
                _buildDietTypeSelector(),

                const SizedBox(height: 15),

                // Plan feedback
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

                buildCalorieCard(),

                const SizedBox(height: 30),

                buildButton(),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: buildBottomNav(context),
    );
  }

  // Top Bar removed, moved to custom_top_bar.dart

  // 🔹 TARGET CARD
  Widget buildTargetCard(double remaining) {
    return GestureDetector(
      onTap: showEditDialog,

      child: Container(
        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(25),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Target Weight",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 5),

            const Text("Set your desired goal",
                style: TextStyle(color: Colors.black54)),

            const SizedBox(height: 15),

            Row(
              children: [
                Text(
                  targetWeight.toStringAsFixed(0),
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                const Text("kg"),
              ],
            ),

            const SizedBox(height: 10),

            LinearProgressIndicator(
              value: currentWeight / targetWeight,
              backgroundColor: Colors.grey.shade300,
              color: Colors.green,
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Current: ${currentWeight.toStringAsFixed(0)} kg"),
                Text(
                  "+${remaining.toStringAsFixed(0)} kg to go",
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // 🔹 MEAL SELECTOR
  Widget buildMealSelector() {
    List<int> meals = [3, 4, 5, 6];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
      ),

      child: Row(
        children: meals.map((meal) {
          bool isSelected = selectedMeals == meal;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedMeals = meal;
                });
              },

              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),

                child: Column(
                  children: [
                    Icon(Icons.restaurant,
                        color: isSelected ? Colors.green : Colors.black54),
                    const SizedBox(height: 5),
                    Text(
                      "$meal Meals",
                      style: TextStyle(
                        color: isSelected ? Colors.green : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 🔹 CALORIE CARD
  Widget buildCalorieCard() {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(25),
      ),

      child: Column(
        children: [

          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.green.shade200,
            child: const Icon(Icons.trending_up, color: Colors.green),
          ),

          const SizedBox(height: 10),

          const Text(
            "CALORIE SURPLUS",
            style: TextStyle(color: Colors.black54),
          ),

          const SizedBox(height: 10),

          const Text(
            "+500 kcal/day",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Divider(height: 30),

          const Text("Daily Calorie Target"),

          const SizedBox(height: 5),

          Text(
            isLoading ? "--" : "${surplusCalories.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} kcal",
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  // Diet type selector
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
                    "\u{1F96C} Vegetarian",
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
                    "\u{1F357} Non-Veg",
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

  // BUTTON — now generates plan
  Widget buildButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: isGenerating ? null : _startPlan,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: isGenerating
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                "Gain Weight \u{1F680}",
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
      ),
    );
  }

  // 🔹 EDIT DIALOG
  void showEditDialog() {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Enter Target Weight"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () {
                double value = double.tryParse(controller.text) ?? targetWeight;

                setState(() {
                  targetWeight = value;
                });

                Navigator.pop(context);
              },
              child: const Text("Save"),
            )
          ],
        );
      },
    );
  }

  // 🔹 BOTTOM NAV
  Widget buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0, 
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