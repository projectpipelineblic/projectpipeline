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

class CreateProjectDialog extends StatefulWidget {
  const CreateProjectDialog({super.key});

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();
  
  // Default task statuses
  final List<TaskStatusItem> _taskStatuses = [
    TaskStatusItem(name: 'To Do', color: const Color(0xFFF59E0B)),
    TaskStatusItem(name: 'In Progress', color: const Color(0xFF8B5CF6)),
    TaskStatusItem(name: 'Done', color: const Color(0xFF10B981)),
  ];
  
  // Invited team members
  final List<String> _invitedEmails = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
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
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
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
                      const Color(0xFF6366F1), // Indigo
                      const Color(0xFFF59E0B), // Amber
                      const Color(0xFF8B5CF6), // Purple
                      const Color(0xFF10B981), // Green
                      const Color(0xFFEF4444), // Red
                      const Color(0xFF3B82F6), // Blue
                      const Color(0xFFEC4899), // Pink
                      const Color(0xFF14B8A6), // Teal
                    ].map((color) {
                      final isSelected = selectedColor == color;
                      return InkWell(
                        onTap: () {
                          setDialogState(() {
                            selectedColor = color;
                          });
                        },
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
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
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
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a status name'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    setState(() {
                      _taskStatuses.insert(
                        _taskStatuses.length - 1, // Insert before "Done"
                        TaskStatusItem(
                          name: name,
                          color: selectedColor,
                        ),
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

  void _removeStatus(int index) {
    if (_taskStatuses.length > 1) { // Keep at least one status
      setState(() {
        _taskStatuses.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must have at least one status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addTeamMember() {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      return;
    }
    
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
    
    // Check if already invited
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
    setState(() {
      _invitedEmails.remove(email);
    });
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
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
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
                      const Color(0xFF6366F1), // Indigo
                      const Color(0xFFF59E0B), // Amber
                      const Color(0xFF8B5CF6), // Purple
                      const Color(0xFF10B981), // Green
                      const Color(0xFFEF4444), // Red
                      const Color(0xFF3B82F6), // Blue
                      const Color(0xFFEC4899), // Pink
                      const Color(0xFF14B8A6), // Teal
                    ].map((color) {
                      final isSelected = selectedColor == color;
                      return InkWell(
                        onTap: () {
                          setDialogState(() {
                            selectedColor = color;
                          });
                        },
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
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
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
                    if (nameController.text.trim().isEmpty) {
                      return;
                    }
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

  Future<void> _createProject() async {
    try {
      print('🔵 [CreateProject] Starting project creation...');
      
      if (_formKey.currentState!.validate()) {
        print('✅ [CreateProject] Form validated');
        
        // Get current user info
        final authState = context.read<AuthBloc>().state;
        String creatorUid = '';
        String creatorName = '';
        String creatorEmail = '';
        
        print('🔍 [CreateProject] Auth state: ${authState.runtimeType}');
        
        if (authState is AuthSuccess) {
          creatorUid = authState.user.uid ?? '';
          creatorName = authState.user.userName;
          creatorEmail = authState.user.email;
        } else if (authState is AuthAuthenticated) {
          creatorUid = authState.user.uid ?? '';
          creatorName = authState.user.userName;
          creatorEmail = authState.user.email;
        }
        
        print('🔍 [CreateProject] Creator UID: $creatorUid');
        print('🔍 [CreateProject] Creator Name: $creatorName');
        print('🔍 [CreateProject] Creator Email: $creatorEmail');
        
        if (creatorUid.isEmpty) {
          print('❌ [CreateProject] Creator UID is empty');
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
        final invitedEmails = List<String>.from(_invitedEmails); // Copy list
        
        print('📝 [CreateProject] Project Name: $projectName');
        print('📝 [CreateProject] Description: $projectDescription');
        print('📝 [CreateProject] Invited Emails: ${invitedEmails.length}');
        print('📝 [CreateProject] Custom Statuses: ${_taskStatuses.length}');
        
        final projectBloc = context.read<ProjectBloc>();
        final messenger = ScaffoldMessenger.of(context); // Cache messenger
        
        // Convert task statuses to map format
        final statusesData = _taskStatuses.map((status) {
          // Convert Color to hex string
          final colorHex = '#${status.color.value.toRadixString(16).substring(2).toUpperCase()}';
          return {
            'name': status.name,
            'colorHex': colorHex,
          };
        }).toList();
        
        print('📝 [CreateProject] Statuses being saved: $statusesData');
        
        // Create project first
        print('🚀 [CreateProject] Dispatching CreateProjectRequested...');
        projectBloc.add(
          CreateProjectRequested(
            name: projectName,
            description: projectDescription,
            creatorUid: creatorUid,
            creatorName: creatorName,
            teamMembers: [], // Empty - creator is added automatically in datasource
            customStatuses: statusesData,
          ),
        );
        
        // Close dialog immediately
        if (mounted) {
          Navigator.pop(context);
          print('✅ [CreateProject] Dialog closed');
        }
      
        // Wait for project creation and send invites
        final subscription = projectBloc.stream.listen((state) async {
          print('🔍 [CreateProject] Project state changed: ${state.runtimeType}');
          
          if (state is ProjectCreated) {
            final projectId = state.project.id ?? '';
            
            print('✅ [CreateProject] Project created with ID: $projectId');
            
            if (projectId.isEmpty) {
              print('❌ [CreateProject] Project ID is empty!');
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Project created but ID is missing'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
            
            // Send invites to all invited emails
            if (invitedEmails.isNotEmpty) {
              print('📧 [CreateProject] Sending ${invitedEmails.length} invitations...');
              int successCount = 0;
              
              for (final email in invitedEmails) {
                print('🔍 [CreateProject] Looking up user: $email');
                
                // First, find user by email
                final findUserResult = await sl<FindUserByEmail>()(
                  FindUserByEmailParams(email: email),
                );
                
                await findUserResult.fold(
                  (failure) {
                    print('⚠️ [CreateProject] User not found: $email - ${failure.message}');
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('User $email not found. They must sign up first.'),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  (userInfo) async {
                    print('✅ [CreateProject] User found: $email (UID: ${userInfo.uid})');
                    print('🔍 [CreateProject] Sending invite with projectId: $projectId, projectName: $projectName');
                    
                    // User found - send invite
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
                          print('❌ [CreateProject] Failed to send invite to $email: ${failure.message}');
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Failed to invite $email: ${failure.message}'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        (_) {
                          print('✅ [CreateProject] Invite sent successfully to $email');
                          successCount++;
                        },
                      );
                    } catch (e) {
                      print('❌ [CreateProject] Exception sending invite: $e');
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Error inviting $email: $e'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                );
              }
              
              print('✅ [CreateProject] Invitations complete. Success: $successCount/${invitedEmails.length}');
              
              // Show final success message
              if (successCount > 0) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Project created! $successCount invitation(s) sent.',
                    ),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            } else {
              print('✅ [CreateProject] No invitations to send');
              // No invites - just show project created
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Project "$projectName" created successfully!'),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }
          } else if (state is ProjectError) {
            print('❌ [CreateProject] Project creation error: ${state.message}');
            messenger.showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        });
        
        // Auto-cancel subscription after handling
        Future.delayed(const Duration(seconds: 10), () {
          print('🔄 [CreateProject] Cancelling subscription');
          subscription.cancel();
        });
      } else {
        print('❌ [CreateProject] Form validation failed');
      }
    } catch (e, stackTrace) {
      print('❌ [CreateProject] EXCEPTION: $e');
      print('❌ [CreateProject] Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating project: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
                      Icons.folder_outlined,
                      color: Color(0xFF6366F1),
                      size: 28,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Text(
                      'Create New Project',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
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
              
              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Project Name
                      Text(
                        'Project Details',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const Gap(16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Project Name *',
                          hintText: 'e.g., Website Redesign',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark 
                            ? const Color(0xFF334155) 
                            : const Color(0xFFF8FAFC),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a project name';
                          }
                          return null;
                        },
                      ),
                      const Gap(16),
                      
                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'What is this project about?',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark 
                            ? const Color(0xFF334155) 
                            : const Color(0xFFF8FAFC),
                        ),
                      ),
                      const Gap(32),
                      
                      // Team Members Section
                      Text(
                        'Invite Team Members',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const Gap(8),
                      Text(
                        'Invite team members by email. They will receive an invitation.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const Gap(16),
                      
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
                                  ? const Color(0xFF334155) 
                                  : const Color(0xFFF8FAFC),
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
                      if (_invitedEmails.isNotEmpty) ...[
                        const Gap(16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Invited Members (${_invitedEmails.length})',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                              const Gap(12),
                              ..._invitedEmails.map((email) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark 
                                          ? const Color(0xFF1E293B) 
                                          : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                                            child: Text(
                                              email[0].toUpperCase(),
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF6366F1),
                                              ),
                                            ),
                                          ),
                                          const Gap(12),
                                          Expanded(
                                            child: Text(
                                              email,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                                              ),
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
                          ),
                        ),
                      ],
                      
                      const Gap(32),
                      
                      // Task Statuses Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Task Workflow Statuses',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addCustomStatus,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Status'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                      const Gap(8),
                      Text(
                        'Customize your workflow by adding statuses like "In Review", "Testing", etc.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const Gap(16),
                      
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
                ),
              ),
              
              const Gap(24),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
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
                    onPressed: _createProject,
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(
                      'Create Project',
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
        ),
      ),
    );
  }
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
          // Drag Handle
          Icon(
            Icons.drag_indicator,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            size: 20,
          ),
          const Gap(12),
          
          // Color Indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const Gap(12),
          
          // Status Name
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
          
          // Edit Button
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Edit status',
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          
          // Delete Button
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

