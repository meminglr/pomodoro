import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/time_formatter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: firestoreService.getUserStatsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final userData = snapshot.data ?? {};
          final totalSeconds = userData['totalFocusSeconds'] as int? ?? 0;
          final totalSeconds = userData['totalFocusSeconds'] as int? ?? 0;
          final totalTime = TimeFormatter.formatSecondsToHm(totalSeconds);
          final username =
              userData['username'] ?? user?.email?.split('@')[0] ?? 'User';

          // Count tasks if available in snapshot, otherwise 0
          // Ideally we fetch tasks count separately or keep a counter in user doc.
          // For now, let's just show Total Hours which is reliable.

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Header
              Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : 'U',
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        username,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () {
                          _showEditNameDialog(
                            context,
                            username,
                            firestoreService,
                          );
                        },
                      ),
                    ],
                  ),
                  Text(
                    user?.email ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Stats
              Row(
                children: [
                  _buildStatCard(context, "Total Time", totalTime, Icons.timer),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    context,
                    "Streak",
                    "0",
                    Icons.local_fire_department,
                  ), // Placeholder streak
                ],
              ),
              const SizedBox(height: 32),

              // Settings
              Text("Settings", style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text("Dark Mode"),
                      secondary: const Icon(Icons.dark_mode),
                      value: theme.brightness == Brightness.dark,
                      onChanged: (val) {
                        // Theme toggle logic - requires a ThemeProvider which we don't have yet.
                        // Placeholder for now.
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Theme settings coming soon!'),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text("Sound Effects"),
                      secondary: const Icon(Icons.volume_up),
                      value: true, // Placeholder
                      onChanged: (val) {
                        // Sound toggle
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Account
              Text("Account", style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.orange),
                      title: const Text("Log Out"),
                      onTap: () {
                        Provider.of<AuthService>(
                          context,
                          listen: false,
                        ).signOut();
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text(
                        "Delete Account",
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () {
                        _showDeleteConfirmation(context);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text("Version 1.0.0", style: theme.textTheme.bodySmall),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 30),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "Are you sure you want to delete your account? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              // Delete logic
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion not implemented yet.'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(
    BuildContext context,
    String currentName,
    FirestoreService firestoreService,
  ) {
    final TextEditingController controller = TextEditingController(
      text: currentName,
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Name"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter your name"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                firestoreService.updateUsername(newName);
              }
              Navigator.pop(ctx);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
