import 'package:flutter/material.dart';

class AlertPage extends StatelessWidget {
  const AlertPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Alert Page',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
