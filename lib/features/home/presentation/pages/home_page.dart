import 'package:flutter/material.dart';
import 'package:project_pipeline/features/projects/presentation/pages/projects_page.dart';
import 'package:project_pipeline/features/profile/presentation/pages/profile_page.dart';
import 'package:project_pipeline/features/home/presentation/pages/dashboard_page.dart';
import 'package:project_pipeline/features/tasks_board/presentation/pages/tasks_board_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // Order: Home/Dashboard (0), Tasks (1), My Project (2), Profile (3)
  final List<Widget> _tabs = [
    const DashboardPage(), // Index 0 - Home tab shows Dashboard
    const TasksBoardPage(), // Index 1 - Tasks tab
    const ProjectsPage(),   // Index 2 - My Project tab
    const ProfilePage(),    // Index 3 - Profile tab
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.task_outlined), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), label: 'My Project'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}