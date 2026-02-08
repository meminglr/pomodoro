import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';

class TaskScreen extends StatelessWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final theme = Theme.of(context);

    // Combine pending (high priority) and completed (crossed out)
    // For now, let's just show sections.

    return Scaffold(
      // Needs Scaffold for FloatingActionButton or can be part of HomeScreen stack
      // Assuming HomeScreen provides Scaffold, but we want FAB here.
      // Since HomeScreen uses NavigationBar, this widget is the BODY.
      // So we can return a Scaffold with backgroundColor transparent to use main Scaffold?
      // No, embedded Scaffolds are okay for FABs.
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: "add_task",
        onPressed: () => _showAddTaskSheet(context),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (taskProvider.pendingTasks.isNotEmpty) ...[
            Text(
              'Pending Tasks',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            ...taskProvider.pendingTasks.map((task) => _TaskTile(task: task)),
            const SizedBox(height: 20),
          ],

          if (taskProvider.completedTasks.isNotEmpty) ...[
            Text(
              'Completed',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            ...taskProvider.completedTasks.map((task) => _TaskTile(task: task)),
          ],

          if (taskProvider.tasks.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 100),
                  Icon(Icons.task_alt, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  Text("No tasks yet!", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow full height for keyboard
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const _AddTaskForm(),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Task task;

  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          activeColor: theme.colorScheme.primary,
          onChanged: (_) => taskProvider.toggleTaskCompletion(task.id),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: task.estimatedPomodoros > 0
            ? Row(
                children: [
                  Icon(Icons.timer, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${task.completedPomodoros}/${task.estimatedPomodoros}',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              )
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => taskProvider.removeTask(task.id),
        ),
      ),
    );
  }
}

class _AddTaskForm extends StatefulWidget {
  const _AddTaskForm();

  @override
  State<_AddTaskForm> createState() => _AddTaskFormState();
}

class _AddTaskFormState extends State<_AddTaskForm> {
  final _titleController = TextEditingController();
  int _estimatedPomodoros = 1;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('New Task', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'What are you working on?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Estimated Pomodoros:'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  if (_estimatedPomodoros > 1) {
                    setState(() => _estimatedPomodoros--);
                  }
                },
              ),
              Text(
                '$_estimatedPomodoros',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  setState(() => _estimatedPomodoros++);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              if (_titleController.text.isNotEmpty) {
                Provider.of<TaskProvider>(context, listen: false).addTask(
                  _titleController.text,
                  estimatedPomodoros: _estimatedPomodoros,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add Task'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
