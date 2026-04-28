import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../services/supabase_service.dart';
import '../../../services/hive_service.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _supabase = SupabaseService();
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _supabase.fetchProfile();
    if (mounted) setState(() { _profile = profile; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final hive = context.read<HiveService>();
    final allSessions = hive.getAllSessions();
    final totalReps =
        allSessions.fold(0, (sum, s) => sum + s.repCount);
    final totalMinutes =
        allSessions.fold(0, (sum, s) => sum + s.durationSeconds) ~/ 60;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Profile', style: AppTextStyles.titleLarge),
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _AvatarSection(profile: _profile),
                  const SizedBox(height: 28),
                  _LifetimeStats(
                    totalSessions: allSessions.length,
                    totalReps: totalReps,
                    totalMinutes: totalMinutes,
                  ),
                  const SizedBox(height: 28),
                  _InfoSection(profile: _profile),
                  const SizedBox(height: 28),
                  _SettingsSection(supabase: _supabase),
                ],
              ),
            ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  final Map<String, dynamic>? profile;
  const _AvatarSection({this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile?['full_name'] as String? ?? 'Athlete';
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'A',
              style: AppTextStyles.displayLarge.copyWith(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(name, style: AppTextStyles.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Member since ${formatShortDate(DateTime.now())}',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

class _LifetimeStats extends StatelessWidget {
  final int totalSessions;
  final int totalReps;
  final int totalMinutes;

  const _LifetimeStats({
    required this.totalSessions,
    required this.totalReps,
    required this.totalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(value: '$totalSessions', label: 'Sessions'),
          _Divider(),
          _Stat(value: '$totalReps', label: 'Total Reps'),
          _Divider(),
          _Stat(value: '${totalMinutes}m', label: 'Active Time'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.displayMedium.copyWith(color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(height: 40, width: 1, color: AppColors.textMuted.withValues(alpha: 0.3));
}

class _InfoSection extends StatelessWidget {
  final Map<String, dynamic>? profile;
  const _InfoSection({this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _InfoTile(
              icon: Icons.person_outline,
              title: 'Full Name',
              value: profile?['full_name'] ?? '—'),
          _InfoTile(
              icon: Icons.email_outlined,
              title: 'Email',
              value: profile?['email'] ?? '—'),
          _InfoTile(
              icon: Icons.monitor_weight_outlined,
              title: 'Goal',
              value: profile?['goal'] ?? 'Build Strength'),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoTile({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(title, style: AppTextStyles.caption),
      subtitle: Text(value, style: AppTextStyles.bodyLarge),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final SupabaseService supabase;
  const _SettingsSection({required this.supabase});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SettingsTile(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          onTap: () {},
        ),
        const SizedBox(height: 10),
        _SettingsTile(
          icon: Icons.help_outline,
          label: 'Help & Support',
          onTap: () {},
        ),
        const SizedBox(height: 10),
        _SettingsTile(
          icon: Icons.logout_rounded,
          label: 'Sign Out',
          color: AppColors.error,
          onTap: () async {
            await supabase.signOut();
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppTextStyles.bodyLarge.copyWith(color: color))),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
