import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_pipeline/features/auth/domain/entities/user_entity.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const String _userKey = 'cached_user';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _themeModeKey = 'theme_mode'; // system, light, dark
  static const String _useSystemThemeKey = 'use_system_theme';

  Future<void> cacheUser(UserEntity user) async {
    print('💾 [LocalStorage] Caching user: ${user.userName}');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setBool(_isLoggedInKey, true);
    print('✅ [LocalStorage] User cached successfully');
  }

  Future<UserEntity?> getCachedUser() async {
    print('🔍 [LocalStorage] Getting cached user...');
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    print('🔍 [LocalStorage] userJson exists: ${userJson != null}');
    
    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        final user = UserEntity.fromJson(userMap);
        print('✅ [LocalStorage] User retrieved: ${user.userName}');
        return user;
      } catch (e) {
        print('❌ [LocalStorage] Error parsing cached user: $e');
        return null;
      }
    }
    print('❌ [LocalStorage] No cached user found');
    return null;
  }

  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    print('🔍 [LocalStorage] isUserLoggedIn: $isLoggedIn');
    return isLoggedIn;
  }

  Future<void> clearUserCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_isLoggedInKey);
  }

  Future<void> logout() async {
    await clearUserCache();
  }

  // ===== Theme Preferences =====
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      _ => 'system',
    });
  }

  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeModeKey) ?? 'system';
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setUseSystemTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useSystemThemeKey, value);
  }

  Future<bool> getUseSystemTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useSystemThemeKey) ?? true;
  }
}
