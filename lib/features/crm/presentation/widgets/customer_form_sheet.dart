import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_bottom_sheet_scaffold.dart';
import 'package:pos/core/widgets/app_field_label.dart';
import 'package:pos/core/widgets/app_filled_button.dart';
import 'package:pos/core/widgets/app_input_decoration.dart';
import 'package:pos/features/crm/domain/entities/customer.dart';
import 'package:pos/features/crm/presentation/cubit/customer_cubit.dart';
import 'package:pos/features/crm/presentation/cubit/customer_state.dart';

class CustomerFormSheet extends StatefulWidget {
  /// Null = create mode; non-null = edit mode.
  final Customer? customer;

  const CustomerFormSheet({super.key, this.customer});

  @override
  State<CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends State<CustomerFormSheet> {
  // Field length caps mirror the DB columns and keep stored values sane.
  static const _nameMax = 80;
  static const _phoneMax = 24;
  static const _emailMax = 120;
  static const _addressMax = 160;
  static const _notesMax = 300;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _notes;

  bool _saving = false;

  // Surfaced inline because a full-height sheet hides the page-level snackbar.
  String? _error;

  bool get _isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _name = TextEditingController(text: c?.name);
    _phone = TextEditingController(text: c?.phone);
    _email = TextEditingController(text: c?.email);
    _address = TextEditingController(text: c?.address);
    _notes = TextEditingController(text: c?.notes);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final cubit = context.read<CustomerCubit>();
      final ok = _isEdit
          ? await cubit.updateCustomer(
              id: widget.customer!.id,
              name: _name.text.trim(),
              phone: _nullable(_phone),
              email: _nullable(_email),
              address: _nullable(_address),
              notes: _nullable(_notes),
            )
          : await cubit.createCustomer(
              name: _name.text.trim(),
              phone: _nullable(_phone),
              email: _nullable(_email),
              address: _nullable(_address),
              notes: _nullable(_notes),
            );
      // Success closes the sheet. On a handled failure the cubit emits
      // CustomerError, which the BlocListener turns into the inline banner —
      // we keep the sheet open so the user keeps their input.
      if (ok && mounted) Navigator.pop(context);
    } catch (e, st) {
      debugPrint('[CustomerForm] Error in _submit: $e\n$st');
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _nullable(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerCubit, CustomerState>(
      listenWhen: (_, current) => current is CustomerError,
      listener: (_, state) {
        if (state is CustomerError && mounted) {
          setState(() => _error = state.message);
        }
      },
      child: AppBottomSheetScaffold(
        title: _isEdit ? 'Edit Customer' : 'Add Customer',
        fullHeight: true,
        maxHeightFactor: 0.95,
        titleTrailing: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
          visualDensity: VisualDensity.compact,
          tooltip: 'Close',
          onPressed: _saving ? null : () => Navigator.pop(context),
        ),
        action: AppFilledButton(
          label: _isEdit ? 'Save Changes' : 'Add Customer',
          loading: _saving,
          onPressed: _saving ? null : _submit,
        ),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null) ...[
                  _ErrorBanner(
                    message: _error!,
                    onDismiss: () => setState(() => _error = null),
                  ),
                  const SizedBox(height: 16),
                ],
                _field(
                  'Customer Name *',
                  _name,
                  hint: 'e.g. Maria Santos',
                  maxLength: _nameMax,
                  textCapitalization: TextCapitalization.words,
                  validator: _validateName,
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _field(
                        'Phone',
                        _phone,
                        hint: '+63 9XX XXX XXXX',
                        maxLength: _phoneMax,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9+()\-\s]'),
                          ),
                        ],
                        validator: _validatePhone,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        'Email',
                        _email,
                        hint: 'name@email.com',
                        maxLength: _emailMax,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _field(
                  'Address',
                  _address,
                  hint: 'Street, city',
                  maxLength: _addressMax,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 14),
                _field(
                  'Notes',
                  _notes,
                  hint: 'Preferences, notes…',
                  maxLength: _notesMax,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Name clash check mirrors the cubit's authoritative guard, surfaced inline
  // here for immediate feedback. Reads the directory from the cubit state.
  String? _validateName(String? v) {
    final name = (v ?? '').trim();
    if (name.isEmpty) return 'Customer name is required';
    if (name.length < 2) return 'Name is too short';
    final state = context.read<CustomerCubit>().state;
    final existing = state is CustomerLoaded
        ? state.customers
        : const <Customer>[];
    final clash = existing.any(
      (c) =>
          c.id != widget.customer?.id &&
          c.name.trim().toLowerCase() == name.toLowerCase(),
    );
    return clash ? 'A customer with this name already exists' : null;
  }

  String? _validateEmail(String? v) {
    final e = (v ?? '').trim();
    if (e.isEmpty) return null; // optional
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);
    return ok ? null : 'Enter a valid email';
  }

  String? _validatePhone(String? v) {
    final p = (v ?? '').trim();
    if (p.isEmpty) return null; // optional
    final digits = p.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7) return 'Enter a valid phone number';
    return null;
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFieldLabel(label),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          textInputAction: maxLines > 1
              ? TextInputAction.newline
              : TextInputAction.next,
          inputFormatters: inputFormatters,
          buildCounter:
              (_, {required currentLength, required isFocused, maxLength}) =>
                  null,
          style: getOutfitStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: appInputDeco(hint),
          validator: validator,
        ),
      ],
    );
  }
}

/// Inline, dismissible error banner shown at the top of the form when a save
/// fails — keeps the reason visible inside the full-height sheet.
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: AppColors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: getOutfitStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
