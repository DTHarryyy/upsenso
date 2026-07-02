import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/widgets/app_bottom_sheet_scaffold.dart';
import 'package:pos/core/widgets/app_field_label.dart';
import 'package:pos/core/widgets/app_filled_button.dart';
import 'package:pos/core/widgets/app_input_decoration.dart';
import 'package:pos/core/widgets/app_modal.dart';
import 'package:pos/features/crm/domain/entities/customer.dart';
import 'package:pos/features/crm/domain/repositories/i_customer_repository.dart';
import 'package:pos/features/crm/presentation/widgets/customer_selection.dart';

/// Inline customer typeahead for checkout — no bottom sheet. Type to see
/// matching customers instantly and tap to link one; a plain typed name is used
/// as a receipt-only label; managers get an inline "Save as customer" action.
///
/// Emits the effective [CustomerSelection] on every change (null = walk-in) so
/// the parent checkout can read it straight off at confirm time.
class CustomerInlinePicker extends StatefulWidget {
  final String? businessId;
  final CustomerSelection? initial;
  final ValueChanged<CustomerSelection?> onChanged;

  const CustomerInlinePicker({
    super.key,
    required this.businessId,
    required this.onChanged,
    this.initial,
  });

  @override
  State<CustomerInlinePicker> createState() => _CustomerInlinePickerState();
}

class _CustomerInlinePickerState extends State<CustomerInlinePicker> {
  final ICustomerRepository _repo = sl<ICustomerRepository>();
  late final TextEditingController _controller;
  StreamSubscription? _sub;

  List<Customer> _all = [];
  Customer? _linked; // a saved record the user tapped
  String _query = '';

  bool get _canManage =>
      sl<PermissionService>().can(PermissionKeys.crmManage);

  @override
  void initState() {
    super.initState();
    _linked = widget.initial?.customer;
    _query = widget.initial?.displayName ?? '';
    _controller = TextEditingController(text: _query);

    final businessId = widget.businessId;
    if (businessId != null && businessId.isNotEmpty) {
      _sub = _repo.watchCustomers(businessId).listen((customers) {
        if (mounted) setState(() => _all = customers);
      }, onError: (Object e, StackTrace st) {
        debugPrint('[CustomerInlinePicker] watch error: $e\n$st');
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onText(String text) {
    final trimmed = text.trim();
    // Editing away from a linked customer's exact name unlinks it — the sale
    // becomes an ad-hoc name until they pick/save again.
    if (_linked != null && _linked!.name.trim() != trimmed) {
      _linked = null;
    }
    setState(() => _query = text);
    _emit(trimmed);
  }

  void _emit(String trimmed) {
    if (trimmed.isEmpty) {
      widget.onChanged(null); // walk-in
    } else if (_linked != null) {
      widget.onChanged(CustomerSelection.record(_linked!));
    } else {
      widget.onChanged(CustomerSelection.nameOnly(trimmed));
    }
  }

  void _link(Customer c) {
    setState(() {
      _linked = c;
      _query = c.name;
      _controller.text = c.name;
      _controller.selection =
          TextSelection.collapsed(offset: c.name.length);
    });
    FocusScope.of(context).unfocus();
    widget.onChanged(CustomerSelection.record(c));
  }

  void _clear() {
    setState(() {
      _linked = null;
      _query = '';
      _controller.clear();
    });
    widget.onChanged(null);
  }

  Future<void> _saveAsCustomer() async {
    final businessId = widget.businessId;
    if (!_canManage || businessId == null || businessId.isEmpty) return;
    final created = await showAppModal<Customer>(
      context: context,
      builder: (_) => _QuickAddCustomerSheet(
        businessId: businessId,
        initialName: _query.trim(),
      ),
    );
    if (created != null && mounted) _link(created);
  }

  List<Customer> get _matches {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _all
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            (c.phone?.contains(q) ?? false) ||
            (c.email?.toLowerCase().contains(q) ?? false))
        .take(6)
        .toList();
  }

  bool get _hasExactMatch {
    final q = _query.trim().toLowerCase();
    return _all.any((c) => c.name.trim().toLowerCase() == q);
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim();
    final isLinked = _linked != null;
    // Collapse suggestions once the field exactly reflects a linked customer.
    final showSuggestions = query.isNotEmpty && !(isLinked && _linked!.name == query);
    final matches = _matches;
    final canSave =
        _canManage && widget.businessId != null && !_hasExactMatch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppFieldLabel('Customer (optional)'),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onChanged: _onText,
          style: getOutfitStyle(color: AppColors.textPrimary),
          decoration: appInputDeco('Search or type a name…').copyWith(
            prefixIcon: Icon(
              isLinked ? IconlyBold.profile : IconlyLight.search,
              size: 18,
              color: isLinked ? AppColors.brand : AppColors.textMuted,
            ),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppColors.textMuted,
                    tooltip: 'Clear',
                    onPressed: _clear,
                  ),
          ),
        ),

        // Linked confirmation — reassures the cashier the sale is attributed.
        if (isLinked && !showSuggestions)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 15, color: AppColors.success),
                const SizedBox(width: 6),
                Text(
                  'Linked — purchase history will be tracked',
                  style:
                      getOutfitStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),

        // Instant suggestions (in-flow, no modal).
        if (showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Column(
              children: [
                for (final c in matches) ...[
                  _MatchRow(customer: c, onTap: () => _link(c)),
                  const Divider(height: 1, color: AppColors.borderSoft),
                ],
                if (matches.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Row(
                      children: [
                        const Icon(IconlyLight.edit_square,
                            size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No match — "$query" will print on the receipt as a name.',
                            style: getOutfitStyle(
                                fontSize: 12.5, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (canSave)
                  _SaveRow(query: query, onTap: _saveAsCustomer),
              ],
            ),
          ),
      ],
    );
  }
}

class _MatchRow extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;

  const _MatchRow({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final subtitle = customer.phone?.isNotEmpty == true
        ? customer.phone!
        : (customer.email?.isNotEmpty == true ? customer.email! : null);
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.brandSoft,
        child: Text(
          customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
          style: getOutfitStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.brand,
          ),
        ),
      ),
      title: Text(
        customer.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: getOutfitStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: getOutfitStyle(fontSize: 12, color: AppColors.textMuted),
            ),
      onTap: onTap,
    );
  }
}

class _SaveRow extends StatelessWidget {
  final String query;
  final VoidCallback onTap;

  const _SaveRow({required this.query, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.brandSoft,
        child: Icon(IconlyLight.add_user, size: 17, color: AppColors.brand),
      ),
      title: Text(
        'Save "$query" as a customer',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: getOutfitStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.brand,
        ),
      ),
      subtitle: Text(
        'Keeps their purchase history',
        style: getOutfitStyle(fontSize: 12, color: AppColors.textMuted),
      ),
      onTap: onTap,
    );
  }
}

/// Minimal name + phone quick-add used at the till. Prefilled with the typed
/// name. Writes straight through the repository (audit-logged, sync-queued) and
/// returns the created [Customer] so the picker can link it immediately.
class _QuickAddCustomerSheet extends StatefulWidget {
  final String businessId;
  final String initialName;

  const _QuickAddCustomerSheet({
    required this.businessId,
    this.initialName = '',
  });

  @override
  State<_QuickAddCustomerSheet> createState() => _QuickAddCustomerSheetState();
}

class _QuickAddCustomerSheetState extends State<_QuickAddCustomerSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  final _phone = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final customer = await sl<ICustomerRepository>().createCustomer(
        businessId: widget.businessId,
        name: _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      );
      if (mounted) Navigator.pop(context, customer);
    } catch (e, st) {
      debugPrint('[QuickAddCustomer] save error: $e\n$st');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add customer.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetScaffold(
      title: 'New Customer',
      action: AppFilledButton(
        label: 'Add Customer',
        loading: _saving,
        onPressed: _saving ? null : _save,
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppFieldLabel('Customer Name *'),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                maxLength: 80,
                buildCounter:
                    (_, {required currentLength, required isFocused, maxLength}) =>
                        null,
                style:
                    getOutfitStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: appInputDeco('e.g. Maria Santos'),
                validator: (v) {
                  final n = (v ?? '').trim();
                  if (n.isEmpty) return 'Customer name is required';
                  if (n.length < 2) return 'Name is too short';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              const AppFieldLabel('Phone'),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                maxLength: 24,
                buildCounter:
                    (_, {required currentLength, required isFocused, maxLength}) =>
                        null,
                style:
                    getOutfitStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: appInputDeco('+63 9XX XXX XXXX'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
