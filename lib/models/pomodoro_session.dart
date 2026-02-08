import 'package:hive/hive.dart';

part 'pomodoro_session.g.dart';

@HiveType(typeId: 1)
class PomodoroSession {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final int durationSeconds;

  @HiveField(2)
  final String? taskId;

  @HiveField(3)
  final bool isSuccessful;

  PomodoroSession({
    required this.date,
    required this.durationSeconds,
    this.taskId,
    this.isSuccessful = true,
  });
}
