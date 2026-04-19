import 'package:flutter/material.dart';

class WeightLoose extends StatefulWidget {
  const WeightLoose({super.key});

  @override
  State<WeightLoose> createState() => _WeightLooseState();
}

class _WeightLooseState extends State<WeightLoose> {
  double selectedGoal = 0.5; // kg/week
  int currentIndex = 2;

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

                buildTopBar(),

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

                const SizedBox(height: 25),

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

      bottomNavigationBar: buildBottomNav(),
    );
  }

  // 🔹 TOP BAR
  Widget buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [

        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back),
        ),

        const Text(
          "Weight Loss Planner",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const Icon(Icons.person),
      ],
    );
  }

  // 🔹 GOAL SELECTOR
  Widget buildGoalSelector() {
    List<double> goals = [0.25, 0.5, 1];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
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
              },

              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),

                child: Center(
                  child: Text(
                    "$goal kg",
                    style: TextStyle(
                      color: isSelected ? Colors.green : Colors.black54,
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
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(25),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "TARGET CALORIES",
            style: TextStyle(color: Colors.black54),
          ),

          const SizedBox(height: 10),

          Row(
            children: const [
              Text(
                "1,800",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 10),
              Text("kcal/day"),
            ],
          ),
        ],
      ),
    );
  }

  // 🔹 PROGRESS CARD
  Widget buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(25),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              const Text(
                "Projected Progress",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "-${selectedGoal}kg/wk",
                  style: const TextStyle(color: Colors.green),
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
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
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

  // 🔹 BUTTON
  Widget buildStartButton() {
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
          "Start Plan →",
          style: TextStyle(fontSize: 18, color: Colors.black),
        ),
      ),
    );
  }

  // 🔹 BOTTOM NAV
  Widget buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: Colors.green,

      onTap: (index) {
        setState(() {
          currentIndex = index;
        });
      },

      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Planner"),
        BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: "Progress"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}