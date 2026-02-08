import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/forest_provider.dart';

class ForestScreen extends StatelessWidget {
  const ForestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final forestProvider = Provider.of<ForestProvider>(context);
    final theme = Theme.of(context);
    final treeState = forestProvider.currentTree;
    final forest = forestProvider.liveTrees; // Only show successful trees

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Your Forest',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${forest.length} Trees Planted',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 40),

                  // Current Tree Visualization
                  Container(
                    height: 250,
                    width: 250,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withAlpha(20),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(child: _buildTreeIcon(treeState, 120)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _getTreeStatusText(treeState),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: treeState == TreeState.withered
                          ? Colors.red
                          : theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Forest History",
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // Forest Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, // Dense forest
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withAlpha(50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.forest,
                    color: Colors.green,
                    size: 30,
                  ),
                );
              }, childCount: forest.length),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildTreeIcon(TreeState state, double size) {
    switch (state) {
      case TreeState.seed:
        return Icon(Icons.grass, size: size, color: Colors.brown);
      case TreeState.sapling:
        return Icon(Icons.nature, size: size, color: Colors.lightGreen);
      case TreeState.tree:
        return Icon(Icons.forest, size: size, color: Colors.green);
      case TreeState.withered:
        return Icon(
          Icons.nature_people,
          size: size,
          color: Colors.grey,
        ); // Dead tree representation
    }
  }

  String _getTreeStatusText(TreeState state) {
    switch (state) {
      case TreeState.seed:
        return "Planting...";
      case TreeState.sapling:
        return "Growing...";
      case TreeState.tree:
        return "Fully Grown!";
      case TreeState.withered:
        return "Withered...";
    }
  }
}
