import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_pipeline/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_bloc.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_event.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_state.dart';
import 'package:project_pipeline/features/projects/domain/usecases/send_team_invite_usecase.dart';
import 'package:project_pipeline/features/projects/domain/usecases/find_user_by_email_usecase.dart';
import 'package:project_pipeline/core/di/service_locator.dart';

class CreateProjectWizard extends StatefulWidget {
  const CreateProjectWizard({super.key});

  @override
  State<CreateProjectWizard> createState() => _CreateProjectWizardState();
}

class _CreateProjectWizardState extends State<CreateProjectWizard> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  
  // Step 1: Project Type
  String? _selectedProjectType;
  
  // Step 2: Project Features
  String _workflowType = 'kanban';
  
  // Step 3: Project Details
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _keyController = TextEditingController();
  
  // Step 4: Team Invitations
  final _emailController = TextEditingController();
  final List<String> _invitedEmails = [];
  
  // Step 5: Custom Statuses
  List<TaskStatusItem> _taskStatuses = [];

  @override
  void initState() {
    super.initState();
    _initializeDefaultStatuses();
  }

  void _initializeDefaultStatuses() {
    _taskStatuses = [
      TaskStatusItem(name: 'To Do', color: const Color(0xFFF59E0B)),
      TaskStatusItem(name: 'In Progress', color: const Color(0xFF8B5CF6)),
      TaskStatusItem(name: 'Done', color: const Color(0xFF10B981)),
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _keyController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _generateProjectKey() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    
    final words = name.split(' ');
    String key;
    
    if (words.length >= 2) {
      key = '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (name.length >= 3) {
      key = name.substring(0, 3).toUpperCase();
    } else {
      key = name.toUpperCase();
    }
    
    _keyController.text = key;
  }

  void _nextStep() {
    // Validate current step before proceeding
    if (_currentStep == 0 && _selectedProjectType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a project type'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_currentStep == 2) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
      _generateProjectKey();
    }
    
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _addTeamMember() {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) return;
    
    // Validate email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_invitedEmails.contains(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This email has already been invited'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _invitedEmails.add(email);
      _emailController.clear();
    });
  }

  void _removeTeamMember(String email) {
    setState(() => _invitedEmails.remove(email));
  }

  void _addCustomStatus() {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        Color selectedColor = const Color(0xFF6366F1);
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              title: Text(
                'Add New Status',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Status Name',
                      hintText: 'e.g., In Review, Testing',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const Gap(16),
                  Text(
                    'Choose Color',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Gap(12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      const Color(0xFF6366F1),
                      const Color(0xFFF59E0B),
                      const Color(0xFF8B5CF6),
                      const Color(0xFF10B981),
                      const Color(0xFFEF4444),
                      const Color(0xFF3B82F6),
                      const Color(0xFFEC4899),
                      const Color(0xFF14B8A6),
                    ].map((color) {
                      final isSelected = selectedColor == color;
                      return InkWell(
                        onTap: () => setDialogState(() => selectedColor = color),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    
                    setState(() {
                      _taskStatuses.insert(
                        _taskStatuses.length - 1,
                        TaskStatusItem(name: name, color: selectedColor),
                      );
                    });
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                  ),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editStatus(int index) {
    final status = _taskStatuses[index];
    final nameController = TextEditingController(text: status.name);
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        Color selectedColor = status.color;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              title: Text(
                'Edit Status',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Status Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const Gap(16),
                  Text(
                    'Choose Color',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Gap(12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      const Color(0xFF6366F1),
                      const Color(0xFFF59E0B),
                      const Color(0xFF8B5CF6),
                      const Color(0xFF10B981),
                      const Color(0xFFEF4444),
                      const Color(0xFF3B82F6),
                      const Color(0xFFEC4899),
                      const Color(0xFF14B8A6),
                    ].map((color) {
                      final isSelected = selectedColor == color;
                      return InkWell(
                        onTap: () => setDialogState(() => selectedColor = color),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    
                    setState(() {
                      _taskStatuses[index] = TaskStatusItem(
                        name: nameController.text.trim(),
                        color: selectedColor,
                      );
                    });
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removeStatus(int index) {
    if (_taskStatuses.length > 1) {
      setState(() => _taskStatuses.removeAt(index));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must have at least one status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authState = context.read<AuthBloc>().state;
    String creatorUid = '';
    String creatorName = '';
    
    if (authState is AuthSuccess) {
      creatorUid = authState.user.uid ?? '';
      creatorName = authState.user.userName;
    } else if (authState is AuthAuthenticated) {
      creatorUid = authState.user.uid ?? '';
      creatorName = authState.user.userName;
    } else if (authState is AuthOffline) {
      creatorUid = authState.user.uid ?? '';
      creatorName = authState.user.userName;
    }
    
    if (creatorUid.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to create project. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    final projectName = _nameController.text.trim();
    final projectDescription = _descriptionController.text.trim();
    final invitedEmails = List<String>.from(_invitedEmails);
    
    final projectBloc = context.read<ProjectBloc>();
    final messenger = ScaffoldMessenger.of(context);
    
    // Convert statuses
    final statusesData = _taskStatuses.map((status) {
      final colorHex = '#${status.color.value.toRadixString(16).substring(2).toUpperCase()}';
      return {
        'name': status.name,
        'colorHex': colorHex,
      };
    }).toList();
    
    // Capture additional features
    final features = <String, bool>{
      'time_tracking': false, // TODO: Get from checkbox state
      'task_dependencies': false, // TODO: Get from checkbox state
      'file_attachments': false, // TODO: Get from checkbox state
    };
    
    // Create project with all wizard configuration
    projectBloc.add(
      CreateProjectRequested(
        name: projectName,
        description: projectDescription,
        creatorUid: creatorUid,
        creatorName: creatorName,
        teamMembers: [],
        customStatuses: statusesData,
        projectType: _selectedProjectType,
        workflowType: _workflowType,
        projectKey: _keyController.text.trim(),
        additionalFeatures: features,
      ),
    );
    
    // Close dialog
    if (mounted) {
      Navigator.pop(context);
    }
    
    // Handle invitations
    final subscription = projectBloc.stream.listen((state) async {
      if (state is ProjectCreated) {
        final projectId = state.project.id ?? '';
        
        if (projectId.isEmpty) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Project created but ID is missing'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        
        // Send invites
        if (invitedEmails.isNotEmpty) {
          int successCount = 0;
          
          for (final email in invitedEmails) {
            final findUserResult = await sl<FindUserByEmail>()(
              FindUserByEmailParams(email: email),
            );
            
            await findUserResult.fold(
              (failure) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('User $email not found. They must sign up first.'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              (userInfo) async {
                try {
                  final inviteResult = await sl<SendTeamInvite>()(
                    SendTeamInviteParams(
                      projectId: projectId,
                      projectName: projectName,
                      invitedUserUid: userInfo.uid,
                      invitedUserEmail: email,
                      creatorName: creatorName,
                      creatorUid: creatorUid,
                      role: 'member',
                      hasAccess: true,
                    ),
                  );
                  
                  inviteResult.fold(
                    (failure) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to invite $email'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    (_) => successCount++,
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Error inviting $email'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            );
          }
          
          if (successCount > 0) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('Project created! $successCount invitation(s) sent.'),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Project "$projectName" created successfully!'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (state is ProjectError) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error: ${state.message}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
    
    Future.delayed(const Duration(seconds: 10), () => subscription.cancel());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        height: 700,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.rocket_launch,
                    color: Color(0xFF6366F1),
                    size: 28,
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create New Project',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Step ${_currentStep + 1} of 5',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const Gap(24),
            
            // Progress Indicator
            _buildProgressIndicator(isDark),
            const Gap(32),
            
            // Step Content
            Expanded(
              child: Form(
                key: _formKey,
                child: _buildStepContent(isDark),
              ),
            ),
            
            const Gap(24),
            
            // Navigation Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  OutlinedButton.icon(
                    onPressed: _previousStep,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: Text(
                      'Back',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                else
                  const SizedBox(),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Gap(12),
                    ElevatedButton.icon(
                      onPressed: _currentStep == 4 ? _createProject : _nextStep,
                      icon: Icon(
                        _currentStep == 4 ? Icons.check : Icons.arrow_forward,
                        size: 20,
                      ),
                      label: Text(
                        _currentStep == 4 ? 'Create Project' : 'Next',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    return Row(
      children: List.generate(5, (index) {
        final isActive = index <= _currentStep;
        
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF6366F1)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (index < 4) const Gap(4),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepContent(bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildProjectTypeStep(isDark);
      case 1:
        return _buildProjectFeaturesStep(isDark);
      case 2:
        return _buildProjectDetailsStep(isDark);
      case 3:
        return _buildTeamInvitationStep(isDark);
      case 4:
        return _buildCustomStatusStep(isDark);
      default:
        return const SizedBox();
    }
  }

  // STEP 1: Project Type Selection
  Widget _buildProjectTypeStep(bool isDark) {
    final projectTypes = [
      ProjectType(
        name: 'Software Development',
        description: 'Build and ship software projects with agile workflows',
        icon: Icons.code,
        color: const Color(0xFF6366F1),
      ),
      ProjectType(
        name: 'Marketing Campaign',
        description: 'Plan, execute, and track marketing initiatives',
        icon: Icons.campaign,
        color: const Color(0xFFEC4899),
      ),
      ProjectType(
        name: 'Product Design',
        description: 'Design and prototype products with creative workflows',
        icon: Icons.brush,
        color: const Color(0xFF8B5CF6),
      ),
      ProjectType(
        name: 'Business Strategy',
        description: 'Manage business goals, OKRs, and strategic planning',
        icon: Icons.business_center,
        color: const Color(0xFF10B981),
      ),
      ProjectType(
        name: 'Research & Analytics',
        description: 'Conduct research and analyze data-driven projects',
        icon: Icons.analytics,
        color: const Color(0xFFF59E0B),
      ),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose your project type',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const Gap(8),
          Text(
            'Select the type that best matches your project. This will help us configure the right features for you.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const Gap(32),
          
          // Project Type Cards
          ...projectTypes.map((type) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ProjectTypeCard(
                  type: type,
                  isSelected: _selectedProjectType == type.name,
                  isDark: isDark,
                  onTap: () => setState(() => _selectedProjectType = type.name),
                ),
              )),
        ],
      ),
    );
  }

  // STEP 2: Project Features Selection
  Widget _buildProjectFeaturesStep(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configure project features',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const Gap(8),
          Text(
            'Choose the tools and features that match your workflow.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const Gap(32),
          
          // Workflow Type
          Text(
            'Workflow Type',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const Gap(16),
          
          _FeatureCard(
            icon: Icons.view_kanban,
            title: 'Kanban Board',
            description: 'Visualize work with cards and columns',
            isSelected: _workflowType == 'kanban',
            isDark: isDark,
            onTap: () => setState(() => _workflowType = 'kanban'),
          ),
          const Gap(12),
          
          _FeatureCard(
            icon: Icons.calendar_view_week,
            title: 'Scrum with Sprints',
            description: 'Plan work in time-boxed sprints',
            isSelected: _workflowType == 'scrum',
            isDark: isDark,
            onTap: () => setState(() => _workflowType = 'scrum'),
          ),
          const Gap(12),
          
          _FeatureCard(
            icon: Icons.list,
            title: 'Simple Task List',
            description: 'Basic task tracking without boards',
            isSelected: _workflowType == 'list',
            isDark: isDark,
            onTap: () => setState(() => _workflowType = 'list'),
          ),
          
          const Gap(32),
          
          // Additional Features
          Text(
            'Additional Features',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const Gap(16),
          
          _CheckboxFeature(
            title: 'Time Tracking',
            description: 'Track time spent on tasks',
            isDark: isDark,
          ),
          const Gap(12),
          
          _CheckboxFeature(
            title: 'Task Dependencies',
            description: 'Link tasks that depend on each other',
            isDark: isDark,
          ),
          const Gap(12),
          
          _CheckboxFeature(
            title: 'File Attachments',
            description: 'Attach files and documents to tasks',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // STEP 3: Project Details
  Widget _buildProjectDetailsStep(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project details',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const Gap(8),
          Text(
            'Give your project a name and description.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const Gap(32),
          
          // Project Name
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Project Name *',
              hintText: 'e.g., Mobile App Redesign',
              prefixIcon: const Icon(Icons.title),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: isDark 
                ? const Color(0xFF1E293B) 
                : Colors.white,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a project name';
              }
              return null;
            },
            onChanged: (_) => _generateProjectKey(),
          ),
          const Gap(20),
          
          // Project Key
          TextFormField(
            controller: _keyController,
            decoration: InputDecoration(
              labelText: 'Project Key *',
              hintText: 'e.g., MAR',
              prefixIcon: const Icon(Icons.key),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: isDark 
                ? const Color(0xFF1E293B) 
                : Colors.white,
              helperText: 'A unique identifier for your project (2-4 characters)',
            ),
            maxLength: 4,
            textCapitalization: TextCapitalization.characters,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a project key';
              }
              if (value.length < 2) {
                return 'Key must be at least 2 characters';
              }
              return null;
            },
          ),
          const Gap(20),
          
          // Description
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'What is this project about?',
              prefixIcon: const Icon(Icons.description),
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: isDark 
                ? const Color(0xFF1E293B) 
                : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // STEP 4: Team Invitation
  Widget _buildTeamInvitationStep(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invite your team',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const Gap(8),
          Text(
            'Invite team members by email. They will receive an invitation to join your project.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const Gap(32),
          
          // Email Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Enter email address',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark 
                      ? const Color(0xFF1E293B) 
                      : Colors.white,
                  ),
                  onSubmitted: (_) => _addTeamMember(),
                ),
              ),
              const Gap(12),
              ElevatedButton.icon(
                onPressed: _addTeamMember,
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Invite'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          
          // Invited Members List
          if (_invitedEmails.isEmpty) ...[
            const Gap(48),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  const Gap(16),
                  Text(
                    'No team members invited yet',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'You can skip this step and invite people later',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const Gap(24),
            Text(
              'Invited Members (${_invitedEmails.length})',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const Gap(16),
            ..._invitedEmails.map((email) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark 
                        ? const Color(0xFF1E293B) 
                        : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark 
                          ? const Color(0xFF334155) 
                          : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                          child: Text(
                            email[0].toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                email,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                'Member • Pending invitation',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeTeamMember(email),
                          icon: const Icon(Icons.close, size: 18),
                          color: Colors.red,
                          tooltip: 'Remove',
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  // STEP 5: Custom Status
  Widget _buildCustomStatusStep(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customize workflow',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const Gap(8),
                    Text(
                      'Add custom statuses to match your workflow. Drag to reorder.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _addCustomStatus,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Status'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const Gap(32),
          
          // Status List
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _taskStatuses.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = _taskStatuses.removeAt(oldIndex);
                  _taskStatuses.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final status = _taskStatuses[index];
                return _StatusListItem(
                  key: ValueKey(status.name + index.toString()),
                  status: status,
                  isDark: isDark,
                  onEdit: () => _editStatus(index),
                  onDelete: () => _removeStatus(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Project Type Data Model
class ProjectType {
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  ProjectType({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// Task Status Data Model
class TaskStatusItem {
  final String name;
  final Color color;

  TaskStatusItem({
    required this.name,
    required this.color,
  });
}

// Project Type Card Widget
class _ProjectTypeCard extends StatelessWidget {
  final ProjectType type;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ProjectTypeCard({
    required this.type,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? type.color
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: type.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                type.icon,
                color: type.color,
                size: 28,
              ),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const Gap(4),
                  Text(
                    type.description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: type.color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

// Feature Card Widget
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6366F1)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
              size: 24,
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const Gap(4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF6366F1),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// Checkbox Feature Widget
class _CheckboxFeature extends StatefulWidget {
  final String title;
  final String description;
  final bool isDark;

  const _CheckboxFeature({
    required this.title,
    required this.description,
    required this.isDark,
  });

  @override
  State<_CheckboxFeature> createState() => _CheckboxFeatureState();
}

class _CheckboxFeatureState extends State<_CheckboxFeature> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _isChecked,
            onChanged: (value) => setState(() => _isChecked = value ?? false),
            activeColor: const Color(0xFF6366F1),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const Gap(4),
                Text(
                  widget.description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Status List Item Widget
class _StatusListItem extends StatelessWidget {
  final TaskStatusItem status;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StatusListItem({
    super.key,
    required this.status,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.drag_indicator,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            size: 20,
          ),
          const Gap(12),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Text(
              status.name,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
          const Gap(12),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Edit status',
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: 'Delete status',
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}

