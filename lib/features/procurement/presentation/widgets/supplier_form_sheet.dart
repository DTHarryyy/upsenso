import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_filled_button.dart';
import 'package:pos/features/procurement/domain/entities/supplier.dart';
import 'package:pos/features/procurement/presentation/cubit/supplier_cubit.dart';
import 'package:pos/features/procurement/presentation/cubit/supplier_state.dart';

class SupplierFormSheet extends StatefulWidget {
  /// Null = create mode; non-null = edit mode.
  final Supplier? supplier;

  const SupplierFormSheet({super.key, this.supplier});

  @override
  State<SupplierFormSheet> createState() => _SupplierFormSheetState();
}

class _SupplierFormSheetState extends State<SupplierFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _contact;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _taxId;
  late final TextEditingController _notes;
  bool _saving = false;

  bool get _isEdit => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    final s = widget.supplier;
    _name = TextEditingController(text: s?.name);
    _contact = TextEditingController(text: s?.contactName);
    _phone = TextEditingController(text: s?.phone);
    _email = TextEditingController(text: s?.email);
    _address = TextEditingController(text: s?.address);
    _taxId = TextEditingController(text: s?.taxId);
    _notes = TextEditingController(text: s?.notes);
  }

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _taxId.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final cubit = context.read<SupplierCubit>();
      final ok = _isEdit
          ? await cubit.updateSupplier(
              id: widget.supplier!.id,
              name: _name.text.trim(),
              contactName: _nullable(_contact),
              phone: _nullable(_phone),
              email: _nullable(_email),
              address: _nullable(_address),
              taxId: _nullable(_taxId),
              notes: _nullable(_notes),
            )
          : await cubit.createSupplier(
              name: _name.text.trim(),
              contactName: _nullable(_contact),
              phone: _nullable(_phone),
              email: _nullable(_email),
              address: _nullable(_address),
              taxId: _nullable(_taxId),
              notes: _nullable(_notes),
            );
      // Stay open on failure (permission denied / duplicate / write error) so
      // the user keeps their input; the cubit surfaces the reason via snackbar.
      if (ok && mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _nullable(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSoft,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isEdit ? 'Edit Supplier' : 'Add Supplier',
              style: getOutfitStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _field(_name, 'Supplier Name *', validator: _validateName),
            const SizedBox(height: 12),
            _field(_contact, 'Contact Person'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field(
                    _phone,
                    'Phone',
                    keyboardType: TextInputType.phone,
                    validator: _validatePhone,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _field(
                    _email,
                    'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _field(_address, 'Address'),
            const SizedBox(height: 12),
            _field(_taxId, 'Tax ID'),
            const SizedBox(height: 12),
            _field(_notes, 'Notes', maxLines: 2),
            const SizedBox(height: 20),
            AppFilledButton(
              label: _isEdit ? 'Save Changes' : 'Add Supplier',
              loading: _saving,
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
        ),
      ),
    );
  }

  // Name clash check mirrors the cubit's authoritative guard, surfaced inline
  // here for immediate feedback. Reads the directory from the cubit state.
  String? _validateName(String? v) {
    final name = (v ?? '').trim();
    if (name.isEmpty) return 'Required';
    final state = context.read<SupplierCubit>().state;
    final existing =
        state is SupplierLoaded ? state.suppliers : const <Supplier>[];
    final clash = existing.any(
      (s) =>
          s.id != widget.supplier?.id &&
          s.name.trim().toLowerCase() == name.toLowerCase(),
    );
    return clash ? 'A supplier with this name already exists' : null;
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
    final ok = RegExp(r'^[0-9+()\-\s]{7,}$').hasMatch(p);
    return ok ? null : 'Enter a valid phone number';
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: getOutfitStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: getOutfitStyle(fontSize: 13, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
        ),
      ),
      validator: validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null),
    );
  }
}
