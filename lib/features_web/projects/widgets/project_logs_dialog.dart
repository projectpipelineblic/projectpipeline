import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';

class ProjectLogsDialog extends StatelessWidget {
  final ProjectEntity project;

  const ProjectLogsDialog({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        width: 800,
        height: 700,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.history,
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
                          'Activity Logs',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          project.name,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
            ),
            
            // Logs Content
            Expanded(
              child: project.id == null
                  ? Center(
                      child: Text(
                        'No project ID',
                        style: GoogleFonts.inter(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('Projects')
                          .doc(project.id)
                          .collection('tasks')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading logs',
                              style: GoogleFonts.inter(
                                color: Colors.red,
                              ),
                            ),
                          );
                        }

                        final allTasks = snapshot.data?.docs ?? [];
                        
                        // Sort tasks by updatedAt, then createdAt
                        final tasks = allTasks.toList()
                          ..sort((a, b) {
                            final aData = a.data() as Map<String, dynamic>;
                            final bData = b.data() as Map<String, dynamic>;
                            
                            final aUpdated = (aData['updatedAt'] as Timestamp?)?.toDate();
                            final bUpdated = (bData['updatedAt'] as Timestamp?)?.toDate();
                            final aCreated = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                            final bCreated = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                            
                            final aTime = aUpdated ?? aCreated;
                            final bTime = bUpdated ?? bCreated;
                            
                            return bTime.compareTo(aTime); // Descending order
                          });
                        
                        print('📋 [ProjectLogs] Displaying ${tasks.length} task activities');

                        if (tasks.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                ),
                                const Gap(16),
                                Text(
                                  'No activity yet',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                                const Gap(8),
                                Text(
                                  'Task updates will appear here',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(24),
                          physics: const AlwaysScrollableScrollPhysics(),
                          shrinkWrap: false,
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final taskDoc = tasks[index];
                            final data = taskDoc.data() as Map<String, dynamic>;
                            
                            final title = data['title'] ?? 'Untitled Task';
                            final status = data['status'] ?? 'todo';
                            final statusName = data['statusName'] as String?;
                            final assigneeName = data['assigneeName'] as String? ?? 'Unassigned';
                            final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
                            final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                            
                            final displayTime = updatedAt ?? createdAt;
                            final now = DateTime.now();
                            final diff = now.difference(displayTime);
                            
                            print('📋 [ProjectLogs] Log #$index: $title');
                            print('   Status: ${statusName ?? status}');
                            print('   Assignee: $assigneeName');
                            print('   Created: $createdAt');
                            print('   Updated: $updatedAt');
                            print('   Display Time: $displayTime');
                            print('   Time Diff: ${diff.inMinutes} minutes ago');
                            print('   ---');

                            return _LogItem(
                              key: ValueKey(taskDoc.id),
                              title: title,
                              status: statusName ?? status,
                              assigneeName: assigneeName,
                              timestamp: displayTime,
                              isDark: isDark,
                              isUpdate: updatedAt != null,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogItem extends StatelessWidget {
  final String title;
  final String status;
  final String assigneeName;
  final DateTime timestamp;
  final bool isDark;
  final bool isUpdate;

  const _LogItem({
    super.key,
    required this.title,
    required this.status,
    required this.assigneeName,
    required this.timestamp,
    required this.isDark,
    this.isUpdate = false,
  });

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'done':
      case 'complete':
      case 'completed':
        return const Color(0xFF10B981);
      case 'inprogress':
      case 'in progress':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  IconData _getStatusIcon() {
    if (isUpdate) {
      return Icons.update;
    }
    return Icons.add_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final now = DateTime.now();
    final timeDiff = now.difference(timestamp);
    String timeAgo;
    
    print('🎨 [LogItem] Building: $title');
    print('   Timestamp: $timestamp');
    print('   Now: $now');
    print('   Diff: ${timeDiff.inMinutes} minutes, ${timeDiff.inHours} hours, ${timeDiff.inDays} days');
    
    if (timeDiff.inSeconds < 60) {
      timeAgo = 'Just now';
    } else if (timeDiff.inMinutes < 60) {
      timeAgo = '${timeDiff.inMinutes}m ago';
    } else if (timeDiff.inHours < 24) {
      timeAgo = '${timeDiff.inHours}h ago';
    } else if (timeDiff.inDays < 7) {
      timeAgo = '${timeDiff.inDays}d ago';
    } else if (timeDiff.inDays < 365) {
      timeAgo = DateFormat('MMM d').format(timestamp);
    } else {
      timeAgo = DateFormat('MMM d, yyyy').format(timestamp);
    }
    
    print('   Display: $timeAgo');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(),
                size: 20,
                color: statusColor,
              ),
            ),
            const Gap(16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          const Gap(4),
                          Text(
                            assigneeName,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const Gap(12),
            
            // Time
            Text(
              timeAgo,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

