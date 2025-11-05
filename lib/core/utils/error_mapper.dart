String authFriendlyMessage(String raw) {
  final lower = raw.toLowerCase();
  
  // Google Sign-In specific errors
  if (lower.contains('google-signin-canceled') || lower.contains('sign_in_canceled')) {
    return 'Google sign-in was canceled';
  }
  if (lower.contains('network_error') || lower.contains('no_internet')) {
    return 'Please check your internet connection';
  }
  if (lower.contains('sign_in_failed')) {
    return 'Google sign-in failed. Please try again.';
  }
  if (lower.contains('api_not_available')) {
    return 'Google Play Services not available';
  }
  if (lower.contains('developer-error') || lower.contains('developer_error')) {
    return 'Google Sign-In configuration error. Please contact support.';
  }
  
  // Firebase Auth errors
  if (lower.contains('invalid-credential') || lower.contains('wrong-password')) {
    return 'Invalid password';
  }
  if (lower.contains('user-not-found')) {
    return 'No account found for this email';
  }
  if (lower.contains('email-already-in-use')) {
    return 'This email is already registered';
  }
  if (lower.contains('account-exists-with-different-credential')) {
    return 'Email already used with a different sign-in method';
  }
  if (lower.contains('invalid-email')) {
    return 'Enter a valid email address';
  }
  if (lower.contains('network') || lower.contains('unavailable') || lower.contains('timeout')) {
    return 'Please check your internet connection';
  }
  
  // Log the raw error for debugging
  print('⚠️ [Error Mapper] Unmapped error: $raw');
  return 'Something went wrong. Please try again.';
}


