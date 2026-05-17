import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'bmi_calculator.dart';
import 'progress.dart';
import 'profile_setting.dart';
import '../widgets/custom_top_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/shimmer_loading.dart';
import '../services/food_service.dart';
import '../services/calorie_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

class FoodTracker extends StatefulWidget {
  const FoodTracker({super.key});

  @override
  State<FoodTracker> createState() => _FoodTrackerState();
}

class _FoodTrackerState extends State<FoodTracker>
    with SingleTickerProviderStateMixin {
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
        backgroundColor: ThemeService.accent,
        onPressed: _showAddFoodSheet,
        child: const Icon(Icons.add, color: Colors.white),
      ),

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                buildTopBar(context, "Food Tracker"),

                const SizedBox(height: AppSpacing.lg),

                buildGoalCard(progress),

                const SizedBox(height: AppSpacing.xl),

                buildFoodLog(),

                const SizedBox(height: AppSpacing.lg),

                buildTotalCard(),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  // 🔹 GOAL CARD — Dynamic data
  Widget buildGoalCard(double progress) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: ThemeService.cardColor,
        borderRadius: AppRadius.xlBorder,
      ),

      child: Column(
        children: [

          Text(
            "Daily Goal",
            style: TextStyle(fontSize: 18, color: ThemeService.textPrimary),
          ),

          const SizedBox(height: AppSpacing.lg),

          Stack(
            alignment: Alignment.center,
            children: [

              SizedBox(
                height: 150,
                width: 150,
                child: CircularProgressIndicator(
                  value: isLoading ? 0 : progress,
                  strokeWidth: 12,
                  color: ThemeService.accent,
                  backgroundColor: ThemeService.dividerColor,
                ),
              ),

              isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: ThemeService.accent,
                        strokeWidth: 2,
                      ),
                    )
                  : Column(
                      children: [
                        Text(
                          "$consumed",
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: ThemeService.textPrimary),
                        ),
                        Text("/ $goal KCAL",
                            style: TextStyle(color: ThemeService.textSecondary)),
                      ],
                    )
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // 🔥 Dynamic macros
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroColumn("Carbs", "${totalCarbs}g", Colors.orange),
              _buildMacroColumn("Protein", "${totalProtein}g", Colors.blue),
              _buildMacroColumn("Fat", "${totalFat}g", Colors.purple),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMacroColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: ThemeService.textSecondary)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  // 🔹 FOOD LOG — Dynamic from Firestore
  Widget buildFoodLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Food Log",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ThemeService.textPrimary),
            ),
            Text("See All",
                style: TextStyle(color: ThemeService.accent)),
          ],
        ),

        const SizedBox(height: AppSpacing.base),

        // Animated content switching
        AnimatedSwitcher(
          duration: AppDurations.normal,
          child: isLoading
              ? const ShimmerList(count: 3, key: ValueKey('shimmer'))
              : foodLog.isEmpty
                  ? EmptyStateWidget(
                      key: const ValueKey('empty'),
                      icon: Icons.restaurant_menu,
                      title: "No meals added yet",
                      subtitle:
                          "Start tracking your nutrition\nby adding your first meal",
                      buttonLabel: "Add First Meal",
                      onButtonPressed: _showAddFoodSheet,
                    )
                  : Column(
                      key: const ValueKey('list'),
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
                              borderRadius: AppRadius.lgBorder,
                            ),
                            child: const Icon(Icons.delete,
                                color: Colors.white),
                          ),
                          onDismissed: (_) => _deleteEntry(item),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(15),

                            decoration: BoxDecoration(
                              color: ThemeService.cardColor,
                              borderRadius: AppRadius.lgBorder,
                            ),

                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [

                                Row(
                                  children: [

                                    CircleAvatar(
                                      backgroundColor:
                                          ThemeService.accent.withOpacity(0.2),
                                      child: Icon(
                                        FoodService.getMealIcon(
                                            item['meal_type'] ?? 'Snack'),
                                        color: ThemeService.accent,
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item["meal_type"] ?? "Food",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: ThemeService.textPrimary),
                                        ),
                                        SizedBox(
                                          width: 150,
                                          child: Text(
                                            item["food_name"] ?? "",
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                color: ThemeService
                                                    .textSecondary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                Text("${item["calories"] ?? 0} kcal",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: ThemeService.textPrimary)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
        ),
      ],
    );
  }

  // 🔹 TOTAL CARD — Dynamic
  Widget buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),

      decoration: BoxDecoration(
        color: ThemeService.cardColor,
        borderRadius: AppRadius.xlBorder,
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Total Consumed",
              style: TextStyle(color: ThemeService.textSecondary)),
          Text(
            "$consumed kcal",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: ThemeService.textPrimary),
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
      decoration: BoxDecoration(
        color: ThemeService.bottomSheetColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ThemeService.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Add Food",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ThemeService.textPrimary),
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
                        style: TextStyle(color: ThemeService.accent),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: ThemeService.textSecondary),
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
                color: ThemeService.selectorBackground,
                borderRadius: AppRadius.xlBorder,
              ),
              child: Row(
                children: mealTypes.map((meal) {
                  final isSelected = selectedMeal == meal;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedMeal = meal),
                      child: AnimatedContainer(
                        duration: AppDurations.fast,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ThemeService.accent
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
                                  : ThemeService.chipUnselectedText,
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
                  backgroundColor: ThemeService.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.xlBorder,
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
            style: TextStyle(color: ThemeService.textPrimary),
            decoration: InputDecoration(
              hintText: "Food name",
              hintStyle: TextStyle(color: ThemeService.textSecondary),
              prefixIcon: Icon(Icons.fastfood, color: ThemeService.textSecondary),
              filled: true,
              fillColor: ThemeService.inputFillColor,
              border: OutlineInputBorder(
                borderRadius: AppRadius.xlBorder,
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customCalController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: ThemeService.textPrimary),
            decoration: InputDecoration(
              hintText: "Calories (kcal)",
              hintStyle: TextStyle(color: ThemeService.textSecondary),
              prefixIcon: Icon(Icons.local_fire_department,
                  color: ThemeService.textSecondary),
              filled: true,
              fillColor: ThemeService.inputFillColor,
              border: OutlineInputBorder(
                borderRadius: AppRadius.xlBorder,
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
            style: TextStyle(color: ThemeService.textPrimary),
            decoration: InputDecoration(
              hintText: "Search food...",
              hintStyle: TextStyle(color: ThemeService.textSecondary),
              prefixIcon: Icon(Icons.search, color: ThemeService.textSecondary),
              filled: true,
              fillColor: ThemeService.inputFillColor,
              border: OutlineInputBorder(
                borderRadius: AppRadius.xlBorder,
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
                color: ThemeService.isDark
                    ? ThemeService.accent.withOpacity(0.1)
                    : Colors.green.shade50,
                borderRadius: AppRadius.mdBorder,
                border: Border.all(color: ThemeService.accent, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedFood!['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: ThemeService.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: ThemeService.textPrimary),
                          decoration: InputDecoration(
                            hintText:
                                "${selectedFood!['default_serving_g'] ?? 100}",
                            labelText: "Quantity (grams)",
                            labelStyle:
                                TextStyle(color: ThemeService.textSecondary),
                            filled: true,
                            fillColor: ThemeService.inputFillColor,
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.mdBorder,
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: ThemeService.accent,
                            ),
                          ),
                          Text(
                            "${selectedFood!['calories_per_100g']} per 100g",
                            style: TextStyle(
                              fontSize: 11,
                              color: ThemeService.textSecondary,
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
              ? Center(
                  child: CircularProgressIndicator(
                      color: ThemeService.accent),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final food = searchResults[index];
                    final isSelected =
                        selectedFood?['id'] == food['id'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedFood = food;
                          _quantityController.text =
                              '${food['default_serving_g'] ?? 100}';
                        });
                      },
                      child: AnimatedContainer(
                        duration: AppDurations.fast,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ThemeService.accent.withOpacity(
                                  ThemeService.isDark ? 0.15 : 0.08)
                              : ThemeService.solidCardColor,
                          borderRadius: AppRadius.mdBorder,
                          border: isSelected
                              ? Border.all(
                                  color: ThemeService.accent, width: 1.5)
                              : null,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  ThemeService.accent.withOpacity(0.15),
                              child: Icon(
                                FoodService.getIconFromName(food['icon']),
                                color: ThemeService.accent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    food['name'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: ThemeService.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    "${food['calories_per_100g']} kcal/100g  •  ${food['category']}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ThemeService.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle,
                                  color: ThemeService.accent),
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