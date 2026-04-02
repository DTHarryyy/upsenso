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
  final String? branchId;
  final _uuid = const Uuid();

  StreamSubscription<ModelDownloadProgress>? _downloadSub;

  AiChatBloc({
    required AiPipeline pipeline,
    required ModelDownloadService downloadService,
    required ModelManager modelManager,
    required this.businessId,
    required this.cashierId,
    this.branchId,
  })  : _pipeline = pipeline,
        _downloadService = downloadService,
        _modelManager = modelManager,
        super(AiChatState(messages: [
          AiChatMessage(
            id: const Uuid().v4(),
            text: "Hi! I'm your Ledgify AI assistant. Ask me about your "
                "sales, products, inventory — or tell me to add a transaction!",
            isUser: false,
            type: AiMessageType.text,
          ),
        ])) {
    on<AiChatInitialized>(_onInitialized);
    on<AiChatMessageSent>(_onMessageSent);
    on<AiChatTransactionConfirmed>(_onTransactionConfirmed);
    on<AiChatTransactionCancelled>(_onTransactionCancelled);
    on<AiModelDownloadRequested>(_onDownloadRequested);
    on<AiModelDownloadProgressUpdated>(_onDownloadProgress);
    on<AiModelDownloadCancelled>(_onDownloadCancelled);
  }

  Future<void> _onInitialized(
    AiChatInitialized event,
    Emitter<AiChatState> emit,
  ) async {
    // Check if model already exists
    final modelAvailable = await _modelManager.isModelAvailable();
    if (modelAvailable) {
      emit(state.copyWith(modelStatus: AiModelStatus.ready));
      await _pipeline.initialize();
    } else {
      emit(state.copyWith(modelStatus: AiModelStatus.notDownloaded));
      // Pipeline still works via rule-based fallback
      await _pipeline.initialize();
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
    } else if (!_downloadService.progressStream.isBroadcast) {
      // Download failed (not cancelled)
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
    final result = await _pipeline.processMessage(
      userMessage: text,
      businessId: businessId,
      cashierId: cashierId,
      branchId: branchId,
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
      branchId: branchId,
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

  @override
  Future<void> close() {
    _downloadSub?.cancel();
    _pipeline.dispose();
    return super.close();
  }
}
