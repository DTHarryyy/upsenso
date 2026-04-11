import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:pos/features/ai_assistant/bloc/ai_chat_event.dart';
import 'package:pos/features/ai_assistant/bloc/ai_chat_state.dart';
import 'package:pos/features/ai_assistant/models/ai_models.dart';
import 'package:pos/features/ai_assistant/services/ai_pipeline.dart';
import 'package:pos/features/ai_assistant/services/model_download_service.dart';
import 'package:pos/features/ai_assistant/services/model_manager.dart';
import 'package:pos/features/ai_assistant/services/response_formatter.dart';

class AiChatBloc extends Bloc<AiChatEvent, AiChatState> {
  final AiPipeline _pipeline;
  final ModelDownloadService _downloadService;
  final ModelManager _modelManager;
  final String businessId;
  final String cashierId;
  final String? Function() selectedBranchId;
  final _uuid = const Uuid();

  StreamSubscription<ModelDownloadProgress>? _downloadSub;

  AiChatBloc({
    required AiPipeline pipeline,
    required ModelDownloadService downloadService,
    required ModelManager modelManager,
    required this.businessId,
    required this.cashierId,
    required this.selectedBranchId,
  })  : _pipeline = pipeline,
        _downloadService = downloadService,
        _modelManager = modelManager,
        super(AiChatState(messages: [])) {
    on<AiChatInitialized>(_onInitialized);
    on<AiChatMessageSent>(_onMessageSent);
    on<AiChatTransactionConfirmed>(_onTransactionConfirmed);
    on<AiChatTransactionCancelled>(_onTransactionCancelled);
    on<AiChatPreviewUpdated>(_onPreviewUpdated);
    on<AiModelDownloadRequested>(_onDownloadRequested);
    on<AiModelDownloadProgressUpdated>(_onDownloadProgress);
    on<AiModelDownloadCancelled>(_onDownloadCancelled);
    on<AiChatMessagesCleared>(_onMessagesCleared);
  }

  Future<void> _onInitialized(
    AiChatInitialized event,
    Emitter<AiChatState> emit,
  ) async {
    // Check if model already exists
    final modelAvailable = await _modelManager.isModelAvailable();
    try {
      if (modelAvailable) {
        emit(state.copyWith(modelStatus: AiModelStatus.ready));
        await _pipeline.initialize();
      } else {
        emit(state.copyWith(modelStatus: AiModelStatus.notDownloaded));
        // Pipeline still works via rule-based fallback
        await _pipeline.initialize();
      }
    } catch (e) {
      emit(state.copyWith(modelStatus: AiModelStatus.notDownloaded));
    }
  }

  Future<void> _onDownloadRequested(
    AiModelDownloadRequested event,
    Emitter<AiChatState> emit,
  ) async {
    emit(state.copyWith(modelStatus: AiModelStatus.downloading));

    // Listen to progress stream
    _downloadSub?.cancel();
    _downloadSub = _downloadService.progressStream.listen((progress) {
      add(AiModelDownloadProgressUpdated(progress));
    });

    // Start download (runs in background)
    final modelPath = await _downloadService.downloadModel();

    _downloadSub?.cancel();
    _downloadSub = null;

    if (modelPath != null) {
      emit(state.copyWith(
        modelStatus: AiModelStatus.ready,
        clearDownload: true,
      ));
      // Reload the pipeline with the real LLM
      await _pipeline.initialize();
    } else {
      // Download failed or was cancelled — reset to notDownloaded
      emit(state.copyWith(
        modelStatus: AiModelStatus.notDownloaded,
        clearDownload: true,
      ));
    }
  }

  void _onDownloadProgress(
    AiModelDownloadProgressUpdated event,
    Emitter<AiChatState> emit,
  ) {
    emit(state.copyWith(downloadProgress: event.progress));

    if (event.progress.status == ModelDownloadStatus.failed) {
      emit(state.copyWith(
        modelStatus: AiModelStatus.notDownloaded,
        clearDownload: true,
      ));
    }
    if (event.progress.status == ModelDownloadStatus.cancelled) {
      emit(state.copyWith(
        modelStatus: AiModelStatus.notDownloaded,
        clearDownload: true,
      ));
    }
  }

  void _onDownloadCancelled(
    AiModelDownloadCancelled event,
    Emitter<AiChatState> emit,
  ) {
    _downloadService.cancel();
  }

  Future<void> _onMessageSent(
    AiChatMessageSent event,
    Emitter<AiChatState> emit,
  ) async {
    final text = event.message.trim();
    if (text.isEmpty) return;

    // Add user message
    final userMsg = AiChatMessage(
      id: _uuid.v4(),
      text: text,
      isUser: true,
      type: AiMessageType.text,
    );

    final updatedMessages = [...state.messages, userMsg];

    // Show loading state
    final loadingMsg = AiChatMessage(
      id: _uuid.v4(),
      text: '',
      isUser: false,
      type: AiMessageType.loading,
    );

    emit(state.copyWith(
      messages: [...updatedMessages, loadingMsg],
      isProcessing: true,
      clearPreview: true,
    ));

    // Process through AI pipeline
    try {
      final result = await _pipeline.processMessage(
        userMessage: text,
        businessId: businessId,
        cashierId: cashierId,
        branchId: selectedBranchId(),
      );

      // Remove loading message and add AI response
      final aiMsg = AiChatMessage(
        id: _uuid.v4(),
        text: result.responseText,
        isUser: false,
        type: result.type == AiResponseType.transactionPreview
            ? AiMessageType.transactionPreview
            : result.type == AiResponseType.error
                ? AiMessageType.error
                : AiMessageType.text,
        transactionPreview: result.preview,
      );

      emit(state.copyWith(
        messages: [...updatedMessages, aiMsg],
        isProcessing: false,
        pendingPreview: result.preview,
      ));
    } catch (e) {
      final errorMsg = AiChatMessage(
        id: _uuid.v4(),
        text: 'Something went wrong. Please try again.',
        isUser: false,
        type: AiMessageType.error,
      );
      emit(state.copyWith(
        messages: [...updatedMessages, errorMsg],
        isProcessing: false,
      ));
    }
  }

  Future<void> _onTransactionConfirmed(
    AiChatTransactionConfirmed event,
    Emitter<AiChatState> emit,
  ) async {
    emit(state.copyWith(isProcessing: true));

    // Layer 9: Execute transaction
    final result = await _pipeline.confirmTransaction(
      preview: event.preview,
      cashierId: cashierId,
      branchId: selectedBranchId(),
    );

    final aiMsg = AiChatMessage(
      id: _uuid.v4(),
      text: result.responseText,
      isUser: false,
      type: result.type == AiResponseType.error
          ? AiMessageType.error
          : AiMessageType.text,
    );

    emit(state.copyWith(
      messages: [...state.messages, aiMsg],
      isProcessing: false,
      clearPreview: true,
    ));
  }

  void _onTransactionCancelled(
    AiChatTransactionCancelled event,
    Emitter<AiChatState> emit,
  ) {
    final aiMsg = AiChatMessage(
      id: _uuid.v4(),
      text: AiResponseFormatter.formatTransactionCancelled(),
      isUser: false,
      type: AiMessageType.text,
    );

    emit(state.copyWith(
      messages: [...state.messages, aiMsg],
      clearPreview: true,
    ));
  }

  void _onPreviewUpdated(
    AiChatPreviewUpdated event,
    Emitter<AiChatState> emit,
  ) {
    // Update the pending preview and the matching message with new variant selections.
    final updatedMessages = state.messages.map((msg) {
      if (msg.transactionPreview != null &&
          msg.transactionPreview == state.pendingPreview) {
        return AiChatMessage(
          id: msg.id,
          text: AiResponseFormatter.formatPreviewMessage(event.updatedPreview),
          isUser: false,
          type: AiMessageType.transactionPreview,
          transactionPreview: event.updatedPreview,
          timestamp: msg.timestamp,
        );
      }
      return msg;
    }).toList();

    emit(state.copyWith(
      messages: updatedMessages,
      pendingPreview: event.updatedPreview,
    ));
  }

  void _onMessagesCleared(
    AiChatMessagesCleared event,
    Emitter<AiChatState> emit,
  ) {
    emit(state.copyWith(messages: [], clearPreview: true));
  }

  @override
  Future<void> close() {
    _downloadSub?.cancel();
    _pipeline.dispose();
    return super.close();
  }
}
