import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CollectedVsExpectedChart extends StatefulWidget {
  final Map<int, Map<int, double>>
      yearlyPayments; // {year: {interval: collectedAmount}}
  final List<int> availableYears; // Available years for selection
  final double expectedTotal; // Expected total amount per interval

  const CollectedVsExpectedChart({
    Key? key,
    required this.yearlyPayments,
    required this.availableYears,
    required this.expectedTotal,
  }) : super(key: key);

  @override
  _CollectedVsExpectedChartState createState() =>
      _CollectedVsExpectedChartState();
}

class _CollectedVsExpectedChartState extends State<CollectedVsExpectedChart> {
  int? selectedYear;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Ensure the first available year is selected if available
    if (widget.availableYears.isNotEmpty) {
      selectedYear = widget.availableYears.first;
    }

    // Simulate a short delay for better user experience
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        // Check if the widget is still in the widget tree
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double textSize = (constraints.maxWidth / 25).clamp(10, 16);
        double barWidth = (constraints.maxWidth / 30).clamp(8, 18);

        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // If there are no available years at all, show an error message
        // if (selectedYear == null) {
        //   return Center(
        //     child: Text(
        //       "No available data.",
        //       style: TextStyle(fontSize: textSize, color: Colors.red),
        //     ),
        //   );
        // }

        List<int> sortedYears = List.from(widget.availableYears)..sort();
        List<String> intervalLabels = [];
        List<BarChartGroupData> barGroups = [];

        final selectedYearData = widget.yearlyPayments[selectedYear] ?? {};

        // Ensure there is at least one valid collected amount
        bool hasValidData = selectedYearData.values.any((amount) => amount > 0);

        if (!hasValidData) {
          return Center(
            child: Text(
              "No collected payments for selected year.",
              style: TextStyle(fontSize: textSize, color: Colors.orange),
            ),
          );
        }

        List<int> sortedIntervals = selectedYearData.keys.toList()..sort();
        int index = 0;

        for (var interval in sortedIntervals) {
          double collected = selectedYearData[interval] ?? 0;
          if (collected > 0) {
            bool reachedTarget = collected >= widget.expectedTotal;

            barGroups.add(
              BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: collected,
                    width: barWidth,
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(
                      colors: reachedTarget
                          ? [Colors.green, Colors.lightGreen]
                          : [Colors.deepPurple, Colors.purpleAccent],
                    ),
                  ),
                ],
              ),
            );

            intervalLabels.add("$interval-$selectedYear");
            index++;
          }
        }

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth * 0.05,
            vertical: constraints.maxHeight * 0.05,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<int>(
                value: selectedYear,
                items: sortedYears
                    .map((year) => DropdownMenuItem(
                          value: year,
                          child: Text("Year: $year"),
                        ))
                    .toList(),
                onChanged: (newYear) {
                  if (newYear != null) {
                    setState(() {
                      selectedYear = newYear;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              Text(
                "💰 Collected vs Expected Payments ($selectedYear)",
                style: TextStyle(
                  fontSize: textSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  "🎯 Target per Interval: ${widget.expectedTotal.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: textSize * 0.8,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
              Expanded(
                child: BarChart(
                  BarChartData(
                    barGroups: barGroups,
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            return index < intervalLabels.length
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      intervalLabels[index],
                                      style: TextStyle(
                                        fontSize: textSize * 0.7,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
