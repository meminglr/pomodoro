import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import '../models/pomodoro_session.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // --- Tasks ---

  Future<void> saveTask(Task task) async {
    if (_userId == null) return;
    try {
      await _db
          .collection('users')
          .doc(_userId)
          .collection('tasks')
          .doc(task.id)
          .set({
            'id': task.id,
            'title': task.title,
            'estimatedPomodoros': task.estimatedPomodoros,
            'completedPomodoros': task.completedPomodoros,
            'isCompleted': task.isCompleted,
            'createdAt': task.createdAt.toIso8601String(),
          });
    } catch (e) {
      print('Error saving task to Firestore: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    if (_userId == null) return;
    try {
      await _db
          .collection('users')
          .doc(_userId)
          .collection('tasks')
          .doc(taskId)
          .delete();
    } catch (e) {
      print('Error deleting task from Firestore: $e');
    }
  }

  Stream<List<Task>> getTasksStream() {
    if (_userId == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(_userId)
        .collection('tasks')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Task(
              id: data['id'],
              title: data['title'],
              estimatedPomodoros: data['estimatedPomodoros'],
              completedPomodoros: data['completedPomodoros'],
              isCompleted: data['isCompleted'],
              createdAt: data['createdAt'] != null
                  ? DateTime.parse(data['createdAt'])
                  : DateTime.now(), // Fallback
            );
          }).toList();
        });
  }

  // --- Forest / Sessions ---

  Future<void> saveSession(PomodoroSession session) async {
    if (_userId == null) return;
    try {
      // Create a unique ID for the session based on date or let Firestore generate one
      // Using timestamp as ID for simple ordering
      final id = session.date.millisecondsSinceEpoch.toString();
      await _db
          .collection('users')
          .doc(_userId)
          .collection('sessions')
          .doc(id)
          .set({
            'date': session.date.toIso8601String(),
            'durationSeconds': session.durationSeconds,
            'taskId': session.taskId,
            'isSuccessful': session.isSuccessful,
          });
    } catch (e) {
      print('Error saving session to Firestore: $e');
    }
  }

  Stream<List<PomodoroSession>> getSessionsStream() {
    if (_userId == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(_userId)
        .collection('sessions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return PomodoroSession(
              date: DateTime.parse(data['date']),
              durationSeconds: data['durationSeconds'],
              taskId: data['taskId'],
              isSuccessful: data['isSuccessful'] ?? true,
            );
          }).toList();
        });
  }

  // --- Stats ---

  Future<void> updateUserStats(int durationSeconds) async {
    if (_userId == null) return;

    final userRef = _db.collection('users').doc(_userId);

    // Use transaction/atomic increment for data integrity if possible,
    // or just increment for MVP. Firestore FieldValue.increment is best.

    // We also need to handle "Weekly" reset. logic.
    // Simplest approach: Just increment total and weekly.
    // A cloud function usually resets weekly stats on Sunday.
    // Without cloud functions, we can check a 'lastReset' date.

    try {
      await userRef.update({
        'totalFocusSeconds': FieldValue.increment(durationSeconds),
        'weeklyFocusSeconds': FieldValue.increment(durationSeconds),
        'monthlyFocusSeconds': FieldValue.increment(durationSeconds),
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // If doc doesn't exist, set it
      await userRef.set({
        'totalFocusSeconds': durationSeconds,
        'weeklyFocusSeconds': durationSeconds,
        'monthlyFocusSeconds': durationSeconds,
        'lastUpdated': DateTime.now().toIso8601String(),
        'username': _auth.currentUser?.email?.split('@')[0] ?? 'User',
      }, SetOptions(merge: true));
    }
  }

  Future<void> updateUsername(String newName) async {
    if (_userId == null) return;
    try {
      await _db.collection('users').doc(_userId).set({
        'username': newName,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating username: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getGlobalLeaderboard() {
    return _db
        .collection('users')
        .orderBy('monthlyFocusSeconds', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }

  Stream<Map<String, dynamic>?> getUserStatsStream() {
    if (_userId == null) return Stream.value(null);
    return _db
        .collection('users')
        .doc(_userId)
        .snapshots()
        .map((doc) => doc.data());
  }
}
