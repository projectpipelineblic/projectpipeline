import 'package:flutter/material.dart';
import 'package:project_pipeline/features/auth/presentation/pages/login_page.dart';
import 'package:project_pipeline/features/auth/presentation/pages/signup_page.dart';
import 'package:project_pipeline/features/auth/presentation/widgets/auth_wrapper.dart';
import 'package:project_pipeline/features/home/presentation/pages/home_page.dart';
import 'package:project_pipeline/features/profile/presentation/pages/settings_page.dart';
import 'package:project_pipeline/features/profile/presentation/pages/team_invites_page.dart';
import 'package:project_pipeline/features_web/auth/pages/web_login_page.dart';
import 'package:project_pipeline/features_web/auth/pages/web_signup_page.dart';
import 'package:project_pipeline/features_web/auth/widgets/web_auth_wrapper.dart';
import 'package:project_pipeline/features_web/home/pages/web_home_page.dart';

class AppRoutes {
  // Mobile Route names
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String authWrapper = '/auth-wrapper';
  static const String settings = '/settings';
  static const String teamInvites = '/team-invites';
  
  // Web Route names
  static const String webAuthWrapper = '/web-auth-wrapper';
  static const String webLogin = '/web-login';
  static const String webSignup = '/web-signup';
  static const String webHome = '/web-home';

  // Route map
  static Map<String, WidgetBuilder> get routes => {
    // Mobile routes
    login: (context) => const LoginPage(),
    signup: (context) => const SignupPage(),
    home: (context) => const HomePage(),
    authWrapper: (context) => const AuthWrapper(),
    settings: (context) => const SettingsPage(),
    teamInvites: (context) => const TeamInvitesPage(),
    // Web routes
    webAuthWrapper: (context) => const WebAuthWrapper(),
    webLogin: (context) => const WebLoginPage(),
    webSignup: (context) => const WebSignupPage(),
    webHome: (context) => const WebHomePage(),
  };

  // Initial route - use PlatformRoutes.authWrapper for platform-aware routing
  static const String initialRoute = authWrapper;

  // Generate route for named navigation
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (context) => const LoginPage(),
          settings: settings,
        );
      case signup:
        return MaterialPageRoute(
          builder: (context) => const SignupPage(),
          settings: settings,
        );
      case home:
        return MaterialPageRoute(
          builder: (context) => const HomePage(),
          settings: settings,
        );
      case authWrapper:
        return MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
          settings: settings,
        );
      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (context) => const SettingsPage(),
          settings: settings,
        );
      case AppRoutes.teamInvites:
        return MaterialPageRoute(
          builder: (context) => const TeamInvitesPage(),
          settings: settings,
        );
      case AppRoutes.webAuthWrapper:
        return MaterialPageRoute(
          builder: (context) => const WebAuthWrapper(),
          settings: settings,
        );
      case AppRoutes.webLogin:
        return MaterialPageRoute(
          builder: (context) => const WebLoginPage(),
          settings: settings,
        );
      case AppRoutes.webSignup:
        return MaterialPageRoute(
          builder: (context) => const WebSignupPage(),
          settings: settings,
        );
      case AppRoutes.webHome:
        return MaterialPageRoute(
          builder: (context) => const WebHomePage(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
          settings: settings,
        );
    }
  }
}
