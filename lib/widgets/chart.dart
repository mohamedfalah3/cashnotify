import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CollectedVsExpectedChart extends StatelessWidget {
  final Map<String, double> collectedPayments;
  final double expectedTotal; // ✅ Expected total amount

  const CollectedVsExpectedChart({
    Key? key,
    required this.collectedPayments,
    required this.expectedTotal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double textSize = (constraints.maxWidth / 25).clamp(10, 16);
        double barWidth = (constraints.maxWidth / 30).clamp(8, 18);

        List<BarChartGroupData> barGroups = [];
        List<String> months = collectedPayments.keys.toList();

        for (int i = 0; i < months.length; i++) {
          double collected = collectedPayments[months[i]] ?? 0;

          // ✅ Check if this specific month reached the expected total
          bool monthReachedTarget = collected >= expectedTotal;

          // ✅ Set color per month
          Color barColor =
              monthReachedTarget ? Colors.green : Colors.deepPurple;

          // Add bars for collected amount
          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: collected,
                  width: barWidth,
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    colors: monthReachedTarget
                        ? [Colors.green, Colors.lightGreen]
                        : [Colors.deepPurple, Colors.purpleAccent],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text("Collected vs Expected")),
          body: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth * 0.05,
              vertical: constraints.maxHeight * 0.05,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "💰 Collected vs Expected Payments",
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
                    "🎯 Target per Month: ${expectedTotal.toStringAsFixed(2)}",
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
                              return index < months.length
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        months[index],
                                        style: TextStyle(
                                          fontSize: textSize * 0.8,
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
          ),
        );
      },
    );
  }
}
