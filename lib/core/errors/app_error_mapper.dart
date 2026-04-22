import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class AppErrorMapper {
  static String message(Object error) {
    if (error is AuthException) return _mapAuthException(error);
    if (error is PostgrestException) return _mapPostgrestException(error);

    if (error is SocketException) {
      return 'You\'re offline. Changes will sync when you reconnect.';
    }

    final msg = error.toString().toLowerCase();

    if (msg.contains('timeout')) {
      return 'Request timed out. Changes will sync when connection improves.';
    }
    if (msg.contains('network') || msg.contains('connection') || msg.contains('socket')) {
      return 'You\'re offline. Changes will sync when you reconnect.';
    }
    if (msg.contains('permission') || msg.contains('unauthorized') || msg.contains('forbidden')) {
      return 'You don\'t have permission to perform this action.';
    }
    if (msg.contains('not found')) {
      return 'The requested item was not found.';
    }
    if (msg.contains('duplicate') || msg.contains('unique')) {
      return 'This item already exists.';
    }

    if (kDebugMode) return error.toString();
    return 'Something went wrong. Please try again.';
  }

  static String _mapAuthException(AuthException error) {
    final code = error.statusCode;
    final msg = error.message.toLowerCase();

    if (code == '429' ||
        msg.contains('over_email_send_rate_limit') ||
        msg.contains('rate limit') ||
        msg.contains('too many requests')) {
      return 'Too many attempts. Please wait a minute and try again.';
    }
    if (msg.contains('smtp') ||
        msg.contains('mailer') ||
        msg.contains('error sending confirmation email') ||
        msg.contains('error sending magic link') ||
        msg.contains('unable to send email')) {
      return 'Email delivery failed. Please try again later.';
    }
    if (msg.contains('signups not allowed') ||
        msg.contains('signup is disabled') ||
        msg.contains('email signups are disabled')) {
      return 'Account registration is currently unavailable. Please contact support.';
    }
    if (code == '401' ||
        msg.contains('invalid login credentials') ||
        msg.contains('access withheld') ||
        msg.contains('wrong password') ||
        msg.contains('authentication failed')) {
      return 'Invalid email or password. Please try again.';
    }
    if (msg.contains('already registered') ||
        msg.contains('already exists') ||
        msg.contains('user already registered')) {
      return 'This email is already registered. Try signing in instead.';
    }
    if (msg.contains('invalid email') || msg.contains('email format')) {
      return 'Please enter a valid email address.';
    }
    if (msg.contains('otp') ||
        msg.contains('token') ||
        msg.contains('expired') ||
        msg.contains('invalid_grant')) {
      return 'Invalid or expired verification code. Please try again.';
    }
    if (msg.contains('password') &&
        (msg.contains('weak') || msg.contains('policy'))) {
      return 'Password is too weak. Use at least 8 characters with numbers.';
    }
    if (msg.contains('user not found') ||
        msg.contains('no user') ||
        msg.contains('does not exist')) {
      return 'No account found with this email. Please sign up instead.';
    }
    if (msg.contains('network') || msg.contains('connection') || msg.contains('timeout')) {
      return 'You\'re offline. Please reconnect to sign in.';
    }

    if (kDebugMode) return error.message;
    return 'Authentication failed. Please try again.';
  }

  static String _mapPostgrestException(PostgrestException error) {
    final code = error.code ?? '';
    final msg = error.message.toLowerCase();

    if (code == '23505' || msg.contains('duplicate') || msg.contains('unique')) {
      return 'This item already exists.';
    }
    if (code == '23503' || msg.contains('foreign key')) {
      return 'This item is linked to other records and cannot be removed.';
    }
    if (code == '42501' || msg.contains('permission') || msg.contains('policy')) {
      return 'You don\'t have permission to perform this action.';
    }

    if (kDebugMode) return error.message;
    return 'Something went wrong. Please try again.';
  }
}
