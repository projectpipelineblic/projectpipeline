import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_pipeline/core/services/connectivity_service.dart';
import 'package:project_pipeline/core/widgets/primart_text.dart';
import 'package:project_pipeline/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:project_pipeline/features/auth/presentation/pages/login_page.dart';
import 'package:project_pipeline/features/home/presentation/pages/home_page.dart';


class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      // Initialize connectivity service
      await _connectivityService.initialize();
      
      // Trigger auth status check through BLoC
      if (mounted) {
        context.read<AuthBloc>().add(CheckAuthStatusRequested());
      }
    } catch (e) {
      print('Error initializing auth: $e');
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated || state is AuthOffline || state is AuthSuccess) {
          setState(() {
            _isLoggedIn = true;
            _isLoading = false;
          });
        } else if (state is AuthUnauthenticated) {
          setState(() {
            _isLoggedIn = false;
            _isLoading = false;
          });
        }
      },
      child: _isLoading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : StreamBuilder<bool>(
              stream: _connectivityService.connectivityStream,
              builder: (context, snapshot) {
                final isConnected = snapshot.data ?? true;
                
                return Column(
                  children: [
                    // Connectivity status bar
                    if (!isConnected)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        color: Colors.orange,
                        child: Row(
                          children: [
                            const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            PrimaryText(
                              text: 'You are offline',
                              size: 14,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    
                    // Main content
                    Expanded(
                      child: _isLoggedIn ? const HomePage() : const LoginPage(),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
