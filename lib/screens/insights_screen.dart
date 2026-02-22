// lib/insights_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'data/emission_data.dart';
import 'data/storage_service.dart';
import 'dart:math';
// FIX: Import DateFormat for date formatting utilities
import 'package:intl/intl.dart'; 

class InsightsScreen extends StatefulWidget {
  final StorageService storageService;
  const InsightsScreen({super.key, required this.storageService});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  String _selectedView = 'Daily';
  List<DailyEmission> _weeklyData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }
  
  Future<void> _loadWeeklyData() async {
    // Generate mock data for the 7 days if data is not present (for demo)
    final mockData = _generateMockWeeklyData();
    // In a real app, you'd use: final storedData = widget.storageService.getWeeklyEmissions();
    
    setState(() {
      _weeklyData = mockData;
      _isLoading = false;
    });
  }
  
  // --- Mock Data Generator (for quick hackathon demo) ---
  List<DailyEmission> _generateMockWeeklyData() {
    final List<DailyEmission> data = [];
    final now = DateTime.now();
    final random = Random();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      // FIX: DateFormat is now available
      final dateKey = DateFormat('yyyy-MM-dd').format(date); 
      
      final travelTotal = random.nextDouble() * 5.0; // 0-5 kg
      final foodTotal = random.nextDouble() * 6.0;   // 0-6 kg
      final energyTotal = random.nextDouble() * 4.0; // 0-4 kg
      final othersTotal = random.nextDouble() * 1.0; // 0-1 kg

      // Simplified mock structure (needs to match DailyEmission structure from emission_data.dart)
      data.add(DailyEmission(
        date: dateKey,
        travel: TravelData(mode: 'Mock', distance: 10, emission: travelTotal),
        food: [
          MealData(type: 'Meat', emission: foodTotal * 0.5),
          MealData(type: 'Veg', emission: foodTotal * 0.5),
        ],
        energy: EnergyData(electricity: 10, lpg: 0, acUsed: 0, totalEmission: energyTotal),
        others: othersTotal,
      ));
    }
    return data;
  }

  // --- Chart Data Processors ---

  List<BarChartGroupData> getWeeklyBarGroups(List<DailyEmission> weeklyData, ThemeData theme) {
    if (weeklyData.isEmpty) return [];

    return weeklyData.asMap().entries.map((entry) {
      final index = entry.key;
      final day = entry.value;

      final totalEmission = day.totalEmission;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: totalEmission,
            color: theme.colorScheme.primary,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
        showingTooltip: false,
      );
    }).toList();
  }

  // Processes data into a map suitable for the comparison chart
  // Key: Category Index (0=Travel, 1=Food, 2=Energy+Others), Value: Total Emission
  List<MapEntry<int, double>> getComparisonData(List<DailyEmission> weeklyData) {
    double totalTravel = weeklyData.fold(0.0, (sum, day) => sum + day.travel.emission);
    double totalFood = weeklyData.fold(0.0, (sum, day) => sum + day.food.fold(0.0, (subSum, meal) => subSum + meal.emission));
    double totalEnergyOthers = weeklyData.fold(0.0, (sum, day) => sum + day.energy.totalEmission + day.others);

    return [
      MapEntry(0, totalTravel),
      MapEntry(1, totalFood),
      MapEntry(2, totalEnergyOthers),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights & History', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- View Selector ---
                  Center(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment<String>(value: 'Daily', label: Text('Weekly Trend')),
                        ButtonSegment<String>(value: 'Category', label: Text('Category Comparison')),
                      ],
                      selected: <String>{_selectedView},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _selectedView = newSelection.first;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Chart View ---
                  _selectedView == 'Daily'
                      ? _buildWeeklyTrendChart(theme)
                      : _buildCategoryComparisonChart(theme),

                  const SizedBox(height: 30),
                  
                  // --- Actionable Insights ---
                  _buildInsightsCard(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildWeeklyTrendChart(ThemeData theme) {
    final barGroups = getWeeklyBarGroups(_weeklyData, theme);
    final maxY = _weeklyData.map((e) => e.totalEmission).reduce(max) * 1.1;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Use raw string for the unit text
            Text(r'Last 7 Days Emission (kg $\text{CO}_2e$)', style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  // FIX: Remove const from BarTouchData constructor
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: theme.colorScheme.secondary.withOpacity(0.9),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final day = _weeklyData[group.x.toInt()];
                        final total = rod.toY.toStringAsFixed(2);
                        // FIX: DateFormat is now available
                        final formattedDate = DateFormat('EEE, MMM d').format(DateTime.parse(day.date)); 
                        
                        return BarTooltipItem(
                          '$formattedDate\n',
                          const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(
                              text: '$total kg CO2e',
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.normal),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final day = _weeklyData[value.toInt()];
                          // FIX: DateFormat is now available
                          final dayOfWeek = DateFormat('EEE').format(DateTime.parse(day.date)); 
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(dayOfWeek, style: const TextStyle(fontSize: 12)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value == meta.maxY) return Text(value.toInt().toString());
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryComparisonChart(ThemeData theme) {
    final dataList = getComparisonData(_weeklyData);
    final maxY = dataList.map((e) => e.value).reduce(max) * 1.1;

    // Define bar groups for the comparison chart
    List<BarChartGroupData> getBarGroups() {
      return dataList.map((entry) {
        return BarChartGroupData(
          x: entry.key,
          barRods: [
            BarChartRodData(
              toY: entry.value,
              color: entry.key == 0 ? Colors.blue.shade400 : (entry.key == 1 ? Colors.red.shade400 : Colors.orange.shade400),
              width: 25,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        );
      }).toList();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Use raw string for the unit text
            Text(r'7-Day Category Totals (kg $\text{CO}_2e$)', style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.center,
                  groupsSpace: 40,
                  // FIX: Remove const from BarTouchData constructor
                  barTouchData: BarTouchData(enabled: false), 
                  barGroups: getBarGroups(),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 20, getTitlesWidget: (value, meta) {
                      const titles = ['Travel', 'Food', 'Home/Others'];
                      return SideTitleWidget(axisSide: meta.axisSide, child: Text(titles[value.toInt()], style: const TextStyle(fontSize: 12)));
                    })),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  maxY: maxY,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard(ThemeData theme) {
    final double avgEmission = _weeklyData.map((e) => e.totalEmission).fold(0.0, (a, b) => a + b) / _weeklyData.length;
    final maxDay = _weeklyData.reduce((a, b) => a.totalEmission > b.totalEmission ? a : b);
    final maxTravel = _weeklyData.map((e) => e.travel.emission).fold(0.0, max);
    final maxFood = _weeklyData.map((e) => e.food.fold(0.0, (sum, meal) => sum + meal.emission)).fold(0.0, max);

    // Dynamic tip generation based on highest category
    String tip;
    if (maxTravel > maxFood && maxTravel > avgEmission) {
      tip = 'Your **Travel** emissions are high. Consider using public transport or cycling for short trips.';
    } else if (maxFood > avgEmission) {
      tip = 'Your **Food** emissions are a major contributor. Try incorporating a few plant-based meals each week.';
    } else {
      tip = 'Keep up the great work! Your emissions are stable. See if you can reduce your **Energy** consumption next.';
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.secondary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actionable Insight', style: theme.textTheme.titleLarge!.copyWith(color: theme.colorScheme.secondary)),
            const Divider(),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Your 7-day average is '),
                  TextSpan(
                    // Use raw string for the unit text
                    text: r'${avgEmission.toStringAsFixed(2)} kg $\text{CO}_2e$.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            // Use raw string for the unit text
            Text(r'Your highest day was on ${maxDay.date} with ${maxDay.totalEmission.toStringAsFixed(2)} kg $\text{CO}_2e$.'),
            const SizedBox(height: 12),
            Text(
              '🎯 Recommendation:',
              style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 4),
            Text(tip),
          ],
        ),
      ),
    );
  }
}
