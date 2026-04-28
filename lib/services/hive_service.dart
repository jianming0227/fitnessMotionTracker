import 'package:hive_flutter/hive_flutter.dart';
import 'models/workout_session.dart';

class HiveService {
  static const String _sessionBox = 'workout_sessions';

  /// Must be called once at app startup, after [Hive.initFlutter()].
  static Future<void> init() async {
    Hive.registerAdapter(WorkoutSessionAdapter());
    await Hive.openBox<WorkoutSession>(_sessionBox);
  }

  Box<WorkoutSession> get sessionBox => Hive.box<WorkoutSession>(_sessionBox);

  Future<void> saveSession(WorkoutSession session) async {
    await sessionBox.put(session.id, session);
  }

  Future<void> deleteSession(String id) async {
    await sessionBox.delete(id);
  }

  List<WorkoutSession> getAllSessions() {
    return sessionBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<WorkoutSession> getSessionsForDate(DateTime date) {
    return sessionBox.values
        .where((s) =>
            s.date.year == date.year &&
            s.date.month == date.month &&
            s.date.day == date.day)
        .toList();
  }

  int getTotalRepsForToday() {
    return getSessionsForDate(DateTime.now())
        .fold(0, (sum, s) => sum + s.repCount);
  }

  Duration getTotalDurationForToday() {
    final totalSeconds = getSessionsForDate(DateTime.now())
        .fold(0, (sum, s) => sum + s.durationSeconds);
    return Duration(seconds: totalSeconds);
  }
}
