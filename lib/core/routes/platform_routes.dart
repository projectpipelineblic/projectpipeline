import 'package:flutter/foundation.dart';
import 'package:project_pipeline/core/routes/routes.dart';

/// Platform-aware routing utility
/// Returns web routes when running on web, mobile routes otherwise
class PlatformRoutes {
  // Check if running on web
  static bool get isWeb => kIsWeb;

  // Auth Routes
  static String get login => isWeb ? AppRoutes.webLogin : AppRoutes.login;
  static String get signup => isWeb ? AppRoutes.webSignup : AppRoutes.signup;
  static String get home => isWeb ? AppRoutes.webHome : AppRoutes.home;
  
  // Settings Routes
  static String get settings => AppRoutes.settings; // Same for both for now
  static String get teamInvites => AppRoutes.teamInvites; // Same for both for now
}

