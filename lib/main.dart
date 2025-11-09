import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:project_pipeline/core/di/service_locator.dart';
import 'package:project_pipeline/core/routes/routes.dart';
import 'package:project_pipeline/core/services/local_storage_service.dart';
import 'package:project_pipeline/core/theme/app_theme.dart';
import 'package:project_pipeline/core/theme/theme_cubit.dart';
import 'package:project_pipeline/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:project_pipeline/features/home/presentation/bloc/dashboard_bloc.dart';
import 'package:project_pipeline/features/projects/presentation/bloc/project_bloc.dart';
import 'package:project_pipeline/firebase_options.dart';

void main() async {
  // Suppress Flutter web framework bugs (trackpad gestures, diagnostics)
  if (kIsWeb && kDebugMode) {
    // Handle Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      final errorString = details.exception.toString();
      
      // Suppress trackpad gesture assertion error
      if (errorString.contains('PointerDeviceKind.trackpad') ||
          errorString.contains('!identical(kind, PointerDeviceKind.trackpad)')) {
        return; // Ignore this known Flutter web framework bug
      }
      
      // Suppress diagnostics-related errors
      if (errorString.contains('LegacyJavaScriptObject') ||
          errorString.contains('DiagnosticsNode')) {
        return; // Ignore this known Flutter web framework bug
      }
      
      // Log other errors normally
      FlutterError.presentError(details);
    };
    
    // Handle uncaught errors and assertions using Zone
    // IMPORTANT: ensureInitialized and runApp must be in the same zone
    runZonedGuarded(() async {
      WidgetsFlutterBinding.ensureInitialized();
      await _runApp();
    }, (error, stackTrace) {
      final errorString = error.toString();
      
      // Suppress trackpad gesture assertion error
      if (errorString.contains('PointerDeviceKind.trackpad') ||
          errorString.contains('!identical(kind, PointerDeviceKind.trackpad)') ||
          stackTrace.toString().contains('events.dart:1639')) {
        // Ignore this known Flutter web framework bug
        return;
      }
      
      // Suppress diagnostics-related errors
      if (errorString.contains('LegacyJavaScriptObject') ||
          errorString.contains('DiagnosticsNode')) {
        // Ignore this known Flutter web framework bug
        return;
      }
      
      // Log other errors normally
      FlutterError.presentError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
        ),
      );
    });
  } else {
  WidgetsFlutterBinding.ensureInitialized();
    await _runApp();
  }
}

Future<void> _runApp() async {
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Check for existing login on web after app is built
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final authBloc = context.read<AuthBloc>();
        final localStorageService = sl<LocalStorageService>();
        
        // Check if user is cached (already logged in)
        localStorageService.getCachedUser().then((cachedUser) {
          if (cachedUser != null && cachedUser.uid != null && mounted) {
            // User is cached, check auth status
            authBloc.add(CheckAuthStatusRequested());
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Platform detection: Use web UI for web, mobile UI for mobile
    final bool isWeb = kIsWeb;
    final String initialRoute = isWeb ? AppRoutes.webLogin : AppRoutes.initialRoute;

    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            // If user becomes authenticated and we're on login page, navigate to home
            if (kIsWeb && (state is AuthSuccess || state is AuthAuthenticated || state is AuthOffline)) {
              final currentRoute = ModalRoute.of(context)?.settings.name;
              if (currentRoute == AppRoutes.webLogin || currentRoute == AppRoutes.webSignup) {
                _navigatorKey.currentState?.pushReplacementNamed(AppRoutes.webHome);
              }
            }
          },
          child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp(
                navigatorKey: _navigatorKey,
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
          ),
        );
      },
    );
  }
}
