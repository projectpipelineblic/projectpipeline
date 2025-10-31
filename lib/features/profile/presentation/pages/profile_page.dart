import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_app/core/utils/app_snackbar.dart';
import 'package:task_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:task_app/features/projects/presentation/bloc/project_bloc.dart';
import 'package:task_app/features/projects/presentation/bloc/project_event.dart';
import 'package:task_app/features/projects/presentation/bloc/project_state.dart';
import 'package:task_app/core/routes/routes.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    String username = 'User';
    String? userId;
    
    final authState = context.watch<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      username = authState.user.userName;
      userId = authState.user.uid;
    } else if (authState is AuthOffline) {
      username = authState.user.userName;
      userId = authState.user.uid;
    } else if (authState is AuthSuccess) {
      username = authState.user.userName;
      userId = authState.user.uid;
    }

    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';

    // Load invites when page loads
    if (userId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ProjectBloc>().add(GetInvitesRequested(userId: userId!));
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 32),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  child: Text(initial, style: const TextStyle(fontSize: 32)),
                ),
                const SizedBox(height: 12),
                Text(username, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.group_add),
                SizedBox(width: 8),
                Text(
                  'Team Invites',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocConsumer<ProjectBloc, ProjectState>(
              listener: (context, state) {
                if (state is InviteAccepted) {
                  AppSnackBar.showSuccess(context, 'Invite accepted');
                  if (userId != null) {
                    context.read<ProjectBloc>().add(GetInvitesRequested(userId: userId));
                  }
                } else if (state is InviteRejected) {
                  AppSnackBar.showSuccess(context, 'Invite rejected');
                  if (userId != null) {
                    context.read<ProjectBloc>().add(GetInvitesRequested(userId: userId));
                  }
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.invites.length,
                    itemBuilder: (context, index) {
                      final invite = state.invites[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            invite.projectName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('From: ${invite.creatorName}'),
                              Text('Role: ${invite.role}'),
                              Text('Access: ${invite.hasAccess ? "Yes" : "No"}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () {
                                  context.read<ProjectBloc>().add(
                                        AcceptInviteRequested(inviteId: invite.inviteId),
                                      );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  context.read<ProjectBloc>().add(
                                        RejectInviteRequested(inviteId: invite.inviteId),
                                      );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.settings),
          ),
          const Divider(),
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) => current is AuthUnauthenticated,
            listener: (context, state) {
              if (state is AuthUnauthenticated && mounted) {
                // Navigate to login and remove all previous routes
                // Use rootNavigator to ensure we navigate at app level
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.of(context, rootNavigator: true)
                        .pushNamedAndRemoveUntil(
                      AppRoutes.authWrapper,
                      (route) => false,
                    );
                  }
                });
              }
            },
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Dispatch logout event
                          context.read<AuthBloc>().add(SignOutRequested());
                        },
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


