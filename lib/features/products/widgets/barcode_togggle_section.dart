import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/features/products/widgets/toggle_row.dart';

class BarcodesSectionToggle extends StatefulWidget {
  final List<TextEditingController> controllers;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  const BarcodesSectionToggle(
      {
        super.key,
        required this.controllers,
      required this.onAdd,
      required this.onRemove});

  @override
  State<BarcodesSectionToggle> createState() =>
      _BarcodesSectionToggleState();
}

class _BarcodesSectionToggleState extends State<BarcodesSectionToggle> {
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _enabled = widget.controllers.any((c) => c.text.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ToggleRow(
          icon: Icons.qr_code_rounded,
          label: 'Barcode(s)',
          enabled: _enabled,
          onChanged: (v) => setState(() => _enabled = v),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _enabled
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...widget.controllers.asMap().entries.map((entry) {
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
                                        size: 17,
                                        color: AppColors.textMuted),
                                  ),
                                  style: getOutfitStyle(
                                      color: AppColors.textPrimary),
                                ),
                              ),
                              if (widget.controllers.length > 1) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => widget.onRemove(i),
                                  child: const Icon(Icons.close_rounded,
                                      size: 18,
                                      color: AppColors.textMuted),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                      TextButton.icon(
                        onPressed: widget.onAdd,
                        icon: const Icon(Icons.add_rounded, size: 15),
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
      ],
    );
  }
}