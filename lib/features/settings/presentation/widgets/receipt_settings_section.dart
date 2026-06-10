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

import 'package:pos/core/widgets/app_filled_button.dart';
import 'package:pos/core/widgets/app_input_decoration.dart';
import 'package:pos/core/widgets/app_labeled_switch.dart';
import 'package:pos/core/widgets/app_section_card.dart';
import 'package:pos/core/widgets/app_switch.dart';
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ── Paper & Format ─────────────────────────────────────────────
        _PrintingCard(
          icon: Icons.straighten_rounded,
          title: 'Paper & Format',
          subtitle: 'Set roll width, font size, and alignment',
          children: [
            _PickerRow(
              label: 'Paper Size',
              child: _SegmentedPicker<String>(
                items: const ['58mm', '80mm'],
                labels: const ['58 mm', '80 mm'],
                value: s.paperSize,
                onChanged: (v) =>
                    _save(context, (x) => x.copyWith(paperSize: v)),
              ),
            ),
            const SizedBox(height: 12),
            _PickerRow(
              label: 'Font Size',
              child: _SegmentedPicker<String>(
                items: const ['small', 'medium', 'large'],
                labels: const ['Small', 'Medium', 'Large'],
                value: s.fontSize,
                onChanged: (v) =>
                    _save(context, (x) => x.copyWith(fontSize: v)),
              ),
            ),
            const SizedBox(height: 12),
            _PickerRow(
              label: 'Text Alignment',
              child: _SegmentedPicker<String>(
                items: const ['left', 'center', 'right'],
                labels: const ['Left', 'Center', 'Right'],
                value: s.textAlignment,
                onChanged: (v) =>
                    _save(context, (x) => x.copyWith(textAlignment: v)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ── Print Behaviour ────────────────────────────────────────────
        _PrintingCard(
          icon: Icons.tune_rounded,
          title: 'Print Behaviour',
          subtitle: 'Control how and when receipts print',
          children: [
            _BehaviourRow(
              icon: Icons.bolt_rounded,
              iconColor: AppColors.warning,
              iconBg: AppColors.warningSoft,
              label: 'Auto Print After Checkout',
              subtitle: 'Prints receipt automatically when sale completes',
              value: s.autoPrintAfterCheckout,
              onChanged: (v) =>
                  _save(context, (x) => x.copyWith(autoPrintAfterCheckout: v)),
            ),
            const _ThinDivider(),
            _BehaviourRow(
              icon: Icons.copy_rounded,
              iconColor: AppColors.info,
              iconBg: AppColors.infoSoft,
              label: 'Print Duplicate Copy',
              subtitle: 'Prints a second copy for the customer',
              value: s.printDuplicateCopy,
              onChanged: (v) =>
                  _save(context, (x) => x.copyWith(printDuplicateCopy: v)),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ── Thermal Printer ────────────────────────────────────────────
        _PrintingCard(
          icon: Icons.print_rounded,
          title: 'Thermal Printer',
          subtitle: 'Direct-print without a system dialog',
          trailing: AppSwitch(
            value: s.thermalPrinterEnabled,
            onChanged: (v) =>
                _save(context, (x) => x.copyWith(thermalPrinterEnabled: v)),
          ),
          children: [
            if (s.thermalPrinterEnabled) ...[
              const SizedBox(height: 4),
              _PrinterSelector(enabled: s.thermalPrinterEnabled),
            ],
          ],
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Premium printing card ─────────────────────────────────────────────────────

class _PrintingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? trailing;

  const _PrintingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06101828),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.brand),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: getOutfitStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: getOutfitStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          if (children.isNotEmpty) ...[
            Divider(
              color: AppColors.borderSoft,
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Picker row with inline label ──────────────────────────────────────────────

class _PickerRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _PickerRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: getOutfitStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}

// ── Behaviour row with icon ───────────────────────────────────────────────────

class _BehaviourRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _BehaviourRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: getOutfitStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: getOutfitStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ── Thin divider between behaviour rows ──────────────────────────────────────

class _ThinDivider extends StatelessWidget {
  const _ThinDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(color: AppColors.borderSoft, height: 16);
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
  String _printerUrl = '';

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final name = await ReceiptPrinterService.loadPrinterName();
    final url = await ReceiptPrinterService.loadPrinterUrl();
    if (mounted) {
      setState(() {
        _printerName = name;
        _printerUrl = url;
      });
    }
  }

  Future<void> _openDialog() async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withAlpha(100),
      builder: (_) => const _PrinterDialog(),
    );
    await _loadSaved();
  }

  Future<void> _clearPrinter() async {
    await ReceiptPrinterService.clearPrinter();
    if (mounted) {
      setState(() {
        _printerName = '';
        _printerUrl = '';
      });
      AppToast.show(
        context,
        'Printer disconnected',
        variant: AppToastVariant.info,
      );
    }
  }

  IconData _iconForUrl(String url) {
    if (url.contains('usb')) return Icons.usb_rounded;
    if (url.contains('bluetooth')) return Icons.bluetooth_rounded;
    return Icons.wifi_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (_printerName.isEmpty) {
      return _buildEmpty();
    }
    return _buildActive();
  }

  Widget _buildEmpty() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status row
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'No printer connected',
              style: getOutfitStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // CTA button full width
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _openDialog,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(
              'Connect a Printer',
              style: getOutfitStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brand,
              side: const BorderSide(color: AppColors.brand),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActive() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Connected status chip
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Connected',
              style: getOutfitStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Printer info row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                _iconForUrl(_printerUrl),
                size: 17,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _printerName,
                    style: getOutfitStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _printerUrl.startsWith('custom://')
                        ? _printerUrl.replaceFirst('custom://', '')
                        : 'System printer',
                    style: getOutfitStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            // Change button
            GestureDetector(
              onTap: _openDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Change',
                  style: getOutfitStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brand,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Disconnect button
            GestureDetector(
              onTap: _clearPrinter,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.errorSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Printer setup dialog (bottom sheet) ──────────────────────────────────────

class _PrinterDialog extends StatefulWidget {
  const _PrinterDialog();

  @override
  State<_PrinterDialog> createState() => _PrinterDialogState();
}

class _PrinterDialogState extends State<_PrinterDialog> {
  int _tabIndex = 0;
  bool _scanning = false;
  bool _scanDone = false;
  List<Printer> _scanResults = [];
  List<CustomPrinterEntry> _customPrinters = [];
  String _activePrinterUrl = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _startScan();
  }

  Future<void> _loadData() async {
    final custom = await ReceiptPrinterService.loadCustomPrinters();
    final url = await ReceiptPrinterService.loadPrinterUrl();
    if (mounted) {
      setState(() {
        _customPrinters = custom;
        _activePrinterUrl = url;
      });
    }
  }

  Future<void> _startScan() async {
    setState(() {
      _scanning = true;
      _scanDone = false;
      _scanResults = [];
    });
    try {
      final printers = await Printing.listPrinters();
      if (mounted) {
        setState(() => _scanResults = printers);
      }
    } catch (_) {
      // scan failure is non-fatal — show empty state
    } finally {
      if (mounted) {
        setState(() {
          _scanning = false;
          _scanDone = true;
        });
      }
    }
  }

  // ── Connect actions ──────────────────────────────────────────────────

  Future<void> _selectScanned(Printer printer) async {
    final previousName = await ReceiptPrinterService.loadPrinterName();
    await ReceiptPrinterService.savePrinter(
      url: printer.url,
      name: printer.name,
    );
    if (!mounted) return;
    final isSwitch = previousName.isNotEmpty && previousName != printer.name;
    AppToast.show(
      context,
      isSwitch ? 'Switched to ${printer.name}' : 'Connected',
      subtitle: isSwitch ? null : printer.name,
      variant: isSwitch ? AppToastVariant.info : AppToastVariant.success,
    );
    Navigator.of(context).pop();
  }

  Future<void> _selectCustom(CustomPrinterEntry entry) async {
    final previousName = await ReceiptPrinterService.loadPrinterName();
    await ReceiptPrinterService.savePrinter(
      url: ReceiptPrinterService.customPrinterUrl(entry.ip),
      name: entry.name,
    );
    if (!mounted) return;
    final isSwitch = previousName.isNotEmpty && previousName != entry.name;
    AppToast.show(
      context,
      isSwitch ? 'Switched to ${entry.name}' : 'Connected',
      subtitle: isSwitch ? null : entry.name,
      variant: isSwitch ? AppToastVariant.info : AppToastVariant.success,
    );
    Navigator.of(context).pop();
  }

  Future<void> _deleteCustom(CustomPrinterEntry entry) async {
    await ReceiptPrinterService.removeCustomPrinter(entry.ip);
    final updated = await ReceiptPrinterService.loadCustomPrinters();
    final activeUrl = await ReceiptPrinterService.loadPrinterUrl();
    if (mounted) {
      setState(() {
        _customPrinters = updated;
        _activePrinterUrl = activeUrl;
      });
      AppToast.show(
        context,
        'Printer removed',
        variant: AppToastVariant.info,
      );
    }
  }

  Future<void> _saveManual(String name, String ip) async {
    final existing = await ReceiptPrinterService.loadCustomPrinters();
    if (existing.any((e) => e.ip == ip)) {
      if (mounted) {
        AppToast.show(
          context,
          'Already saved',
          subtitle: 'A printer at $ip is already in your list.',
          variant: AppToastVariant.info,
        );
        Navigator.of(context).pop();
      }
      return;
    }
    final entry = CustomPrinterEntry(name: name, ip: ip);
    await ReceiptPrinterService.addCustomPrinter(entry);
    await ReceiptPrinterService.savePrinter(
      url: ReceiptPrinterService.customPrinterUrl(ip),
      name: name,
    );
    if (mounted) {
      AppToast.show(
        context,
        'Printer added',
        subtitle: '$name is ready to use.',
        variant: AppToastVariant.success,
      );
      Navigator.of(context).pop();
    }
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenW > 600 ? 80 : 24,
        vertical: 40,
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: 480, maxHeight: screenH * 0.78),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22101828),
              blurRadius: 40,
              offset: Offset(0, 16),
            ),
            BoxShadow(
              color: Color(0x0A101828),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.print_rounded,
                      size: 20,
                      color: AppColors.brand,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Printer Setup',
                          style: getOutfitStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Find or add a thermal printer',
                          style: getOutfitStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    splashRadius: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Tab bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Row(
                  children: [
                    _TabChip(
                      label: 'Search',
                      active: _tabIndex == 0,
                      onTap: () => setState(() => _tabIndex = 0),
                    ),
                    _TabChip(
                      label: 'Add Manually',
                      active: _tabIndex == 1,
                      onTap: () => setState(() => _tabIndex = 1),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Divider(color: AppColors.borderSoft, height: 1),

            // ── Tab body ─────────────────────────────────────────────
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _tabIndex == 0
                    ? _PrinterSearchTab(
                        key: const ValueKey('search'),
                        scanning: _scanning,
                        scanDone: _scanDone,
                        results: _scanResults,
                        customPrinters: _customPrinters,
                        activePrinterUrl: _activePrinterUrl,
                        onSelectScanned: _selectScanned,
                        onSelectCustom: _selectCustom,
                        onDeleteCustom: _deleteCustom,
                        onRetry: _startScan,
                      )
                    : _PrinterManualTab(
                        key: const ValueKey('manual'),
                        onSave: _saveManual,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab chip ──────────────────────────────────────────────────────────────────

class _TabChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: active ? AppColors.brand : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: getOutfitStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Search tab ────────────────────────────────────────────────────────────────

class _PrinterSearchTab extends StatelessWidget {
  final bool scanning;
  final bool scanDone;
  final List<Printer> results;
  final List<CustomPrinterEntry> customPrinters;
  final String activePrinterUrl;
  final Future<void> Function(Printer) onSelectScanned;
  final Future<void> Function(CustomPrinterEntry) onSelectCustom;
  final Future<void> Function(CustomPrinterEntry) onDeleteCustom;
  final VoidCallback onRetry;

  const _PrinterSearchTab({
    super.key,
    required this.scanning,
    required this.scanDone,
    required this.results,
    required this.customPrinters,
    required this.activePrinterUrl,
    required this.onSelectScanned,
    required this.onSelectCustom,
    required this.onDeleteCustom,
    required this.onRetry,
  });

  static IconData _iconForUrl(String url) {
    if (url.contains('usb')) return Icons.usb_rounded;
    if (url.contains('bluetooth')) return Icons.bluetooth_rounded;
    return Icons.wifi_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (scanning) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: AppColors.brand,
                strokeWidth: 2.5,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Searching for printers…',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      );
    }

    final hasContent = results.isNotEmpty || customPrinters.isNotEmpty;

    if (scanDone && !hasContent) {
      return Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.print_disabled_rounded,
              size: 42,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No printers detected',
              style: getOutfitStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Make sure your printer is on and\nconnected to the same network.',
              textAlign: TextAlign.center,
              style: getOutfitStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                'Try Again',
                style: getOutfitStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brand,
                side: const BorderSide(color: AppColors.brand),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (customPrinters.isNotEmpty) ...[
          _SectionLabel('Saved Printers'),
          ...customPrinters.map(
            (e) => _SavedPrinterTile(
              entry: e,
              isActive:
                  activePrinterUrl == ReceiptPrinterService.customPrinterUrl(e.ip),
              onSelect: () => onSelectCustom(e),
              onDelete: () => onDeleteCustom(e),
            ),
          ),
        ],
        if (customPrinters.isNotEmpty && results.isNotEmpty)
          const SizedBox(height: 8),
        if (results.isNotEmpty) ...[
          _SectionLabel('Found on Network'),
          ...results.map(
            (p) => _ScannedPrinterTile(
              printer: p,
              isActive: activePrinterUrl == p.url,
              onSelect: () => onSelectScanned(p),
              iconData: _iconForUrl(p.url),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6, top: 2),
      child: Text(
        label.toUpperCase(),
        style: getOutfitStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ── Scanned printer tile ──────────────────────────────────────────────────────

class _ScannedPrinterTile extends StatelessWidget {
  final Printer printer;
  final bool isActive;
  final VoidCallback onSelect;
  final IconData iconData;

  const _ScannedPrinterTile({
    required this.printer,
    required this.isActive,
    required this.onSelect,
    required this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.brandSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppColors.brand.withAlpha(80)
                : AppColors.borderSoft,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isActive ? AppColors.brand.withAlpha(25) : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                iconData,
                size: 16,
                color: isActive ? AppColors.brand : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    printer.name,
                    style: getOutfitStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isActive ? AppColors.brand : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _PrinterTypeBadge(printer.url),
                ],
              ),
            ),
            if (isActive)
              const Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: AppColors.success,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Saved (manual) printer tile ───────────────────────────────────────────────

class _SavedPrinterTile extends StatelessWidget {
  final CustomPrinterEntry entry;
  final bool isActive;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  const _SavedPrinterTile({
    required this.entry,
    required this.isActive,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.brandSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppColors.brand.withAlpha(80)
                : AppColors.borderSoft,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isActive ? AppColors.brand.withAlpha(25) : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.wifi_rounded,
                size: 16,
                color: isActive ? AppColors.brand : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: getOutfitStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isActive ? AppColors.brand : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    entry.ip,
                    style: getOutfitStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              const Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: AppColors.success,
              )
            else
              GestureDetector(
                onTap: onDelete,
                child: const Icon(
                  IconlyLight.delete,
                  size: 17,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Printer type badge ────────────────────────────────────────────────────────

class _PrinterTypeBadge extends StatelessWidget {
  final String url;
  const _PrinterTypeBadge(this.url);

  ({String label, Color color}) get _meta {
    if (url.contains('usb')) {
      return (label: 'USB', color: AppColors.textSecondary);
    }
    if (url.contains('bluetooth')) {
      return (label: 'Bluetooth', color: AppColors.brand);
    }
    if (url.startsWith('custom://')) {
      return (label: 'Wi-Fi', color: AppColors.info);
    }
    return (label: 'Network', color: AppColors.info);
  }

  @override
  Widget build(BuildContext context) {
    final m = _meta;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: m.color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        m.label,
        style: getOutfitStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: m.color,
        ),
      ),
    );
  }
}

// ── Manual tab ────────────────────────────────────────────────────────────────

class _PrinterManualTab extends StatefulWidget {
  final Future<void> Function(String name, String ip) onSave;

  const _PrinterManualTab({super.key, required this.onSave});

  @override
  State<_PrinterManualTab> createState() => _PrinterManualTabState();
}

class _PrinterManualTabState extends State<_PrinterManualTab> {
  final _nameCtrl = TextEditingController();
  final _ipCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ipCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(_nameCtrl.text.trim(), _ipCtrl.text.trim());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Printer Name',
              style: getOutfitStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              style: getOutfitStyle(
                fontSize: 13.5,
                color: AppColors.textPrimary,
              ),
              decoration: appInputDeco(
                'e.g. Counter Printer',
                fillColor: AppColors.surfaceAlt,
                radius: 10,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a printer name' : null,
            ),
            const SizedBox(height: 16),
            Text(
              'IP Address',
              style: getOutfitStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _ipCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: getOutfitStyle(
                fontSize: 13.5,
                color: AppColors.textPrimary,
              ),
              decoration: appInputDeco(
                'e.g. 192.168.1.100',
                fillColor: AppColors.surfaceAlt,
                radius: 10,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter an IP address';
                if (!RegExp(r'^(\d{1,3}\.){3}\d{1,3}$').hasMatch(v.trim())) {
                  return 'Enter a valid IP (e.g. 192.168.1.100)';
                }
                return null;
              },
            ),
            const SizedBox(height: 6),
            Text(
              'Find the IP in your printer\'s settings or printed label.',
              style: getOutfitStyle(fontSize: 11.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            AppFilledButton(
              label: 'Add Printer',
              icon: Icons.add_rounded,
              loading: _saving,
              onPressed: _submit,
            ),
            const SizedBox(height: 4),
          ],
        ),
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
