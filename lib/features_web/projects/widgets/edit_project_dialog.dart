import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_bloc.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_event.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_state.dart';

class EditProjectDialog extends StatefulWidget {
  final ProjectEntity project;
  
  const EditProjectDialog({
    super.key,
    required this.project,
  });

  @override
  State<EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<EditProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  
  late List<TaskStatusItem> _taskStatuses;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _descriptionController = TextEditingController(text: widget.project.description);
    
    // Load existing custom statuses or use defaults
    if (widget.project.customStatuses != null && widget.project.customStatuses!.isNotEmpty) {
      _taskStatuses = widget.project.customStatuses!.map((status) {
        // Parse hex color
        Color color;
        try {
          final hexColor = status.colorHex.replaceAll('#', '');
          color = Color(int.parse('FF$hexColor', radix: 16));
        } catch (e) {
          color = const Color(0xFF6366F1);
        }
        
        return TaskStatusItem(
          name: status.name,
          color: color,
        );
      }).toList();
    } else {
      // Default statuses
      _taskStatuses = [
        TaskStatusItem(name: 'To Do', color: const Color(0xFFF59E0B)),
        TaskStatusItem(name: 'In Progress', color: const Color(0xFF8B5CF6)),
        TaskStatusItem(name: 'Done', color: const Color(0xFF10B981)),
      ];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
                        _taskStatuses.length - 1, // Insert before last
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
    if (_taskStatuses.length > 1) {
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

  Future<void> _updateProject() async {
    try {
      print('🔵 [EditProject] Starting project update...');
      
      if (_formKey.currentState!.validate()) {
        print('✅ [EditProject] Form validated');
        
        final projectName = _nameController.text.trim();
        final projectDescription = _descriptionController.text.trim();
        
        // Convert task statuses to map format
        final statusesData = _taskStatuses.map((status) {
          final colorHex = '#${status.color.value.toRadixString(16).substring(2).toUpperCase()}';
          return {
            'name': status.name,
            'colorHex': colorHex,
          };
        }).toList();
        
        print('📝 [EditProject] Project Name: $projectName');
        print('📝 [EditProject] Description: $projectDescription');
        print('📝 [EditProject] Custom Statuses: ${statusesData.length}');
        
        final projectBloc = context.read<ProjectBloc>();
        final messenger = ScaffoldMessenger.of(context);
        
        print('🚀 [EditProject] Dispatching UpdateProjectRequested...');
        projectBloc.add(
          UpdateProjectRequested(
            projectId: widget.project.id!,
            name: projectName,
            description: projectDescription,
            customStatuses: statusesData,
          ),
        );
        
        // Close dialog immediately
        if (mounted) {
          Navigator.pop(context);
          print('✅ [EditProject] Dialog closed');
        }
        
        // Listen for update result
        final subscription = projectBloc.stream.listen((state) {
          print('🔍 [EditProject] Project state changed: ${state.runtimeType}');
          
          if (state is ProjectUpdated) {
            print('✅ [EditProject] Project updated successfully');
            messenger.showSnackBar(
              SnackBar(
                content: Text('Project "${projectName}" updated successfully!'),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          } else if (state is ProjectError) {
            print('❌ [EditProject] Project update error: ${state.message}');
            messenger.showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        });
        
        Future.delayed(const Duration(seconds: 5), () {
          subscription.cancel();
        });
      } else {
        print('❌ [EditProject] Form validation failed');
      }
    } catch (e, stackTrace) {
      print('❌ [EditProject] EXCEPTION: $e');
      print('❌ [EditProject] Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating project: $e'),
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
                      Icons.edit_outlined,
                      color: Color(0xFF6366F1),
                      size: 28,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Text(
                      'Edit Project',
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
                        'Manage your workflow statuses',
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
                    onPressed: _updateProject,
                    icon: const Icon(Icons.save, size: 20),
                    label: Text(
                      'Save Changes',
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

