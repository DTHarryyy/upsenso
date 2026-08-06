import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/features/products/widgets/toggle_row.dart';

class SkuSectionToggle extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onAutoSku;
  const SkuSectionToggle(
      {super.key,required this.controller, required this.onAutoSku});

  @override
  State<SkuSectionToggle> createState() => SkuSectionToggleState();
}

class SkuSectionToggleState extends State<SkuSectionToggle> {
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _enabled = widget.controller.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ToggleRow(
          icon: Icons.tag_rounded,
          label: 'SKU',
          enabled: _enabled,
          onChanged: (v) => setState(() => _enabled = v),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _enabled
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: widget.controller,
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
                              fontWeight: FontWeight.w600),
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
