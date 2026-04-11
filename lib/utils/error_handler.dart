import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

String getAuthErrorMessage(Object e) {
  // No internet / network unreachable
  if (e is SocketException) {
    return 'No internet connection. Please check your network and try again.';
  }

  // Supabase wraps network errors in AuthException sometimes
  if (e is AuthException) {
    final msg = e.message.toLowerCase();

    // Network-related Supabase messages
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection') ||
        msg.contains('unreachable')) {
      return 'No internet connection. Please check your network and try again.';
    }

    // Common auth errors — give friendly messages
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid email or password')) {
      return 'Incorrect email or password.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please verify your email before logging in.';
    }
    if (msg.contains('user already registered')) {
      return 'An account with this email already exists.';
    }
    if (msg.contains('password should be at least')) {
      return 'Password must be at least 6 characters.';
    }

    // Fall back to Supabase's own message, capitalized
    return e.message;
  }

  // Anything else
  return 'Something went wrong. Please try again.';
}