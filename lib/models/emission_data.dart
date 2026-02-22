/// This file defines the data models for tracking carbon emissions.
/// It includes the EmissionCategory, the EmissionEntry, and the DailyEmission classes.

import 'package:flutter/material.dart';

// --- 1. EmissionCategory Model ---

/// Represents a major category of carbon emission (e.g., Travel, Food).
/// It includes metadata like a user-friendly title, color, and icon.
class EmissionCategory {
  /// Unique identifier for the category.
  final String id;

  /// User-friendly name of the category.
  final String title;

  /// Color used for visualization (charts, tiles).
  final Color color;

  /// Icon used to represent the category.
  final IconData icon;

  const EmissionCategory({
    required this.id,
    required this.title,
    required this.color,
    required this.icon,
  });

  @override
  String toString() {
    return 'EmissionCategory(id: $id, title: $title)';
  }
}

// --- 2. EmissionEntry Model ---

/// Represents a single, recorded event of carbon emission.
class EmissionEntry {
  /// Unique identifier for this entry (e.g., a Firestore ID).
  final String id;

  /// The category this emission belongs to (e.g., Travel).
  final EmissionCategory category;

  /// The value of the carbon emission (e.g., 2.5 kg CO2e).
  final double emissionValue;

  /// A description or source of the emission (e.g., "Flight to New York", "Beef Dinner").
  final String source;

  /// The date and time the emission was recorded.
  final DateTime date;

  const EmissionEntry({
    required this.id,
    required this.category,
    required this.emissionValue,
    required this.source,
    required this.date,
  });

  /// Creates a copy of the entry, optionally updating some fields.
  EmissionEntry copyWith({
    String? id,
    EmissionCategory? category,
    double? emissionValue,
    String? source,
    DateTime? date,
  }) {
    return EmissionEntry(
      id: id ?? this.id,
      category: category ?? this.category,
      emissionValue: emissionValue ?? this.emissionValue,
      source: source ?? this.source,
      date: date ?? this.date,
    );
  }

  // A helper to show total emission and category in a readable format
  @override
  String toString() {
    return '${emissionValue.toStringAsFixed(2)} kg CO2e from ${category.title} (${source}) on ${date.toIso8601String().substring(0, 10)}';
  }
}

// --- 3. Predefined Categories and Mock Data (Utility) ---

/// Utility class to provide access to predefined categories and mock data.
class EmissionConstants {
  /// List of all primary emission categories.
  static const List<EmissionCategory> categories = [
    EmissionCategory(
      id: 'travel',
      title: 'Travel',
      color: Color(0xFF4C7B8E), // Blue-Gray
      icon: Icons.flight_takeoff,
    ),
    EmissionCategory(
      id: 'food',
      title: 'Food',
      color: Color(0xFF5B8C5A), // Green
      icon: Icons.local_dining,
    ),
    EmissionCategory(
      id: 'energy',
      title: 'Energy',
      color: Color(0xFFB56576), // Rose
      icon: Icons.lightbulb,
    ),
    EmissionCategory(
      id: 'shopping',
      title: 'Shopping',
      color: Color(0xFFC9A66B), // Gold
      icon: Icons.shopping_bag,
    ),
    EmissionCategory(
      id: 'waste',
      title: 'Waste',
      color: Color(0xFF6C5B7B), // Purple-Gray
      icon: Icons.delete_sweep,
    ),
  ];

  /// Provides a sample of mock emission entries for demonstration.
  static List<EmissionEntry> get mockEntries {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));

    final travel = categories.firstWhere((c) => c.id == 'travel');
    final food = categories.firstWhere((c) => c.id == 'food');
    final energy = categories.firstWhere((c) => c.id == 'energy');

    return [
      EmissionEntry(
        id: '1',
        category: travel,
        emissionValue: 0.85,
        source: 'Commute by Car (5km)',
        date: today,
      ),
      EmissionEntry(
        id: '2',
        category: food,
        emissionValue: 1.5,
        source: 'Beef Dinner',
        date: today,
      ),
      EmissionEntry(
        id: '3',
        category: energy,
        emissionValue: 2.1,
        source: 'Daily Electricity Use',
        date: today,
      ),
      EmissionEntry(
        id: '4',
        category: travel,
        emissionValue: 0.12,
        source: 'Bus Ride',
        date: yesterday,
      ),
      EmissionEntry(
        id: '5',
        category: food,
        emissionValue: 0.45,
        source: 'Vegetarian Lunch',
        date: yesterday,
      ),
      EmissionEntry(
        id: '6',
        category: energy,
        emissionValue: 1.9,
        source: 'Daily Electricity Use',
        date: twoDaysAgo,
      ),
    ];
  }
}

// --------------------------------------------------------------------------
// --- 4. Models required by StorageService and other input screens ---
// NOTE: These are simplified models to make the project compile.
// --------------------------------------------------------------------------

/// Represents data collected from a travel input.
class TravelData {
  final String mode;
  final double distance;
  final double emission;

  const TravelData({
    required this.mode,
    required this.distance,
    required this.emission,
  });
}

/// Represents data collected from a meal input.
class MealData {
  final String name; // e.g., "Breakfast" or "Beef Dinner"
  final double emission;

  const MealData({
    required this.name,
    required this.emission,
  });
}

/// Represents data collected from an energy input.
class EnergyData {
  final double electricity;
  final double lpg;
  final bool acUsed;
  final bool heaterUsed;
  final bool fridgeAlwaysOn;
  final double emission;

  const EnergyData({
    required this.electricity,
    required this.lpg,
    required this.acUsed,
    required this.heaterUsed,
    required this.fridgeAlwaysOn,
    required this.emission,
  });
}

/// Represents the total calculated emissions for a single day.
/// This is the model used by the StorageService (Hive Box) and InsightsScreen.
class DailyEmission {
  final String date; // Formatted as YYYY-MM-DD
  // NOTE: These fields (travel, food, energy) were included in the previous model,
  // but they are not used in the current version of the code snippet for total
  // calculation, so we can simplify by removing them or keeping them for future use.
  // For now, we are adding the required `entries` and `total` getter.
  
  // The raw list of all individual emission events for the day.
  final List<EmissionEntry> entries;

  const DailyEmission({
    required this.date,
    required this.entries,
  });

  /// Calculates the total emission for the day. This is the field 
  /// that insights_screen.dart and home_screen.dart were looking for.
  double get total {
    return entries.fold(0.0, (sum, entry) => sum + entry.emissionValue);
  }
  
  // Temporary: Add a copyWith method to help with updates if needed
  DailyEmission copyWith({
    String? date,
    List<EmissionEntry>? entries,
  }) {
    return DailyEmission(
      date: date ?? this.date,
      entries: entries ?? this.entries,
    );
  }
}
