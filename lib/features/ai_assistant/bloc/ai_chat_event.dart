import 'package:equatable/equatable.dart';
import 'package:pos/features/ai_assistant/models/ai_models.dart';
import 'package:pos/features/ai_assistant/services/model_download_service.dart';

abstract class AiChatEvent extends Equatable {
  const AiChatEvent();

  @override
  List<Object?> get props => [];
}

/// User sends a text message.
class AiChatMessageSent extends AiChatEvent {
  final String message;
  const AiChatMessageSent(this.message);

  @override
  List<Object?> get props => [message];
}

/// User confirms a pending transaction preview.
class AiChatTransactionConfirmed extends AiChatEvent {
  final AiTransactionPreview preview;
  const AiChatTransactionConfirmed(this.preview);

  @override
  List<Object?> get props => [preview];
}

/// User cancels a pending transaction preview.
class AiChatTransactionCancelled extends AiChatEvent {
  const AiChatTransactionCancelled();
}

/// User changed a variant selection in the preview — update pending preview.
class AiChatPreviewUpdated extends AiChatEvent {
  final AiTransactionPreview updatedPreview;
  const AiChatPreviewUpdated(this.updatedPreview);

  @override
  List<Object?> get props => [updatedPreview];
}

/// Initialize the AI pipeline on page open.
class AiChatInitialized extends AiChatEvent {
  const AiChatInitialized();
}

/// User taps "Download AI Model".
class AiModelDownloadRequested extends AiChatEvent {
  const AiModelDownloadRequested();
}

/// Internal event: download progress updated.
class AiModelDownloadProgressUpdated extends AiChatEvent {
  final ModelDownloadProgress progress;
  const AiModelDownloadProgressUpdated(this.progress);

  @override
  List<Object?> get props => [progress];
}

/// User taps cancel on a running download.
class AiModelDownloadCancelled extends AiChatEvent {
  const AiModelDownloadCancelled();
}

/// User confirms clearing all chat messages.
class AiChatMessagesCleared extends AiChatEvent {
  const AiChatMessagesCleared();
}
