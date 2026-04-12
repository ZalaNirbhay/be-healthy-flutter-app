import 'package:flutter/material.dart';
import 'bmi_calculator.dart';
import 'sidebar.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppSidebar(), // ✅ Sidebar attached

      backgroundColor: Colors.transparent,

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6FCF97), Color(0xFFDFF5EA)],
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

                buildTopBar(context), // ✅ PASS CONTEXT

                const SizedBox(height: 20),

                const Text(
                  "Welcome Back!",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                buildProgressCard(),

                const SizedBox(height: 25),

                buildToolsSection(context),

                const SizedBox(height: 25),

                buildQuickActions(),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: buildBottomNav(),
    );
  }
}

//////////////////// TOP BAR ////////////////////

Widget buildTopBar(BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [

      // ✅ FIXED MENU BUTTON
      Builder(
        builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu, size: 28),
            onPressed: () {
              Scaffold.of(context).openDrawer(); // ✅ OPEN SIDEBAR
            },
          );
        },
      ),

      const Text(
        "BeHealth",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      const CircleAvatar(
        radius: 18,
        backgroundColor: Colors.white,
      ),
    ],
  );
}

//////////////////// PROGRESS ////////////////////

Widget buildProgressCard() {
  return Container(
    padding: const EdgeInsets.all(20),

    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.3),
      borderRadius: BorderRadius.circular(25),
    ),

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "Daily Progress",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),

        const Text("BMI and Hydration Tracking"),

        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [

            buildCircle("22.5", "BMI", Colors.green),

            Container(
              height: 80,
              width: 1,
              color: Colors.white,
            ),

            buildCircle("1.5L", "WATER", Colors.blue),
          ],
        ),
      ],
    ),
  );
}

Widget buildCircle(String value, String label, Color color) {
  return Column(
    children: [

      Container(
        width: 90,
        height: 90,

        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 6),
        ),

        child: Center(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      const SizedBox(height: 5),

      Text(label),
    ],
  );
}

//////////////////// TOOLS ////////////////////

Widget buildToolsSection(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const Text(
        "Tools",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 15),

      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,

        children: [

          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BmiCalculator(),
                ),
              );
            },
            child: buildToolCard(Icons.calculate, "BMI", "Calculator"),
          ),

          InkWell(
            onTap: () {},
            child: buildToolCard(Icons.restaurant, "Maintenance", "Calories"),
          ),

          InkWell(
            onTap: () {},
            child: buildToolCard(Icons.trending_down, "Weight Loss", "Planner"),
          ),

          InkWell(
            onTap: () {},
            child: buildToolCard(Icons.trending_up, "Weight Gain", "Planner"),
          ),
        ],
      ),
    ],
  );
}

Widget buildToolCard(IconData icon, String title, String subtitle) {
  return Container(
    padding: const EdgeInsets.all(15),

    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.5),
      borderRadius: BorderRadius.circular(20),
    ),

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(icon, color: Colors.green),
        ),

        const Spacer(),

        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),

        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    ),
  );
}

//////////////////// QUICK ACTIONS ////////////////////

Widget buildQuickActions() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const Text(
        "Quick Actions",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 15),

      Row(
        children: [

          buildActionChip(Icons.water_drop, "Log Water"),
          const SizedBox(width: 10),
          buildActionChip(Icons.fastfood, "Add Food"),
        ],
      ),
    ],
  );
}

Widget buildActionChip(IconData icon, String text) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(30),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 5),
          Text(text),
        ],
      ),
    ),
  );
}

//////////////////// BOTTOM NAV ////////////////////

Widget buildBottomNav() {
  return BottomNavigationBar(
    selectedItemColor: Colors.green,
    unselectedItemColor: Colors.grey,

    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
      BottomNavigationBarItem(icon: Icon(Icons.monitor_weight), label: "BMI"),
      BottomNavigationBarItem(icon: Icon(Icons.local_fire_department), label: "Calories"),
      BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: "Progress"),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
    ],
  );
}