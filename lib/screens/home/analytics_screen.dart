import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../services/dashboard_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  DashboardData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final data = await DashboardService.instance.fetchDashboard();
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _data = DashboardData.empty(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.purplePrimary));
    }

    final data = _data!;

    return RefreshIndicator(
      onRefresh: _fetch,
      color: AppTheme.purplePrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Overall score ring
            _buildScoreRing(data),
            const SizedBox(height: 24),

            // Progress chart
            _buildProgressChart(data),
            const SizedBox(height: 24),

            // Recent sessions list
            _buildSessionsList(data),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreRing(DashboardData data) {
    final avg = data.avgScore;
    return Center(
      child: Column(
        children: [
          const Text('Average Score',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.whiteText)),
          const SizedBox(height: 16),
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: avg / 100,
                    strokeWidth: 12,
                    backgroundColor: AppTheme.carbonGray,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      avg >= 80 ? Colors.green.shade400 : avg >= 60 ? Colors.amber : Colors.red.shade400,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      avg > 0 ? '$avg' : '—',
                      style: const TextStyle(
                          fontSize: 42, fontWeight: FontWeight.bold, color: AppTheme.whiteText),
                    ),
                    if (avg > 0)
                      Text('/ 100', style: TextStyle(fontSize: 13, color: AppTheme.grayText)),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _miniStat('Total', '${data.totalInterviews}', AppTheme.gradientBlue),
              const SizedBox(width: 24),
              _miniStat('Best', data.highestScore > 0 ? '${data.highestScore}%' : '—', Colors.amber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: AppTheme.grayText)),
      ],
    );
  }

  Widget _buildProgressChart(DashboardData data) {
    if (data.progressData.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text('Complete interviews to see your progress chart.',
              style: TextStyle(color: AppTheme.grayText), textAlign: TextAlign.center),
        ),
      );
    }

    final spots = data.progressData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.score.toDouble());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Progress Over Time',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.whiteText)),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
          child: SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withValues(alpha: 0.08),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}',
                        style: TextStyle(color: AppTheme.grayText, fontSize: 11),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= data.progressData.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            data.progressData[idx].date,
                            style: TextStyle(color: AppTheme.grayText, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.purplePrimary,
                    barWidth: 3,
                    dotData: FlDotData(
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 4,
                        color: AppTheme.purplePrimary,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.purplePrimary.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate(delay: 200.ms).fadeIn(duration: 500.ms),
      ],
    );
  }

  Widget _buildSessionsList(DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Sessions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.whiteText)),
        const SizedBox(height: 12),
        if (data.recentInterviews.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text('No sessions yet.', style: TextStyle(color: AppTheme.grayText)),
            ),
          )
        else
          ...data.recentInterviews.asMap().entries.map((e) {
            final interview = e.value;
            final score = interview.score ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(interview.role,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.whiteText)),
                          Text(interview.date,
                              style: TextStyle(fontSize: 12, color: AppTheme.grayText)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: score / 100,
                              minHeight: 8,
                              backgroundColor: AppTheme.carbonGray,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                score >= 80 ? Colors.green.shade400 : score >= 60 ? Colors.amber : Colors.red.shade400,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            interview.score != null ? '${interview.score}%' : '—',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.whiteText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate(delay: (e.key * 60).ms).fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0),
            );
          }),
      ],
    );
  }
}
