import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];

  TaskProvider() {
    _loadTasks();
  }

  void _loadTasks() {
    _tasks = StorageService.getTasks();
    notifyListeners();
    _syncWithFirestore();
  }

  void _syncWithFirestore() {
    FirestoreService().getTasksStream().listen((cloudTasks) {
      if (cloudTasks.isNotEmpty) {
        // Simple strategy: Cloud wins or merge.
        // For simplicity: Update local with cloud if cloud has more or different data.
        // Actually, let's just replace local with cloud for now to ensure consistency across devices.
        // In a real app, you'd want smarter merging.
        _tasks = cloudTasks;

        // Update local storage to match cloud
        // Clear local first? Or just overwrite.
        // For now, let's just save all cloud tasks to local Hive
        for (var task in cloudTasks) {
          StorageService.saveTask(task);
        }
        notifyListeners();
      }
    });
  }

  List<Task> get tasks => List.unmodifiable(_tasks);

  List<Task> get pendingTasks =>
      _tasks.where((task) => !task.isCompleted).toList();
  List<Task> get completedTasks =>
      _tasks.where((task) => task.isCompleted).toList();

  void addTask(
    String title, {
    String? description,
    int estimatedPomodoros = 1,
  }) {
    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      estimatedPomodoros: estimatedPomodoros,
    );
    _tasks.add(newTask);
    StorageService.saveTask(newTask);
    FirestoreService().saveTask(newTask); // Sync to Firestore
    notifyListeners();
  }

  void toggleTaskCompletion(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _tasks[index];
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
      _tasks[index] = updatedTask;
      StorageService.saveTask(updatedTask);
      FirestoreService().saveTask(updatedTask); // Sync to Firestore
      notifyListeners();
    }
  }

  void removeTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    StorageService.deleteTask(id);
    FirestoreService().deleteTask(id); // Sync to Firestore
    notifyListeners();
  }

  void updateTask(Task updatedTask) {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      StorageService.saveTask(updatedTask);
      FirestoreService().saveTask(updatedTask); // Sync to Firestore
      notifyListeners();
    }
  }
}
