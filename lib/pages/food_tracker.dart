import 'package:flutter/material.dart';

class FoodTracker extends StatefulWidget {
  const FoodTracker({super.key});

  @override
  State<FoodTracker> createState() => _FoodTrackerState();
}

class _FoodTrackerState extends State<FoodTracker> {
  int consumed = 1150;
  int goal = 2000;

  int currentIndex = 1;

  List<Map<String, dynamic>> foodLog = [
    {
      "title": "Breakfast",
      "desc": "Oatmeal and black coffee",
      "cal": 350,
      "icon": Icons.free_breakfast,
    },
    {
      "title": "Lunch",
      "desc": "Grilled chicken salad",
      "cal": 600,
      "icon": Icons.lunch_dining,
    },
    {
      "title": "Snack",
      "desc": "Greek yogurt & berries",
      "cal": 200,
      "icon": Icons.icecream,
    },
  ];

  @override
  Widget build(BuildContext context) {
    double progress = consumed / goal;

    return Scaffold(
      backgroundColor: Colors.transparent,

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: addFoodDialog,
        child: const Icon(Icons.add),
      ),

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

                buildGoalCard(progress),

                const SizedBox(height: 25),

                buildFoodLog(),

                const SizedBox(height: 20),

                buildTotalCard(),
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

        const Icon(Icons.menu),

        const Text(
          "Food Tracker",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.person, color: Colors.white),
        ),
      ],
    );
  }

  // 🔹 GOAL CARD
  Widget buildGoalCard(double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(25),
      ),

      child: Column(
        children: [

          const Text(
            "Daily Goal",
            style: TextStyle(fontSize: 18),
          ),

          const SizedBox(height: 20),

          Stack(
            alignment: Alignment.center,
            children: [

              SizedBox(
                height: 150,
                width: 150,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  color: Colors.green,
                  backgroundColor: Colors.grey.shade300,
                ),
              ),

              Column(
                children: [
                  Text(
                    "$consumed",
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Text("/ $goal KCAL"),
                ],
              )
            ],
          ),

          const SizedBox(height: 20),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text("Carbs\n120g", textAlign: TextAlign.center),
              Text("Protein\n85g", textAlign: TextAlign.center),
              Text("Fat\n45g", textAlign: TextAlign.center),
            ],
          )
        ],
      ),
    );
  }

  // 🔹 FOOD LOG
  Widget buildFoodLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              "Food Log",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text("See All", style: TextStyle(color: Colors.green)),
          ],
        ),

        const SizedBox(height: 15),

        Column(
          children: foodLog.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(15),

              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  Row(
                    children: [

                      CircleAvatar(
                        backgroundColor: Colors.green.shade200,
                        child: Icon(item["icon"], color: Colors.green),
                      ),

                      const SizedBox(width: 10),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item["title"],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          Text(item["desc"]),
                        ],
                      ),
                    ],
                  ),

                  Text("${item["cal"]} kcal"),
                ],
              ),
            );
          }).toList(),
        )
      ],
    );
  }

  // 🔹 TOTAL CARD
  Widget buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(25),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Total Consumed"),
          Text(
            "$consumed kcal",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // 🔹 ADD FOOD DIALOG
  void addFoodDialog() {
    TextEditingController title = TextEditingController();
    TextEditingController cal = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Add Food"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: "Food Name")),
              TextField(controller: cal, decoration: const InputDecoration(labelText: "Calories"), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                int calories = int.tryParse(cal.text) ?? 0;

                setState(() {
                  foodLog.add({
                    "title": title.text,
                    "desc": "Custom food",
                    "cal": calories,
                    "icon": Icons.fastfood,
                  });

                  consumed += calories;
                });

                Navigator.pop(context);
              },
              child: const Text("Add"),
            )
          ],
        );
      },
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
        BottomNavigationBarItem(icon: Icon(Icons.local_fire_department), label: "Calories"),
        BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: "Workout"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}