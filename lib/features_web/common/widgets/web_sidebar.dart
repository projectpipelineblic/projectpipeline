import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_pipeline/core/theme/theme_cubit.dart';
import 'package:sidebarx/sidebarx.dart';

class WebSidebar extends StatelessWidget {
  final SidebarXController controller;

  const WebSidebar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SidebarX(
      controller: controller,
      theme: SidebarXTheme(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark 
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        hoverColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        itemTextPadding: const EdgeInsets.only(left: 20),
        selectedItemTextPadding: const EdgeInsets.only(left: 20),
        itemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.transparent),
        ),
        selectedItemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF6366F1).withOpacity(0.2),
          ),
          color: isDark 
            ? const Color(0xFF6366F1).withOpacity(0.2)
            : const Color(0xFFEEF2FF),
        ),
        iconTheme: IconThemeData(
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          size: 22,
        ),
        selectedIconTheme: const IconThemeData(
          color: Color(0xFF6366F1),
          size: 22,
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
        ),
        selectedTextStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6366F1),
        ),
      ),
      extendedTheme: const SidebarXTheme(
        width: 240,
        decoration: BoxDecoration(
          color: Colors.transparent,
        ),
      ),
      headerBuilder: (context, extended) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              // Logo and title - responsive to collapsed state
              if (extended)
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Logo with white check
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                          Text(
                            'Pipeline',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              if (extended) ...[
                const Gap(16),
                Divider(
                  thickness: 1,
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                const Gap(12),
                // Theme Toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ThemeToggleButton(
                        icon: Icons.light_mode_outlined,
                        label: 'Light',
                        isSelected: !isDark,
                        onTap: () {
                          context.read<ThemeCubit>().setThemeMode(ThemeMode.light);
                        },
                      ),
                      _ThemeToggleButton(
                        icon: Icons.dark_mode_outlined,
                        label: 'Dark',
                        isSelected: isDark,
                        onTap: () {
                          context.read<ThemeCubit>().setThemeMode(ThemeMode.dark);
                        },
                      ),
                    ],
                  ),
                ),
                const Gap(12),
                Divider(
                  thickness: 1,
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ],
            ],
          ),
        );
      },
      items: [
        SidebarXItem(
          icon: Icons.dashboard_outlined,
          label: 'Dashboard',
          onTap: () {},
        ),
        SidebarXItem(
          icon: Icons.folder_outlined,
          label: 'Projects',
          onTap: () {},
        ),
        SidebarXItem(
          icon: Icons.task_alt_outlined,
          label: 'Tasks Board',
          onTap: () {},
        ),
        SidebarXItem(
          icon: Icons.mail_outline,
          label: 'Invitations',
          onTap: () {},
        ),
        SidebarXItem(
          icon: Icons.person_outline,
          label: 'Profile',
          onTap: () {},
        ),
      ],
      footerDivider: Divider(
        thickness: 1,
        indent: 16,
        endIndent: 16,
        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
      ),
    );
  }
}

// Theme Toggle Button Widget
class _ThemeToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeToggleButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
              ? const Color(0xFF6366F1)
              : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected 
                  ? Colors.white
                  : const Color(0xFF94A3B8),
              ),
              const Gap(4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected 
                    ? Colors.white
                    : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

