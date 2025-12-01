// lib/main.dart
import 'package:flutter/material.dart';

import 'screens/quest_list_screen.dart';

void main() {
  runApp(const NeighborhoodQuestApp());
}

class NeighborhoodQuestApp extends StatelessWidget {
  const NeighborhoodQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neighborhood Quest',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const QuestListScreen(),
    );
  }
}
