import 'package:hive/hive.dart';

part 'workout_session.g.dart';

@HiveType(typeId: 0)
class WorkoutSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String exerciseType;

  @HiveField(2)
  final int repCount;

  @HiveField(3)
  final int durationSeconds;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final double? avgFormScore; // 0.0 – 1.0

  WorkoutSession({
    required this.id,
    required this.exerciseType,
    required this.repCount,
    required this.durationSeconds,
    required this.date,
    this.avgFormScore,
  });
}
