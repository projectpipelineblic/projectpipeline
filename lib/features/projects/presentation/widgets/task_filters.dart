import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:project_pipeline/core/theme/app_pallete.dart';
import 'package:project_pipeline/core/widgets/primart_text.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';

enum TaskStatusFilter { all, todo, inProgress, done, custom }

class TaskFilters extends StatelessWidget {
  const TaskFilters({
    super.key,
    required this.selected,
    required this.onChanged,
    this.customStatuses,
    this.selectedStatusName,
    this.onStatusNameChanged,
  });

  final TaskStatusFilter selected;
  final ValueChanged<TaskStatusFilter> onChanged;
  final List<CustomStatus>? customStatuses;
  final String? selectedStatusName;
  final ValueChanged<String?>? onStatusNameChanged;

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    
    // Use custom statuses if available, otherwise use defaults
    final hasCustomStatuses = customStatuses != null && customStatuses!.isNotEmpty;
    
    print('🔍 [TaskFilters] Building filters...');
    print('🔍 [TaskFilters] Has custom statuses: $hasCustomStatuses');
    print('🔍 [TaskFilters] Custom statuses count: ${customStatuses?.length ?? 0}');
    
    if (hasCustomStatuses) {
      print('✅ [TaskFilters] Rendering CUSTOM status chips');
      print('✅ [TaskFilters] Total custom statuses: ${customStatuses!.length}');
      print('✅ [TaskFilters] Selected status name: $selectedStatusName');
      
      // Render custom statuses with string-based filtering
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Always show "All" filter first
            GestureDetector(
              onTap: () {
                onChanged(TaskStatusFilter.all);
                if (onStatusNameChanged != null) {
                  onStatusNameChanged!(null); // Clear custom status filter
                }
              },
              child: _FilterChip(
                label: 'All',
                selected: selected == TaskStatusFilter.all && selectedStatusName == null,
                color: const Color(0xFF6366F1),
                isWeb: isWeb,
              ),
            ),
            const SizedBox(width: 8),
            // Show all custom statuses as clickable chips
            ...customStatuses!.map((status) {
              print('  🔹 Status: ${status.name} (${status.colorHex})');
              
              // Parse hex color
              Color statusColor;
              try {
                final hexColor = status.colorHex.replaceAll('#', '');
                statusColor = Color(int.parse('FF$hexColor', radix: 16));
                print('    ✅ Color parsed: $statusColor');
              } catch (e) {
                print('    ❌ Color parse error: $e');
                statusColor = const Color(0xFF6366F1); // Default color
              }
              
              final isSelected = selectedStatusName == status.name;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () {
                    print('🔘 [TaskFilters] Custom status clicked: ${status.name}');
                    onChanged(TaskStatusFilter.custom);
                    if (onStatusNameChanged != null) {
                      onStatusNameChanged!(status.name);
                    }
                  },
                  child: _FilterChip(
                    label: status.name,
                    selected: isSelected,
                    color: statusColor,
                    isWeb: isWeb,
                  ),
                ),
              );
            }),
          ],
        ),
      );
    }
    
    print('⚠️ [TaskFilters] Rendering DEFAULT status chips');
    
    
    // Default statuses
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onChanged(TaskStatusFilter.all),
            child: _FilterChip(
              label: 'All',
              selected: selected == TaskStatusFilter.all,
              color: const Color(0xFF6366F1),
              isWeb: isWeb,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onChanged(TaskStatusFilter.todo),
            child: _FilterChip(
              label: 'To Do',
              selected: selected == TaskStatusFilter.todo,
              color: const Color(0xFFF59E0B),
              isWeb: isWeb,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onChanged(TaskStatusFilter.inProgress),
            child: _FilterChip(
              label: 'In Progress',
              selected: selected == TaskStatusFilter.inProgress,
              color: const Color(0xFF8B5CF6),
              isWeb: isWeb,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onChanged(TaskStatusFilter.done),
            child: _FilterChip(
              label: 'Done',
              selected: selected == TaskStatusFilter.done,
              color: const Color(0xFF10B981),
              isWeb: isWeb,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    this.isWeb = false,
  });

  final String label;
  final bool selected;
  final Color color;
  final bool isWeb;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Web-optimized colors
    final bgColor = selected 
      ? color
      : (isWeb 
          ? (isDark ? const Color(0xFF1E293B) : Colors.white)
          : Colors.white);
    
    final borderColor = selected 
      ? color
      : (isWeb
          ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
          : Theme.of(context).dividerColor);
    
    final textColor = selected 
      ? Colors.white
      : (isWeb
          ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
          : AppPallete.secondary);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
      child: PrimaryText(
        text: label,
        size: 13,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        color: textColor,
      ),
    );
  }
}


