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

    double parseAmount(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value.replaceAll(',', '').trim()) ?? 0.0;
      }
      return 0.0;
    }

    // Function to get collected amounts per year and month
    Map<int, Map<int, double>> getCollectedAmounts(List<Place> places) {
      Map<int, Map<int, double>> collectedPayments = {};

      for (var place in places) {
        final currentUser = place.currentUser;
        if (currentUser != null) {
          final payments = currentUser['payments'] ?? {};

          for (var entry in payments.entries) {
            DateTime date = DateTime.tryParse(entry.key) ?? DateTime.now();
            int year = date.year;
            int month = date.month;

            collectedPayments.putIfAbsent(year, () => {});
            collectedPayments[year]!.putIfAbsent(month, () => 0);
            collectedPayments[year]![month] =
                (collectedPayments[year]![month] ?? 0) +
                    parseAmount(entry.value);
          }
        }
      }

      return collectedPayments;
    }

    // Function to get total expected amount
    double getTotalExpected(List<Place> places) {
      return places.fold(0.0, (sum, place) {
        final currentUser = place.currentUser;
        return sum +
            (currentUser != null ? parseAmount(currentUser['amount']) : 0);
      });
    }

    double totalExpected =
        getTotalExpected(placesProvider.filteredPlaces ?? []);

    final collectedPayments =
        getCollectedAmounts(placesProvider.filteredPlaces ?? []);

    List<int> years = collectedPayments.keys.toList()..sort();
    if (selectedYear == null && years.isNotEmpty) {
      selectedYear = years.first;
    }

    final selectedYearData =
        selectedYear != null ? collectedPayments[selectedYear] ?? {} : {};

    List<BarChartGroupData> barGroups = [];
    for (int month = 1; month <= 12; month++) {
      double collected = selectedYearData[month] ?? 0.0;

      // Expected amount per month should be totalExpected / 12
      double expectedPerMonth = totalExpected;

      // DEBUG PRINT STATEMENTS
      print(
          "Month: $month | Collected: $collected | Expected: $expectedPerMonth");

      // Make color RED if collected < expected, otherwise GREEN
      Color barColor =
          (collected >= expectedPerMonth) ? Colors.green : Colors.red;

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
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                "بڕی پارەی پێوییستی مانگانە ${totalExpected.toStringAsFixed(2)}",
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
                          style: TextStyle(color: Colors.blue),
                        ),
                      ))
                  .toList(),
              onChanged: (newYear) {
                setState(() {
                  selectedYear = newYear;
                });
              },
              dropdownColor: Colors.white,
              style: TextStyle(color: Colors.blue),
              iconEnabledColor: Colors.blue,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: BarChart(
                  BarChartData(
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            int month = value.toInt() + 1;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                "$month",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                value.toStringAsFixed(0),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
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
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
