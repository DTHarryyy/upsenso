import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/widgets.dart';

class MoreOptionsCard extends StatefulWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final List<TextEditingController> barcodeControllers;
  final VoidCallback onAddBarcode;
  final void Function(int) onRemoveBarcode;
  final TextEditingController skuController;
  final VoidCallback onAutoSku;
  final TextEditingController taxController;
  final bool trackExpiry;
  final ValueChanged<bool> onTrackExpiryChanged;

  /// Expiry date text controller — updated by the parent when a date is
  /// picked. Avoids using [initialValue] + [key] which forces element
  /// disposal mid-build and triggers the defunct-element lifecycle error.
  final TextEditingController expiryController;
  final VoidCallback onPickExpiryDate;

  /// True when Track Expiry is on but no date is selected yet.
  final bool expiryRequired;

  final bool stockAlertEnabled;
  final ValueChanged<bool> onStockAlertChanged;
  final TextEditingController stockAlertController;

  const MoreOptionsCard({
    super.key,
    required this.expanded,
    required this.onToggle,
    required this.barcodeControllers,
    required this.onAddBarcode,
    required this.onRemoveBarcode,
    required this.skuController,
    required this.onAutoSku,
    required this.taxController,
    required this.trackExpiry,
    required this.onTrackExpiryChanged,
    required this.expiryController,
    required this.onPickExpiryDate,
    required this.expiryRequired,
    required this.stockAlertEnabled,
    required this.onStockAlertChanged,
    required this.stockAlertController,
  });

  @override
  State<MoreOptionsCard> createState() => _MoreOptionsCardState();
}

class _MoreOptionsCardState extends State<MoreOptionsCard> {
  bool _barcodeEnabled = false;
  bool _skuEnabled = false;
  bool _taxEnabled = false;

  @override
  void initState() {
    super.initState();
    _barcodeEnabled =
        widget.barcodeControllers.any((c) => c.text.isNotEmpty);
    _skuEnabled = widget.skuController.text.isNotEmpty;
    _taxEnabled = widget.taxController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          GestureDetector(
            onTap: widget.onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.settings_outlined,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'More Options',
                    style: getOutfitStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: widget.expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: widget.expanded
                ? _buildBody(context)
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1, color: AppColors.borderSoft),

        // ── Barcode(s) ────────────────────────────────────────────────────
        _SectionToggleRow(
          icon: Icons.qr_code_rounded,
          label: 'Barcode(s)',
          enabled: _barcodeEnabled,
          onChanged: (v) => setState(() => _barcodeEnabled = v),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: _barcodeEnabled
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...widget.barcodeControllers.asMap().entries.map(
                            (entry) {
                          final i = entry.key;
                          final ctrl = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: ctrl,
                                    keyboardType: TextInputType.number,
                                    decoration: appInputDeco(
                                      i == 0
                                          ? 'Scan or type barcode'
                                          : 'Additional barcode',
                                    ).copyWith(
                                      prefixIcon: const Icon(
                                        Icons.qr_code_rounded,
                                        size: 18,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    style: getOutfitStyle(
                                        color: AppColors.textPrimary),
                                  ),
                                ),
                                if (widget.barcodeControllers.length > 1) ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => widget.onRemoveBarcode(i),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 20,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                      TextButton.icon(
                        onPressed: widget.onAddBarcode,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(
                          'Add Barcode',
                          style: getOutfitStyle(
                            color: AppColors.brand,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.brand,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),

        const Divider(height: 1, color: AppColors.borderSoft),

        // ── SKU ───────────────────────────────────────────────────────────
        _SectionToggleRow(
          icon: Icons.tag_rounded,
          label: 'SKU',
          enabled: _skuEnabled,
          onChanged: (v) => setState(() => _skuEnabled = v),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: _skuEnabled
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: widget.skuController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: appInputDeco('e.g. CAFE-001'),
                          style:
                              getOutfitStyle(color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: widget.onAutoSku,
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.brand),
                        child: Text(
                          'Auto',
                          style: getOutfitStyle(
                            color: AppColors.brand,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),

        const Divider(height: 1, color: AppColors.borderSoft),

        // ── Tax ───────────────────────────────────────────────────────────
        _SectionToggleRow(
          icon: Icons.percent_rounded,
          label: 'Tax (%)',
          enabled: _taxEnabled,
          onChanged: (v) => setState(() => _taxEnabled = v),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: _taxEnabled
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextFormField(
                    controller: widget.taxController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    decoration: appInputDeco('0.00', prefixText: '% '),
                    style: getOutfitStyle(color: AppColors.textPrimary),
                    validator: (v) {
                      if (v != null && v.trim().isNotEmpty) {
                        final p = double.tryParse(v);
                        if (p == null) return 'Enter a valid percentage';
                        if (p < 0 || p > 100) return 'Must be between 0–100';
                      }
                      return null;
                    },
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),

        const Divider(height: 1, color: AppColors.borderSoft),

        // ── Track Expiry ──────────────────────────────────────────────────
        _SectionToggleRow(
          icon: Icons.event_rounded,
          label: 'Track Expiry',
          subtitle: 'Enable for perishable or dated items',
          enabled: widget.trackExpiry,
          onChanged: widget.onTrackExpiryChanged,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: widget.trackExpiry
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppFieldLabel('Expiry Date'),
                      TextFormField(
                        controller: widget.expiryController,
                        readOnly: true,
                        onTap: widget.onPickExpiryDate,
                        decoration: appInputDeco('dd/mm/yyyy').copyWith(
                          suffixIcon: const Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ),
                        style: getOutfitStyle(color: AppColors.textPrimary),
                        validator: (_) => widget.expiryRequired
                            ? 'Please select an expiry date'
                            : null,
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),

        const Divider(height: 1, color: AppColors.borderSoft),

        // ── Stock Alert ───────────────────────────────────────────────────
        _SectionToggleRow(
          icon: Icons.notifications_outlined,
          label: 'Stock Alert',
          subtitle: 'Get notified when stock falls below a threshold',
          enabled: widget.stockAlertEnabled,
          onChanged: widget.onStockAlertChanged,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: widget.stockAlertEnabled
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppFieldLabel('Alert When Stock Falls Below'),
                      TextFormField(
                        controller: widget.stockAlertController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: appInputDeco('e.g. 5'),
                        style: getOutfitStyle(color: AppColors.textPrimary),
                        validator: (v) {
                          if (widget.stockAlertEnabled) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter an alert threshold';
                            }
                            if (int.tryParse(v) == null) {
                              return 'Enter a whole number';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }
}

class _SectionToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _SectionToggleRow({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: enabled ? AppColors.brand : AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: getOutfitStyle(
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    style: getOutfitStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            onChanged: onChanged,
            activeThumbColor: AppColors.brand,
          ),
        ],
      ),
    );
  }
}
