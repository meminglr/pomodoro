import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class GlobalLeaderboardScreen extends StatelessWidget {
  const GlobalLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().getGlobalLeaderboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No data available yet."));
          }

          final users = snapshot.data!;
          final theme = Theme.of(context);

          return ListView.builder(
            itemCount: users.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final user = users[index];
              final minutes = (user['monthlyFocusSeconds'] ?? 0) ~/ 60;
              final hours = (minutes / 60).toStringAsFixed(1);
              final username = user['username'] ?? 'User';

              // Top 3 highlighting
              Color? cardColor;
              if (index == 0) cardColor = Colors.amber.withAlpha(50);
              if (index == 1) cardColor = Colors.grey.withAlpha(50);
              if (index == 2) cardColor = Colors.brown.withAlpha(50);

              return Card(
                color: cardColor,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Text(
                    '$hours hrs',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  subtitle: Text('Last 30 Days'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
