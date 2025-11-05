import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_pipeline/core/services/local_storage_service.dart';

class ThemeState extends Equatable {
  final ThemeMode themeMode;
  final bool useSystemTheme;

  const ThemeState({
    required this.themeMode,
    required this.useSystemTheme,
  });

  ThemeState copyWith({ThemeMode? themeMode, bool? useSystemTheme}) => ThemeState(
        themeMode: themeMode ?? this.themeMode,
        useSystemTheme: useSystemTheme ?? this.useSystemTheme,
      );

  @override
  List<Object?> get props => [themeMode, useSystemTheme];
}

class ThemeCubit extends Cubit<ThemeState> {
  final LocalStorageService _localStorageService;

  ThemeCubit({required LocalStorageService localStorageService})
      : _localStorageService = localStorageService,
        super(const ThemeState(themeMode: ThemeMode.system, useSystemTheme: true)) {
    _load();
  }

  Future<void> _load() async {
    final useSystem = await _localStorageService.getUseSystemTheme();
    final mode = await _localStorageService.getThemeMode();
    emit(ThemeState(themeMode: mode, useSystemTheme: useSystem));
  }

  Future<void> setUseSystemTheme(bool value) async {
    await _localStorageService.setUseSystemTheme(value);
    if (value) {
      await _localStorageService.setThemeMode(ThemeMode.system);
      emit(state.copyWith(useSystemTheme: true, themeMode: ThemeMode.system));
    } else {
      emit(state.copyWith(useSystemTheme: false));
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _localStorageService.setThemeMode(mode);
    emit(state.copyWith(themeMode: mode));
  }
}


