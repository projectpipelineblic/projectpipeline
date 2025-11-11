import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_pipeline/core/di/service_locator.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';
import 'package:project_pipeline/features/projects/domain/entities/sprint_entity.dart';
import 'package:project_pipeline/features/projects/domain/usecases/get_sprints_usecase.dart' show GetSprints, GetSprintsParams;

/// Sprint Gantt Timeline - Visual timeline showing sprints as colored bars
class SprintGanttTimeline extends StatefulWidget {
  const SprintGanttTimeline({
    super.key,
    required this.project,
    required this.onSprintTap,
    required this.onAddSprintTap,
  });

  final ProjectEntity project;
  final void Function(SprintEntity sprint) onSprintTap;
  final VoidCallback onAddSprintTap;

  @override
  State<SprintGanttTimeline> createState() => _SprintGanttTimelineState();
}

class _SprintGanttTimelineState extends State<SprintGanttTimeline> {
  List<SprintEntity> _sprints = [];
  bool _isLoading = true;
  String? _error;
  final ScrollController _headerScrollController = ScrollController();
  final List<ScrollController> _rowScrollControllers = [];
  bool _hasScrolledToToday = false;
  bool _isJumpingToToday = false;

  @override
  void initState() {
    super.initState();
    _loadSprints();
  }

  @override
  void dispose() {
    _headerScrollController.dispose();
    for (final controller in _rowScrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _ensureRowControllers(int count) {
    // Add controllers if we need more
    while (_rowScrollControllers.length < count) {
      _rowScrollControllers.add(ScrollController());
    }
    // Remove controllers if we have too many
    while (_rowScrollControllers.length > count) {
      _rowScrollControllers.removeLast().dispose();
    }
  }

  void _onScroll(double offset) {
    // Sync header
    if (_headerScrollController.hasClients) {
      _headerScrollController.jumpTo(offset);
    }
    
    // Sync all rows
    for (final controller in _rowScrollControllers) {
      if (controller.hasClients) {
        controller.jumpTo(offset);
      }
    }
  }

  Future<void> _loadSprints() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await sl<GetSprints>()(GetSprintsParams(projectId: widget.project.id ?? ''));
    result.fold(
      (failure) {
        setState(() {
          _error = failure.message;
          _isLoading = false;
        });
      },
      (sprints) {
        setState(() {
          _sprints = sprints;
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const Gap(16),
            Text(_error!, style: GoogleFonts.inter(color: Colors.red)),
            const Gap(16),
            ElevatedButton(
              onPressed: _loadSprints,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Ensure we have the right number of scroll controllers
    _ensureRowControllers(_sprints.length);
    
    return _buildTimelineView(isDark);
  }
  
  @override
  void didUpdateWidget(SprintGanttTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset scroll flag when widget updates (e.g., switching views)
    _hasScrolledToToday = false;
  }

  Widget _buildTimelineView(bool isDark) {
    // Infinite timeline: Always centered on today
    final dayWidth = 30.0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Always start timeline 1 year before today, end 1 year after
    DateTime startDate = DateTime(now.year - 1, now.month, 1);
    DateTime endDate = DateTime(now.year + 1, now.month + 1, 0);
    
    // Expand range if sprints exist outside this range
    if (_sprints.isNotEmpty) {
      final allDates = _sprints.expand((s) => [s.startDate, s.endDate]).toList();
      final earliestSprint = allDates.reduce((a, b) => a.isBefore(b) ? a : b);
      final latestSprint = allDates.reduce((a, b) => a.isAfter(b) ? a : b);
      
      // Extend range to include all sprints with 1 month padding
      if (earliestSprint.isBefore(startDate)) {
        startDate = DateTime(earliestSprint.year, earliestSprint.month - 1, 1);
      }
      if (latestSprint.isAfter(endDate)) {
        endDate = DateTime(latestSprint.year, latestSprint.month + 2, 0);
      }
    }
    
    // Calculate today's position in the timeline
    final todayOffset = today.difference(startDate).inDays;
    final todayPosition = todayOffset * dayWidth;
    
    print('🔍 [Timeline] Today: $today');
    print('🔍 [Timeline] Start: $startDate, End: $endDate');
    print('🔍 [Timeline] Today offset: $todayOffset days, Position: $todayPosition px');
    
    // Auto-scroll to today on every view
    if (!_hasScrolledToToday && !_isJumpingToToday) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _isJumpingToToday) return;
        
        // Wait for layout to complete
        Future.delayed(const Duration(milliseconds: 200), () async {
          if (!_headerScrollController.hasClients || !mounted || _isJumpingToToday) return;
          
          setState(() {
            _hasScrolledToToday = true;
            _isJumpingToToday = true;
          });
          
          try {
            // Calculate target scroll to center today in viewport
            final viewportWidth = MediaQuery.of(context).size.width - 200;
            final idealScroll = todayPosition - (viewportWidth / 2);
            
            // Clamp to valid scroll range
            final maxScroll = _headerScrollController.position.maxScrollExtent;
            final targetScroll = idealScroll.clamp(0.0, maxScroll);
            
            print('🔍 [Timeline] Viewport: $viewportWidth, Target scroll: $targetScroll');
            
            // Jump directly to today (no animation on first load for accuracy)
            _headerScrollController.jumpTo(targetScroll);
            
            // Sync all row controllers
            for (final controller in _rowScrollControllers) {
              if (controller.hasClients) {
                controller.jumpTo(targetScroll);
              }
            }
          } finally {
            if (mounted) {
              // Small delay before allowing another scroll
              await Future.delayed(const Duration(milliseconds: 100));
              if (mounted) {
                setState(() => _isJumpingToToday = false);
              }
            }
          }
        });
      });
    }
    
    // Generate months for header and calculate total width
    final months = <DateTime>[];
    var currentMonth = DateTime(startDate.year, startDate.month, 1);
    double totalWidth = 0.0;
    
    while (currentMonth.isBefore(endDate) || currentMonth.month == endDate.month) {
      months.add(currentMonth);
      final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
      totalWidth += daysInMonth * dayWidth;
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    }
    
    final totalDays = endDate.difference(startDate).inDays;

    return Column(
      children: [
        // Month Headers
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          child: Row(
            children: [
              // Sprint names column
              Container(
                width: 200,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sprints',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
              // Timeline header
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification && _headerScrollController.hasClients) {
                      _onScroll(_headerScrollController.offset);
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _headerScrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                  child: SizedBox(
                    width: totalWidth,
                    height: 50,
                    child: Stack(
                      children: [
                        // Month labels
                        Row(
                          children: months.map((month) {
                            final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
                            final monthWidth = daysInMonth * dayWidth;
                            
                            return Container(
                              width: monthWidth,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${_getMonthName(month.month)} ${month.year}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                  ),
              ),
            ],
          ),
        ),
        // Sprint Rows with Today indicator
        Expanded(
          child: Stack(
            children: [
              // Sprint rows (always show 10 rows, empty or filled)
              ListView.builder(
                itemCount: 10, // Always show 10 rows
                itemBuilder: (context, index) {
                  // Show sprint if exists at this index
                  if (index < _sprints.length) {
                    final sprint = _sprints[index];
                    return _buildSprintRow(
                      sprint, 
                      startDate, 
                      totalDays, 
                      totalWidth, 
                      _rowScrollControllers[index],
                      isDark,
                    );
                  } 
                  // Show "Add Sprint" button after last sprint
                  else if (index == _sprints.length) {
                    return _buildAddSprintRow(totalWidth, isDark);
                  }
                  // Show empty row
                  else {
                    return _buildEmptyRow(totalWidth, isDark);
                  }
                },
              ),
              // Today indicator - uses AnimatedBuilder to follow scroll
              if (todayOffset >= 0 && todayOffset <= totalDays)
                AnimatedBuilder(
                  animation: _headerScrollController,
                  builder: (context, child) {
                    final scrollOffset = _headerScrollController.hasClients 
                        ? _headerScrollController.offset 
                        : 0.0;
                    final indicatorPosition = 200 + todayPosition - scrollOffset - 12;
                    
                    // Only show if within visible area
                    if (indicatorPosition < 200 - 50 || indicatorPosition > MediaQuery.of(context).size.width) {
                      return const SizedBox.shrink();
                    }
                    
                    return Positioned(
                      left: indicatorPosition,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Column(
                          children: [
                            // Circle at top
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.today,
                                  size: 14,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ),
                            // Vertical line (centered under the circle)
                            Expanded(
                              child: Container(
                                width: 2,
                                margin: const EdgeInsets.only(left: 11),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white,
                                      Colors.white.withOpacity(0.3),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddSprintRow(double totalWidth, bool isDark) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          // Add Sprint button
          Container(
            width: 200,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(
                right: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: InkWell(
              onTap: widget.onAddSprintTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add,
                      size: 18,
                      color: Color(0xFF6366F1),
                    ),
                    const Gap(6),
                    Text(
                      'Add Sprint',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Empty timeline
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRow(double totalWidth, bool isDark) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          // Empty sprint name area
          Container(
            width: 200,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(
                right: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
          ),
          // Empty timeline
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSprintRow(
    SprintEntity sprint, 
    DateTime timelineStart, 
    int totalDays, 
    double totalWidth,
    ScrollController rowScrollController,
    bool isDark,
  ) {
    final sprintStart = sprint.startDate;
    final sprintEnd = sprint.endDate;
    final sprintDays = sprintEnd.difference(sprintStart).inDays + 1;
    
    // Calculate position
    final startOffset = sprintStart.difference(timelineStart).inDays;
    final dayWidth = 30.0;
    
    final leftPosition = startOffset * dayWidth;
    final barWidth = sprintDays * dayWidth;
    
    // Get color based on status
    final barColor = _getSprintColor(sprint.status);
    
    return Container(
      height: 80,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          // Sprint name
          Container(
            width: 200,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(
                right: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: barColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        sprint.name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Gap(4),
                Text(
                  _getStatusText(sprint.status),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: barColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Timeline with sprint bar (scrollable)
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification && rowScrollController.hasClients) {
                  _onScroll(rowScrollController.offset);
                }
                return false;
              },
              child: SingleChildScrollView(
                controller: rowScrollController,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(), // Smooth scrolling
              child: SizedBox(
                width: totalWidth,
                height: 80,
                child: Stack(
                  children: [
                    // Background grid
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _TimelineGridPainter(
                          isDark: isDark,
                          dayWidth: dayWidth,
                          totalDays: totalDays,
                        ),
                      ),
                    ),
                    // Sprint bar (candle)
                    Positioned(
                      left: leftPosition,
                      top: 20,
                      child: InkWell(
                        onTap: () => widget.onSprintTap(sprint),
                        child: Container(
                          width: barWidth,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                barColor,
                                barColor.withOpacity(0.7),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: barColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: barColor,
                              width: 2,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Center(
                              child: Text(
                                sprint.name,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Progress indicator for active sprints
                    if (sprint.status == SprintStatus.active && sprint.totalStoryPoints > 0)
                      Positioned(
                        left: leftPosition,
                        top: 62,
                        child: Container(
                          width: barWidth,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: sprint.progressPercentage / 100,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
              ),
          ),
        ],
      ),
    );
  }

  Color _getSprintColor(SprintStatus status) {
    switch (status) {
      case SprintStatus.planning:
        return const Color(0xFF3B82F6); // Blue for planning/not started
      case SprintStatus.active:
        return const Color(0xFFEC4899); // Pink for active/started
      case SprintStatus.completed:
        return const Color(0xFF10B981); // Green for completed
      case SprintStatus.cancelled:
        return const Color(0xFFEF4444); // Red for cancelled
    }
  }

  String _getStatusText(SprintStatus status) {
    switch (status) {
      case SprintStatus.planning:
        return 'PLANNING';
      case SprintStatus.active:
        return 'ACTIVE';
      case SprintStatus.completed:
        return 'COMPLETED';
      case SprintStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}

/// Custom painter for timeline grid
class _TimelineGridPainter extends CustomPainter {
  final bool isDark;
  final double dayWidth;
  final int totalDays;

  _TimelineGridPainter({
    required this.isDark,
    required this.dayWidth,
    required this.totalDays,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)).withOpacity(0.3)
      ..strokeWidth = 1.0;

    // Draw vertical lines for each week
    for (int i = 0; i <= totalDays; i += 7) {
      final x = i * dayWidth;
      if (x <= size.width) {
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height),
          linePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineGridPainter oldDelegate) {
    return oldDelegate.totalDays != totalDays;
  }
}

