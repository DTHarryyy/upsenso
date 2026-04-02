import 'package:equatable/equatable.dart';
import 'package:pos/features/ai_assistant/models/ai_models.dart';
import 'package:pos/features/ai_assistant/services/model_download_service.dart';

/// Whether the LLM model is available on-device.
enum AiModelStatus {
  /// Initial state — haven't checked yet.
  checking,

  /// No model found; download not started.
  notDownloaded,

  /// Download is in progress.
  downloading,

  /// Model file is on disk and ready.
  ready,
}

class AiChatState extends Equatable {
  final List<AiChatMessage> messages;
  final bool isProcessing;
  final AiTransactionPreview? pendingPreview;
  final AiModelStatus modelStatus;
  final ModelDownloadProgress? downloadProgress;

  const AiChatState({
    this.messages = const [],
    this.isProcessing = false,
    this.pendingPreview,
    this.modelStatus = AiModelStatus.checking,
    this.downloadProgress,
  });

  AiChatState copyWith({
    List<AiChatMessage>? messages,
    bool? isProcessing,
    AiTransactionPreview? pendingPreview,
    bool clearPreview = false,
    AiModelStatus? modelStatus,
    ModelDownloadProgress? downloadProgress,
    bool clearDownload = false,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isProcessing: isProcessing ?? this.isProcessing,
      pendingPreview:
          clearPreview ? null : (pendingPreview ?? this.pendingPreview),
      modelStatus: modelStatus ?? this.modelStatus,
      downloadProgress:
          clearDownload ? null : (downloadProgress ?? this.downloadProgress),
    );
  }

  @override
  List<Object?> get props => [
        messages,
        isProcessing,
        pendingPreview,
        modelStatus,
        downloadProgress,
      ];
}
