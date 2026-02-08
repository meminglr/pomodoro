import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group_model.dart';
import '../models/chat_message_model.dart';
import '../models/user_stats_model.dart';
import 'dart:math';

class GroupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;
  String? get _userName => _auth.currentUser?.email?.split('@')[0] ?? 'User';

  // --- Group Management ---

  Future<String?> createGroup(String groupName) async {
    if (_userId == null) return null;

    final code = _generateGroupCode();
    final groupId = _db.collection('groups').doc().id;

    final group = Group(
      id: groupId,
      name: groupName,
      code: code,
      ownerId: _userId!,
      memberIds: [_userId!],
      createdAt: DateTime.now(),
    );

    try {
      await _db.collection('groups').doc(groupId).set(group.toMap());
      // Optionally update user's current group ID in their profile
      await _updateUserGroup(groupId);
      return groupId;
    } catch (e) {
      print('Error creating group: $e');
      return null;
    }
  }

  Future<String?> joinGroup(String code) async {
    if (_userId == null) return null;

    try {
      final query = await _db
          .collection('groups')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null; // Group not found

      final doc = query.docs.first;
      final group = Group.fromMap(doc.data());

      if (group.memberIds.contains(_userId)) return group.id; // Already joined

      // Add user to members
      await _db.collection('groups').doc(group.id).update({
        'memberIds': FieldValue.arrayUnion([_userId]),
      });

      await _updateUserGroup(group.id);

      return group.id;
    } catch (e) {
      print('Error joining group: $e');
      return null;
    }
  }

  Future<void> leaveGroup(String groupId) async {
    if (_userId == null) return;
    try {
      await _db.collection('groups').doc(groupId).update({
        'memberIds': FieldValue.arrayRemove([_userId]),
      });
      await _updateUserGroup(null);
    } catch (e) {
      print('Error leaving group: $e');
    }
  }

  Future<void> _updateUserGroup(String? groupId) async {
    if (_userId == null) return;
    await _db.collection('users').doc(_userId).set({
      'groupId': groupId,
    }, SetOptions(merge: true));
  }

  Future<void> updateGroupStats(String groupId, int durationSeconds) async {
    try {
      await _db.collection('groups').doc(groupId).update({
        'totalSeconds': FieldValue.increment(durationSeconds),
      });
    } catch (e) {
      print('Error updating group stats: $e');
    }
  }

  String _generateGroupCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  Stream<Group?> getUserGroupStream() {
    if (_userId == null) return Stream.value(null);
    return _db.collection('users').doc(_userId).snapshots().asyncMap((
      userDoc,
    ) async {
      if (!userDoc.exists) return null;
      final groupId = userDoc.data()?['groupId'];
      if (groupId == null) return null;

      final groupDoc = await _db.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) return null;

      return Group.fromMap(groupDoc.data()!);
    });
  }

  // --- Chat ---

  Future<void> sendMessage(String groupId, String text) async {
    if (_userId == null) return;

    final messageId = _db
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .doc()
        .id;
    final message = ChatMessage(
      id: messageId,
      senderId: _userId!,
      senderName: _userName!,
      text: text,
      timestamp: DateTime.now(),
    );

    await _db
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .doc(messageId)
        .set(message.toMap());
  }

  Stream<List<ChatMessage>> getGroupMessages(String groupId) {
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.data()))
              .toList();
        });
  }

  // --- Group Leaderboard ---

  Stream<List<UserStats>> getGroupLeaderboard(String groupId) {
    return _db.collection('groups').doc(groupId).snapshots().asyncMap((
      groupSnapshot,
    ) async {
      if (!groupSnapshot.exists) return [];

      final group = Group.fromMap(groupSnapshot.data()!);
      final memberIds = group.memberIds;

      if (memberIds.isEmpty) return [];

      // Firestore 'in' query supports up to 10 items. For more, we might need multiple queries
      // or fetching all users and filtering. For MVP, we iterate and fetch.
      // Or better, store UserStats SUBCOLLECTION in Group? No, duplicate data.
      // Let's fetch users where documentId in memberIds.

      // Split into chunks of 10 if needed, but for MVP let's assume small groups or fetch individual docs.
      List<UserStats> stats = [];

      // Fetching each user doc individually is safer for >10 members
      for (var id in memberIds) {
        final doc = await _db.collection('users').doc(id).get();
        if (doc.exists) {
          // We need to construct UserStats from the user doc
          // If UserStats fields are in the user doc root
          // Let's handle missing stats gracefully
          final data = doc.data()!;
          stats.add(
            UserStats(
              userId: id,
              username: data['username'] ?? data['email'] ?? 'Unknown',
              weeklyFocusSeconds: data['weeklyFocusSeconds'] ?? 0,
              monthlyFocusSeconds: data['monthlyFocusSeconds'] ?? 0,
              totalFocusSeconds: data['totalFocusSeconds'] ?? 0,
              lastUpdated: data['lastUpdated'] != null
                  ? DateTime.parse(data['lastUpdated'])
                  : DateTime.now(),
            ),
          );
        }
      }

      // Sort by weekly focus (descending)
      stats.sort(
        (a, b) => b.weeklyFocusSeconds.compareTo(a.weeklyFocusSeconds),
      );

      return stats;
    });
  }
}
