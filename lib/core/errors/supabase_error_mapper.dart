import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthErrorMapper {
  static String message(Object error) {
    // Supabase auth errors
    if (error is AuthException) {
      final code = error.statusCode; // sometimes null
      final msg = error.message.toLowerCase();

      // Rate limit: email sending
      if (code == '429' ||
          msg.contains('over_email_send_rate_limit') ||
          msg.contains('rate limit') ||
          msg.contains('too many requests')) {
        return 'Too many sign-up attempts. Please wait a minute and try again.';
      }

      // Email already registered
      if (msg.contains('already registered') ||
          msg.contains('already exists') ||
          msg.contains('user already registered')) {
        return 'This email is already registered. Try signing in instead.';
      }

      // Invalid email
      if (msg.contains('invalid email')) {
        return 'Please enter a valid email address.';
      }

      // Weak password / policy
      if (msg.contains('password') &&
          (msg.contains('weak') || msg.contains('policy'))) {
        return 'Password is too weak. Use at least 8 characters with numbers.';
      }

      // Default fallback
      return 'Sign up failed. Please try again.';
    }

    // Anything else
    return 'Something went wrong. Please try again.';
  }
}
