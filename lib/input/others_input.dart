/// A Flutter widget to handle user input for Miscellaneous ("Others") carbon emissions.

import 'package:flutter/material.dart';
import '../models/emission_data.dart'; // Import the data models
import 'package:intl/intl.dart'; // FIX: Added missing import for DateFormat

class OthersInputScreen extends StatefulWidget {
  final Function(EmissionEntry entry) onSaveEmission;

  const OthersInputScreen({
    super.key,
    required this.onSaveEmission,
  });

  @override
  State<OthersInputScreen> createState() => _OthersInputScreenState();
}

class _OthersInputScreenState extends State<OthersInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emissionController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  
  double _calculatedEmission = 0.0;
  bool _isCalculated = false;

  @override
  void dispose() {
    _emissionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Find the Others category from the constants
  final EmissionCategory _othersCategory = EmissionConstants.categories.firstWhere(
    (c) => c.id == 'others',
    orElse: () => const EmissionCategory(
      id: 'default_others',
      title: 'Others',
      color: Colors.purple,
      icon: Icons.inventory_2,
    ),
  );

  /// Validates the input and prepares the emission value.
  void _calculateEmission() {
    if (_formKey.currentState!.validate()) {
      final double? emission = double.tryParse(_emissionController.text);

      if (emission != null && emission >= 0) {
        setState(() {
          _calculatedEmission = emission; // In this screen, the input is the emission value itself
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
      category: _othersCategory,
      emissionValue: _calculatedEmission,
      source: _descriptionController.text.isNotEmpty 
          ? _descriptionController.text 
          : 'Miscellaneous Emission',
      date: _selectedDate,
    );

    // Call the parent callback function
    widget.onSaveEmission(entry);

    // Close the screen, passing the result back (double in this case)
    Navigator.of(context).pop(_calculatedEmission); 
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
        title: const Text('Log Others/Miscellaneous'),
        backgroundColor: _othersCategory.color,
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

              // 2. Description
              Text(
                'Description (e.g., Online Shopping, Services)',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: 'Brief description',
                  hintText: 'e.g., New T-shirt shipment (2kg CO2e est.)',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // 3. Emission Value Input
              Text(
                r'Input Emission Value Directly (kg $\text{CO}_2e$)', // FIX: Use raw string
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emissionController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Emission Value',
                  hintText: 'e.g., 3.4',
                  prefixIcon: const Icon(Icons.public),
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

              // 4. Calculate/Verify Button
              ElevatedButton.icon(
                onPressed: _calculateEmission,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('VERIFY & PREPARE TO SAVE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _othersCategory.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // 5. Results and Save Button
              if (_isCalculated) ...[
                Divider(color: _othersCategory.color.withOpacity(0.5)),
                const SizedBox(height: 10),
                const Text(
                  'Emission Value to Save:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                        color: _othersCategory.color,
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
