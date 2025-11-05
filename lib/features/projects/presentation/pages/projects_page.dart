import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_pipeline/core/utils/app_snackbar.dart';
import 'package:project_pipeline/core/widgets/primart_text.dart';
import 'package:project_pipeline/core/theme/app_pallete.dart';
import 'package:project_pipeline/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_bloc.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_event.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_state.dart';
import 'package:project_pipeline/features/projects/presentation/pages/add_project_page.dart';
import 'package:project_pipeline/features/projects/presentation/pages/project_detail_page.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  String? _currentUserUid;
  bool _hasLoadedInitial = false;
  List<ProjectEntity>? _projects;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedInitial) {
      _getCurrentUser();
      _hasLoadedInitial = true;
    }
  }

  void _getCurrentUser() {
    final authState = context.read<AuthBloc>().state;
    String? userId;
    
    if (authState is AuthAuthenticated) {
      userId = authState.user.uid;
    } else if (authState is AuthSuccess) {
      userId = authState.user.uid;
    } else if (authState is AuthOffline) {
      userId = authState.user.uid;
    }

    if (userId != null) {
      if (_currentUserUid != userId) {
        setState(() {
          _currentUserUid = userId;
        });
        _loadProjects();
      } else if (_currentUserUid == null) {
        _currentUserUid = userId;
        _loadProjects();
      }
    }
  }

  void _loadProjects() {
    if (_currentUserUid != null) {
      context.read<ProjectBloc>().add(
            GetProjectsRequested(userId: _currentUserUid!),
          );
    }
  }

  void _navigateToAddProject() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProjectPage(),
      ),
    );
    // Reload projects when returning from add project page
    if (mounted) {
      _loadProjects();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: PrimaryText(
          text: 'My Projects',
          size: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFE5E7EB)
              : AppPallete.secondary,
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, authState) {
              // When auth becomes available or username is updated, (re)load projects
              if (authState is AuthAuthenticated ||
                  authState is AuthSuccess ||
                  authState is AuthOffline ||
                  authState is UsernameUpdated) {
                _getCurrentUser();
              }
            },
          ),
          BlocListener<ProjectBloc, ProjectState>(
            listener: (context, state) {
              if (state is ProjectLoading) {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
              } else if (state is ProjectLoaded) {
                setState(() {
                  _projects = state.projects;
                  _isLoading = false;
                  _errorMessage = null;
                });
              } else if (state is ProjectError) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = state.message;
                });
                AppSnackBar.showError(context, state.message);
              } else if (state is ProjectCreated) {
                // After create, refresh list without wiping current UI
                _loadProjects();
              }
            },
          ),
        ],
        child: Builder(
          builder: (_) {
            if (_isLoading && (_projects == null || _projects!.isEmpty)) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_errorMessage != null && (_projects == null || _projects!.isEmpty)) {
              return _buildErrorState();
            }

            final projects = _projects ?? const <ProjectEntity>[];
            if (projects.isEmpty) {
              return _buildEmptyState();
            }
            return _buildProjectsList(projects);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddProject,
        backgroundColor: AppPallete.primary,
        child: const Icon(Icons.add, color: AppPallete.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 64,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF9CA3AF)
                  : AppPallete.textGray,
            ),
            const SizedBox(height: 16),
            PrimaryText(
              text: 'No projects yet',
              size: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFE5E7EB)
                  : AppPallete.secondary,
            ),
            const SizedBox(height: 8),
            PrimaryText(
              text: 'Create your first project to get started',
              size: 14,
              color: AppPallete.textGray,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _navigateToAddProject,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPallete.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const PrimaryText(
                text: 'Create Project',
                color: AppPallete.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppPallete.orange,
            ),
            const SizedBox(height: 16),
            PrimaryText(
              text: 'Failed to load projects',
              size: 18,
              fontWeight: FontWeight.bold,
              color: AppPallete.secondary,
            ),
            const SizedBox(height: 8),
            PrimaryText(
              text: 'Please try again later',
              size: 14,
              color: AppPallete.textGray,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProjects,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPallete.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const PrimaryText(
                text: 'Retry',
                color: AppPallete.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsList(List<ProjectEntity> projects) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadProjects();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: projects.length,
        itemBuilder: (context, index) {
          final project = projects[index];
          return _buildProjectCard(project);
        },
      ),
    );
  }

  Widget _buildProjectCard(ProjectEntity project) {
    final isCreator = project.creatorUid == _currentUserUid;
    final memberCount = project.members.length;
    final pendingInvitesCount = project.pendingInvites.length;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProjectDetailPage(project: project),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with initials
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: PrimaryText(
                      text: _projectInitials(project.name),
                      size: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: PrimaryText(
                                text: project.name,
                                size: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            if (isCreator)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: PrimaryText(
                                  text: 'Owner',
                                  size: 12,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        PrimaryText(
                          text: project.description,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.people_outline,
                    label: '$memberCount member${memberCount != 1 ? 's' : ''}',
                  ),
                  const SizedBox(width: 12),
                  if (pendingInvitesCount > 0)
                    _buildInfoChip(
                      icon: Icons.mail_outline,
                      label:
                          '$pendingInvitesCount invite${pendingInvitesCount != 1 ? 's' : ''}',
                      color: AppPallete.orange,
                    ),
                  const Spacer(),
                  _buildMembersAvatars(project.members),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color ?? colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        PrimaryText(
          text: label,
          size: 12,
          color: color ?? colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }

  String _projectInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    final words = trimmed.split(RegExp(r"\s+")).where((w) => w.isNotEmpty).toList();
    if (words.length == 1) {
      final w = words.first;
      return (w.length >= 2 ? w.substring(0, 2) : w.substring(0, 1)).toUpperCase();
    }
    final first = words[0][0];
    final second = words[1][0];
    return (first + second).toUpperCase();
  }

  Widget _buildMembersAvatars(List<ProjectMember> members) {
    final colorScheme = Theme.of(context).colorScheme;
    const double size = 28;
    const double radius = 6;

    // Show up to 5 avatars, then a "+N others" indicator
    const int maxAvatars = 5;
    final int visible = members.length > maxAvatars ? maxAvatars : members.length;
    final int overflow = members.length - visible;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (int i = 0; i < visible; i++)
          Tooltip(
            message: members[i].name.isNotEmpty ? members[i].name : members[i].email,
            child: Container(
              height: size,
              width: size,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.4),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: PrimaryText(
                text: _memberInitials(
                  members[i].name.isNotEmpty ? members[i].name : members[i].email,
                ),
                size: 12,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),
        if (overflow > 0)
          Container(
            height: size,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.4),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: PrimaryText(
              text: '+$overflow others',
              size: 12,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
      ],
    );
  }

  String _memberInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    final words = trimmed.split(RegExp(r"\s+")).where((w) => w.isNotEmpty).toList();
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    final first = words.first.substring(0, 1);
    final last = words.last.substring(0, 1);
    return (first + last).toUpperCase();
  }

  // Removed date formatting as we now display member avatars instead
}

