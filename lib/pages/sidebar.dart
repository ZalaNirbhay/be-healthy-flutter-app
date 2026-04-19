import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'bmi_calculator.dart';
import 'food_tracker.dart';
import 'weight_loose.dart';
import 'weight_gain.dart';
import 'progress.dart';
import 'profile_setting.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6FCF97), Color(0xFFB7E4C7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              // 🔹 Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Row(
                      children: const [
                        Icon(Icons.favorite_border, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          "BeHealth",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.white),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 Profile Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(15),

                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),

                child: Row(
                  children: [

                    const CircleAvatar(
                      radius: 25,
                      backgroundImage: AssetImage("assets/images/profile1.jpg",
                      ),
                    ),

                    const SizedBox(width: 15),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "John Doe",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "john@behealth.com",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // 🔹 Menu Items
              buildMenuItem(context, Icons.dashboard, "Dashboard", false, () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Dashboard()));
              }),

              buildMenuItem(context, Icons.calculate, "BMI Calculator", false, () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BmiCalculator()));
              }),

              buildMenuItem(context, Icons.local_fire_department, "Calories", false, () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FoodTracker()));
              }),

              buildMenuItem(context, Icons.trending_down, "Weight Loss", false, () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WeightLoose()));
              }),

              buildMenuItem(context, Icons.trending_up, "Weight Gain", false, () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WeightGain()));
              }),

              buildMenuItem(context, Icons.show_chart, "Progress", false, () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const progress()));
              }),

              buildMenuItem(context, Icons.person, "Profile", false, () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileSetting()));
              }),

              const Spacer(),

              // 🔹 Divider
              const Divider(color: Colors.white30, indent: 20, endIndent: 20),

              // 🔹 Logout
              buildMenuItem(context, Icons.logout, "Logout", false, () {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Reusable Menu Item
  Widget buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),

        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),

        child: Row(
          children: [

            Icon(icon, color: Colors.white),

            const SizedBox(width: 15),

            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),

            if (isActive)
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
          ],
        ),
      ),
    );
  }
}