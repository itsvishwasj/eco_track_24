/// A Flutter widget to handle user input for Food-related carbon emissions.

import 'package:flutter/material.dart';
import '../models/emission_data.dart';
// FIX: Added missing import for DateFormat
import 'package:intl/intl.dart'; 


// --- Food Emission Factors (in kg CO2e per 100g or per standardized serving) ---
// Note: These factors are highly simplified for demonstration.
// Real-world factors vary widely based on fuel, vehicle efficiency, and occupancy.
const Map<String, double> _foodEmissionFactors = {
  'Beef (per 100g)': 6.0,
  'Lamb (per 100g)': 4.0,
  'Poultry (per 100g)': 0.7,
  'Fish (Farm, per 100g)': 0.5,
  'Dairy (Milk/Cheese, per 100g)': 0.4,
  'Grains (Rice/Bread, per 100g)': 0.3,
  'Vegetables (per 100g)': 0.1,
  'Fruits (per 100g)': 0.2,
  'Processed Snacks (per serving)': 0.8,
  'Coffee/Tea (per cup)': 0.15,
};

class FoodInputScreen extends StatefulWidget {
  final Function(EmissionEntry entry) onSaveEmission;

  const FoodInputScreen({
    super.key,
    required this.onSaveEmission,
  });

  @override
  State<FoodInputScreen> createState() => _FoodInputScreenState();
}

class _FoodInputScreenState extends State<FoodInputScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedFood;
  double _quantity = 1.0;
  DateTime _selectedDate = DateTime.now();

  double _calculatedEmission = 0.0;
  bool _isCalculated = false;

  // Find the Food category from the constants
  final EmissionCategory _foodCategory = EmissionConstants.categories.firstWhere(
    (c) => c.id == 'food',
    orElse: () => const EmissionCategory(
      id: 'default_food',
      title: 'Food',
      color: Colors.orange,
      icon: Icons.restaurant,
    ),
  );

  /// Validates the input and calculates the emission.
  void _calculateEmission() {
    if (_formKey.currentState!.validate() && _selectedFood != null) {
      final double factor = _foodEmissionFactors[_selectedFood!] ?? 0.0;
      
      setState(() {
        _calculatedEmission = factor * _quantity;
        _isCalculated = true;
      });
    }
  }

  /// Creates and saves the emission entry.
  void _saveEmission() {
    if (!_isCalculated) {
      print('Calculation required before saving.'); 
      return;
    }

    final entry = EmissionEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Mock ID
      category: _foodCategory,
      emissionValue: _calculatedEmission,
      source: 'Meal Entry: ${_selectedFood!} ($_quantity servings)',
      date: _selectedDate,
    );

    // Call the parent callback function
    widget.onSaveEmission(entry);

    // Close the screen, passing the result back (MealData in this case)
    Navigator.of(context).pop([MealData(
      type: _selectedFood!,
      emission: _calculatedEmission,
    )]);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Meal'),
        backgroundColor: _foodCategory.color,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // 1. Date Picker
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text('Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
                onTap: _selectDate,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.dividerColor),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Food Dropdown
              Text(
                'Select Food Item',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.fastfood),
                  labelText: 'Food Category',
                ),
                value: _selectedFood,
                hint: const Text('Choose a food item...'),
                items: _foodEmissionFactors.keys.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedFood = newValue;
                    _isCalculated = false; // Recalculate if source changes
                  });
                },
                validator: (value) => value == null ? 'Please select a food item.' : null,
              ),
              const SizedBox(height: 24),

              // 3. Quantity Slider
              Text(
                'Quantity (Servings or 100g increments)',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Quantity:', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(_quantity.toStringAsFixed(1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: _quantity,
                        min: 0.1,
                        max: 5.0,
                        divisions: 49, // Allows steps of 0.1
                        label: _quantity.toStringAsFixed(1),
                        onChanged: (double value) {
                          setState(() {
                            _quantity = value;
                            _isCalculated = false; // Recalculate if quantity changes
                          });
                        },
                        activeColor: _foodCategory.color,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 4. Calculate Button
              ElevatedButton.icon(
                onPressed: _calculateEmission,
                icon: const Icon(Icons.calculate),
                label: const Text('CALCULATE EMISSION'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _foodCategory.color,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // 5. Results and Save Button
              if (_isCalculated) ...[
                Divider(color: _foodCategory.color.withOpacity(0.5)),
                const SizedBox(height: 10),
                Text(
                  r'Total Estimated $\text{CO}_2$ Emission for Meal:', // FIX: Use raw string
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      // FIX: Use raw string
                      '${_calculatedEmission.toStringAsFixed(2)}' + r' kg $\text{CO}_2e$',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: _foodCategory.color,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _saveEmission,
                      icon: const Icon(Icons.save),
                      label: const Text('SAVE MEAL'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
