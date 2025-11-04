import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_app/core/theme/theme_cubit.dart';
import 'package:task_app/core/utils/app_snackbar.dart';
import 'package:task_app/features/auth/presentation/bloc/auth_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _showChangeUsernameBottomSheet(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    String? currentUsername;
    String? userId;

    if (authState is AuthAuthenticated) {
      currentUsername = authState.user.userName;
      userId = authState.user.uid;
    } else if (authState is AuthOffline) {
      currentUsername = authState.user.userName;
      userId = authState.user.uid;
    } else if (authState is AuthSuccess) {
      currentUsername = authState.user.userName;
      userId = authState.user.uid;
    }

    if (userId == null) {
      AppSnackBar.showError(context, 'User not found');
      return;
    }

    // Capture userId as non-nullable for use in closure
    final String userIdNonNull = userId;
    final TextEditingController controller = TextEditingController(text: currentUsername);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Change Username',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFFE5E7EB)
                            : const Color(0xFF1F2937),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Current username: $currentUsername',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This will update your username everywhere including projects, tasks, and team invites.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'New Username',
                    hintText: 'Enter new username',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username cannot be empty';
                    }
                    if (value.trim().length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: BlocConsumer<AuthBloc, AuthState>(
                    listener: (context, state) {
                      if (state is UsernameUpdated) {
                        Navigator.pop(sheetContext);
                        AppSnackBar.showSuccess(context, 'Username updated successfully');
                      } else if (state is UsernameUpdateError) {
                        AppSnackBar.showError(context, state.message);
                      }
                    },
                    builder: (context, state) {
                      final isLoading = state is UsernameUpdating;
                      return ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                if (formKey.currentState!.validate()) {
                                  final newUsername = controller.text.trim();
                                  if (newUsername == currentUsername) {
                                    AppSnackBar.showError(context, 'Username is the same');
                                    return;
                                  }
                                  context.read<AuthBloc>().add(
                                        UpdateUsernameRequested(
                                          uid: userIdNonNull,
                                          newUsername: newUsername,
                                        ),
                                      );
                                }
                              },
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Update Username'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Change Username'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showChangeUsernameBottomSheet(context),
              ),
              const Divider(),
              CheckboxListTile(
                title: const Text('Use device color mode'),
                value: state.useSystemTheme,
                onChanged: (val) => context.read<ThemeCubit>().setUseSystemTheme(val ?? true),
              ),
              const SizedBox(height: 8),
              IgnorePointer(
                ignoring: state.useSystemTheme,
                child: Opacity(
                  opacity: state.useSystemTheme ? 0.5 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Appearance',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      RadioListTile<ThemeMode>(
                        title: const Text('Light'),
                        value: ThemeMode.light,
                        groupValue: state.themeMode,
                        onChanged: state.useSystemTheme 
                            ? null 
                            : (val) {
                                if (val != null) {
                                  context.read<ThemeCubit>().setThemeMode(val);
                                }
                              },
                      ),
                      RadioListTile<ThemeMode>(
                        title: const Text('Dark'),
                        value: ThemeMode.dark,
                        groupValue: state.themeMode,
                        onChanged: state.useSystemTheme 
                            ? null 
                            : (val) {
                                if (val != null) {
                                  context.read<ThemeCubit>().setThemeMode(val);
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


