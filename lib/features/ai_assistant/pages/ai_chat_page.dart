import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/features/ai_assistant/bloc/ai_chat_bloc.dart';
import 'package:pos/features/ai_assistant/bloc/ai_chat_event.dart';
import 'package:pos/features/ai_assistant/bloc/ai_chat_state.dart';
import 'package:pos/features/ai_assistant/models/ai_models.dart';
import 'package:pos/features/ai_assistant/widgets/download_progress_banner.dart';
import 'package:pos/features/ai_assistant/widgets/transaction_preview_card.dart';
import 'package:pos/features/ai_assistant/widgets/typing_indicator.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _inputHasFocus = false;

  @override
  void initState() {
    super.initState();
    context.read<AiChatBloc>().add(const AiChatInitialized());
    _focusNode.addListener(() {
      setState(() => _inputHasFocus = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
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

  void _showMenu(BuildContext btnCtx, AiChatState state) {
    final RenderBox button = btnCtx.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(btnCtx).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
            button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: btnCtx,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.surface,
      elevation: 12,
      shadowColor: Colors.black.withAlpha(18),
      items: [
        if (state.modelStatus == AiModelStatus.notDownloaded)
          PopupMenuItem<String>(
            value: 'download',
            child: _MenuItemContent(
              icon: Icons.download_rounded,
              iconColor: AppColors.brand,
              iconBg: AppColors.brandSoft,
              label: 'Download AI Model',
              subtitle: 'Qwen 2.5 1.5B · ~1 GB',
            ),
          ),
        if (state.modelStatus == AiModelStatus.downloading)
          PopupMenuItem<String>(
            value: 'cancel_download',
            child: _MenuItemContent(
              icon: Icons.cancel_outlined,
              iconColor: AppColors.error,
              iconBg: AppColors.errorSoft,
              label: 'Cancel Download',
              subtitle:
                  '${state.downloadProgress?.percentInt ?? 0}% complete',
            ),
          ),
        if (state.messages.isNotEmpty)
          const PopupMenuItem<String>(
            value: 'clear',
            child: _MenuItemContent(
              icon: Icons.delete_outline_rounded,
              iconColor: AppColors.textSecondary,
              iconBg: AppColors.surfaceAlt,
              label: 'Clear Chat',
            ),
          ),
        const PopupMenuItem<String>(
          value: 'info',
          child: _MenuItemContent(
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.textSecondary,
            iconBg: AppColors.surfaceAlt,
            label: 'About AI Assistant',
          ),
        ),
      ],
    ).then((value) {
      if (!mounted) return;
      final bloc = context.read<AiChatBloc>();
      if (value == 'download') {
        bloc.add(const AiModelDownloadRequested());
      } else if (value == 'cancel_download') {
        bloc.add(const AiModelDownloadCancelled());
      } else if (value == 'clear') {
        _showClearConfirm();
      } else if (value == 'info') {
        _showAboutDialog();
      }
    });
  }

  void _showClearConfirm() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Clear Chat',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        content: const Text(
          'All messages will be removed. This cannot be undone.',
          style: TextStyle(
              color: AppColors.textSecondary, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () {
              context.read<AiChatBloc>().add(const AiChatMessagesCleared());
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.brand, AppColors.brandDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'AI Assistant',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: const Text(
          'Powered by Qwen 2.5 1.5B running fully on-device.\n\nYour data never leaves this device — all processing is private and offline.',
          style: TextStyle(
              color: AppColors.textSecondary, fontSize: 14, height: 1.6),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AiChatBloc, AiChatState>(
        listener: (context, state) => _scrollToBottom(),
        builder: (context, state) {
          return Column(
            children: [
              _AiAppBar(
                state: state,
                onMenuTap: (btnCtx) => _showMenu(btnCtx, state),
              ),
              if (state.modelStatus == AiModelStatus.downloading)
                DownloadProgressBanner(progress: state.downloadProgress),
              Expanded(
                child: state.messages.isEmpty
                    ? _WelcomeView(
                        state: state,
                        onSuggestionTap: (prompt) {
                          _controller.text = prompt;
                          _sendMessage();
                        },
                        onDownloadTap: () => context
                            .read<AiChatBloc>()
                            .add(const AiModelDownloadRequested()),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final msg = state.messages[index];
                          return _ChatBubbleRow(
                            message: msg,
                            formattedTime: _formatTime(msg.timestamp),
                            onConfirm: msg.transactionPreview != null
                                ? () => context
                                    .read<AiChatBloc>()
                                    .add(AiChatTransactionConfirmed(
                                      state.pendingPreview ??
                                          msg.transactionPreview!,
                                    ))
                                : null,
                            onCancel: msg.transactionPreview != null
                                ? () => context
                                    .read<AiChatBloc>()
                                    .add(const AiChatTransactionCancelled())
                                : null,
                            isProcessing: state.isProcessing,
                            showPreviewActions:
                                state.pendingPreview != null &&
                                    msg.transactionPreview ==
                                        state.pendingPreview,
                            onPreviewUpdated: msg.transactionPreview != null
                                ? (updated) => context
                                    .read<AiChatBloc>()
                                    .add(AiChatPreviewUpdated(updated))
                                : null,
                          );
                        },
                      ),
              ),
              _InputBar(
                controller: _controller,
                focusNode: _focusNode,
                isProcessing: state.isProcessing,
                hasFocus: _inputHasFocus,
                onSend: _sendMessage,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── AppBar ──────────────────────────────────────────────────────────────────

class _AiAppBar extends StatelessWidget {
  final AiChatState state;
  final void Function(BuildContext ctx) onMenuTap;

  const _AiAppBar({required this.state, required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel) = switch (state.modelStatus) {
      AiModelStatus.ready => (AppColors.success, 'On-device · Ready'),
      AiModelStatus.downloading => (AppColors.warning, 'Downloading…'),
      AiModelStatus.notDownloaded => (AppColors.textMuted, 'Cloud mode'),
      AiModelStatus.checking => (AppColors.textMuted, 'Checking…'),
    };

    return Container(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 58,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18),
                    color: AppColors.textPrimary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  // Avatar
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.brand, AppColors.brandDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.smart_toy_rounded,
                        color: Colors.white, size: 19),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Assistant',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15.5,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              statusLabel,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Builder(
                    builder: (btnCtx) => IconButton(
                      icon:
                          const Icon(Icons.more_vert_rounded, size: 21),
                      color: AppColors.textSecondary,
                      onPressed: () => onMenuTap(btnCtx),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.borderSoft),
          ],
        ),
      ),
    );
  }
}

// ─── Welcome / Quick-actions ─────────────────────────────────────────────────

class _WelcomeView extends StatelessWidget {
  final AiChatState state;
  final ValueChanged<String> onSuggestionTap;
  final VoidCallback onDownloadTap;

  const _WelcomeView({
    required this.state,
    required this.onSuggestionTap,
    required this.onDownloadTap,
  });

  static const _chips = [
    (label: 'Sales today',         prompt: 'What are my sales today?',                        icon: Icons.trending_up_rounded),
    (label: 'Top products',        prompt: 'Show my top-selling products',                     icon: Icons.star_rounded),
    (label: 'New transaction',     prompt: 'Create a transaction for 2 items',                 icon: Icons.receipt_long_rounded),
    (label: "Last week expenses",  prompt: "What were last week's expenses?",                  icon: Icons.account_balance_wallet_rounded),
    (label: 'Product count',       prompt: 'How many products do I have?',                     icon: Icons.inventory_2_rounded),
    (label: 'Low stock',           prompt: 'Which products are running low on stock?',         icon: Icons.warning_amber_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Hero (vertically centered in available space) ──
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Glowing gradient icon
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.brand, AppColors.brandDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brand.withAlpha(60),
                          blurRadius: 24,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.smart_toy_rounded,
                        color: Colors.white, size: 34),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'How can I help you?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ask about sales, expenses, or products.\nOr tap a suggestion below to get started.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13.5,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Chips + optional download nudge ───────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.modelStatus == AiModelStatus.notDownloaded) ...[
                _DownloadNudge(onDownloadTap: onDownloadTap),
                const SizedBox(height: 18),
              ],

              // Section label
              const Padding(
                padding: EdgeInsets.only(left: 2, bottom: 10),
                child: Text(
                  'SUGGESTED',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),

              // Chips wrap — centred
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: _chips
                      .map((c) => _SuggestionChip(
                            label: c.label,
                            icon: c.icon,
                            onTap: () => onSuggestionTap(c.prompt),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Download nudge ───────────────────────────────────────────────────────────

class _DownloadNudge extends StatelessWidget {
  final VoidCallback onDownloadTap;
  const _DownloadNudge({required this.onDownloadTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brand.withAlpha(45)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brand.withAlpha(22),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.rocket_launch_rounded,
                color: AppColors.brand, size: 17),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Download on-device AI for smarter, fully private responses.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: onDownloadTap,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              padding:
                  const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Download',
                style:
                    TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Suggestion chip ─────────────────────────────────────────────────────────

class _SuggestionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.borderSoft, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.brand, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Chat bubble ─────────────────────────────────────────────────────────────

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

    // Typing / loading bubble
    if (message.type == AiMessageType.loading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _AiAvatar(),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(18),
                ),
                border:
                    Border.all(color: AppColors.borderSoft, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 8,
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

    final isError = message.type == AiMessageType.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _AiAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Bubble
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: isUser && !isError
                        ? const LinearGradient(
                            colors: [AppColors.brand, AppColors.brandDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isUser
                        ? null
                        : isError
                            ? AppColors.errorSoft
                            : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: isError
                                ? AppColors.error.withAlpha(40)
                                : AppColors.borderSoft,
                            width: 1,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? AppColors.brand.withAlpha(35)
                            : Colors.black.withAlpha(5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : isError
                              ? AppColors.error
                              : AppColors.textPrimary,
                      fontSize: 14.5,
                      height: 1.5,
                    ),
                  ),
                ),

                // Transaction preview card
                if (message.type == AiMessageType.transactionPreview &&
                    message.transactionPreview != null &&
                    showPreviewActions)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TransactionPreviewCard(
                      preview: message.transactionPreview!,
                      onConfirm: onConfirm ?? () {},
                      onCancel: onCancel ?? () {},
                      isProcessing: isProcessing,
                      onPreviewUpdated: onPreviewUpdated,
                    ),
                  ),

                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    formattedTime,
                    style: TextStyle(
                      color: AppColors.textMuted.withAlpha(180),
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ─── AI avatar ───────────────────────────────────────────────────────────────

class _AiAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brand, AppColors.brandDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Icon(Icons.smart_toy_rounded,
          color: Colors.white, size: 16),
    );
  }
}

// ─── Input bar ───────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isProcessing;
  final bool hasFocus;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isProcessing,
    required this.hasFocus,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
            top: BorderSide(color: AppColors.borderSoft, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        14,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text field
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: hasFocus
                      ? AppColors.brand.withAlpha(130)
                      : AppColors.borderSoft,
                  width: hasFocus ? 1.5 : 1,
                ),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                enabled: !isProcessing,
                maxLines: 5,
                minLines: 1,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText:
                      isProcessing ? 'Processing…' : 'Ask anything…',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted.withAlpha(200),
                    fontSize: 14.5,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 11),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          _SendButton(isProcessing: isProcessing, onSend: onSend),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onSend;

  const _SendButton({required this.isProcessing, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: isProcessing
            ? null
            : const LinearGradient(
                colors: [AppColors.brand, AppColors.brandDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isProcessing ? AppColors.surfaceAlt : null,
        shape: BoxShape.circle,
        boxShadow: isProcessing
            ? null
            : [
                BoxShadow(
                  color: AppColors.brand.withAlpha(65),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: isProcessing ? null : onSend,
          child: Center(
            child: isProcessing
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.brand.withAlpha(160),
                    ),
                  )
                : const Icon(Icons.arrow_upward_rounded,
                    color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

// ─── Menu item ───────────────────────────────────────────────────────────────

class _MenuItemContent extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String? subtitle;

  const _MenuItemContent({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: iconColor, size: 15),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 1),
              Text(
                subtitle!,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
