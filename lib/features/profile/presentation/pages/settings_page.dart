import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_app/core/theme/theme_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
                      const Text('Appearance'),
                      const SizedBox(height: 8),
                      RadioListTile<ThemeMode>(
                        title: const Text('Light'),
                        value: ThemeMode.light,
                        groupValue: state.themeMode == ThemeMode.system ? ThemeMode.light : state.themeMode,
                        onChanged: (val) => context.read<ThemeCubit>().setThemeMode(ThemeMode.light),
                      ),
                      RadioListTile<ThemeMode>(
                        title: const Text('Dark'),
                        value: ThemeMode.dark,
                        groupValue: state.themeMode == ThemeMode.system ? ThemeMode.dark : state.themeMode,
                        onChanged: (val) => context.read<ThemeCubit>().setThemeMode(ThemeMode.dark),
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


