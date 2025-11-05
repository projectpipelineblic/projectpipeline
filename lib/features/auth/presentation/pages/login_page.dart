import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:project_pipeline/core/routes/routes.dart';
import 'package:project_pipeline/core/utils/app_snackbar.dart';
import 'package:project_pipeline/core/widgets/primart_text.dart';
import 'package:project_pipeline/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:project_pipeline/features/auth/presentation/widgets/auth_button.dart';
import 'package:project_pipeline/features/auth/presentation/widgets/auth_divider.dart';
import 'package:project_pipeline/features/auth/presentation/widgets/auth_google.dart';
import 'package:project_pipeline/features/auth/presentation/widgets/auth_logo.dart';
import 'package:project_pipeline/features/auth/presentation/widgets/auth_rich_text.dart';
import 'package:project_pipeline/features/auth/presentation/widgets/auth_textfield.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  String? _lastSnackMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    return null;
  }

  void _handleSignin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        SignInRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        ),
      );
    }
  }

  void _navigateToSignup() {
    Navigator.pushNamed(context, AppRoutes.signup);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous != current,
      listener: (context, state) {
        if (state is AuthSuccess) {
          final message = 'Welcome back, ${state.user.userName}';
          if (_lastSnackMessage != message) {
            _lastSnackMessage = message;
            AppSnackBar.showSuccess(context, message);
          }
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
        } else if (state is AuthError) {
          final message = state.message;
          if (_lastSnackMessage != message) {
            _lastSnackMessage = message;
            AppSnackBar.showError(context, message);
          }
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 50.h),
                  
                  // Logo and App Name
                  const AuthLogo(),
                  
                  SizedBox(height: 20.h),
                  // Sign In Title
                  
                  SizedBox(height: 15.h),
                  AuthRichText(
                    firstWord: 'Plan',
                    secondWord: 'Execute',
                    thirdWord: 'Achieve',
                    fontSize: 25.sp,
                  ),
                  SizedBox(height: 20.h),
                  
                  // Email Field
                  AuthTextField(
                    hintText: 'Email Address',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  // Password Field
                  AuthTextField(
                    hintText: 'Password',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: _validatePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                  ),
                  
                  SizedBox(height: 32.h),
                  
                  // Sign In Button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return AuthButton(
                        text: 'Login',
                        onPressed: state is AuthLoading ? null : _handleSignin,
                        isLoading: state is AuthLoading,
                      );
                    },
                  ),
                  
                  SizedBox(height: 40.h),

                  AuthDivider(),
                  SizedBox(height: 10.h),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return GoogleButton(
                        onTap: state is AuthLoading 
                          ? null 
                          : () {
                              context.read<AuthBloc>().add(GoogleSignInRequested());
                            },
                      );
                    },
                  ),
                  SizedBox(height: 10.h),
                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PrimaryText(
                        text: 'Don\'t have an account?',
                        size: 14.sp,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 8.h),
                  
                  GestureDetector(
                    onTap: _navigateToSignup,
                    child: PrimaryText(
                      text: 'Sign up',
                      size: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
