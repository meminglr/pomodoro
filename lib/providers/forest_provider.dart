import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';
import '../models/pomodoro_session.dart';
import '../services/firestore_service.dart';

enum TreeState { seed, sapling, tree, withered }

class ForestProvider with ChangeNotifier {
  TreeState _currentTree = TreeState.seed;
  List<PomodoroSession> _forest = [];

  ForestProvider() {
    _loadForest();
  }

  void _loadForest() {
    _forest = StorageService.getSessions();
    notifyListeners();
    _syncWithFirestore();
  }

  void _syncWithFirestore() {
    FirestoreService().getSessionsStream().listen((cloudSessions) {
      if (cloudSessions.isNotEmpty) {
        // Merge strategy: Overwrite local with cloud for consistency
        _forest = cloudSessions;
        // Update local storage
        // Ideally we clear and add all, but Hive box put just overwrites by key.
        // Since we don't have IDs for sessions easily in Hive (auto-increment keys?),
        // let's assume we just adding for now.
        // Actually, let's keep it simple: Cloud is master.
        for (var session in cloudSessions) {
          StorageService.saveSession(session);
        }
        notifyListeners();
      }
    });
  }

  TreeState get currentTree => _currentTree;
  List<PomodoroSession> get forest => _forest;

  List<PomodoroSession> get liveTrees =>
      _forest.where((s) => s.isSuccessful).toList();
  List<PomodoroSession> get witheredTrees =>
      _forest.where((s) => !s.isSuccessful).toList();

  void plantSeed() {
    _currentTree = TreeState.seed;
    notifyListeners();
  }

  void growTree(double progress) {
    // 0.0 to 1.0
    if (_currentTree == TreeState.withered) return;

    if (progress < 0.5) {
      if (_currentTree != TreeState.seed) {
        _currentTree = TreeState.seed;
        notifyListeners();
      }
    } else if (progress < 0.95) {
      if (_currentTree != TreeState.sapling) {
        _currentTree = TreeState.sapling;
        notifyListeners();
      }
    } else {
      // Almost done, full tree visualization
      if (_currentTree != TreeState.tree) {
        _currentTree = TreeState.tree;
        notifyListeners();
      }
    }
  }

  void witherTree() {
    _currentTree = TreeState.withered;
    notifyListeners();
  }

  void harvestTree(PomodoroSession session) {
    _currentTree = TreeState.tree; // Ensure it looks like a tree
    _forest.add(session);
    FirestoreService().saveSession(session); // Sync to Firestore
    notifyListeners();
  }
}
