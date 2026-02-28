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
        return 'Too many attempts. Please wait a minute and try again.';
      }

      // Invalid login credentials
      if (code == '401' ||
          msg.contains('invalid login credentials') ||
          msg.contains('access withheld') ||
          msg.contains('wrong password') ||
          msg.contains('authentication failed')) {
        return 'Invalid email or password. Please try again.';
      }

      // Email already registered
      if (msg.contains('already registered') ||
          msg.contains('already exists') ||
          msg.contains('user already registered')) {
        return 'This email is already registered. Try signing in instead.';
      }

      // Invalid email
      if (msg.contains('invalid email') || msg.contains('email format')) {
        return 'Please enter a valid email address.';
      }

      // Weak password / policy
      if (msg.contains('password') &&
          (msg.contains('weak') || msg.contains('policy'))) {
        return 'Password is too weak. Use at least 8 characters with numbers.';
      }

      // User not found
      if (msg.contains('user not found') ||
          msg.contains('no user') ||
          msg.contains('does not exist')) {
        return 'No account found with this email. Please sign up instead.';
      }

      // Network errors
      if (msg.contains('network') ||
          msg.contains('connection') ||
          msg.contains('timeout')) {
        return 'Network error. Please check your connection and try again.';
      }

      // Default fallback for auth errors
      return 'Authentication failed. Please try again.';
    }

    // Anything else
    return 'Something went wrong. Please try again.';
  }
}
