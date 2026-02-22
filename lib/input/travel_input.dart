/// A Flutter widget to handle user input for Travel-related carbon emissions.

import 'package:flutter/material.dart';
import '../models/emission_data.dart'; // Import the data models
import 'package:intl/intl.dart'; // FIX: Added missing import for DateFormat

// --- Emission Factors (in kg CO2e per km) ---
// Note: These are rough, simple estimates for demonstration.
// Real-world factors vary widely based on fuel, vehicle efficiency, and occupancy.
const Map<String, double> _emissionFactors = {
  'car': 0.170,  // Average gasoline car
  'bus': 0.089,  // Public bus
  'train': 0.040, // Rail/Electric train
  'plane': 0.250, // Short-haul flight
};

class TravelInputScreen extends StatefulWidget {
  final Function(EmissionEntry entry) onSaveEmission;

  const TravelInputScreen({
    super.key,
    required this.onSaveEmission,
  });

  @override
  State<TravelInputScreen> createState() => _TravelInputScreenState();
}

class _TravelInputScreenState extends State<TravelInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _distanceController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // State variables for the selected mode and calculated results
  String? _selectedMode; // e.g., 'car', 'bus'
  double _calculatedEmission = 0.0;
  bool _isCalculated = false;

  @override
  void dispose() {
    _distanceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Find the Travel category from the constants
  final EmissionCategory _travelCategory = EmissionConstants.categories.firstWhere(
    (c) => c.id == 'travel',
    orElse: () => const EmissionCategory(
      id: 'default_travel',
      title: 'Travel',
      color: Colors.blue,
      icon: Icons.directions_car,
    ),
  );

  /// Validates the input and calculates the emission.
  void _calculateEmission() {
    if (_formKey.currentState!.validate() && _selectedMode != null) {
      final double? distance = double.tryParse(_distanceController.text);
      final double factor = _emissionFactors[_selectedMode!] ?? 0.0;

      if (distance != null && distance >= 0) {
        setState(() {
          _calculatedEmission = distance * factor;
          _isCalculated = true;
        });
      }
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
      category: _travelCategory,
      emissionValue: _calculatedEmission,
      source: _descriptionController.text.isNotEmpty 
          ? _descriptionController.text 
          : 'Trip by $_selectedMode (${_distanceController.text} km)',
      date: _selectedDate,
    );

    // Call the parent callback function
    widget.onSaveEmission(entry);

    // Close the screen, passing the result back (TravelData in this case)
    Navigator.of(context).pop([TravelData(
      mode: _selectedMode!,
      distance: double.tryParse(_distanceController.text) ?? 0.0,
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
        title: const Text('Log Travel'),
        backgroundColor: _travelCategory.color,
        foregroundColor: Colors.white,
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

              // 2. Mode Dropdown
              Text(
                'Mode of Transport',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.directions_car),
                  labelText: 'Select Mode',
                ),
                value: _selectedMode,
                hint: const Text('Choose a travel mode...'),
                items: _emissionFactors.keys.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value.substring(0, 1).toUpperCase() + value.substring(1)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedMode = newValue;
                    _isCalculated = false; // Recalculate if mode changes
                  });
                },
                validator: (value) => value == null ? 'Please select a mode of transport.' : null,
              ),
              const SizedBox(height: 24),

              // 3. Distance Input
              Text(
                'Distance Traveled (km)',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _distanceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Distance in km',
                  hintText: 'e.g., 5.0',
                  prefixIcon: const Icon(Icons.social_distance),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a distance.';
                  }
                  if (double.tryParse(value) == null || double.parse(value)! < 0) {
                    return 'Please enter a valid non-negative number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 4. Description
              Text(
                'Description (Optional)',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: 'Brief description',
                  hintText: 'e.g., Daily commute',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // 5. Calculate Button
              ElevatedButton.icon(
                onPressed: _calculateEmission,
                icon: const Icon(Icons.calculate),
                label: const Text('CALCULATE EMISSION'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _travelCategory.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // 6. Results and Save Button
              if (_isCalculated) ...[
                Divider(color: _travelCategory.color.withOpacity(0.5)),
                const SizedBox(height: 10),
                Text(
                  r'Estimated $\text{CO}_2$ Emission:', // FIX: Use raw string
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
                        color: _travelCategory.color,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _saveEmission,
                      icon: const Icon(Icons.save),
                      label: const Text('SAVE ENTRY'),
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
