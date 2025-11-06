import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WebTasksBoardPage extends StatelessWidget {
  const WebTasksBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tasks Board',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'View and manage all your tasks',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 32),
          // TODO: Implement tasks board with kanban view
          Center(
            child: Text(
              'Tasks board coming soon...',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

