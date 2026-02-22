import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final double initialGoal;

  // Constructor now requires initialGoal
  const SettingsScreen({super.key, required this.initialGoal}); 

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _currentGoal;
  late TextEditingController _goalController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _currentGoal = widget.initialGoal;
    _goalController = TextEditingController(text: _currentGoal.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      final double? newGoal = double.tryParse(_goalController.text);
      if (newGoal != null && newGoal > 0) {
        // Pop the screen and return the new goal value
        Navigator.of(context).pop(newGoal); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Use raw string for the unit text
              Text(
                r'Set Daily Carbon Emission Goal (kg $\text{CO}_2e$)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _goalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Daily Goal',
                  suffixText: 'kg CO2e',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a goal.';
                  }
                  if (double.tryParse(value) == null || double.parse(value)! <= 0) {
                    return 'Please enter a valid number greater than zero.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveGoal,
                  icon: const Icon(Icons.save),
                  label: const Text('SAVE GOAL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
