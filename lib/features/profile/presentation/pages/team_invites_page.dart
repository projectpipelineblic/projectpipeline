import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_app/core/utils/app_snackbar.dart';
import 'package:task_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:task_app/features/projects/presentation/bloc/project_bloc.dart';
import 'package:task_app/features/projects/presentation/bloc/project_event.dart';
import 'package:task_app/features/projects/presentation/bloc/project_state.dart';

class TeamInvitesPage extends StatefulWidget {
  const TeamInvitesPage({super.key});

  @override
  State<TeamInvitesPage> createState() => _TeamInvitesPageState();
}

class _TeamInvitesPageState extends State<TeamInvitesPage> {
  @override
  void initState() {
    super.initState();
    _loadInvites();
  }

  void _loadInvites() {
    final authState = context.read<AuthBloc>().state;
    String? userId;
    
    if (authState is AuthAuthenticated) {
      userId = authState.user.uid;
    } else if (authState is AuthOffline) {
      userId = authState.user.uid;
    } else if (authState is AuthSuccess) {
      userId = authState.user.uid;
    }

    if (userId != null) {
      context.read<ProjectBloc>().add(GetInvitesRequested(userId: userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Invites'),
      ),
      body: BlocConsumer<ProjectBloc, ProjectState>(
        listener: (context, state) {
          if (state is InviteAccepted) {
            AppSnackBar.showSuccess(context, 'Invite accepted');
            _loadInvites();
          } else if (state is InviteRejected) {
            AppSnackBar.showSuccess(context, 'Invite rejected');
            _loadInvites();
          } else if (state is ProjectError) {
            AppSnackBar.showError(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is ProjectLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is InvitesLoaded) {
            if (state.invites.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No pending invites'),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.invites.length,
              itemBuilder: (context, index) {
                final invite = state.invites[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invite.projectName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('From: ${invite.creatorName}'),
                        Text('Role: ${invite.role}'),
                        Text('Access: ${invite.hasAccess ? "Yes" : "No"}'),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text(
                                'Reject',
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () {
                                context.read<ProjectBloc>().add(
                                      RejectInviteRequested(inviteId: invite.inviteId),
                                    );
                              },
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check),
                              label: const Text('Accept'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                context.read<ProjectBloc>().add(
                                      AcceptInviteRequested(inviteId: invite.inviteId),
                                    );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No pending invites'),
            ),
          );
        },
      ),
    );
  }
}

