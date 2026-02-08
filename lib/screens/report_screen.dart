import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/storage_service.dart';
import '../utils/time_formatter.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // For now, fetching data directly. Ideally, use a Provider.
    // Assuming StorageService has synchronous access since values are in memory after openBox.
    // However, Hive values are lazy loaded only if lazy box is used. Standard box loads in memory.
    final sessions = StorageService.getSessions();
    final today = DateTime.now();

    // Simple logic to calculate daily minutes for the last 7 days
    final Map<int, int> dailyMinutes = {};
    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final dayKey = day.weekday; // Simple key, 1=Mon, 7=Sun
      dailyMinutes[dayKey] = 0;
    }

    for (var session in sessions) {
      // Check if session is within last 7 days
      final diff = today.difference(session.date).inDays;
      if (diff <= 7 && diff >= 0) {
        final dayKey = session.date.weekday;
        dailyMinutes[dayKey] =
            (dailyMinutes[dayKey] ?? 0) + (session.durationSeconds ~/ 60);
      }
    }

    final theme = Theme.of(context);

    // Calculate total focus time
    final totalSeconds = sessions.fold<int>(
      0,
      (sum, session) => sum + session.durationSeconds,
    );
    final totalTime = TimeFormatter.formatSecondsToHm(totalSeconds);

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Inherit from HomeScreen Scaffold or container
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Focus',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10), // .withOpacity(0.04)
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 120, // Example max Y (2 hours)
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const style = TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          );
                          String text;
                          switch (value.toInt()) {
                            case 1:
                              text = 'Mn';
                              break;
                            case 2:
                              text = 'Tu';
                              break;
                            case 3:
                              text = 'Wd';
                              break;
                            case 4:
                              text = 'Th';
                              break;
                            case 5:
                              text = 'Fr';
                              break;
                            case 6:
                              text = 'Sa';
                              break;
                            case 7:
                              text = 'Su';
                              break;
                            default:
                              text = '';
                          }
                          return SideTitleWidget(
                            meta: meta,
                            space: 4,
                            child: Text(text, style: style),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: dailyMinutes.entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: theme.colorScheme.primary,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total Time',
                    value: totalTime,
                    icon: Icons.timer,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Sessions',
                    value: sessions.length.toString(),
                    icon: Icons.check_circle_outline,
                    color: Colors.orangeAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10), // .withOpacity(0.04)
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
