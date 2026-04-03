import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/features/ai_assistant/bloc/ai_chat_bloc.dart';
import 'package:pos/features/ai_assistant/bloc/ai_chat_event.dart';
import 'package:pos/features/ai_assistant/bloc/ai_chat_state.dart';
import 'package:pos/features/ai_assistant/models/ai_models.dart';
import 'package:pos/features/ai_assistant/widgets/download_offer_banner.dart';
import 'package:pos/features/ai_assistant/widgets/download_progress_banner.dart';
import 'package:pos/features/ai_assistant/widgets/transaction_preview_card.dart';
import 'package:pos/features/ai_assistant/widgets/typing_indicator.dart';

/// Layer 1 — Full-page AI assistant chat screen.
class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<AiChatBloc>().add(const AiChatInitialized());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<AiChatBloc>().add(AiChatMessageSent(text));
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'AI Assistant',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded),
            color: AppColors.textSecondary,
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderSoft),
        ),
      ),
      body: BlocConsumer<AiChatBloc, AiChatState>(
        listener: (context, state) {
          _scrollToBottom();
        },
        builder: (context, state) {
          return Column(
            children: [
              _ModelStatusBanner(state: state),

              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final msg = state.messages[index];
                    return _ChatBubbleRow(
                      message: msg,
                      formattedTime: _formatTime(msg.timestamp),
                      onConfirm: msg.transactionPreview != null
                          ? () => context.read<AiChatBloc>().add(
                                AiChatTransactionConfirmed(
                                  state.pendingPreview ?? msg.transactionPreview!,
                                ),
                              )
                          : null,
                      onCancel: msg.transactionPreview != null
                          ? () => context.read<AiChatBloc>().add(
                                const AiChatTransactionCancelled(),
                              )
                          : null,
                      isProcessing: state.isProcessing,
                      showPreviewActions:
                          state.pendingPreview != null &&
                          msg.transactionPreview == state.pendingPreview,
                      onPreviewUpdated: msg.transactionPreview != null
                          ? (updated) => context.read<AiChatBloc>().add(
                                AiChatPreviewUpdated(updated),
                              )
                          : null,
                    );
                  },
                ),
              ),

              // ── Input bar ──────────────────────────────────
              Container(
                color: AppColors.surface,
                padding: EdgeInsets.fromLTRB(
                  12,
                  8,
                  12,
                  MediaQuery.of(context).padding.bottom + 12,
                ),
                child: Row(
                  children: [
                    // Text field
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          enabled: !state.isProcessing,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: state.isProcessing
                                ? 'Processing...'
                                : 'Type message...',
                            hintStyle: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Send button
                    _CircleIconButton(
                      icon: state.isProcessing
                          ? Icons.hourglass_top_rounded
                          : Icons.send_rounded,
                      filled: true,
                      onPressed:
                          state.isProcessing ? () {} : _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChatBubbleRow extends StatelessWidget {
  final AiChatMessage message;
  final String formattedTime;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isProcessing;
  final bool showPreviewActions;
  final ValueChanged<AiTransactionPreview>? onPreviewUpdated;

  const _ChatBubbleRow({
    required this.message,
    required this.formattedTime,
    this.onConfirm,
    this.onCancel,
    this.isProcessing = false,
    this.showPreviewActions = false,
    this.onPreviewUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    // Loading indicator
    if (message.type == AiMessageType.loading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.brandSoft,
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 18,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const TypingIndicator(),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.brandSoft,
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 18,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.brand
                        : message.type == AiMessageType.error
                            ? AppColors.errorSoft
                            : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUser
                          ? AppColors.textInverse
                          : message.type == AiMessageType.error
                              ? AppColors.error
                              : AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                // Transaction preview card
                if (message.type == AiMessageType.transactionPreview &&
                    message.transactionPreview != null &&
                    showPreviewActions)
                  TransactionPreviewCard(
                    preview: message.transactionPreview!,
                    onConfirm: onConfirm ?? () {},
                    onCancel: onCancel ?? () {},
                    isProcessing: isProcessing,
                    onPreviewUpdated: onPreviewUpdated,
                  ),
                const SizedBox(height: 4),
                Text(
                  formattedTime,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 24),
        ],
      ),
    );
  }
}



class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;

  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.brand : AppColors.surfaceAlt,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 22,
            color: filled ? AppColors.textInverse : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ModelStatusBanner extends StatelessWidget {
  final AiChatState state;
  const _ModelStatusBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    switch (state.modelStatus) {
      case AiModelStatus.checking:
        return const SizedBox.shrink();

      case AiModelStatus.ready:
        return const SizedBox.shrink();

      case AiModelStatus.notDownloaded:
        return const DownloadOfferBanner();

      case AiModelStatus.downloading:
        return DownloadProgressBanner(progress: state.downloadProgress);
    }
  }
}
