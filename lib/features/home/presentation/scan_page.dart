import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

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
                          Icons.qr_code_scanner,
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
                      // TODO: Implement QR scanner functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('QR Scanner - Coming Soon!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Start Scanning'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Implement manual entry
                  },
                  icon: const Icon(Icons.keyboard),
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
