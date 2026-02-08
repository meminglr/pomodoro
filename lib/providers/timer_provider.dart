import 'dart:async';
import 'package:flutter/material.dart';
import '../models/pomodoro_session.dart';
import '../services/storage_service.dart';
import 'forest_provider.dart';
import '../services/firestore_service.dart';
import '../services/group_service.dart';
import '../services/sound_service.dart';

enum TimerStatus { initial, running, paused, finished }

enum TimerMode { work, shortBreak, longBreak }

class TimerProvider with ChangeNotifier {
  Timer? _timer;
  TimerStatus _status = TimerStatus.initial;
  TimerMode _mode = TimerMode.work;
  int _remainingTime = 25 * 60; // 25 minutes
  int _currentTotalDuration = 25 * 60; // Track total for progress calculation
  int _completedPomodoros = 0;

  // Strict Mode
  bool _isStrictMode = false;

  // Dependencies
  ForestProvider? _forestProvider;

  void updateDependencies({required ForestProvider forestProvider}) {
    _forestProvider = forestProvider;
  }

  // Constants
  static const int defaultWorkDuration = 25 * 60;
  static const int defaultShortBreakDuration = 5 * 60;
  static const int defaultLongBreakDuration = 15 * 60;

  TimerStatus get status => _status;
  TimerMode get mode => _mode;
  int get remainingTime => _remainingTime;
  int get completedPomodoros => _completedPomodoros;
  bool get isStrictMode => _isStrictMode;

  void toggleStrictMode(bool value) {
    if (_status == TimerStatus.initial) {
      _isStrictMode = value;
      notifyListeners();
    }
  }

  void setDuration(int minutes, int seconds) {
    if (_status == TimerStatus.initial) {
      _remainingTime = (minutes * 60) + seconds;
      _currentTotalDuration = _remainingTime;
      notifyListeners();
    }
  }

  double get progress {
    if (_currentTotalDuration == 0) return 0;
    return 1.0 - (_remainingTime / _currentTotalDuration);
  }

  void startTimer() {
    if (_status == TimerStatus.running) return;

    // Plant tree if starting work mode from initial
    if (_status == TimerStatus.initial &&
        _remainingTime == defaultWorkDuration) {
      if (_mode == TimerMode.work) {
        _forestProvider?.plantSeed();
      }
    }

    _status = TimerStatus.running;
    notifyListeners(); // Notify listeners after status change and before timer starts

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        _remainingTime--;

        // Gamification: Grow tree during work mode
        if (_mode == TimerMode.work) {
          final progress = 1.0 - (_remainingTime / _currentTotalDuration);
          _forestProvider?.growTree(progress);
        }

        notifyListeners();
      } else {
        // Timer reached 0
        _finishTimer();
      }
    });

    SoundService().playStart();
    SoundService().vibrateStart();
  }

  void pauseTimer() {
    _timer?.cancel();
    _status = TimerStatus.paused;
    notifyListeners();
  }

  void stopTimer() {
    _timer?.cancel();

    // Strict Mode / Gamification Penalty
    // Only wither if we were in work mode and give up early
    if (_mode == TimerMode.work &&
        _status != TimerStatus.finished &&
        _remainingTime >
            0 && // Fix: Don't penalize if time is up but finishTimer hasn't run yet
        _remainingTime < _currentTotalDuration) {
      _forestProvider?.witherTree();
      SoundService().vibrateStrictPenalty();
    } else {
      // Normal stop
      SoundService().playStop();
      SoundService().vibrateStop();
    }

    _resetTimer(); // This will set _status to initial and _remainingTime
    notifyListeners();
  }

  void _finishTimer() {
    _timer?.cancel();
    _status = TimerStatus.finished;

    SoundService().playFinish();
    SoundService().vibrateFinish();

    if (_mode == TimerMode.work) {
      _completedPomodoros++;
      // Create Session Record
      final session = PomodoroSession(
        date: DateTime.now(),
        durationSeconds: _currentTotalDuration, // Full duration
        isSuccessful: true,
        // taskId: currentTaskId, // To implement later
      );
      StorageService.saveSession(session);

      // Harvest Tree
      _forestProvider?.harvestTree(session);

      // Sync Stats (Fire-and-forget)
      _syncStats(_currentTotalDuration);
    }

    // Auto-switch mode logic could go here, for now just notify
    notifyListeners();
  }

  Future<void> _syncStats(int duration) async {
    try {
      // Update User Stats
      await FirestoreService().updateUserStats(duration);

      // Update Group Stats if user is in a group
      final groupStream = GroupService().getUserGroupStream();
      final group = await groupStream.first;
      if (group != null) {
        await GroupService().updateGroupStats(group.id, duration);
      }
    } catch (e) {
      print("Error syncing stats: $e");
    }
  }

  void _resetTimer() {
    _status = TimerStatus.initial;
    switch (_mode) {
      case TimerMode.work:
        _remainingTime = defaultWorkDuration;
        break;
      case TimerMode.shortBreak:
        _remainingTime = defaultShortBreakDuration;
        break;
      case TimerMode.longBreak:
        _remainingTime = defaultLongBreakDuration;
        break;
    }
    _currentTotalDuration = _remainingTime;
  }

  void switchMode(TimerMode newMode) {
    _timer?.cancel();
    _mode = newMode;
    _resetTimer();
    notifyListeners();
  }

  String get timeString {
    final minutes = (_remainingTime ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingTime % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
