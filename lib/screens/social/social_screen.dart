import 'package:flutter/material.dart';
import '../../services/group_service.dart';
import '../../models/group_model.dart';
import 'group_dashboard.dart';
import '../global_leaderboard_screen.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Social'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Group'),
              Tab(text: 'Global Leaderboard'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [GroupTab(), GlobalLeaderboardScreen()],
        ),
      ),
    );
  }
}

class GroupTab extends StatelessWidget {
  const GroupTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Group?>(
      stream: GroupService().getUserGroupStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data != null) {
          return GroupDashboard(group: snapshot.data!);
        }

        return _buildJoinCreateView(context);
      },
    );
  }

  Widget _buildJoinCreateView(BuildContext context) {
    final theme = Theme.of(context);
    final groupService = GroupService();
    final codeController = TextEditingController();
    final nameController = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.group_add, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 20),
          Text(
            'Join a Squad',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'Focus together with friends and track your progress.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 40),

          // Join Group
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Join Existing Group',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Group Code (6 digits)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: () async {
                      if (codeController.text.length != 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code must be 6 characters'),
                          ),
                        );
                        return;
                      }
                      final groupId = await groupService.joinGroup(
                        codeController.text.toUpperCase(),
                      );
                      if (groupId == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Group not found or error joining'),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Join Group'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(padding: EdgeInsets.all(8), child: Text("OR")),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 20),

          // Create Group
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Create New Group', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Group Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty) return;
                      await groupService.createGroup(nameController.text);
                    },
                    child: const Text('Create Group'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
