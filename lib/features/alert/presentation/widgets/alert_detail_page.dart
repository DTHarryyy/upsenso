import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/features/alert/data/alert_model.dart';
import 'package:pos/features/alert/presentation/widgets/alert_detail_content.dart';

class AlertDetailPage extends StatelessWidget {
  final FraudAlert alert;

  const AlertDetailPage({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(IconlyLight.arrow_left,
              color: AppColors.textPrimary),
        ),
        title: Text(
          alert.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderSoft),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: AlertDetailContent(alert: alert),
      ),
    );
  }
}
