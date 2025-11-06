import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:project_pipeline/core/di/service_locator.dart';
import 'package:project_pipeline/core/routes/routes.dart';
import 'package:project_pipeline/core/theme/app_theme.dart';
import 'package:project_pipeline/core/theme/theme_cubit.dart';
import 'package:project_pipeline/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:project_pipeline/features/home/presentation/bloc/dashboard_bloc.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_bloc.dart';
import 'package:project_pipeline/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await init(); // Initialize dependency injection
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthBloc>()),
        BlocProvider(create: (_) => sl<ThemeCubit>()),
        BlocProvider(create: (_) => sl<ProjectBloc>()),
        BlocProvider(create: (_) => sl<DashboardBloc>()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Platform detection: Use web UI for web, mobile UI for mobile
    final bool isWeb = kIsWeb;
    final String initialRoute = isWeb ? AppRoutes.webAuthWrapper : AppRoutes.initialRoute;

    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp(
              title: 'Project Pipeline',
              theme: AppTheme.lightModeTheme,
              darkTheme: AppTheme.darkModeTheme,
              themeMode: themeState.themeMode,
              debugShowCheckedModeBanner: false,
              initialRoute: initialRoute,
              routes: AppRoutes.routes,
              onGenerateRoute: AppRoutes.generateRoute,
            );
          },
        );
      },
    );
  }
}
