import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/features/ai_assistant/bloc/ai_chat_bloc.dart';
import 'package:pos/features/ai_assistant/bloc/ai_chat_event.dart';
import 'package:pos/features/ai_assistant/services/model_download_service.dart';

class DownloadProgressBanner extends StatelessWidget {
  final ModelDownloadProgress? progress;
  const DownloadProgressBanner({super.key, this.progress});

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final pct = p?.percentInt ?? 0;
    final downloaded = p?.downloadedMB ?? '0.0';
    final total = p?.totalMB ?? '0.0';
    final fraction = p?.progress ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSoft, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Spinning indicator
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: fraction > 0 ? fraction : null,
                  backgroundColor: AppColors.brand.withAlpha(30),
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Downloading AI Model  $pct%',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context
                    .read<AiChatBloc>()
                    .add(const AiModelDownloadCancelled()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.errorSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 5,
              backgroundColor: AppColors.brand.withAlpha(25),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.brand),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$downloaded MB / $total MB',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
