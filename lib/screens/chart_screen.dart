import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helper/helper_class.dart';
import '../helper/place.dart';

class CollectedVsExpectedScreen extends StatefulWidget {
  @override
  _CollectedVsExpectedScreenState createState() =>
      _CollectedVsExpectedScreenState();
}

class _CollectedVsExpectedScreenState extends State<CollectedVsExpectedScreen> {
  int? selectedYear;

  @override
  Widget build(BuildContext context) {
    final placesProvider = Provider.of<PaymentProvider>(context);

    // Function to parse amount from string to double
    double parseAmount(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value.replaceAll(',', '').trim()) ?? 0.0;
      }
      return 0.0;
    }

    // Function to get collected and expected payments for each year and month
    Map<int, Map<int, double>> getCollectedVsExpected(List<Place> places) {
      Map<int, Map<int, double>> monthlyPayments =
          {}; // {year: {month: collectedAmount}}

      for (var place in places) {
        final currentUser = place.currentUser;
        if (currentUser != null) {
          final expectedAmount = parseAmount(currentUser['amount']);
          final payments = currentUser['payments'] ?? {};

          for (var entry in payments.entries) {
            DateTime date = DateTime.tryParse(entry.key) ?? DateTime.now();
            int year = date.year;
            int month = date.month;

            // Initialize yearly data if not present
            if (!monthlyPayments.containsKey(year)) {
              monthlyPayments[year] = {};
            }

            // Add the collected amount for the month of the year
            monthlyPayments[year]![month] =
                (monthlyPayments[year]![month] ?? 0) + parseAmount(entry.value);
          }
        }
      }

      return monthlyPayments;
    }

    // Get monthly payments for each year
    final monthlyPayments =
        getCollectedVsExpected(placesProvider.filteredPlaces ?? []);

    // List of years available for selection
    List<int> years = monthlyPayments.keys.toList()..sort();
    if (selectedYear == null && years.isNotEmpty) {
      selectedYear = years.first;
    }

    // Get data for the selected year
    final selectedYearData =
        selectedYear != null ? monthlyPayments[selectedYear] ?? {} : {};

    // Calculate the expected payment sum for the selected year
    double expectedTotal = 0.0;
    for (var place in placesProvider.filteredPlaces ?? []) {
      if (place.currentUser != null) {
        expectedTotal += parseAmount(place.currentUser!['amount']);
      }
    }

    // Generate the chart data
    List<BarChartGroupData> barGroups = [];
    for (int month = 1; month <= 12; month++) {
      double collected = selectedYearData[month] ?? 0.0;

      // Set the bar color based on whether collected amount exceeds or matches the expected total
      Color barColor =
          collected >= expectedTotal / 12 ? Colors.green : Colors.red;

      barGroups.add(
        BarChartGroupData(
          x: month - 1,
          barRods: [
            BarChartRodData(
              toY: collected,
              color: barColor,
              width: 16,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              "Collected vs Expected Payments by Year and Month",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            // Display the expected total payment
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                "بڕی پارەی پێوییستی مانگانە ${expectedTotal.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            DropdownButton<int>(
              value: selectedYear,
              items: years
                  .map((year) => DropdownMenuItem<int>(
                        value: year,
                        child: Text(
                          "ساڵ: $year",
                          style:
                              TextStyle(color: Colors.blue), // Year text color
                        ),
                      ))
                  .toList(),
              onChanged: (newYear) {
                setState(() {
                  selectedYear = newYear;
                });
              },
              dropdownColor: Colors.white,
              // Background color of dropdown
              style: TextStyle(color: Colors.blue),
              // Text color inside dropdown
              iconEnabledColor: Colors.blue, // Icon color
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          // Display months from 1 to 12
                          int month = value.toInt() + 1;
                          return Text(
                            "$month",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue, // Y-axis number color
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: barGroups,
                ),
              ),
            ),
            const SizedBox(height: 16), // Added padding at the bottom
          ],
        ),
      ),
    );
  }
}
