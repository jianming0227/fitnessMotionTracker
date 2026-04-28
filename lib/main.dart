import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_theme.dart';
import 'features/dashboard/views/dashboard_view.dart';
import 'services/hive_service.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Hive local database ──────────────────────────────────────────────────
  await Hive.initFlutter();
  await HiveService.init();

  // ── Supabase backend ─────────────────────────────────────────────────────
  // NOTE: Replace the URL and anonKey inside supabase_service.dart with your
  // real Supabase project credentials before running on device.
  try {
    await SupabaseService.init();
  } catch (e) {
    debugPrint('Supabase init skipped (no credentials): $e');
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<HiveService>(create: (_) => HiveService()),
        Provider<SupabaseService>(create: (_) => SupabaseService()),
      ],
      child: const FitnessApp(),
    ),
  );
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitForm — AI Fitness Coach',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const DashboardView(),
    );
  }
}
