

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/routes/app_routes.dart';

class FloatingAIAssistantBar extends StatelessWidget {
  const FloatingAIAssistantBar({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => context.push(AppRoutes.aiChat),
      backgroundColor: Colors.white,
      child: const Icon(Icons.smart_toy_rounded, color: Colors.black87),
    );
  }
}
