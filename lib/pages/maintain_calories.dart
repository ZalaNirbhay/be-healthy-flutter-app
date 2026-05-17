import 'package:flutter/material.dart';
import '../widgets/custom_top_bar.dart';
import '../services/calorie_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

class MaintainCalories extends StatefulWidget {
  const MaintainCalories({super.key});

  @override
  State<MaintainCalories> createState() => _MaintainCaloriesState();
}

class _MaintainCaloriesState extends State<MaintainCalories> {
  String activityLevel = "Moderately Active (3-5 days/week)";
  int currentIndex = 1;

  @override
  void dispose() {
    ThemeService.themeMode.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  double minCal = 1800;
  double maxCal = 2600;

  // 🔥 Dynamic TDEE data
  int tdee = 0;
  int bmr = 0;
  int weightLossCalories = 0;
  int weightGainCalories = 0;
  bool isLoading = true;
  bool isRecalculating = false;
  String? errorMessage;

  final List<String> activityOptions = [
    "Sedentary (little or no exercise)",
    "Lightly Active (1-3 days/week)",
    "Moderately Active (3-5 days/week)",
    "Very Active (6-7 days/week)",
    "Athlete (2x training)",
  ];

  @override
  void initState() {
    super.initState();
    _calculateCalories();
    ThemeService.themeMode.addListener(_onThemeChange);
  }

  // 🔥 Fetch user data and calculate TDEE
  Future<void> _calculateCalories() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    // Map the dropdown value to the profile activity_level format
    final profileActivityLevel = CalorieService.mapDropdownToProfileLevel(activityLevel);

    final result = await CalorieService.calculateFromProfile(
      overrideActivityLevel: profileActivityLevel,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        tdee = result['tdee'];
        bmr = result['bmr'];
        weightLossCalories = result['weight_loss_calories'];
        weightGainCalories = result['weight_gain_calories'];
        minCal = weightLossCalories.toDouble();
        maxCal = weightGainCalories.toDouble();
        isLoading = false;
        isRecalculating = false;
      });

      // Save to history
      CalorieService.saveCalculationHistory(
        tdee: tdee,
        type: 'maintenance_calories',
      );
    } else {
      setState(() {
        isLoading = false;
        isRecalculating = false;
        errorMessage = result['message'] ?? 'Calculation failed';
      });
    }
  }

  // 🔥 Recalculate when button pressed or activity changes
  Future<void> _recalculate() async {
    setState(() => isRecalculating = true);
    await _calculateCalories();
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

                buildTopBar(context, "Maintenance Calories"),

                const SizedBox(height: 25),

                Text(
                  "ACTIVITY LEVEL",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ThemeService.textSecondary,
                  ),
                ),

                const SizedBox(height: 10),

                buildDropdown(),

                const SizedBox(height: 25),

                buildMainCard(),

                const SizedBox(height: 25),

                buildRangeCard(),

                const SizedBox(height: 25),

                buildInfoCard(),

                const SizedBox(height: 25),

                buildButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 DROPDOWN
  Widget buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: ThemeService.cardColor,
        borderRadius: AppRadius.xlBorder,
      ),
      child: DropdownButton<String>(
        value: activityLevel,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: ThemeService.solidCardColor,
        style: TextStyle(color: ThemeService.textPrimary, fontSize: 14),
        iconEnabledColor: ThemeService.textSecondary,
        items: activityOptions.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            activityLevel = value!;
          });
          // Auto-recalculate when activity changes
          _recalculate();
        },
      ),
    );
  }

  // 🔹 MAIN CARD — Now dynamic
  Widget buildMainCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: ThemeService.cardColor,
        borderRadius: AppRadius.xxlBorder,
      ),
      child: Column(
        children: [
          if (isLoading)
            const SizedBox(
              height: 50,
              child: Center(
                child: CircularProgressIndicator(color: Colors.green),
              ),
            )
          else if (errorMessage != null)
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 14),
              textAlign: TextAlign.center,
            )
          else ...[
            // 🔥 Dynamic TDEE value
            Text(
              _formatNumber(tdee),
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: ThemeService.textPrimary),
            ),
            const SizedBox(height: 5),
            Text("kcal / day", style: TextStyle(color: ThemeService.textSecondary)),
          ],
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: ThemeService.accent.withOpacity(0.2),
              borderRadius: AppRadius.lgBorder,
            ),
            child: Text(
              "Daily Maintenance Goal",
              style: TextStyle(color: ThemeService.accent),
            ),
          )
        ],
      ),
    );
  }

  // 🔹 RANGE CARD — Now dynamic with weight loss/gain values
  Widget buildRangeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeService.cardColor,
        borderRadius: AppRadius.xlBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("CALORIE RANGE",
              style: TextStyle(color: ThemeService.textSecondary)),
          const SizedBox(height: 20),
          RangeSlider(
            values: RangeValues(
              minCal.clamp(1000, 4000),
              maxCal.clamp(1000, 4000),
            ),
            min: 1000,
            max: 4000,
            activeColor: ThemeService.accent,
            inactiveColor: ThemeService.dividerColor,
            onChanged: (values) {
              setState(() {
                minCal = values.start;
                maxCal = values.end;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${minCal.toInt()}", style: TextStyle(color: ThemeService.textPrimary)),
              Text("${maxCal.toInt()}", style: TextStyle(color: ThemeService.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Deficit", style: TextStyle(color: ThemeService.textSecondary)),
              Text("Surplus", style: TextStyle(color: ThemeService.textSecondary)),
            ],
          )
        ],
      ),
    );
  }

  // 🔹 INFO CARD
  Widget buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeService.cardColor,
        borderRadius: AppRadius.xlBorder,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: ThemeService.accent.withOpacity(0.2),
            child: Icon(Icons.info, color: ThemeService.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Maintenance calories are the number of calories your body needs to maintain your current weight based on your activity level.",
              style: TextStyle(color: ThemeService.textSecondary),
            ),
          )
        ],
      ),
    );
  }

  // 🔹 BUTTON — Now functional
  Widget buildButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: isRecalculating ? null : _recalculate,
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeService.accent,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.xxlBorder,
          ),
        ),
        child: isRecalculating
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                "Recalculate",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
      ),
    );
  }

  /// Format number with comma separator (e.g. 2,200)
  String _formatNumber(int number) {
    String str = number.toString();
    if (str.length <= 3) return str;

    String result = '';
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      count++;
      result = str[i] + result;
      if (count % 3 == 0 && i != 0) {
        result = ',$result';
      }
    }
    return result;
  }
}