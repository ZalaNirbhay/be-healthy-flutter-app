import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'bmi_calculator.dart';
import 'progress.dart';
import 'profile_setting.dart';
import '../widgets/custom_top_bar.dart';
import '../services/food_service.dart';
import '../services/calorie_service.dart';

class FoodTracker extends StatefulWidget {
  const FoodTracker({super.key});

  @override
  State<FoodTracker> createState() => _FoodTrackerState();
}

class _FoodTrackerState extends State<FoodTracker> {
  // 🔥 Dynamic data from Firestore
  int consumed = 0;
  int goal = 2000;
  int totalProtein = 0;
  int totalCarbs = 0;
  int totalFat = 0;
  bool isLoading = true;

  List<Map<String, dynamic>> foodLog = [];

  int currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    // Seed food database if empty (first-time setup)
    await FoodService.seedFoodDatabase();

    // Load calorie goal from user profile
    final calorieResult = await CalorieService.calculateFromProfile();
    if (calorieResult['success'] == true) {
      goal = calorieResult['tdee'] ?? 2000;
    }

    // Load today's food entries
    await _loadTodayEntries();
  }

  Future<void> _loadTodayEntries() async {
    final entries = await FoodService.getTodayEntries();
    final totals = FoodService.calculateDailyTotals(entries);

    if (mounted) {
      setState(() {
        foodLog = entries;
        consumed = totals['calories'] ?? 0;
        totalProtein = totals['protein'] ?? 0;
        totalCarbs = totals['carbs'] ?? 0;
        totalFat = totals['fat'] ?? 0;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: Colors.transparent,

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: _showAddFoodSheet,
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

                buildTopBar(context, "Food Tracker"),

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

      bottomNavigationBar: buildBottomNav(context),
    );
  }

  // 🔹 GOAL CARD — Dynamic data
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
                  value: isLoading ? 0 : progress,
                  strokeWidth: 12,
                  color: Colors.green,
                  backgroundColor: Colors.grey.shade300,
                ),
              ),

              isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.green,
                        strokeWidth: 2,
                      ),
                    )
                  : Column(
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

          // 🔥 Dynamic macros
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text("Carbs\n${totalCarbs}g", textAlign: TextAlign.center),
              Text("Protein\n${totalProtein}g", textAlign: TextAlign.center),
              Text("Fat\n${totalFat}g", textAlign: TextAlign.center),
            ],
          )
        ],
      ),
    );
  }

  // 🔹 FOOD LOG — Dynamic from Firestore
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

        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Colors.green),
            ),
          )
        else if (foodLog.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                "No food logged today.\nTap + to add food!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ),
          )
        else
          Column(
            children: foodLog.map((item) {
              return Dismissible(
                key: Key(item['id'] ?? item.hashCode.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _deleteEntry(item),
                child: Container(
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
                            child: Icon(
                              FoodService.getMealIcon(item['meal_type'] ?? 'Snack'),
                              color: Colors.green,
                            ),
                          ),

                          const SizedBox(width: 10),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item["meal_type"] ?? "Food",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                width: 150,
                                child: Text(
                                  item["food_name"] ?? "",
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      Text("${item["calories"] ?? 0} kcal"),
                    ],
                  ),
                ),
              );
            }).toList(),
          )
      ],
    );
  }

  // 🔹 TOTAL CARD — Dynamic
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

  // ═══════════════════════════════════════════════
  //  ADD FOOD BOTTOM SHEET (Full-featured)
  // ═══════════════════════════════════════════════

  void _showAddFoodSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddFoodSheet(
        onFoodAdded: () => _loadTodayEntries(),
      ),
    );
  }

  // 🔹 Delete entry with swipe
  Future<void> _deleteEntry(Map<String, dynamic> entry) async {
    final entryId = entry['id'];
    if (entryId == null) return;

    final success = await FoodService.deleteEntry(entryId);
    if (success) {
      await _loadTodayEntries();
    }
  }

  // 🔹 BOTTOM NAV
  Widget buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 2,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,

      onTap: (index) {
        if (index == 2) return;
        if (index == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Dashboard()));
        if (index == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BmiCalculator()));
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

// ═══════════════════════════════════════════════════════════
//  ADD FOOD BOTTOM SHEET WIDGET
// ═══════════════════════════════════════════════════════════

class _AddFoodSheet extends StatefulWidget {
  final VoidCallback onFoodAdded;

  const _AddFoodSheet({required this.onFoodAdded});

  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _customNameController = TextEditingController();
  final TextEditingController _customCalController = TextEditingController();

  List<Map<String, dynamic>> searchResults = [];
  Map<String, dynamic>? selectedFood;
  String selectedMeal = 'Breakfast';
  bool isSearching = false;
  bool isSaving = false;
  bool isCustomMode = false;

  final List<String> mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void initState() {
    super.initState();
    _loadAllFoods();
  }

  Future<void> _loadAllFoods() async {
    setState(() => isSearching = true);
    final results = await FoodService.searchFoodItems('');
    if (mounted) {
      setState(() {
        searchResults = results;
        isSearching = false;
      });
    }
  }

  Future<void> _search(String query) async {
    setState(() => isSearching = true);
    final results = await FoodService.searchFoodItems(query);
    if (mounted) {
      setState(() {
        searchResults = results;
        isSearching = false;
      });
    }
  }

  Future<void> _addSelectedFood() async {
    if (isSaving) return;

    if (isCustomMode) {
      // Custom food entry
      final name = _customNameController.text.trim();
      final cal = int.tryParse(_customCalController.text) ?? 0;

      if (name.isEmpty || cal <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter food name and calories')),
        );
        return;
      }

      setState(() => isSaving = true);

      final result = await FoodService.quickAddFood(
        foodName: name,
        calories: cal,
        mealType: selectedMeal,
      );

      setState(() => isSaving = false);

      if (result['success'] == true) {
        widget.onFoodAdded();
        if (mounted) Navigator.pop(context);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Failed to add')),
          );
        }
      }
      return;
    }

    if (selectedFood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a food item')),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ??
        (selectedFood!['default_serving_g'] ?? 100);

    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }

    setState(() => isSaving = true);

    final nutrition = FoodService.calculateNutrition(selectedFood!, quantity);

    final result = await FoodService.addFoodEntry(
      foodName: selectedFood!['name'],
      mealType: selectedMeal,
      calories: nutrition['calories']!,
      protein: nutrition['protein']!,
      carbs: nutrition['carbs']!,
      fat: nutrition['fat']!,
      quantityGrams: quantity,
      foodItemId: selectedFood!['id'],
      iconName: selectedFood!['icon'] ?? 'fastfood',
    );

    setState(() => isSaving = false);

    if (result['success'] == true) {
      widget.onFoodAdded();
      if (mounted) Navigator.pop(context);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to add')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF5FFF8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Add Food",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isCustomMode = !isCustomMode;
                          selectedFood = null;
                        });
                      },
                      child: Text(
                        isCustomMode ? "Search Food" : "Custom Entry",
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Meal Type Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: mealTypes.map((meal) {
                  final isSelected = selectedMeal == meal;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedMeal = meal),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.green
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Center(
                          child: Text(
                            meal,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Content
          Expanded(
            child: isCustomMode
                ? _buildCustomEntry()
                : _buildSearchEntry(),
          ),

          // Add Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isSaving ? null : _addSelectedFood,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Add to Log",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Custom food entry form
  Widget _buildCustomEntry() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          TextField(
            controller: _customNameController,
            decoration: InputDecoration(
              hintText: "Food name",
              prefixIcon: const Icon(Icons.fastfood),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customCalController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Calories (kcal)",
              prefixIcon: const Icon(Icons.local_fire_department),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Search-based food entry
  Widget _buildSearchEntry() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            onChanged: _search,
            decoration: InputDecoration(
              hintText: "Search food...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Quantity input (shown when food is selected)
        if (selectedFood != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedFood!['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: "${selectedFood!['default_serving_g'] ?? 100}",
                            labelText: "Quantity (grams)",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        children: [
                          Text(
                            "${_getPreviewCalories()} kcal",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            "${selectedFood!['calories_per_100g']} per 100g",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        // Food list
        Expanded(
          child: isSearching
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final food = searchResults[index];
                    final isSelected = selectedFood?['id'] == food['id'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedFood = food;
                          _quantityController.text =
                              '${food['default_serving_g'] ?? 100}';
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.green.shade50
                              : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: isSelected
                              ? Border.all(color: Colors.green, width: 1.5)
                              : null,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.green.shade100,
                              child: Icon(
                                FoodService.getIconFromName(food['icon']),
                                color: Colors.green,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    food['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    "${food['calories_per_100g']} kcal/100g  •  ${food['category']}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle,
                                  color: Colors.green),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  int _getPreviewCalories() {
    if (selectedFood == null) return 0;
    final qty = int.tryParse(_quantityController.text) ??
        (selectedFood!['default_serving_g'] ?? 100);
    final cal = selectedFood!['calories_per_100g'] ?? 0;
    return ((cal * qty) / 100).round();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    _customNameController.dispose();
    _customCalController.dispose();
    super.dispose();
  }
}