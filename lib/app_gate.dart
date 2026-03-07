import 'package:flutter/material.dart';
import 'package:pos/features/auth/presentation/sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos/features/onboarding/onboarding.dart';

class AppGate extends StatelessWidget {
  const AppGate({super.key});

  Future<bool> _seenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('seen_onboarding') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _seenOnboarding(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError) {
          return Scaffold(
            body: Center(child: Text('Prefs error: ${snap.error}')),
          );
        }

        final seen = snap.data ?? false;
        return seen ? const SignIn() : const Onboarding();
      },
    );
  }
}
