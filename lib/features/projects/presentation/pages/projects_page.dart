import 'package:flutter/material.dart';
import 'package:task_app/features/projects/presentation/pages/add_project_page.dart';

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Project'),
        actions: [
          IconButton(
            tooltip: 'Add New Project',
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddProjectPage()),
              );
            },
          ),
        ],
      ),
      body: const Center(child: Text('My Projects')),
    );
  }
}


