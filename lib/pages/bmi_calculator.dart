import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'food_tracker.dart';
import 'progress.dart';
import 'profile_setting.dart';
import '../widgets/custom_top_bar.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';

class BmiCalculator extends StatefulWidget {
  const BmiCalculator({super.key});

  @override
  State<BmiCalculator> createState() => _BmiCalculatorState();
}

class _BmiCalculatorState extends State<BmiCalculator> {
  double height = 175;
  double weight = 70;
  double bmi = 22.9;
  String status = "Normal";

  int selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // 🔥 Prefill from user profile
  Future<void> _loadProfileData() async {
    final data = await AuthService.getUserDocument();
    if (data != null && mounted) {
      final h = data['height_cm'];
      final w = data['weight_kg'];
      if (h != null && w != null) {
        setState(() {
          height = (h is int) ? h.toDouble() : h;
          weight = (w is int) ? w.toDouble() : w;
        });
        calculateBMI();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              children: [
                buildTopBar(context, "BMI Calculator"),
                const SizedBox(height: 30),

                buildGauge(),

                const SizedBox(height: 20),

                buildLabels(),

                const SizedBox(height: 30),

                buildInputCard("Height", height, "cm", Icons.straighten),

                const SizedBox(height: 15),

                buildInputCard("Weight", weight, "kg", Icons.monitor_weight),

                const SizedBox(height: 30),

                buildButton(),

                const SizedBox(height: 25),

                buildHealthTip(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: buildBottomNav(context),
    );
  }

  // AppBar removed, moved to custom_top_bar.dart

  // 🔹 Gauge
  Widget buildGauge() {
    return Column(
      children: [

        Container(
          width: 220,
          height: 110,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(200),
              topRight: Radius.circular(200),
            ),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 14,
            ),
          ),
        ),

        Transform.translate(
          offset: const Offset(0, -40),

          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(40),
            ),

            child: Column(
              children: [

                Text(
                  bmi.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  status,
                  style: TextStyle(
                    color: getStatusColor(),
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 🔹 Labels
  Widget buildLabels() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text("Underweight"),
        Text("Normal"),
        Text("Overweight"),
      ],
    );
  }

  // 🔹 Editable Input Card
  Widget buildInputCard(
      String title, double value, String unit, IconData icon) {
    return GestureDetector(
      onTap: () => showEditDialog(title),

      child: Container(
        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(30),
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [

            Row(
              children: [

                CircleAvatar(
                  backgroundColor: Colors.green.shade200,
                  child: Icon(icon, color: Colors.green),
                ),

                const SizedBox(width: 15),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title),
                    Text(
                      value.toString(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ],
            ),

            Row(
              children: [
                Text(unit),
                const SizedBox(width: 5),
                const Icon(Icons.edit, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Dialog for editing
  void showEditDialog(String type) {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter $type"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () {
                double value = double.tryParse(controller.text) ?? 0;

                setState(() {
                  if (type == "Height") {
                    height = value;
                  } else {
                    weight = value;
                  }
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

  // 🔹 Button
  Widget buildButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,

      child: ElevatedButton(
        onPressed: calculateBMI,

        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),

        child: const Text(
          "Calculate BMI",
          style: TextStyle(fontSize: 18, color: Colors.black),
        ),
      ),
    );
  }

  // 🔹 BMI Logic
  void calculateBMI() {
    double h = height / 100;
    double result = weight / (h * h);

    setState(() {
      bmi = result;

      if (bmi < 18.5) {
        status = "Underweight";
      } else if (bmi < 25) {
        status = "Normal";
      } else {
        status = "Overweight";
      }
    });
  }

  Color getStatusColor() {
    if (status == "Normal") return Colors.green;
    if (status == "Underweight") return Colors.orange;
    return Colors.red;
  }

  // 🔹 Health Tip
  Widget buildHealthTip() {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
      ),

      child: const Text(
        "Maintain a balanced diet and regular exercise to keep your BMI in the normal range.",
      ),
    );
  }

  // 🔹 Bottom Navigation
  Widget buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 1,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      backgroundColor: ThemeService.isDark ? const Color(0xFF1A1A2E) : Colors.white,

      onTap: (index) {
        if (index == 1) return;
        if (index == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Dashboard()));
        if (index == 2) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FoodTracker()));
        if (index == 3) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const progress()));
        if (index == 4) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileSetting()));
      },

      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Dashboard"),
        BottomNavigationBarItem(icon: Icon(Icons.monitor_weight), label: "BMI"),
        BottomNavigationBarItem(icon: Icon(Icons.local_fire_department), label: "Calories"),
        BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: "Progress"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}