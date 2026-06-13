import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_filled_button.dart';
import 'package:pos/features/procurement/domain/entities/supplier.dart';
import 'package:pos/features/procurement/presentation/cubit/supplier_cubit.dart';

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
    _notes = TextEditingController(text: s?.notes);
  }

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final cubit = context.read<SupplierCubit>();
      if (_isEdit) {
        await cubit.updateSupplier(
          id: widget.supplier!.id,
          name: _name.text.trim(),
          contactName: _contact.text.trim().isEmpty ? null : _contact.text.trim(),
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          address: _address.text.trim().isEmpty ? null : _address.text.trim(),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
      } else {
        await cubit.createSupplier(
          name: _name.text.trim(),
          contactName: _contact.text.trim().isEmpty ? null : _contact.text.trim(),
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          address: _address.text.trim().isEmpty ? null : _address.text.trim(),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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
            _field(_name, 'Supplier Name *', required: true),
            const SizedBox(height: 12),
            _field(_contact, 'Contact Person'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(_phone, 'Phone')),
                const SizedBox(width: 10),
                Expanded(child: _field(_email, 'Email')),
              ],
            ),
            const SizedBox(height: 12),
            _field(_address, 'Address'),
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

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
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
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }
}
