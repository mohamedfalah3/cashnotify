import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CollectedVsExpectedChart extends StatelessWidget {
  final Map<String, double> collectedPayments;
  final Map<String, double> expectedPayments;

  const CollectedVsExpectedChart({
    Key? key,
    required this.collectedPayments,
    required this.expectedPayments,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double chartHeight = constraints.maxHeight * 0.75;
        double textSize = (constraints.maxWidth / 25).clamp(10, 16);
        double barWidth = (constraints.maxWidth / 30).clamp(8, 18);

        List<BarChartGroupData> barGroups = [];
        List<String> months = collectedPayments.keys.toList();

        for (int i = 0; i < months.length; i++) {
          double collected = collectedPayments[months[i]] ?? 0;
          double expected = expectedPayments[months[i]] ?? 0;
          bool reachedTarget = collected >= expected;

          // Define colors
          Color barColor = reachedTarget ? Colors.green : Colors.deepPurple;

          // Add bars for collected amount
          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: collected,
                  width: barWidth,
                  color: barColor,
                  borderRadius: BorderRadius.circular(6),
                  gradient: reachedTarget
                      ? LinearGradient(
                          colors: [Colors.green, Colors.lightGreen])
                      : LinearGradient(
                          colors: [Colors.deepPurple, Colors.purpleAccent]),
                ),
              ],
            ),
          );
        }

        return Card(
          elevation: 6,
          shadowColor: Colors.black26,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
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
                if (expectedPayments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      "🎯 Target: ${expectedPayments.values.first.toStringAsFixed(2)}",
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
