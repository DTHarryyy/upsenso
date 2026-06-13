import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/features/products/presentation/cubit/product_form_state.dart';

class RecipeLineTile extends StatefulWidget {
  final RecipeLineFormEntry line;
  final VoidCallback onRemove;
  final ValueChanged<double> onQtyChanged;

  const RecipeLineTile({
    super.key,
    required this.line,
    required this.onRemove,
    required this.onQtyChanged,
  });

  @override
  State<RecipeLineTile> createState() => _RecipeLineTileState();
}

class _RecipeLineTileState extends State<RecipeLineTile> {
  late final TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(
      text: widget.line.quantity.toStringAsFixed(
        widget.line.quantity % 1 == 0 ? 0 : 3,
      ),
    );
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.line.ingredientName,
                  style: getOutfitStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (widget.line.unit != null)
                  Text(
                    widget.line.unit!,
                    style: getOutfitStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _qtyController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
              ],
              textAlign: TextAlign.center,
              decoration: appInputDeco('0'),
              style:
                  getOutfitStyle(color: AppColors.textPrimary, fontSize: 14),
              onChanged: (v) {
                final qty = double.tryParse(v);
                if (qty != null && qty > 0) widget.onQtyChanged(qty);
              },
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(
              Icons.remove_circle_outline_rounded,
              color: AppColors.error,
              size: 20,
            ),
            onPressed: widget.onRemove,
            splashRadius: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
