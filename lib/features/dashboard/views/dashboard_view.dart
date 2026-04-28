import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../services/hive_service.dart';
import '../../../services/models/workout_session.dart';
import '../../motion_tracking/views/pose_detector_view.dart';
import '../../profile/views/profile_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ───────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildHeader(context)),

            // ── Today's Stats ─────────────────────────────────────────
            SliverToBoxAdapter(child: _TodayStatsRow()),

            // ── Today's Plan ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text("Today's Plan", style: AppTextStyles.titleLarge),
              ),
            ),
            SliverToBoxAdapter(child: _TodaysPlanCard(context)),

            // ── Weekly Activity Chart ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                child: Text('Weekly Activity', style: AppTextStyles.titleLarge),
              ),
            ),
            SliverToBoxAdapter(child: _WeeklyChart()),

            // ── Recent Sessions ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                child: Text('Recent Sessions', style: AppTextStyles.titleLarge),
              ),
            ),
            _RecentSessionsList(),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),

      // ── Start Tracking FAB ────────────────────────────────────────────
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _StartTrackingButton(onSessionEnd: _refresh),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good ${_greeting()}, Athlete 👋',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text('Dashboard', style: AppTextStyles.displayMedium),
              ],
            ),
          ),
          IconButton(
            icon: const CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.card,
              child: Icon(Icons.person_outline, color: AppColors.textSecondary),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileView()),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

// ── Today's Stats Row ─────────────────────────────────────────────────────

class _TodayStatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hive = context.read<HiveService>();
    final reps = hive.getTotalRepsForToday();
    final duration = hive.getTotalDurationForToday();
    final sessions = hive.getSessionsForDate(DateTime.now()).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          _StatCard(
            icon: Icons.repeat_rounded,
            value: '$reps',
            label: 'Total Reps',
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: Icons.timer_outlined,
            value: formatDuration(duration),
            label: 'Active Time',
            color: AppColors.secondary,
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: Icons.fitness_center,
            value: '$sessions',
            label: 'Sessions',
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.titleMedium),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

// ── Today's Plan Card ─────────────────────────────────────────────────────

class _TodaysPlanCard extends StatelessWidget {
  final BuildContext parentContext;
  const _TodaysPlanCard(this.parentContext);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Squat Mastery',
                    style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '3 sets · 15 reps · Beginner',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  const _PlanProgressBar(progress: 0.4),
                  const SizedBox(height: 6),
                  Text('40% complete',
                      style: AppTextStyles.caption
                          .copyWith(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _WorkoutTypeIcon(),
          ],
        ),
      ),
    );
  }
}

class _PlanProgressBar extends StatelessWidget {
  final double progress;
  const _PlanProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 6,
        backgroundColor: Colors.white24,
        valueColor: const AlwaysStoppedAnimation(Colors.white),
      ),
    );
  }
}

class _WorkoutTypeIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.directions_run, color: Colors.white, size: 36),
    );
  }
}

// ── Weekly Chart ─────────────────────────────────────────────────────────

class _WeeklyChart extends StatelessWidget {
  List<_DayData> _buildWeekData(HiveService hive) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final reps = hive
          .getSessionsForDate(day)
          .fold(0, (s, session) => s + session.repCount);
      return _DayData(label: days[i], reps: reps.toDouble());
    });
  }

  @override
  Widget build(BuildContext context) {
    final hive = context.read<HiveService>();
    final data = _buildWeekData(hive);
    final maxY = data.map((d) => d.reps).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 180,
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: BarChart(
          BarChartData(
            maxY: maxY > 0 ? maxY * 1.3 : 30,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) => Text(
                    data[value.toInt()].label,
                    style: AppTextStyles.caption,
                  ),
                ),
              ),
              leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(
              data.length,
              (i) => BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i].reps,
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(
                      colors: i == 6
                          ? [AppColors.primary, AppColors.primaryLight]
                          : [
                              AppColors.primary.withValues(alpha: 0.4),
                              AppColors.primary.withValues(alpha: 0.2),
                            ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayData {
  final String label;
  final double reps;
  const _DayData({required this.label, required this.reps});
}

// ── Recent Sessions List ──────────────────────────────────────────────────

class _RecentSessionsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hive = context.read<HiveService>();
    final sessions = hive.getAllSessions().take(5).toList();

    if (sessions.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: _EmptySessionsCard(),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: _SessionTile(session: sessions[i]),
        ),
        childCount: sessions.length,
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final WorkoutSession session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fitness_center,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.exerciseType, style: AppTextStyles.labelLarge),
                const SizedBox(height: 2),
                Text(
                  formatDate(session.date),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${session.repCount} reps',
                  style: AppTextStyles.titleMedium
                      .copyWith(color: AppColors.primary)),
              Text(
                formatDuration(Duration(seconds: session.durationSeconds)),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptySessionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.sports_gymnastics,
              color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text('No sessions yet', style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Text('Tap "Start Tracking" to begin your first workout!',
              textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

// ── Start Tracking Button ─────────────────────────────────────────────────

class _StartTrackingButton extends StatelessWidget {
  final VoidCallback onSessionEnd;
  const _StartTrackingButton({required this.onSessionEnd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton.icon(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PoseDetectorView()),
          );
          // Refresh dashboard stats after session ends
          onSessionEnd();
        },
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Start Tracking'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 56),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          shadowColor: AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
