import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_pipeline/core/theme/app_pallete.dart';
import 'package:project_pipeline/core/widgets/primart_text.dart';
import 'package:project_pipeline/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:project_pipeline/core/routes/routes.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    String username = 'User';
    
    final authState = context.watch<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      username = authState.user.userName;
    } else if (authState is AuthOffline) {
      username = authState.user.userName;
    } else if (authState is AuthSuccess) {
      username = authState.user.userName;
    }

    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: PrimaryText(
          text: 'Profile',
          size: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFE5E7EB)
              : AppPallete.secondary,
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 32),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  child: Text(initial, style: const TextStyle(fontSize: 32)),
                ),
                const SizedBox(height: 12),
                Text(username, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.group_add),
            title: const Text('Team Invites'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.teamInvites),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.settings),
          ),
          const Divider(),
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) => current is AuthUnauthenticated,
            listener: (context, state) {
              if (state is AuthUnauthenticated) {
                // Navigate to login and remove all previous routes
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    Navigator.of(context, rootNavigator: true)
                        .pushNamedAndRemoveUntil(
                      AppRoutes.authWrapper,
                      (route) => false,
                    );
                  }
                });
              }
            },
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          // Dispatch logout event
                          context.read<AuthBloc>().add(SignOutRequested());
                        },
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}


