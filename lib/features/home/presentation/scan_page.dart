import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  void _showManualEntryDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Code Manually'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter QR / barcode value',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submitCode(ctx, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _submitCode(ctx, controller.text),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _submitCode(BuildContext context, String code) {
    final trimmed = code.trim();
    Navigator.of(context).pop();
    if (trimmed.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code entered: $trimmed'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Scan QR'), elevation: 0),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.brand, width: 3),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.brandSoft,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          IconlyLight.scan,
                          size: 80,
                          color: AppColors.brand,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Scan QR Code',
                        style: AppTextStyles.title(
                          context,
                        ).copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Position QR code within the frame',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body(
                            context,
                          ).copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 200,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('QR Scanner - Coming Soon!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(IconlyLight.scan),
                    label: const Text('Start Scanning'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => _showManualEntryDialog(context),
                  icon: const Icon(IconlyLight.edit),
                  label: const Text('Enter Code Manually'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
