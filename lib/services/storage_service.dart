import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';
import '../models/pomodoro_session.dart';

class StorageService {
  static const String taskBoxName = 'tasks';
  static const String sessionBoxName = 'sessions';
  static const String settingsBoxName = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(PomodoroSessionAdapter());

    // Open Boxes
    await Hive.openBox<Task>(taskBoxName);
    await Hive.openBox<PomodoroSession>(sessionBoxName);
    await Hive.openBox(settingsBoxName);
  }

  // Task Operations
  static Box<Task> get _taskBox => Hive.box<Task>(taskBoxName);

  static List<Task> getTasks() {
    return _taskBox.values.toList();
  }

  static Future<void> saveTask(Task task) async {
    await _taskBox.put(task.id, task);
  }

  static Future<void> deleteTask(String id) async {
    await _taskBox.delete(id);
  }

  // Session Operations
  static Box<PomodoroSession> get _sessionBox =>
      Hive.box<PomodoroSession>(sessionBoxName);

  static List<PomodoroSession> getSessions() {
    return _sessionBox.values.toList();
  }

  static Future<void> saveSession(PomodoroSession session) async {
    await _sessionBox.add(session);
  }
}
