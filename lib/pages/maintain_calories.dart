import 'package:flutter/material.dart';
import '../widgets/custom_top_bar.dart';

class MaintainCalories extends StatefulWidget {
  const MaintainCalories({super.key});

  @override
  State<MaintainCalories> createState() => _MaintainCaloriesState();
}

class _MaintainCaloriesState extends State<MaintainCalories> {
  String activityLevel = "Moderately Active (3-5 days/week)";
  int currentIndex = 1;

  double minCal = 1800;
  double maxCal = 2600;

  final List<String> activityOptions = [
    "Sedentary (little or no exercise)",
    "Lightly Active (1-3 days/week)",
    "Moderately Active (3-5 days/week)",
    "Very Active (6-7 days/week)",
    "Athlete (2x training)",
  ];

  @override
  Widget build(BuildContext context) {
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

                buildTopBar(context, "Maintenance Calories"),

                const SizedBox(height: 25),

                const Text(
                  "ACTIVITY LEVEL",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
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
    ); // ✅ FIXED HERE (removed extra comma)
  }

  // 🔹 DROPDOWN
  Widget buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(25),
      ),
      child: DropdownButton<String>(
        value: activityLevel,
        isExpanded: true,
        underline: const SizedBox(),
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
        },
      ),
    );
  }

  // 🔹 MAIN CARD
  Widget buildMainCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          const Text(
            "2,200",
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          const Text("kcal / day"),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Daily Maintenance Goal",
              style: TextStyle(color: Colors.green),
            ),
          )
        ],
      ),
    );
  }

  // 🔹 RANGE CARD
  Widget buildRangeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("CALORIE RANGE",
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          RangeSlider(
            values: RangeValues(minCal, maxCal),
            min: 1500,
            max: 3000,
            activeColor: Colors.green,
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
              Text("${minCal.toInt()}"),
              Text("${maxCal.toInt()}"),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Deficit"),
              Text("Surplus"),
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
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green.withOpacity(0.2),
            child: const Icon(Icons.info, color: Colors.green),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Maintenance calories are the number of calories your body needs to maintain your current weight based on your activity level.",
            ),
          )
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
          "Recalculate",
          style: TextStyle(fontSize: 18, color: Colors.black),
        ),
      ),
    );
  }
}