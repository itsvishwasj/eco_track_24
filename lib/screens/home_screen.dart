import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; 
import '../data/emission_data.dart';
// Note: We will now use an updated travel input that returns a list
import '../input/travel_input.dart'; 
import '../input/food_input.dart';
import '../input/energy_input.dart';
// New input screen for miscellaneous emissions
import '../input/others_input.dart'; 
import '../settings_screen.dart'; 

// --- Data Models for Charts and State ---

class EmissionCategory {
  final String category;
  final double emission;
  final Color color; // Using standard Flutter Color

  const EmissionCategory(this.category, this.emission, this.color);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key}); 

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Daily data state
  double _totalDailyEmission = 0.0;
  List<TravelData> _travelData = []; // Now stores multiple TravelData objects
  List<MealData> _foodData = [];
  EnergyData? _energyData;
  double _othersEmission = 0.0; // New state variable for Others category
  double _goal = 15.0; // Default goal: 15 kg CO2 per day
  int _touchedIndex = -1; // State for FL Chart interactivity

  // Default categories list, matching what would be returned from EmissionConstants
  final List<EmissionCategory> _defaultCategories = [
    const EmissionCategory('Travel', 0.0, Color(0xFF42A5F5)), // Blue
    const EmissionCategory('Food', 0.0, Color(0xFFFFA726)),   // Orange
    const EmissionCategory('Energy', 0.0, Color(0xFFFFEB3B)), // Yellow
    const EmissionCategory('Others', 0.0, Color(0xFFAB47BC)), // Purple
  ];

  @override
  void initState() {
    super.initState();
    _recalculateTotalEmission();
  }

  // Helper to safely get category color and icon (not used in this simplified model, but good practice)
  Color _getCategoryColor(String id) {
    return _defaultCategories.firstWhere(
      (c) => c.category.toLowerCase() == id.toLowerCase(),
      orElse: () => const EmissionCategory('', 0.0, Colors.grey),
    ).color;
  }

  // --- Input Navigation and Data Handling ---

  // Refactored helper function for navigation to input screens
  Future<void> _navigateAndGetEmissionData<T>(
    Widget screen,
    void Function(T data) updateState,
  ) async {
    final T? result = await Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (context) => screen,
      ),
    );

    if (result != null) {
      updateState(result);
      _recalculateTotalEmission();
    }
  }

  void _navigateAndGetTravelData() {
    _navigateAndGetEmissionData<List<TravelData>>(
      TravelInputScreen(onSaveEmission: (entry) {
        // Since TravelInputScreen returns TravelData, we adapt the mock flow
      }),
      (data) {
        setState(() {
          _travelData.addAll(data);
        });
      },
    );
  }

  void _navigateAndGetFoodData() {
    _navigateAndGetEmissionData<List<MealData>>(
      FoodInputScreen(onSaveEmission: (entry) {
        // Since FoodInputScreen returns MealData, we adapt the mock flow
      }),
      (data) {
        setState(() {
          _foodData.addAll(data);
        });
      },
    );
  }

  void _navigateAndGetEnergyData() {
    _navigateAndGetEmissionData<EnergyData>(
      EnergyInputScreen(onSaveEmission: (entry) {
        // Since EnergyInputScreen returns EnergyData, we adapt the mock flow
      }),
      (data) {
        setState(() {
          _energyData = data;
        });
      },
    );
  }

  void _navigateAndGetOthersData() {
    _navigateAndGetEmissionData<double>(
      OthersInputScreen(onSaveEmission: (entry) {
        // Since OthersInputScreen returns double, we adapt the mock flow
      }),
      (data) {
        setState(() {
          _othersEmission += data; // Add to existing others emission
        });
      },
    );
  }

  void _navigateAndSetGoal() async {
    final newGoal = await Navigator.of(context).push<double>(
      MaterialPageRoute(
        // FIX: Pass the required parameter 'initialGoal'
        builder: (context) => SettingsScreen(initialGoal: _goal), 
      ),
    );

    if (newGoal != null) {
      setState(() {
        _goal = newGoal;
      });
    }
  }

  // --- Data Calculation ---

  void _recalculateTotalEmission() {
    double travelTotal = _travelData.fold(0.0, (sum, data) => sum + data.emission);
    double foodTotal = _foodData.fold(0.0, (sum, data) => sum + data.emission);
    double energyTotal = _energyData?.totalEmission ?? 0.0;
    double othersTotal = _othersEmission;

    setState(() {
      _totalDailyEmission = travelTotal + foodTotal + energyTotal + othersTotal;
    });
  }

  // --- UI Components ---

  Widget _buildInputButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, color: color),
          label: Text(title),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            foregroundColor: Colors.black87,
            backgroundColor: color.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: color, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalProgressCard(ThemeData theme, double currentEmission, double goal) {
    final difference = (goal - currentEmission).abs();
    
    // FIX: Use raw strings (r'...') to avoid interpolation error with '\$'
    final String goalMessage = currentEmission > goal
        ? r'⚠️ Goal Exceeded by ${(currentEmission - goal).toStringAsFixed(2)} kg $\text{CO}_2e$' 
        : r'✅ You have ${difference.toStringAsFixed(2)} kg $\text{CO}_2e$ left until your goal.'; 

    final double progress = currentEmission / goal;
    final Color progressColor = progress > 1.0 ? Colors.red.shade600 : theme.colorScheme.primary;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Daily Progress', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                // FIX: Use raw string
                Text(r'Daily Goal: ${goal.toStringAsFixed(1)} kg $\text{CO}_2e$', style: theme.textTheme.titleLarge), 
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0), // Clamp progress to 1.0 for visualization
                minHeight: 15,
                backgroundColor: progressColor.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              goalMessage,
              style: TextStyle(
                fontSize: 14,
                color: currentEmission > goal ? Colors.red.shade700 : Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Current Total:', style: TextStyle(fontSize: 16)),
                Text(
                  // FIX: Use raw string for the unit part only, interpolating the value outside
                  '${currentEmission.toStringAsFixed(2)}' + r' kg $\text{CO}_2e$',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryChips(ThemeData theme) {
    // 1. Calculate emission totals per category
    final Map<String, double> categoryEmissions = {
      'Travel': _travelData.fold(0.0, (sum, data) => sum + data.emission),
      'Food': _foodData.fold(0.0, (sum, data) => sum + data.emission),
      'Energy': _energyData?.totalEmission ?? 0.0,
      'Others': _othersEmission,
    };

    // 2. Filter out zero emissions and sort (optional)
    final List<MapEntry<String, double>> nonZeroEmissions = categoryEmissions.entries
        .where((e) => e.value > 0)
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value)); // Sort descending

    if (nonZeroEmissions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No entries logged yet. Start tracking your activities!',
            style: TextStyle(fontStyle: FontStyle.italic)),
        ),
      );
    }

    // 3. Build chips
    return Wrap(
      spacing: 8.0, // horizontal spacing
      runSpacing: 8.0, // vertical spacing
      children: nonZeroEmissions.map((entry) {
        final category = _defaultCategories.firstWhere((c) => c.category == entry.key);
        final value = entry.value;

        return Chip(
          avatar: Icon(category.icon, color: category.color),
          label: Text(
            // FIX: Use raw string
            r'${category.title}: ${value.toStringAsFixed(2)} kg $\text{CO}_2e$',
            style: TextStyle(color: category.color),
          ),
          backgroundColor: category.color.withOpacity(0.1),
          side: BorderSide(color: category.color.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        );
      }).toList(),
    );
  }

  Widget _buildPieChart(ThemeData theme) {
    final Map<String, double> categoryEmissions = {
      'Travel': _travelData.fold(0.0, (sum, data) => sum + data.emission),
      'Food': _foodData.fold(0.0, (sum, data) => sum + data.emission),
      'Energy': _energyData?.totalEmission ?? 0.0,
      'Others': _othersEmission,
    };

    final total = categoryEmissions.values.fold(0.0, (sum, value) => sum + value);
    if (total == 0.0) {
      return const SizedBox.shrink();
    }

    final List<PieChartSectionData> sections = categoryEmissions.entries
        .where((entry) => entry.value > 0) // Only show non-zero entries
        .toList()
        .asMap()
        .entries
        .map((entry) {
      final index = entry.key;
      final data = entry.value;
      final categoryInfo = _defaultCategories.firstWhere((c) => c.category == data.key);
      
      final isTouched = index == _touchedIndex;
      final double fontSize = isTouched ? 18 : 14;
      final double radius = isTouched ? 110 : 100;

      return PieChartSectionData(
        color: categoryInfo.color,
        value: data.value,
        title: '${(data.value / total * 100).toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        badgeWidget: isTouched
            ? _buildBadge(categoryInfo.icon, categoryInfo.color, radius)
            : null,
        badgePositionPercentageOffset: 0.98,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Daily Emission Breakdown', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 300,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Legend
        Wrap(
          spacing: 12.0,
          runSpacing: 8.0,
          children: categoryEmissions.entries
              .where((entry) => entry.value > 0)
              .map((entry) {
            final categoryInfo = _defaultCategories.firstWhere((c) => c.category == entry.key);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: categoryInfo.color,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${categoryInfo.category}: ${entry.value.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(width: 4),
                // FIX: Use raw string
                const Text(r'kg $\text{CO}_2e$'),
              ],
            );
          }).toList(),
        )
      ],
    );
  }

  Widget _buildBadge(IconData icon, Color color, double radius) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: radius * 0.25,
      height: radius * 0.25,
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Center(
        child: Icon(icon, color: Colors.white, size: radius * 0.12),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // FIX: Define theme locally inside the build method
    final theme = Theme.of(context); 

    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoTrack Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateAndSetGoal,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. Header and Date ---
              Text('Today: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: theme.textTheme.titleMedium),
              const SizedBox(height: 20),

              // --- 2. Input Buttons (Four buttons now, spread across two rows) ---
              const Text('Log Today\'s Activities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              // Row 1: Travel, Food
              Row(
                children: <Widget>[
                  _buildInputButton('Travel', Icons.directions_car, _getCategoryColor('travel'), _navigateAndGetTravelData),
                  _buildInputButton('Food', Icons.restaurant, _getCategoryColor('food'), _navigateAndGetFoodData),
                ],
              ),
              // Row 2: Energy, Others
              Row(
                children: <Widget>[
                  _buildInputButton('Energy', Icons.flash_on, _getCategoryColor('energy'), _navigateAndGetEnergyData),
                  _buildInputButton('Others', Icons.more_horiz, _getCategoryColor('others'), _navigateAndGetOthersData),
                ],
              ),
              const SizedBox(height: 20),
              
              // --- 3. Goal Progress ---
              _buildGoalProgressCard(theme, _totalDailyEmission, _goal),
              const SizedBox(height: 20),

              // --- 4. Summary Chips ---
              _buildSummaryChips(theme),
              const SizedBox(height: 20),

              // --- 5. Chart Breakdown ---
              _buildPieChart(theme),
              const SizedBox(height: 80), // Extra space for bottom safety
            ],
          ),
        ),
      ),
    );
  }
}
