import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:project_pipeline/core/routes/platform_routes.dart';
import 'package:project_pipeline/core/routes/routes.dart';
import 'package:project_pipeline/core/utils/app_snackbar.dart';
import 'package:project_pipeline/core/widgets/primart_text.dart';
import 'package:project_pipeline/core/validator/validator.dart';
import 'package:project_pipeline/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:project_pipeline/features/auth/presentation/widgets/auth_button.dart';
import 'package:project_pipeline/features/auth/presentation/widgets/auth_logo.dart';
import 'package:project_pipeline/features/auth/presentation/widgets/auth_rich_text.dart';
import 'package:project_pipeline/features/auth/presentation/widgets/auth_textfield.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  String? _validateName(String? value) => AppValidators.name(value);
  String? _validateEmail(String? value) => AppValidators.email(value);
  String? _validatePassword(String? value) => AppValidators.password(value);
  String? _validateConfirmPassword(String? value) => AppValidators.confirmPassword(value, _passwordController.text);

  void _handleSignup() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        SignUpRequested(
          userName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        ),
      );
    }
  }

  void _navigateToSignin() {
    Navigator.pushNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          AppSnackBar.showSuccess(context, 'Account created successfully!');
          Navigator.pushNamedAndRemoveUntil(
            context, 
            PlatformRoutes.home, // Platform-aware: /home (mobile) or /web-home (web)
            (route) => false,
          );
        } else if (state is AuthError) {
          AppSnackBar.showError(context, state.message);
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
                SizedBox(height: 30.h),
                // PrimaryText(
                //   text: 'Register',
                //   size: 32.sp,
                //   fontWeight: FontWeight.bold,
                //   color: Theme.of(context).colorScheme.secondary,
                // ),
                
                // Logo and App Name
                SizedBox(height: 20.h),
                const AuthLogo(),
                
                
                // Register Title
                
                SizedBox(height: 15.h),
                AuthRichText(
                  firstWord: 'Join',
                  secondWord: 'Plan',
                  thirdWord: 'Grow',
                  fontSize: 25.sp,
                ),
                SizedBox(height: 20.h),
                
                // Name Field
                AuthTextField(
                  hintText: 'Name',
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  validator: _validateName,
                ),
                
                SizedBox(height: 16.h),
                
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
                
                SizedBox(height: 16.h),
                
                // Confirm Password Field
                AuthTextField(
                  hintText: 'Confirm Password',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  validator: _validateConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    onPressed: _toggleConfirmPasswordVisibility,
                  ),
                ),
                
                SizedBox(height: 32.h),
                
                // Register Button
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return AuthButton(
                      text: 'Register',
                      onPressed: state is AuthLoading ? null : _handleSignup,
                      isLoading: state is AuthLoading,
                    );
                  },
                ),
                
                SizedBox(height: 40.h),
                
                // Sign In Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PrimaryText(
                      text: 'Already have an account?',
                      size: 14.sp,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ],
                ),
                
                SizedBox(height: 8.h),
                
                GestureDetector(
                  onTap: _navigateToSignin,
                  child: PrimaryText(
                    text: 'Log in',
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
    ));
  }
}
