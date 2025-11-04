import 'package:flutter/material.dart';
import 'package:task_app/features/auth/presentation/pages/login_page.dart';
import 'package:task_app/features/auth/presentation/pages/signup_page.dart';
import 'package:task_app/features/auth/presentation/widgets/auth_wrapper.dart';
import 'package:task_app/features/home/presentation/pages/home_page.dart';
import 'package:task_app/features/profile/presentation/pages/settings_page.dart';
import 'package:task_app/features/profile/presentation/pages/team_invites_page.dart';

class AppRoutes {
  // Route names
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String authWrapper = '/auth-wrapper';
  static const String settings = '/settings';
  static const String teamInvites = '/team-invites';

  // Route map
  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const LoginPage(),
    signup: (context) => const SignupPage(),
    home: (context) => const HomePage(),
    authWrapper: (context) => const AuthWrapper(),
    settings: (context) => const SettingsPage(),
    teamInvites: (context) => const TeamInvitesPage(),
  };

  // Initial route
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
      default:
        return MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
          settings: settings,
        );
    }
  }
}
