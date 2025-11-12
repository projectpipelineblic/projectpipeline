import 'package:flutter/material.dart';
import 'package:project_pipeline/core/di/service_locator.dart';
import 'package:project_pipeline/core/theme/app_pallete.dart';
import 'package:project_pipeline/features/projects/domain/entities/project_entity.dart';
import 'package:project_pipeline/features/projects/domain/entities/sprint_entity.dart';
import 'package:project_pipeline/features/projects/domain/usecases/get_sprints_usecase.dart' show GetSprints, GetSprintsParams;

/// Mobile Sprint Gantt Timeline - Horizontal scrolling timeline for sprints
class MobileSprintGanttTimeline extends StatefulWidget {
  const MobileSprintGanttTimeline({
    super.key,
    required this.project,
    required this.onSprintTap,
  });

  final ProjectEntity project;
  final void Function(SprintEntity sprint) onSprintTap;

  @override
  State<MobileSprintGanttTimeline> createState() => _MobileSprintGanttTimelineState();
}

class _MobileSprintGanttTimelineState extends State<MobileSprintGanttTimeline> {
  List<SprintEntity> _sprints = [];
  bool _isLoading = true;
  String? _error;
  final ScrollController _headerScrollController = ScrollController();
  final List<ScrollController> _rowScrollControllers = [];
  bool _hasScrolledToToday = false;

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
    while (_rowScrollControllers.length < count) {
      _rowScrollControllers.add(ScrollController());
    }
    while (_rowScrollControllers.length > count) {
      _rowScrollControllers.removeLast().dispose();
    }
  }

  void _onScroll(double offset) {
    if (_headerScrollController.hasClients) {
      _headerScrollController.jumpTo(offset);
    }
    
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadSprints,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPallete.primary,
                  foregroundColor: AppPallete.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_sprints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline_outlined,
              size: 80,
              color: isDark ? const Color(0xFF4B5563) : AppPallete.textGray.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No sprints yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF9CA3AF) : AppPallete.textGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create sprints to see them here',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFF6B7280) : AppPallete.textGray.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    _ensureRowControllers(_sprints.length);
    return _buildTimelineView(isDark);
  }

  Widget _buildTimelineView(bool isDark) {
    final dayWidth = 25.0; // Smaller for mobile
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Timeline range
    DateTime startDate = DateTime(now.year - 1, now.month, 1);
    DateTime endDate = DateTime(now.year + 1, now.month + 1, 0);
    
    if (_sprints.isNotEmpty) {
      final allDates = _sprints.expand((s) => [s.startDate, s.endDate]).toList();
      final earliestSprint = allDates.reduce((a, b) => a.isBefore(b) ? a : b);
      final latestSprint = allDates.reduce((a, b) => a.isAfter(b) ? a : b);
      
      if (earliestSprint.isBefore(startDate)) {
        startDate = DateTime(earliestSprint.year, earliestSprint.month - 1, 1);
      }
      if (latestSprint.isAfter(endDate)) {
        endDate = DateTime(latestSprint.year, latestSprint.month + 2, 0);
      }
    }
    
    final todayOffset = today.difference(startDate).inDays;
    final todayPosition = todayOffset * dayWidth;
    
    // Auto-scroll to today
    if (!_hasScrolledToToday) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!_headerScrollController.hasClients || !mounted) return;
          
          setState(() => _hasScrolledToToday = true);
          
          final viewportWidth = MediaQuery.of(context).size.width - 120;
          final idealScroll = todayPosition - (viewportWidth / 2);
          final maxScroll = _headerScrollController.position.maxScrollExtent;
          final targetScroll = idealScroll.clamp(0.0, maxScroll);
          
          _headerScrollController.jumpTo(targetScroll);
          
          for (final controller in _rowScrollControllers) {
            if (controller.hasClients) {
              controller.jumpTo(targetScroll);
            }
          }
        });
      });
    }
    
    // Generate months
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
            color: isDark ? const Color(0xFF1E1E1E) : AppPallete.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF2D2D2D) : AppPallete.borderGray,
              ),
            ),
          ),
          child: Row(
            children: [
              // Sprint column header
              Container(
                width: 120,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sprints',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFE5E7EB) : AppPallete.secondary,
                  ),
                ),
              ),
              // Month headers
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
                      child: Row(
                        children: months.map((month) {
                          final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
                          final monthWidth = daysInMonth * dayWidth;
                          
                          return Container(
                            width: monthWidth,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.centerLeft,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getMonthName(month.month),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFFE5E7EB) : AppPallete.secondary,
                                  ),
                                ),
                                Text(
                                  '${month.year}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark ? const Color(0xFF9CA3AF) : AppPallete.textGray,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Sprint Rows
        Expanded(
          child: Stack(
            children: [
              ListView.builder(
                itemCount: _sprints.length,
                itemBuilder: (context, index) {
                  final sprint = _sprints[index];
                  return _buildSprintRow(
                    sprint,
                    startDate,
                    totalDays,
                    totalWidth,
                    _rowScrollControllers[index],
                    isDark,
                    dayWidth,
                  );
                },
              ),
              // Today indicator
              if (todayOffset >= 0 && todayOffset <= totalDays)
                AnimatedBuilder(
                  animation: _headerScrollController,
                  builder: (context, child) {
                    final scrollOffset = _headerScrollController.hasClients 
                        ? _headerScrollController.offset 
                        : 0.0;
                    final indicatorPosition = 120 + todayPosition - scrollOffset - 1;
                    
                    if (indicatorPosition < 120 - 20 || indicatorPosition > MediaQuery.of(context).size.width) {
                      return const SizedBox.shrink();
                    }
                    
                    return Positioned(
                      left: indicatorPosition,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Column(
                          children: [
                            // Today indicator dot
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppPallete.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppPallete.primary.withOpacity(0.3),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.today,
                                  size: 10,
                                  color: AppPallete.white,
                                ),
                              ),
                            ),
                            // Vertical line
                            Expanded(
                              child: Container(
                                width: 2,
                                color: AppPallete.primary.withOpacity(0.5),
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

  Widget _buildSprintRow(
    SprintEntity sprint,
    DateTime timelineStart,
    int totalDays,
    double totalWidth,
    ScrollController rowScrollController,
    bool isDark,
    double dayWidth,
  ) {
    final sprintStart = sprint.startDate;
    final sprintEnd = sprint.endDate;
    final sprintDays = sprintEnd.difference(sprintStart).inDays + 1;
    
    final startOffset = sprintStart.difference(timelineStart).inDays;
    final leftPosition = startOffset * dayWidth;
    final barWidth = sprintDays * dayWidth;
    
    final barColor = _getSprintColor(sprint.status);
    
    return Container(
      height: 70,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2D2D2D) : AppPallete.borderGray,
          ),
        ),
      ),
      child: Row(
        children: [
          // Sprint name
          Container(
            width: 120,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : AppPallete.white,
              border: Border(
                right: BorderSide(
                  color: isDark ? const Color(0xFF2D2D2D) : AppPallete.borderGray,
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
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: barColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        sprint.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFE5E7EB) : AppPallete.secondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusText(sprint.status),
                  style: TextStyle(
                    fontSize: 10,
                    color: barColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Timeline
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
                physics: const ClampingScrollPhysics(),
                child: SizedBox(
                  width: totalWidth,
                  height: 70,
                  child: Stack(
                    children: [
                      // Background grid
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _MobileTimelineGridPainter(
                            isDark: isDark,
                            dayWidth: dayWidth,
                            totalDays: totalDays,
                          ),
                        ),
                      ),
                      // Sprint bar
                      Positioned(
                        left: leftPosition,
                        top: 15,
                        child: InkWell(
                          onTap: () => widget.onSprintTap(sprint),
                          child: Container(
                            width: barWidth,
                            height: 35,
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
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Center(
                                child: Text(
                                  sprint.name,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppPallete.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Progress indicator
                      if (sprint.status == SprintStatus.active && sprint.totalStoryPoints > 0)
                        Positioned(
                          left: leftPosition,
                          top: 52,
                          child: Container(
                            width: barWidth,
                            height: 3,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF374151) : AppPallete.borderGray,
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
        return const Color(0xFF3B82F6);
      case SprintStatus.active:
        return const Color(0xFFEC4899);
      case SprintStatus.completed:
        return const Color(0xFF10B981);
      case SprintStatus.cancelled:
        return const Color(0xFFEF4444);
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

/// Custom painter for mobile timeline grid
class _MobileTimelineGridPainter extends CustomPainter {
  final bool isDark;
  final double dayWidth;
  final int totalDays;

  _MobileTimelineGridPainter({
    required this.isDark,
    required this.dayWidth,
    required this.totalDays,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = (isDark ? const Color(0xFF374151) : AppPallete.borderGray).withOpacity(0.3)
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
  bool shouldRepaint(covariant _MobileTimelineGridPainter oldDelegate) {
    return oldDelegate.totalDays != totalDays;
  }
}

