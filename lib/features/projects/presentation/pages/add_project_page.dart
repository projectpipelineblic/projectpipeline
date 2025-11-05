import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_pipeline/core/utils/app_snackbar.dart';
import 'package:project_pipeline/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_bloc.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_event.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_state.dart';

class AddProjectPage extends StatefulWidget {
  const AddProjectPage({super.key});

  @override
  State<AddProjectPage> createState() => _AddProjectPageState();
}

class _AddProjectPageState extends State<AddProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<TeamMemberField> _teamMembers = [];
  String? _currentUserUid;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _currentUserUid = authState.user.uid;
      _currentUserName = authState.user.userName;
    } else if (authState is AuthSuccess) {
      _currentUserUid = authState.user.uid;
      _currentUserName = authState.user.userName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (var member in _teamMembers) {
      member.emailController.dispose();
    }
    super.dispose();
  }

  void _addTeamMemberField() {
    setState(() {
      _teamMembers.add(TeamMemberField(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        emailController: TextEditingController(),
        isAdmin: false,
      ));
    });
  }

  void _removeTeamMemberField(String id) {
    setState(() {
      final member = _teamMembers.firstWhere((m) => m.id == id);
      member.emailController.dispose();
      _teamMembers.removeWhere((m) => m.id == id);
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_currentUserUid == null || _currentUserName == null) {
        AppSnackBar.showError(context, 'User not authenticated');
        return;
      }

      final teamMembersList = _teamMembers
          .where((m) => m.emailController.text.isNotEmpty)
          .map((m) => {
                'email': m.emailController.text.trim(),
                'role': m.isAdmin ? 'admin' : 'member',
                'hasAccess': m.isAdmin, // Admin has access by default
              })
          .toList();

      context.read<ProjectBloc>().add(
            CreateProjectRequested(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              creatorUid: _currentUserUid!,
              creatorName: _currentUserName!,
              teamMembers: teamMembersList,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Project'),
      ),
      body: BlocListener<ProjectBloc, ProjectState>(
        listener: (context, state) {
          if (state is ProjectCreated) {
            Navigator.of(context).pop();
            AppSnackBar.showSuccess(context, 'Project created successfully');
          } else if (state is ProjectError) {
            AppSnackBar.showError(context, state.message);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Project Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter project name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Team Members',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addTeamMemberField,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Member'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._teamMembers.map((member) => _buildTeamMemberField(member)),
                const SizedBox(height: 24),
                BlocBuilder<ProjectBloc, ProjectState>(
                  builder: (context, state) {
                    final isLoading = state is ProjectLoading;
                    return ElevatedButton(
                      onPressed: isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create Project'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamMemberField(TeamMemberField member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: member.emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      hintText: 'colleague@example.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null &&
                          value.trim().isNotEmpty &&
                          !value.contains('@')) {
                        return 'Please enter valid email';
                      }
                      return null;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeTeamMemberField(member.id),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Is Admin: '),
                Switch(
                  value: member.isAdmin,
                  onChanged: (value) {
                    setState(() {
                      member.isAdmin = value;
                    });
                  },
                ),
                const SizedBox(width: 8),
                Text(member.isAdmin ? 'Admin' : 'Member'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TeamMemberField {
  final String id;
  final TextEditingController emailController;
  bool isAdmin;

  TeamMemberField({
    required this.id,
    required this.emailController,
    required this.isAdmin,
  });
}
