import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/widgets.dart';

/// Editor for a variant's multiple barcodes: a reveal toggle, then a list of
/// removeable rows (input + Auto), plus "Add barcode". The parent owns the
/// [controllers] list (for disposal) and mutates it via [onAdd]/[onRemove].
class BarcodesEditor extends StatefulWidget {
  final List<TextEditingController> controllers;

  /// Generates a unique barcode for the row's Auto button.
  final Future<String?> Function()? onGenerate;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  const BarcodesEditor({
    super.key,
    required this.controllers,
    required this.onAdd,
    required this.onRemove,
    this.onGenerate,
  });

  @override
  State<BarcodesEditor> createState() => _BarcodesEditorState();
}

class _BarcodesEditorState extends State<BarcodesEditor> {
  bool _enabled = false;
  int? _generatingIndex;

  @override
  void initState() {
    super.initState();
    _enabled = widget.controllers.any((c) => c.text.isNotEmpty);
  }

  Future<void> _auto(int index) async {
    if (widget.onGenerate == null || _generatingIndex != null) return;
    setState(() => _generatingIndex = index);
    try {
      final code = await widget.onGenerate!.call();
      if (!mounted) return;
      setState(() {
        if (code != null && code.isNotEmpty) {
          widget.controllers[index].text = code;
        }
        _generatingIndex = null;
      });
    } catch (_) {
      if (mounted) setState(() => _generatingIndex = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Stay open whenever a code exists — survives the post-frame edit-prefill.
    final open = _enabled || widget.controllers.any((c) => c.text.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(IconlyLight.scan,
                size: 16, color: open ? AppColors.brand : AppColors.textMuted),
            const SizedBox(width: 10),
            Text(
              'Barcode(s)',
              style: getOutfitStyle(
                color: open ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Text('(optional)',
                style: getOutfitStyle(color: AppColors.textMuted, fontSize: 11)),
            const Spacer(),
            AppSwitch(
              value: open,
              onChanged: (v) => setState(() {
                _enabled = v;
                if (!v) {
                  for (final c in widget.controllers) {
                    c.clear();
                  }
                }
              }),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: open
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
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
                                  textInputAction: TextInputAction.done,
                                  decoration:
                                      appInputDeco(i == 0
                                              ? 'Scan or type barcode'
                                              : 'Additional barcode')
                                          .copyWith(
                                    prefixIcon: const Icon(IconlyLight.scan,
                                        size: 17, color: AppColors.textMuted),
                                  ),
                                  style: getOutfitStyle(
                                      color: AppColors.textPrimary),
                                ),
                              ),
                              if (widget.onGenerate != null) ...[
                                const SizedBox(width: 6),
                                _AutoButton(
                                  loading: _generatingIndex == i,
                                  onTap: () => _auto(i),
                                ),
                              ],
                              if (widget.controllers.length > 1) ...[
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => widget.onRemove(i),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.close_rounded,
                                        size: 18, color: AppColors.textMuted),
                                  ),
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
                          'Add barcode',
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

/// Clickable "Auto" text that generates a barcode for its row.
class _AutoButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _AutoButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: AppColors.brand),
              )
            : Text(
                'Auto',
                style: getOutfitStyle(
                  color: AppColors.brand,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
