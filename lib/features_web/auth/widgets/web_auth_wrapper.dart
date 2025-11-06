import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_pipeline/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:project_pipeline/features_web/auth/pages/web_login_page.dart';
import 'package:project_pipeline/features_web/home/pages/web_home_page.dart';

class WebAuthWrapper extends StatefulWidget {
  const WebAuthWrapper({super.key});

  @override
  State<WebAuthWrapper> createState() => _WebAuthWrapperState();
}

class _WebAuthWrapperState extends State<WebAuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Check auth status on mount - will load from cache if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthBloc>().add(CheckAuthStatusRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        print('🔐 Web Auth State: ${state.runtimeType}');
        
        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (state is AuthSuccess || state is AuthAuthenticated) {
          print('✅ User authenticated, showing WebHomePage');
          return const WebHomePage();
        } else if (state is AuthOffline) {
          print('📡 Offline mode, showing WebHomePage');
          return const WebHomePage();
        } else if (state is AuthUnauthenticated) {
          print('❌ Not authenticated, showing WebLoginPage');
          return const WebLoginPage();
        } else {
          print('⚠️ Unknown auth state: ${state.runtimeType}, showing WebLoginPage');
          return const WebLoginPage();
        }
      },
    );
  }
}

