import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

import 'package:pos/core/widgets/app_labeled_switch.dart';
import 'package:pos/core/widgets/app_section_card.dart';
import 'package:pos/core/widgets/app_toast.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/settings/domain/receipt_settings.dart';
import 'package:pos/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:pos/features/settings/presentation/widgets/receipt_preview.dart';
import 'package:pos/features/settings/services/receipt_printer_service.dart';

// ── Tab 1: Business ───────────────────────────────────────────────────────────

class BusinessTab extends StatelessWidget {
  final ReceiptSettings settings;
  const BusinessTab({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final s = settings;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppSectionCard(
          icon: IconlyLight.work,
          title: 'Business Details',
          children: [
            _ReadOnlyRow(label: 'Business Name', value: s.businessName),
            const _Divider(),
            _ReadOnlyRow(label: 'Branch', value: s.storeName),
            const _Divider(),
            _ReadOnlyRow(label: 'Email', value: s.email),
            const _Divider(),
            _EditableRow(
              label: 'Address',
              value: s.address,
              placeholder: 'Add address',
              hint: '123 Main St, City',
              maxLines: 2,
              onChanged: (v) => _save(context, (x) => x.copyWith(address: v)),
            ),
            const _Divider(),
            _EditableRow(
              label: 'Contact No.',
              value: s.contactNumber,
              placeholder: 'Add contact number',
              hint: '+63 912 345 6789',
              keyboardType: TextInputType.phone,
              onChanged: (v) =>
                  _save(context, (x) => x.copyWith(contactNumber: v)),
            ),
            const _Divider(),
            _EditableRow(
              label: 'Website / Social',
              value: s.website,
              placeholder: 'Add website or social',
              hint: 'www.mybusiness.com',
              onChanged: (v) => _save(context, (x) => x.copyWith(website: v)),
            ),
            const _Divider(),
            _EditableRow(
              label: 'TIN Number',
              value: s.tinNumber,
              placeholder: 'Add TIN',
              hint: '000-000-000-000',
              onChanged: (v) => _save(context, (x) => x.copyWith(tinNumber: v)),
            ),
            const _Divider(),
            _EditableRow(
              label: 'Permit No.',
              value: s.permitNumber,
              placeholder: 'Add permit number',
              hint: 'BIR-2024-0001',
              onChanged: (v) =>
                  _save(context, (x) => x.copyWith(permitNumber: v)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _LogoBanner(),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Tab 2: Receipt ────────────────────────────────────────────────────────────

class ReceiptTab extends StatelessWidget {
  final ReceiptSettings settings;
  const ReceiptTab({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final s = settings;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppSectionCard(
          icon: Icons.text_fields_rounded,
          title: 'Receipt Text',
          children: [
            _CompactFieldRow(
              label: 'Header',
              value: s.headerText,
              hint: 'Appears at the top of every receipt',
              onChanged: (v) =>
                  _save(context, (x) => x.copyWith(headerText: v)),
            ),
            const _Divider(),
            _CompactFieldRow(
              label: 'Footer',
              value: s.footerText,
              hint: 'Thank you for your purchase!',
              onChanged: (v) =>
                  _save(context, (x) => x.copyWith(footerText: v)),
            ),
            const _Divider(),
            _CompactFieldRow(
              label: 'Return Policy',
              value: s.returnPolicy,
              hint: 'No returns after 7 days...',
              onChanged: (v) =>
                  _save(context, (x) => x.copyWith(returnPolicy: v)),
            ),
            const _Divider(),
            _CompactFieldRow(
              label: 'Custom Notes',
              value: s.customNotes,
              hint: 'Any additional notes',
              onChanged: (v) =>
                  _save(context, (x) => x.copyWith(customNotes: v)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _CollapsibleSectionCard(
          icon: Icons.toggle_on_rounded,
          title: 'Show on Receipt',
          children: [
            AppLabeledSwitch(
              label: 'Business Logo',
              value: s.showLogo,
              onChanged: (v) => _save(context, (x) => x.copyWith(showLogo: v)),
            ),
            const _Divider(),
            AppLabeledSwitch(
              label: 'Order ID / Invoice No.',
              value: s.showOrderId,
              onChanged: (v) =>
                  _save(context, (x) => x.copyWith(showOrderId: v)),
            ),
            const _Divider(),
            AppLabeledSwitch(
              label: 'Date & Time',
              value: s.showDateTime,
              onChanged: (v) =>
                  _save(context, (x) => x.copyWith(showDateTime: v)),
            ),
            const _Divider(),
            AppLabeledSwitch(
              label: 'Cashier Name',
              value: s.showCashierName,
              onChanged: (v) =>
                  _save(context, (x) => x.copyWith(showCashierName: v)),
            ),
            const _Divider(),
            AppLabeledSwitch(
              label: 'Customer Name',
              value: s.showCustomerName,
              onChanged: (v) =>
                  _save(context, (x) => x.copyWith(showCustomerName: v)),
            ),
            const _Divider(),
            AppLabeledSwitch(
              label: 'Tax Breakdown',
              value: s.showTaxBreakdown,
              onChanged: (v) =>
                  _save(context, (x) => x.copyWith(showTaxBreakdown: v)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _PreviewBanner(settings: s),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Tab 3: Printing ───────────────────────────────────────────────────────────

class PrintingTab extends StatelessWidget {
  final ReceiptSettings settings;
  const PrintingTab({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final s = settings;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppSectionCard(
          icon: Icons.print_rounded,
          title: 'Paper & Format',
          children: [
            _LabeledPicker(label: 'Paper Size'),
            const SizedBox(height: 8),
            _SegmentedPicker<String>(
              items: const ['58mm', '80mm'],
              labels: const ['58 mm', '80 mm'],
              value: s.paperSize,
              onChanged: (v) => _save(context, (x) => x.copyWith(paperSize: v)),
            ),
            const SizedBox(height: 16),
            _LabeledPicker(label: 'Font Size'),
            const SizedBox(height: 8),
            _SegmentedPicker<String>(
              items: const ['small', 'medium', 'large'],
              labels: const ['Small', 'Medium', 'Large'],
              value: s.fontSize,
              onChanged: (v) => _save(context, (x) => x.copyWith(fontSize: v)),
            ),
            const SizedBox(height: 16),
            _LabeledPicker(label: 'Text Alignment'),
            const SizedBox(height: 8),
            _SegmentedPicker<String>(
              items: const ['left', 'center', 'right'],
              labels: const ['Left', 'Center', 'Right'],
              value: s.textAlignment,
              onChanged: (v) =>
                  _save(context, (x) => x.copyWith(textAlignment: v)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          icon: Icons.settings_rounded,
          title: 'Print Behaviour',
          children: [
            AppLabeledSwitch(
              label: 'Auto Print After Checkout',
              value: s.autoPrintAfterCheckout,
              onChanged: (v) =>
                  _save(context, (x) => x.copyWith(autoPrintAfterCheckout: v)),
            ),
            const _Divider(),
            AppLabeledSwitch(
              label: 'Print Duplicate Copy',
              value: s.printDuplicateCopy,
              onChanged: (v) =>
                  _save(context, (x) => x.copyWith(printDuplicateCopy: v)),
            ),
            const _Divider(),
            AppLabeledSwitch(
              label: 'Thermal Printer',
              subtitle:
                  'Direct-print to your POS thermal printer (skip dialog)',
              value: s.thermalPrinterEnabled,
              onChanged: (v) =>
                  _save(context, (x) => x.copyWith(thermalPrinterEnabled: v)),
            ),
            if (s.thermalPrinterEnabled) ...[
              const SizedBox(height: 14),
              _PrinterSelector(enabled: s.thermalPrinterEnabled),
            ],
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Shared save helper ────────────────────────────────────────────────────────

void _save(
  BuildContext context,
  ReceiptSettings Function(ReceiptSettings) patch,
) {
  context.read<SettingsCubit>().update(patch);
}

// ── Preview banner ────────────────────────────────────────────────────────────

class _PreviewBanner extends StatelessWidget {
  final ReceiptSettings settings;
  const _PreviewBanner({required this.settings});

  void _showPreview(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'receipt-preview',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim, _) => _ReceiptPreviewOverlay(settings: settings),
      transitionBuilder: (ctx, anim, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.94,
              end: 1.0,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPreview(context),
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

// ── Receipt preview overlay ───────────────────────────────────────────────────

class _ReceiptPreviewOverlay extends StatelessWidget {
  final ReceiptSettings settings;
  const _ReceiptPreviewOverlay({required this.settings});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(color: Colors.black.withAlpha(120)),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 32,
                    horizontal: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ReceiptPreview(settings: settings),
                      const SizedBox(height: 20),
                      Text(
                        'Tap anywhere to close',
                        style: getOutfitStyle(
                          fontSize: 12,
                          color: Colors.white.withAlpha(140),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Segmented picker (replaces dropdowns for short option sets) ───────────────

class _SegmentedPicker<T> extends StatelessWidget {
  final List<T> items;
  final List<String> labels;
  final T value;
  final ValueChanged<T> onChanged;

  const _SegmentedPicker({
    required this.items,
    required this.labels,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final isActive = items[i] == value;
          final isFirst = i == 0;
          final isLast = i == items.length - 1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(items[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.brand : Colors.transparent,
                  borderRadius: BorderRadius.horizontal(
                    left: isFirst ? const Radius.circular(9) : Radius.zero,
                    right: isLast ? const Radius.circular(9) : Radius.zero,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: getOutfitStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Small label above a segmented picker ─────────────────────────────────────

class _LabeledPicker extends StatelessWidget {
  final String label;
  const _LabeledPicker({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: getOutfitStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

// ── Thin divider between switch rows ─────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Divider(height: 1, color: AppColors.borderSoft),
    );
  }
}

// ── Logo picker ───────────────────────────────────────────────────────────────

// ── Logo banner — one-time dismissible notice with CTA to Business Profile ────

class _LogoBanner extends StatefulWidget {
  const _LogoBanner();

  @override
  State<_LogoBanner> createState() => _LogoBannerState();
}

class _LogoBannerState extends State<_LogoBanner> {
  bool _hasLogo = false;
  bool _dismissed = false;
  bool _uploading = false;
  String? _businessId;

  static const _prefKey = 'receipt_logo_banner_dismissed';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthBloc>().state;
    _businessId = auth is AuthAuthenticated ? (auth.user.businessId ?? '') : '';
    final prefs = await SharedPreferences.getInstance();
    final logo = prefs.getString('biz_logo_$_businessId') ?? '';
    final dismissed = prefs.getBool(_prefKey) ?? false;
    if (mounted) {
      setState(() {
        _hasLogo = logo.isNotEmpty;
        _dismissed = dismissed;
      });
    }
  }

  Future<void> _pickLogo() async {
    if (_uploading || _businessId == null) return;

    final source = await _showSourceSheet();
    if (source == null) return;

    if (!kIsWeb && source == ImageSource.camera) {
      var status = await Permission.camera.status;
      if (status.isPermanentlyDenied) {
        if (!mounted) return;
        final open = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Camera Permission Required'),
            content: const Text(
              'Camera access is permanently denied. Enable it in App Settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        if (open != true) return;
        await openAppSettings();
        status = await Permission.camera.status;
      } else if (!status.isGranted) {
        status = await Permission.camera.request();
      }
      if (!status.isGranted) return;
    }

    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 512,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;

    // Capture before async gap
    final cubit = context.read<SettingsCubit>();

    setState(() => _uploading = true);
    try {
      final bytes = Uint8List.fromList(await picked.readAsBytes());
      final ext = p.extension(picked.path).toLowerCase();
      final safeExt = ext.isNotEmpty ? ext : '.jpg';
      final mimeType = safeExt == '.png'
          ? 'image/png'
          : safeExt == '.webp'
          ? 'image/webp'
          : 'image/jpeg';

      await cubit.uploadLogo(
        businessId: _businessId!,
        fileName: 'logo$safeExt',
        bytes: bytes,
        mimeType: mimeType,
      );

      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() => _hasLogo = true);
        await prefs.setString('biz_logo_$_businessId', 'uploaded');
        if (mounted) {
          AppToast.show(
            context,
            'Logo uploaded successfully',
            variant: AppToastVariant.success,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          'Upload failed: $e',
          variant: AppToastVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<ImageSource?> _showSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSoft,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Upload Business Logo',
                style: getOutfitStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Choose a square image for best results.',
                style: getOutfitStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 12),
            if (!kIsWeb)
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    IconlyLight.camera,
                    color: AppColors.brand,
                    size: 18,
                  ),
                ),
                title: Text(
                  'Take Photo',
                  style: getOutfitStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Open camera',
                  style: getOutfitStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  IconlyLight.image,
                  color: AppColors.brand,
                  size: 18,
                ),
              ),
              title: Text(
                'Choose from Gallery',
                style: getOutfitStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Browse your photos',
                style: getOutfitStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
    if (mounted) setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasLogo || _dismissed) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.brand.withAlpha(50)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(IconlyLight.info_circle, size: 17, color: AppColors.brand),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add your business logo',
                  style: getOutfitStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your logo will appear on every receipt you print.',
                  style: getOutfitStyle(
                    fontSize: 12,
                    color: AppColors.brand.withAlpha(180),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _uploading ? null : _pickLogo,
                  child: _uploading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.brand,
                          ),
                        )
                      : Text(
                          'Upload Logo →',
                          style: getOutfitStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brand,
                          ),
                        ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _dismiss,
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppColors.brand,
            ),
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

// ── Collapsible section card ──────────────────────────────────────────────────

class _CollapsibleSectionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _CollapsibleSectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  State<_CollapsibleSectionCard> createState() =>
      _CollapsibleSectionCardState();
}

class _CollapsibleSectionCardState extends State<_CollapsibleSectionCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _ctrl;
  late final Animation<double> _iconTurn;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 0.0, // starts collapsed
    );
    _iconTurn = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_expanded) {
      _ctrl.reverse();
    } else {
      _ctrl.forward();
    }
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07101828),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x04101828),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _toggle,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.brand.withAlpha(8),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(widget.icon, size: 17, color: AppColors.brand),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.title,
                    style: getOutfitStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                RotationTransition(
                  turns: _iconTurn,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: _expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [const SizedBox(height: 16), ...widget.children],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Read-only info row ────────────────────────────────────────────────────────

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: getOutfitStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value.isNotEmpty ? value : '—',
            style: getOutfitStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: value.isNotEmpty
                  ? AppColors.textPrimary
                  : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Compact field row (label left, value right, expands on tap) ──────────────

class _CompactFieldRow extends StatefulWidget {
  final String label;
  final String value;
  final String hint;
  final ValueChanged<String> onChanged;

  const _CompactFieldRow({
    required this.label,
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<_CompactFieldRow> createState() => _CompactFieldRowState();
}

class _CompactFieldRowState extends State<_CompactFieldRow> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;
  bool _expanded = false;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
    _focus = FocusNode()..addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focus.hasFocus && _expanded) {
      setState(() => _expanded = false);
      _isDirty = false;
    }
  }

  @override
  void didUpdateWidget(_CompactFieldRow old) {
    super.didUpdateWidget(old);
    if (!_isDirty && old.value != widget.value) _ctrl.text = widget.value;
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _open() {
    setState(() => _expanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.value.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _open,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      widget.label,
                      style: getOutfitStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _expanded
                            ? AppColors.brand
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEmpty ? widget.hint : widget.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: getOutfitStyle(
                        fontSize: 13,
                        fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w500,
                        color: isEmpty
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    IconlyLight.edit,
                    size: 13,
                    color: _expanded
                        ? AppColors.brand
                        : AppColors.textMuted.withAlpha(180),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    maxLines: 3,
                    style: getOutfitStyle(
                      fontSize: 13.5,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: getOutfitStyle(
                        fontSize: 13.5,
                        color: AppColors.textMuted,
                      ),
                      filled: true,
                      fillColor: AppColors.inputFill,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.brand,
                          width: 1.5,
                        ),
                      ),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      _isDirty = true;
                      widget.onChanged(v);
                      setState(() {});
                    },
                    onEditingComplete: () => _focus.unfocus(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ── Editable inline row ───────────────────────────────────────────────────────

class _EditableRow extends StatefulWidget {
  final String label;
  final String value;
  final String placeholder;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;
  final ValueChanged<String> onChanged;

  const _EditableRow({
    required this.label,
    required this.value,
    required this.placeholder,
    this.hint = '',
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    required this.onChanged,
  });

  @override
  State<_EditableRow> createState() => _EditableRowState();
}

class _EditableRowState extends State<_EditableRow> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;
  bool _expanded = false;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
    _focus = FocusNode()..addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focus.hasFocus && _expanded) {
      setState(() => _expanded = false);
      _isDirty = false;
    }
  }

  @override
  void didUpdateWidget(_EditableRow old) {
    super.didUpdateWidget(old);
    if (!_isDirty && old.value != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _open() {
    setState(() => _expanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.value.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Tappable display row ──────────────────────────────────────────
        GestureDetector(
          onTap: _open,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      widget.label,
                      style: getOutfitStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _expanded
                            ? AppColors.brand
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      isEmpty ? widget.placeholder : widget.value,
                      style: getOutfitStyle(
                        fontSize: 13,
                        fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w600,
                        color: isEmpty
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    IconlyLight.edit,
                    size: 13,
                    color: _expanded
                        ? AppColors.brand
                        : AppColors.textMuted.withAlpha(180),
                  ),
                ],
              ),
            ),
          ),
        ),
        // ── Input — slides in below when tapped ───────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    maxLines: widget.maxLines,
                    keyboardType: widget.keyboardType,
                    style: getOutfitStyle(
                      fontSize: 13.5,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: getOutfitStyle(
                        fontSize: 13.5,
                        color: AppColors.textMuted,
                      ),
                      filled: true,
                      fillColor: AppColors.inputFill,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.brand,
                          width: 1.5,
                        ),
                      ),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      _isDirty = true;
                      widget.onChanged(v);
                      setState(() {});
                    },
                    onEditingComplete: () => _focus.unfocus(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
