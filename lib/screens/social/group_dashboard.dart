import 'package:flutter/material.dart';
import '../../models/group_model.dart';
import '../../services/group_service.dart';
import '../../models/chat_message_model.dart';
import '../../models/user_stats_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/time_formatter.dart';

class GroupDashboard extends StatefulWidget {
  final Group group;
  const GroupDashboard({super.key, required this.group});

  @override
  State<GroupDashboard> createState() => _GroupDashboardState();
}

class _GroupDashboardState extends State<GroupDashboard> {
  final _messageController = TextEditingController();
  final _groupService = GroupService();
  final _userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          _buildHeader(context),
          const TabBar(
            tabs: [
              Tab(text: "Ranking"),
              Tab(text: "Chat"),
            ],
          ),
          Expanded(
            child: TabBarView(children: [_buildRankingTab(), _buildChatTab()]),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final totalTime = TimeFormatter.formatSecondsToHm(
      widget.group.totalSeconds,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
      child: Column(
        children: [
          Text(
            widget.group.name,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          SelectableText(
            "Code: ${widget.group.code}",
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat("Members", "${widget.group.memberIds.length}"),
              _buildStat("Total Time", totalTime),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.exit_to_app, size: 16),
            label: const Text("Leave Group"),
            onPressed: () async {
              await _groupService.leaveGroup(widget.group.id);
            },
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildRankingTab() {
    return StreamBuilder<List<UserStats>>(
      stream: _groupService.getGroupLeaderboard(widget.group.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data ?? [];

        if (stats.isEmpty) {
          return const Center(child: Text("No stats available."));
        }

        return ListView.builder(
          itemCount: stats.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final user = stats[index];
            final timeStr = TimeFormatter.formatSecondsToHm(
              user.weeklyFocusSeconds,
            );

            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text("${index + 1}")),
                title: Text(user.username),
                trailing: Text("$timeStr /week"),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: _groupService.getGroupMessages(widget.group.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final messages = snapshot.data!;

              if (messages.isEmpty)
                return const Center(child: Text("Say hello!"));

              return ListView.builder(
                reverse: true, // Show newest at bottom
                itemCount: messages.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  // Reverse index because listview is reversed
                  final msg = messages[index];
                  final isMe = msg.senderId == _userId;

                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blueAccent : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Text(
                              msg.senderName,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          Text(
                            msg.text,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: "Send a message...",
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
            ],
          ),
        ),
      ],
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    _groupService.sendMessage(widget.group.id, _messageController.text.trim());
    _messageController.clear();
  }
}
