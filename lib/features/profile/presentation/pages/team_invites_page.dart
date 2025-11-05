import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_pipeline/core/utils/app_snackbar.dart';
import 'package:project_pipeline/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_bloc.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_event.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_state.dart';

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

  Widget _buildProjectAvatar(String projectName) {
    // Get first two letters of project name for avatar
    final initials = projectName.isNotEmpty
        ? projectName.length >= 2
            ? projectName.substring(0, 2).toUpperCase()
            : projectName[0].toUpperCase()
        : 'P';

    // Generate a color based on project name
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    final colorIndex = projectName.hashCode % colors.length;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors[colorIndex],
            colors[colorIndex].withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors[colorIndex].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showRejectConfirmation(
    BuildContext context,
    String inviteId,
    String projectName,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Invite'),
        content: Text('Are you sure you want to reject the invite to "$projectName"?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ProjectBloc>().add(
                    RejectInviteRequested(inviteId: inviteId),
                  );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
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
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header with Avatar and Project Name
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor.withOpacity(0.1),
                              Theme.of(context).primaryColor.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Project Avatar
                            _buildProjectAvatar(invite.projectName),
                            const SizedBox(width: 12),
                            // Project Name and Invite Label
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    invite.projectName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      letterSpacing: 0.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Team Invite',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Content Section
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Invite Details
                            _buildDetailRow(
                              Icons.person_outline,
                              'Invited by',
                              invite.creatorName,
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.shield_outlined,
                              'Role',
                              invite.role.toUpperCase(),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.vpn_key_outlined,
                              'Access Level',
                              invite.hasAccess ? 'Full Access' : 'Limited Access',
                            ),
                            
                            const SizedBox(height: 20),
                            const Divider(height: 1),
                            const SizedBox(height: 16),
                            
                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 20,
                                    ),
                                    label: const Text('Reject'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(
                                        color: Colors.red,
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: () {
                                      _showRejectConfirmation(
                                        context,
                                        invite.inviteId,
                                        invite.projectName,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(
                                      Icons.check_circle_rounded,
                                      size: 20,
                                    ),
                                    label: const Text('Accept'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: () {
                                      context.read<ProjectBloc>().add(
                                            AcceptInviteRequested(
                                              inviteId: invite.inviteId,
                                            ),
                                          );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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

