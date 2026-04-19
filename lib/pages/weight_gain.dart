import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'bmi_calculator.dart';
import 'food_tracker.dart';
import 'progress.dart';
import 'profile_setting.dart';
import '../widgets/custom_top_bar.dart';

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

                const SizedBox(height: 25),

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

          const Text(
            "2,800 kcal",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 BUTTON
  Widget buildButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,

      child: ElevatedButton(
        onPressed: () {},

        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),

        child: const Text(
          "Gain Weight 🚀",
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