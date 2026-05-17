import 'package:flutter/material.dart';
import '../widgets/custom_top_bar.dart';
import '../widgets/bottom_nav.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

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
            padding: const EdgeInsets.all(AppSpacing.lg),

            child: Column(
              children: [
                buildTopBar(context, "BMI Calculator"),
                const SizedBox(height: AppSpacing.xxl),

                buildGauge(),

                const SizedBox(height: AppSpacing.lg),

                buildLabels(),

                const SizedBox(height: AppSpacing.xxl),

                buildInputCard("Height", height, "cm", Icons.straighten),

                const SizedBox(height: AppSpacing.base),

                buildInputCard("Weight", weight, "kg", Icons.monitor_weight),

                const SizedBox(height: AppSpacing.xxl),

                buildButton(),

                const SizedBox(height: AppSpacing.xl),

                buildHealthTip(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

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
              color: ThemeService.dividerColor,
              width: 14,
            ),
          ),
        ),

        Transform.translate(
          offset: const Offset(0, -40),

          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 40),
            decoration: BoxDecoration(
              color: ThemeService.cardColorStrong,
              borderRadius: BorderRadius.circular(40),
            ),

            child: Column(
              children: [

                Text(
                  bmi.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: ThemeService.textPrimary,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text("Underweight", style: TextStyle(color: ThemeService.textSecondary)),
        Text("Normal", style: TextStyle(color: ThemeService.textSecondary)),
        Text("Overweight", style: TextStyle(color: ThemeService.textSecondary)),
      ],
    );
  }

  // 🔹 Editable Input Card
  Widget buildInputCard(
      String title, double value, String unit, IconData icon) {
    return GestureDetector(
      onTap: () => showEditDialog(title),

      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),

        decoration: BoxDecoration(
          color: ThemeService.cardColor,
          borderRadius: AppRadius.xxlBorder,
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [

            Row(
              children: [

                CircleAvatar(
                  backgroundColor: ThemeService.accent.withOpacity(0.2),
                  child: Icon(icon, color: ThemeService.accent),
                ),

                const SizedBox(width: 15),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: ThemeService.textSecondary)),
                    Text(
                      value.toString(),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: ThemeService.textPrimary),
                    ),
                  ],
                ),
              ],
            ),

            Row(
              children: [
                Text(unit, style: TextStyle(color: ThemeService.textSecondary)),
                const SizedBox(width: 5),
                Icon(Icons.edit, size: 18, color: ThemeService.textSecondary),
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
          backgroundColor: ThemeService.solidCardColor,
          title: Text("Enter $type",
              style: TextStyle(color: ThemeService.textPrimary)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(color: ThemeService.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: ThemeService.inputFillColor,
              border: OutlineInputBorder(
                borderRadius: AppRadius.mdBorder,
                borderSide: BorderSide.none,
              ),
            ),
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
              child: Text("Save", style: TextStyle(color: ThemeService.accent)),
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
          backgroundColor: ThemeService.accent,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.xxlBorder,
          ),
        ),

        child: const Text(
          "Calculate BMI",
          style: TextStyle(fontSize: 18, color: Colors.white),
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
      padding: const EdgeInsets.all(AppSpacing.lg),

      decoration: BoxDecoration(
        color: ThemeService.cardColorStrong,
        borderRadius: AppRadius.xlBorder,
      ),

      child: Text(
        "Maintain a balanced diet and regular exercise to keep your BMI in the normal range.",
        style: TextStyle(color: ThemeService.textSecondary),
      ),
    );
  }
}