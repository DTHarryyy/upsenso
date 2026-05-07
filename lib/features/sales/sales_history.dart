import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/branch/branch_state.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/database/daos/transactions_dao.dart';
import 'package:pos/core/database/app_database.dart';

class SalesHistory extends StatefulWidget {
  const SalesHistory({super.key});

  @override
  State<SalesHistory> createState() => _SalesHistoryState();
}

class _SalesHistoryState extends State<SalesHistory> {
  late final TransactionsDao _txDao;
  StreamSubscription<List<TransactionsTableData>>? _txSub;
  List<TransactionsTableData> _transactions = [];
  bool _loading = true;

  // Detail expansion — holds the ID of the currently expanded transaction
  String? _expandedTxId;
  List<TransactionItemsTableData>? _expandedItems;
  bool _loadingItems = false;

  @override
  void initState() {
    super.initState();
    _txDao = sl<TransactionsDao>();
  }

  @override
  void dispose() {
    _txSub?.cancel();
    super.dispose();
  }

  void _subscribe(String? branchId) {
    _txSub?.cancel();
    _txSub = _txDao.watchTransactions(branchId: branchId).listen((list) {
      if (mounted)
        setState(() {
          _transactions = list;
          _loading = false;
        });
    });
  }

  Future<void> _toggleExpand(String txId) async {
    if (_expandedTxId == txId) {
      setState(() {
        _expandedTxId = null;
        _expandedItems = null;
      });
      return;
    }
    setState(() {
      _expandedTxId = txId;
      _expandedItems = null;
      _loadingItems = true;
    });
    final items = await _txDao.getItemsByTransactionId(txId);
    if (mounted && _expandedTxId == txId) {
      setState(() {
        _expandedItems = items;
        _loadingItems = false;
      });
    }
  }

  // ── Formatting helpers ──

  String _fmt(double v) =>
      '₱${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}';

  String _fmtDate(DateTime d) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }

  String _fmtTime(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final p = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }

  String _fmtQty(double q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BranchCubit, BranchState>(
      listener: (context, branchState) {
        _subscribe(branchState.selectedBranchId);
      },
      builder: (context, branchState) {
        // Subscribe on first build
        if (_loading && _txSub == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _subscribe(branchState.selectedBranchId);
          });
        }

        return Scaffold(
          backgroundColor: AppColors.background,

          body: _buildBody(context),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brand),
      );
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: AppTextStyles.subtitle(
                context,
              ).copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Completed sales will appear here',
              style: AppTextStyles.body(
                context,
              ).copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    // Group transactions by date
    final grouped = <String, List<TransactionsTableData>>{};
    for (final tx in _transactions) {
      final key = _fmtDate(tx.createdAt);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    final dateKeys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: dateKeys.length,
      itemBuilder: (context, groupIdx) {
        final dateLabel = dateKeys[groupIdx];
        final txList = grouped[dateLabel]!;
        final dailyTotal = txList.fold(0.0, (s, t) => s + t.totalAmount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (groupIdx > 0) const SizedBox(height: 16),
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateLabel,
                    style: AppTextStyles.subtitle(
                      context,
                    ).copyWith(color: AppColors.textPrimary),
                  ),
                  Text(
                    _fmt(dailyTotal),
                    style: AppTextStyles.subtitle(context).copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            // Transaction cards for this date
            ...txList.map((tx) => _buildTransactionCard(context, tx)),
          ],
        );
      },
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionsTableData tx) {
    final isExpanded = _expandedTxId == tx.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _toggleExpand(tx.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isExpanded
                  ? AppColors.brand.withValues(alpha: 0.3)
                  : AppColors.borderSoft,
            ),
            boxShadow: isExpanded
                ? [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main row
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _paymentColor(
                          tx.paymentMethod,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _paymentIcon(tx.paymentMethod),
                        size: 20,
                        color: _paymentColor(tx.paymentMethod),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.customerName?.isNotEmpty == true
                                ? tx.customerName!
                                : 'Walk-in Customer',
                            style: AppTextStyles.body(context).copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_fmtTime(tx.createdAt)}  •  ${tx.itemCount} item${tx.itemCount != 1 ? 's' : ''}  •  ${_capitalise(tx.paymentMethod)}',
                            style: AppTextStyles.caption(
                              context,
                            ).copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Amount
                    Text(
                      _fmt(tx.totalAmount),
                      style: AppTextStyles.money(
                        context,
                      ).copyWith(color: AppColors.accent),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Expanded detail
              if (isExpanded) _buildDetail(context, tx),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, TransactionsTableData tx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, color: AppColors.borderSoft),
        // Line items
        if (_loadingItems)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.brand,
                ),
              ),
            ),
          )
        else if (_expandedItems != null && _expandedItems!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Column(
              children: _expandedItems!.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.variantName != 'Default'
                                  ? '${item.productName} (${item.variantName})'
                                  : item.productName,
                              style: AppTextStyles.body(
                                context,
                              ).copyWith(color: AppColors.textPrimary),
                            ),
                            Text(
                              '${_fmtQty(item.qty)} × ${_fmt(item.unitPrice)}',
                              style: AppTextStyles.caption(
                                context,
                              ).copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _fmt(item.lineTotal),
                        style: AppTextStyles.body(context).copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        // Summary footer
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
          ),
          child: Column(
            children: [
              _summaryRow(context, 'Subtotal', _fmt(tx.subtotal)),
              if (tx.taxAmount > 0)
                _summaryRow(context, 'Tax', _fmt(tx.taxAmount)),
              if (tx.discountAmount > 0)
                _summaryRow(context, 'Discount', '-${_fmt(tx.discountAmount)}'),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: AppTextStyles.subtitle(context).copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _fmt(tx.totalAmount),
                    style: AppTextStyles.money(
                      context,
                    ).copyWith(color: AppColors.accent),
                  ),
                ],
              ),
              if (tx.amountReceived != null) ...[
                const SizedBox(height: 6),
                _summaryRow(context, 'Received', _fmt(tx.amountReceived!)),
                _summaryRow(context, 'Change', _fmt(tx.changeDue ?? 0)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: AppTextStyles.body(context).copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Style helpers ──

  IconData _paymentIcon(String method) {
    switch (method.toLowerCase()) {
      case 'card':
        return Icons.credit_card;
      case 'gcash':
      case 'ewallet':
        return Icons.phone_android;
      default:
        return Icons.payments_outlined;
    }
  }

  Color _paymentColor(String method) {
    switch (method.toLowerCase()) {
      case 'card':
        return AppColors.brand;
      case 'gcash':
      case 'ewallet':
        return AppColors.info;
      default:
        return AppColors.accent;
    }
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
