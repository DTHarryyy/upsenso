import 'package:flutter/material.dart';
import 'package:pos/core/ui/widgets/custom_app_bar.dart';

class Inventory extends StatelessWidget {
  const Inventory({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        branches: ["Main Branch", "Branch A", "Branch B"],
        selectedBranch: "Main Branch",
        userName: "John Doe",
        userRole: "Admin",
      ),
      body: const Center(child: Text('Inventory Page')),
    );
  }
}
