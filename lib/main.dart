import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/timer_provider.dart';
import 'providers/task_provider.dart';
import 'utils/app_theme.dart';
import 'services/storage_service.dart';
import 'providers/forest_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_gate.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await StorageService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(
          create: (_) => ForestProvider(),
        ), // Initialize ForestProvider first
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProxyProvider<ForestProvider, TimerProvider>(
          create: (_) => TimerProvider(),
          update: (_, forest, timer) {
            timer!.updateDependencies(forestProvider: forest);
            return timer;
          },
        ),
      ],
      child: const OdakToDoApp(),
    ),
  );
}

class OdakToDoApp extends StatelessWidget {
  const OdakToDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OdakToDo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Auto switch based on system
      home: const AuthGate(),
    );
  }
}
