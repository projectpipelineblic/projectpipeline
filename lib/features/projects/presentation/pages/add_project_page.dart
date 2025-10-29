import 'package:flutter/material.dart';

class AddProjectPage extends StatelessWidget {
  const AddProjectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Project')),
      body: const Center(
        child: Text('Project creation form goes here'),
      ),
    );
  }
}


