import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_toast.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/settings/domain/receipt_settings.dart';
import 'package:pos/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:pos/features/settings/presentation/cubit/settings_state.dart';
import 'package:pos/features/settings/presentation/widgets/receipt_preview.dart';
import 'package:pos/features/settings/services/receipt_printer_service.dart';

class ReceiptSettingsSection extends StatelessWidget {
  const ReceiptSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(64),
              child: CircularProgressIndicator(color: AppColors.brand),
            ),
          );
        }

        final s = state.settings;
        if (s == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Preview banner ──────────────────────────────────────────
            _PreviewBanner(settings: s),
            const SizedBox(height: 20),

            // ── Business details ────────────────────────────────────────
            _SettingsCard(
              icon: IconlyLight.work,
              title: 'Business Details',
              children: [
                _FieldRow(
                  label: 'Business Name',
                  value: s.businessName,
                  hint: 'e.g. Mang Juan Store',
                  onChanged: (v) =>
                      _save(context, (x) => x.copyWith(businessName: v)),
                ),
                _FieldRow(
                  label: 'Store / Branch Name',
                  value: s.storeName,
                  hint: 'e.g. Main Branch',
                  onChanged: (v) =>
                      _save(context, (x) => x.copyWith(storeName: v)),
                ),
                _FieldRow(
                  label: 'Owner Name',
                  value: s.ownerName,
                  hint: 'e.g. Juan dela Cruz',
                  onChanged: (v) =>
                      _save(context, (x) => x.copyWith(ownerName: v)),
                ),
                _FieldRow(
                  label: 'Business Address',
                  value: s.address,
                  hint: '123 Main St, City',
                  maxLines: 2,
                  onChanged: (v) =>
                      _save(context, (x) => x.copyWith(address: v)),
                ),
                _FieldRow(
                  label: 'Contact Number',
                  value: s.contactNumber,
                  hint: '+63 912 345 6789',
                  keyboardType: TextInputType.phone,
                  onChanged: (v) =>
                      _save(context, (x) => x.copyWith(contactNumber: v)),
                ),
                _FieldRow(
                  label: 'Email Address',
                  value: s.email,
                  hint: 'hello@mybusiness.com',
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (v) => _save(context, (x) => x.copyWith(email: v)),
                ),
                _FieldRow(
                  label: 'Website / Social',
                  value: s.website,
                  hint: 'www.mybusiness.com',
                  onChanged: (v) =>
                      _save(context, (x) => x.copyWith(website: v)),
                ),
                _FieldRow(
                  label: 'TIN Number',
                  value: s.tinNumber,
                  hint: '000-000-000-000',
                  onChanged: (v) =>
                      _save(context, (x) => x.copyWith(tinNumber: v)),
                ),
                _FieldRow(
                  label: 'Permit / Registration No.',
                  value: s.permitNumber,
                  hint: 'e.g. BIR-2024-0001',
                  onChanged: (v) =>
                      _save(context, (x) => x.copyWith(permitNumber: v)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Logo ────────────────────────────────────────────────────
            _SettingsCard(
              icon: IconlyLight.image,
              title: 'Business Logo',
              children: [
                _SwitchRow(
                  label: 'Show Logo on Receipt',
                  value: s.showLogo,
                  onChanged: (v) =>
                      _save(context, (x) => x.copyWith(showLogo: v)),
                ),
                if (s.showLogo) ...[
                  const SizedBox(height: 12),
                  _LogoPicker(settings: s),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // ── Receipt content ─────────────────────────────────────────
            _SettingsCard(
              icon: Icons.text_fields_rounded,
              title: 'Receipt Content',
              children: [
                _FieldRow(
                  label: 'Header Text',
                  value: s.headerText,
                  hint: 'Appears at the top of every receipt',
                  maxLines: 2,
                  onChanged: (v) =>
                      _save(context, (x) => x.copyWith(headerText: v)),
                ),
                _FieldRow(
                  label: 'Footer / Thank You Message',
                  value: s.footerText,
                  hint: 'Thank you for your purchase!',
                  maxLines: 2,
                  onChanged: (v) =>
                      _save(context, (x) => x.copyWith(footerText: v)),
                ),
                _FieldRow(
                  label: 'Return Policy',
                  value: s.returnPolicy,
                  hint: 'No returns after 7 days...',
                  maxLines: 3,
                  onChanged: (v) =>
                      _save(context, (x) => x.copyWith(returnPolicy: v)),
                ),
                _FieldRow(
                  label: 'Custom Notes',
                  value: s.customNotes,
                  hint: 'Any additional notes',
                  maxLines: 2,
                  onChanged: (v) =>
                      _save(context, (x) => x.copyWith(customNotes: v)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Receipt toggles ─────────────────────────────────────────
            _SettingsCard(
              icon: Icons.toggle_on_rounded,
              title: 'Receipt Visibility',
              children: [
                _SwitchRow(
                  label: 'Show QR Code',
                  value: s.showQrCode,
                  onChanged: (v) =>
                      _save(context, (x) => x.copyWith(showQrCode: v)),
                ),
                _SwitchRow(
                  label: 'Show Tax Breakdown',
                  value: s.showTaxBreakdown,
                  onChanged: (v) =>
                      _save(context, (x) => x.copyWith(showTaxBreakdown: v)),
                ),
                _SwitchRow(
                  label: 'Show Cashier Name',
                  value: s.showCashierName,
                  onChanged: (v) =>
                      _save(context, (x) => x.copyWith(showCashierName: v)),
                ),
                _SwitchRow(
                  label: 'Show Customer Name',
                  value: s.showCustomerName,
                  onChanged: (v) =>
                      _save(context, (x) => x.copyWith(showCustomerName: v)),
                ),
                _SwitchRow(
                  label: 'Show Date & Time',
                  value: s.showDateTime,
                  onChanged: (v) =>
                      _save(context, (x) => x.copyWith(showDateTime: v)),
                ),
                _SwitchRow(
                  label: 'Show Order ID / Invoice No.',
                  value: s.showOrderId,
                  onChanged: (v) =>
                      _save(context, (x) => x.copyWith(showOrderId: v)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Printing preferences ────────────────────────────────────
            _SettingsCard(
              icon: Icons.print_rounded,
              title: 'Printing Preferences',
              children: [
                _DropdownRow<String>(
                  label: 'Paper Size',
                  value: s.paperSize,
                  items: const ['58mm', '80mm'],
                  onChanged: (v) =>
                      _save(context, (x) => x.copyWith(paperSize: v)),
                ),
                _DropdownRow<String>(
                  label: 'Font Size',
                  value: s.fontSize,
                  items: const ['small', 'medium', 'large'],
                  labels: const ['Small', 'Medium', 'Large'],
                  onChanged: (v) =>
                      _save(context, (x) => x.copyWith(fontSize: v)),
                ),
                _DropdownRow<String>(
                  label: 'Text Alignment',
                  value: s.textAlignment,
                  items: const ['left', 'center', 'right'],
                  labels: const ['Left', 'Center', 'Right'],
                  onChanged: (v) =>
                      _save(context, (x) => x.copyWith(textAlignment: v)),
                ),
                _SwitchRow(
                  label: 'Auto Print After Checkout',
                  value: s.autoPrintAfterCheckout,
                  onChanged: (v) => _save(
                    context,
                    (x) => x.copyWith(autoPrintAfterCheckout: v),
                  ),
                ),
                _SwitchRow(
                  label: 'Print Duplicate Copy',
                  value: s.printDuplicateCopy,
                  onChanged: (v) =>
                      _save(context, (x) => x.copyWith(printDuplicateCopy: v)),
                ),
                _SwitchRow(
                  label: 'Thermal Printer Support',
                  subtitle:
                      'Direct-print to your POS thermal printer (skip dialog)',
                  value: s.thermalPrinterEnabled,
                  onChanged: (v) => _save(
                    context,
                    (x) => x.copyWith(thermalPrinterEnabled: v),
                  ),
                ),
                if (s.thermalPrinterEnabled) ...[
                  const SizedBox(height: 8),
                  _PrinterSelector(enabled: s.thermalPrinterEnabled),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // ── Currency & tax ──────────────────────────────────────────
            _SettingsCard(
              icon: IconlyBold.wallet,
              title: 'Currency & Tax',
              children: [
                _FieldRow(
                  label: 'Currency Symbol',
                  value: s.currencySymbol,
                  hint: '₱',
                  onChanged: (v) =>
                      _save(context, (x) => x.copyWith(currencySymbol: v)),
                ),
                _PercentRow(
                  label: 'Tax Percentage (%)',
                  value: s.taxPercentage,
                  onChanged: (v) =>
                      _save(context, (x) => x.copyWith(taxPercentage: v)),
                ),
                _PercentRow(
                  label: 'Service Charge (%)',
                  value: s.serviceChargePercentage,
                  onChanged: (v) => _save(
                    context,
                    (x) => x.copyWith(serviceChargePercentage: v),
                  ),
                ),
                _SwitchRow(
                  label: 'VAT Inclusive',
                  subtitle: 'Price already includes tax',
                  value: s.vatInclusive,
                  onChanged: (v) =>
                      _save(context, (x) => x.copyWith(vatInclusive: v)),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  void _save(
    BuildContext context,
    ReceiptSettings Function(ReceiptSettings) patch,
  ) {
    context.read<SettingsCubit>().update(patch);
  }
}

// ── Preview banner ────────────────────────────────────────────────────────────

class _PreviewBanner extends StatelessWidget {
  final ReceiptSettings settings;
  const _PreviewBanner({required this.settings});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BlocProvider.value(
          value: context.read<SettingsCubit>(),
          child: DraggableScrollableSheet(
            initialChildSize: 0.92,
            minChildSize: 0.5,
            maxChildSize: 0.96,
            builder: (_, ctrl) => Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderSoft,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          'Receipt Preview',
                          style: getOutfitStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: ctrl,
                      padding: const EdgeInsets.all(20),
                      child: ReceiptPreview(settings: settings),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.brandSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.brand.withAlpha(50)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                IconlyLight.paper,
                size: 20,
                color: AppColors.textInverse,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview Receipt',
                    style: getOutfitStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brand,
                    ),
                  ),
                  Text(
                    'Tap to see how your receipt looks',
                    style: getOutfitStyle(
                      fontSize: 12,
                      color: AppColors.brand.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              IconlyLight.arrow_right,
              size: 14,
              color: AppColors.brand,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Logo picker ───────────────────────────────────────────────────────────────

class _LogoPicker extends StatelessWidget {
  final ReceiptSettings settings;
  const _LogoPicker({required this.settings});

  @override
  Widget build(BuildContext context) {
    final hasLogo =
        settings.logoLocalPath.isNotEmpty || settings.logoUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo preview
        if (hasLogo)
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildLogoImage(settings),
            ),
          ),
        const SizedBox(height: 10),
        BlocBuilder<SettingsCubit, SettingsState>(
          buildWhen: (p, c) => p.isUploadingLogo != c.isUploadingLogo,
          builder: (ctx, state) {
            if (state.isUploadingLogo) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.brand,
                  ),
                ),
              );
            }
            return SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _pick(ctx),
                icon: const Icon(IconlyLight.upload, size: 18),
                label: Text(hasLogo ? 'Change Logo' : 'Upload Logo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brand,
                  side: const BorderSide(color: AppColors.brand),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLogoImage(ReceiptSettings s) {
    if (s.logoLocalPath.isNotEmpty && !kIsWeb) {
      return Image.file(File(s.logoLocalPath), fit: BoxFit.contain);
    }
    if (s.logoUrl.isNotEmpty) {
      return Image.network(s.logoUrl, fit: BoxFit.contain);
    }
    return const SizedBox.shrink();
  }

  Future<void> _pick(BuildContext context) async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;
    final businessId = auth.user.businessId ?? '';

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (!context.mounted) return;

    // Capture cubit reference before any async gap to avoid BuildContext leak.
    final cubit = context.read<SettingsCubit>();

    final bytes = await picked.readAsBytes();
    final ext = picked.name.split('.').last.toLowerCase();
    final mimeType = _mimeFromExt(ext);

    await cubit.uploadLogo(
      businessId: businessId,
      fileName: 'logo_${DateTime.now().millisecondsSinceEpoch}.$ext',
      bytes: bytes,
      mimeType: mimeType,
      localPath: kIsWeb ? null : picked.path,
    );
  }

  String _mimeFromExt(String ext) => switch (ext) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };
}

// ── Shared card wrapper ───────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.brand),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: getOutfitStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.borderSoft),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Field row ─────────────────────────────────────────────────────────────────

class _FieldRow extends StatefulWidget {
  final String label;
  final String value;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;
  final ValueChanged<String> onChanged;

  const _FieldRow({
    required this.label,
    required this.value,
    this.hint = '',
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    required this.onChanged,
  });

  @override
  State<_FieldRow> createState() => _FieldRowState();
}

class _FieldRowState extends State<_FieldRow> {
  late final TextEditingController _ctrl;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_FieldRow old) {
    super.didUpdateWidget(old);
    // Only sync from parent if user isn't actively editing
    if (!_isDirty && old.value != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: getOutfitStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _ctrl,
            maxLines: widget.maxLines,
            keyboardType: widget.keyboardType,
            style: getOutfitStyle(fontSize: 13.5, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: getOutfitStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
              filled: true,
              fillColor: AppColors.surfaceAlt,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
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
                borderSide: const BorderSide(
                  color: AppColors.brand,
                  width: 1.5,
                ),
              ),
            ),
            onChanged: (v) {
              _isDirty = true;
              widget.onChanged(v);
            },
            onEditingComplete: () => _isDirty = false,
          ),
        ],
      ),
    );
  }
}

// ── Printer selector ──────────────────────────────────────────────────────────

class _PrinterSelector extends StatefulWidget {
  final bool enabled;
  const _PrinterSelector({required this.enabled});

  @override
  State<_PrinterSelector> createState() => _PrinterSelectorState();
}

class _PrinterSelectorState extends State<_PrinterSelector> {
  String _printerName = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final name = await ReceiptPrinterService.loadPrinterName();
    if (mounted) setState(() => _printerName = name);
  }

  Future<void> _pickPrinter() async {
    setState(() => _loading = true);
    try {
      final printers = await Printing.listPrinters();
      if (!mounted) return;
      if (printers.isEmpty) {
        AppToast.show(
          context,
          'No printers found',
          subtitle: 'No printers were detected on this device.',
          variant: AppToastVariant.error,
        );
        return;
      }
      final chosen = await showDialog<Printer>(
        context: context,
        builder: (_) => SimpleDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Select Thermal Printer',
            style: getOutfitStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          children: printers
              .map(
                (p) => SimpleDialogOption(
                  onPressed: () => Navigator.of(context).pop(p),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.print_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            p.name,
                            style: getOutfitStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      );
      if (chosen != null) {
        await ReceiptPrinterService.savePrinter(
          url: chosen.url,
          name: chosen.name,
        );
        if (mounted) setState(() => _printerName = chosen.name);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _clearPrinter() async {
    await ReceiptPrinterService.clearPrinter();
    if (mounted) setState(() => _printerName = '');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.print_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Configured Printer',
                style: getOutfitStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _printerName.isEmpty ? 'No printer selected' : _printerName,
            style: getOutfitStyle(
              fontSize: 13,
              fontWeight: _printerName.isEmpty
                  ? FontWeight.w400
                  : FontWeight.w600,
              color: _printerName.isEmpty
                  ? AppColors.textMuted
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _pickPrinter,
                  icon: _loading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.brand,
                          ),
                        )
                      : const Icon(IconlyLight.search, size: 16),
                  label: Text(
                    _printerName.isEmpty ? 'Select Printer' : 'Change Printer',
                    style: getOutfitStyle(fontSize: 12.5),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brand,
                    side: const BorderSide(color: AppColors.brand),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              if (_printerName.isNotEmpty) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _loading ? null : _clearPrinter,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Icon(IconlyLight.delete, size: 16),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Switch row ────────────────────────────────────────────────────────────────

class _SwitchRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: getOutfitStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: getOutfitStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.brand,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

// ── Dropdown row ──────────────────────────────────────────────────────────────

class _DropdownRow<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final List<String>? labels;
  final ValueChanged<T> onChanged;

  const _DropdownRow({
    required this.label,
    required this.value,
    required this.items,
    this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: getOutfitStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                items: items.asMap().entries.map((e) {
                  final display = labels != null
                      ? labels![e.key]
                      : '${e.value}';
                  return DropdownMenuItem<T>(
                    value: e.value,
                    child: Text(
                      display,
                      style: getOutfitStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
                style: getOutfitStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                dropdownColor: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Percentage row ────────────────────────────────────────────────────────────

class _PercentRow extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _PercentRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_PercentRow> createState() => _PercentRowState();
}

class _PercentRowState extends State<_PercentRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.value == 0 ? '' : widget.value.toString(),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.label,
              style: getOutfitStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: TextFormField(
              controller: _ctrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              style: getOutfitStyle(
                fontSize: 13.5,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                suffixText: '%',
                suffixStyle: getOutfitStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
                filled: true,
                fillColor: AppColors.surfaceAlt,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
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
                  borderSide: const BorderSide(
                    color: AppColors.brand,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (v) {
                final parsed = double.tryParse(v);
                if (parsed != null && parsed >= 0 && parsed <= 100) {
                  widget.onChanged(parsed);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
