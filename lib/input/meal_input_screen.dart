// lib/input/meal_input_screen.dart

import 'package:flutter/material.dart';
import '../models/emission_data.dart'; // Ensure this is '../models/emission_data.dart'

// This screen seems to be an old or incomplete version, 
// using an old EmissionFactors class that does not exist in the provided emission_data.dart

class MealInputScreen extends StatefulWidget {
  final String mealName;
  const MealInputScreen({super.key, required this.mealName});

  @override
  State<MealInputScreen> createState() => _MealInputScreenState();
}

class _MealInputScreenState extends State<MealInputScreen> {
  // Key: Food category, Value: [isEnabled, quantity]
  final Map<String, List<dynamic>> _foodState = {}; 
  double _currentEmission = 0.0;
  String _ecoTip = '';

  // Placeholder for EmissionFactors.food (based on food_input.dart's data)
  final Map<String, double> _foodEmissionFactors = {
    'Beef & Lamb': 6.0,
    'Poultry & Pork': 0.7,
    'Fish & Seafood': 0.5,
    'Dairy & Eggs': 0.4,
    'Rice & Grains': 0.3,
    'Vegetables & Fruits': 0.1,
    'Processed Foods': 0.8,
  };

  @override
  void initState() {
    super.initState();
    // Initialize state from emission factors
    _foodEmissionFactors.keys.forEach((category) {
      _foodState[category] = [false, 0.0]; // [isEnabled, quantity]
    });
    _updateEmission(); // Calculate initial zero emission
  }

  void _updateEmission() {
    double totalEmission = 0.0;
    double meatTotal = 0.0;
    double riceTotal = 0.0;
    
    _foodState.forEach((category, state) {
      final isEnabled = state[0] as bool;
      final quantity = state[1] as double;
      
      if (isEnabled && quantity > 0) {
        final factor = _foodEmissionFactors[category] ?? 0.0;
        totalEmission += factor * quantity;
      }
      
      // Track specific quantities for tips
      if (category.contains('Beef & Lamb') && isEnabled) meatTotal += quantity;
      if (category.contains('Rice & Grains') && isEnabled) riceTotal += quantity;
    });

    setState(() {
      _currentEmission = totalEmission;
      _ecoTip = _generateTip(meatTotal, riceTotal);
    });
  }

  String _generateTip(double meatServings, double riceServings) {
    if (meatServings >= 2.0) {
      return "🥩 High Meat Intake: Try one plant-based meal daily to significantly cut your footprint!";
    }
    if (riceServings >= 3.0) {
      return "🍚 High Rice Intake: Consider replacing some rice with locally sourced potatoes or pasta to vary your footprint.";
    }
    if (_currentEmission > 10.0) {
      return "🚩 High Footprint: Today's meal is high. Look for sustainable alternatives next time.";
    }
    if (_currentEmission > 0.1) {
      return "👍 Great Choice! Your meal has a relatively low carbon footprint.";
    }
    return "Start logging your food items to see your estimated footprint and get an eco tip!";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foodCategory = EmissionConstants.categories.firstWhere(
      (c) => c.id == 'food',
      orElse: () => const EmissionCategory(id: 'food', title: 'Food', color: Colors.green, icon: Icons.local_dining),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.mealName} Input', style: TextStyle(color: foodCategory.color, fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () {
              // In a real app, this would save the MealData object and pop
              // Returning the total emission as a placeholder for simplicity
              Navigator.pop(context, _currentEmission);
            },
            tooltip: 'Save Meal',
            color: Colors.green,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emission Summary Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: foodCategory.color.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estimated CO₂e:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(
                      '${_currentEmission.toStringAsFixed(2)} kg',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: foodCategory.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Eco Tip Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.lightBlue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _ecoTip,
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Food Item Checklists
            Text(
              'Select Food Items and Quantity (Servings/100g)',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // List of food items
            ..._foodEmissionFactors.keys.map((category) {
              return _buildFoodItemSelector(theme, category, foodCategory.color);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItemSelector(ThemeData theme, String category, Color color) {
    final isEnabled = _foodState[category]![0] as bool;
    final quantity = _foodState[category]![1] as double;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isEnabled ? color.withOpacity(0.5) : Colors.grey.shade300)
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(category, style: TextStyle(fontWeight: FontWeight.bold, color: isEnabled ? color : Colors.black)),
            value: isEnabled,
            onChanged: (bool value) {
              setState(() {
                _foodState[category]![0] = value;
                // Reset quantity when disabled
                if (!value) _foodState[category]![1] = 0.0;
                _updateEmission();
              });
            },
            activeColor: theme.colorScheme.primary,
          ),
          
          // Slider visible only when enabled
          if (isEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Servings:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(quantity.toStringAsFixed(1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: quantity,
                    min: 0,
                    max: 5,
                    divisions: 10, // 0.5 step size
                    label: quantity.toStringAsFixed(1),
                    onChanged: (double value) {
                      setState(() {
                        _foodState[category]![1] = value;
                        _updateEmission();
                      });
                    },
                    activeColor: theme.colorScheme.secondary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}