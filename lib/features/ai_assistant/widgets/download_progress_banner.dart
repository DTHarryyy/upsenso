import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/features/ai_assistant/bloc/ai_chat_bloc.dart';
import 'package:pos/features/ai_assistant/bloc/ai_chat_event.dart';
import 'package:pos/features/ai_assistant/services/model_download_service.dart';

class DownloadProgressBanner extends StatelessWidget {
  final ModelDownloadProgress? progress;
  const DownloadProgressBanner({super.key,this.progress});

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final pct = p?.percentInt ?? 0;
    final downloaded = p?.downloadedMB ?? '0.0';
    final total = p?.totalMB ?? '0.0';
    final fraction = p?.progress ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSoft, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Downloading AI model… $pct%',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              // Cancel button
              GestureDetector(
                onTap: () {
                  context
                      .read<AiChatBloc>()
                      .add(const AiModelDownloadCancelled());
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: AppColors.brand.withAlpha(30),
              color: AppColors.brand,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$downloaded MB / $total MB',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}