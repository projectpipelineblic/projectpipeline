String authFriendlyMessage(String raw) {
  final lower = raw.toLowerCase();
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
  return 'Something went wrong. Please try again.';
}


