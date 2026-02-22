/// A Flutter widget to handle user input for Energy-related carbon emissions.

import 'package:flutter/material.dart';
import '../models/emission_data.dart'; // Import the data models
import 'package:intl/intl.dart'; // FIX: Added missing import for DateFormat

// NOTE: In a real app, this factor would be dynamic based on the user's location (grid mix).
// This is a placeholder factor (e.g., 0.45 kg CO2e per kWh, a rough global average).
const double _emissionFactorKwh = 0.45;

class EnergyInputScreen extends StatefulWidget {
  // Placeholder function for saving the calculated emission entry to the database
  final Function(EmissionEntry entry) onSaveEmission;

  const EnergyInputScreen({
    super.key,
    required this.onSaveEmission,
  });

  @override
  State<EnergyInputScreen> createState() => _EnergyInputScreenState();
}

class _EnergyInputScreenState extends State<EnergyInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kwhController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  
  double _calculatedEmission = 0.0;
  bool _isCalculated = false;

  @override
  void dispose() {
    _kwhController.dispose();
    super.dispose();
  }

  // Find the Energy category from the constants
  final EmissionCategory _energyCategory = EmissionConstants.categories.firstWhere(
    (c) => c.id == 'energy',
    orElse: () => const EmissionCategory(
      id: 'default_energy',
      title: 'Energy',
      color: Colors.yellow,
      icon: Icons.flash_on,
    ),
  );

  /// Validates the input and calculates the emission.
  void _calculateEmission() {
    if (_formKey.currentState!.validate()) {
      final double? kwh = double.tryParse(_kwhController.text);

      if (kwh != null && kwh >= 0) {
        setState(() {
          _calculatedEmission = kwh * _emissionFactorKwh;
          _isCalculated = true;
        });
      }
    }
  }

  /// Creates and saves the emission entry.
  void _saveEmission() {
    if (!_isCalculated) {
      // In a real app, use a modal dialog or snackbar instead of print
      print('Calculation required before saving.'); 
      return;
    }

    final entry = EmissionEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Mock ID
      category: _energyCategory,
      emissionValue: _calculatedEmission,
      source: 'Electricity Consumption (${_kwhController.text} kWh)',
      date: _selectedDate,
    );

    // Call the parent callback function
    widget.onSaveEmission(entry);

    // Close the screen, passing the result back (EmissionEntry in this case)
    // For this demonstration, we'll return the calculated emission value (double)
    Navigator.of(context).pop(EnergyData(
      electricity: double.tryParse(_kwhController.text) ?? 0.0,
      lpg: 0.0,
      acUsed: 0.0,
      totalEmission: _calculatedEmission,
    ));
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
        title: const Text('Log Energy Use'),
        backgroundColor: _energyCategory.color,
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

              // 2. Input Fields
              Text(
                'Electricity Consumption (kWh)',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _kwhController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'kWh used',
                  hintText: 'e.g., 10.5',
                  prefixIcon: const Icon(Icons.power),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a value.';
                  }
                  if (double.tryParse(value) == null || double.parse(value)! < 0) {
                    return 'Please enter a valid non-negative number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 3. Calculate Button
              ElevatedButton.icon(
                onPressed: _calculateEmission,
                icon: const Icon(Icons.calculate),
                label: const Text('CALCULATE EMISSION'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _energyCategory.color,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // 4. Results and Save Button
              if (_isCalculated) ...[
                Divider(color: _energyCategory.color.withOpacity(0.5)),
                const SizedBox(height: 10),
                Text(
                  // FIX: Use raw string for $\\text{CO}_2e$
                  r'Estimated $\text{CO}_2$ Emission:',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      // FIX: Use raw string for $\\text{CO}_2e$
                      '${_calculatedEmission.toStringAsFixed(2)}' + r' kg $\text{CO}_2e$',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: _energyCategory.color,
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
