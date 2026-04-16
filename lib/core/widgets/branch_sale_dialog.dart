import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

/// A record returned when the user confirms a branch selection.
typedef BranchSelection = ({String name, String? id});

/// Shows a bottom-sheet dialog asking the cashier which branch this sale
/// belongs to. Returns [BranchSelection] on confirm, or `null` if cancelled.
///
/// Only call this when [BranchCubit.getSelectedBranchIdForFiltering] returns
/// `null` (i.e. "All Branches" is currently selected).
Future<BranchSelection?> showBranchSaleDialog(BuildContext context) {
  final cubit = context.read<BranchCubit>();
  final options = cubit.getAvailableBranchOptions();

  return showModalBottomSheet<BranchSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _BranchSaleSheet(options: options),
    ),
  );
}

class _BranchSaleSheet extends StatefulWidget {
  final List<BranchSelection> options;

  const _BranchSaleSheet({required this.options});

  @override
  State<_BranchSaleSheet> createState() => _BranchSaleSheetState();
}

class _BranchSaleSheetState extends State<_BranchSaleSheet> {
  BranchSelection? _selected;

  @override
  void initState() {
    super.initState();
    // Auto-select if there is exactly one branch
    if (widget.options.length == 1) {
      _selected = widget.options.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSoft,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.store_rounded,
                      color: AppColors.brand,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Branch',
                          style: getOutfitStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          'Choose where to record this sale',
                          style: getOutfitStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.borderSoft),
            const SizedBox(height: 8),

            // Branch list
            if (widget.options.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 32, horizontal: 24),
                child: Column(
                  children: [
                    const Icon(Icons.store_mall_directory_outlined,
                        size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      'No branches available',
                      style: getOutfitStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please add a branch before making a sale.',
                      textAlign: TextAlign.center,
                      style: getOutfitStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  shrinkWrap: true,
                  itemCount: widget.options.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final branch = widget.options[i];
                    final isSelected = _selected?.name == branch.name;
                    return _BranchTile(
                      name: branch.name,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selected = branch),
                    );
                  },
                ),
              ),

            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.borderSoft),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                              color: AppColors.borderSoft),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: getOutfitStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _selected == null
                            ? null
                            : () => Navigator.of(context).pop(_selected),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brand,
                          disabledBackgroundColor: AppColors.disabled,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _selected == null
                              ? 'Select a Branch'
                              : 'Confirm — ${_selected!.name}',
                          style: getOutfitStyle(
                            color: _selected == null
                                ? AppColors.disabledText
                                : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchTile extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _BranchTile({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.brandSoft : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.brand : AppColors.borderSoft,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isSelected ? AppColors.brand : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brand
                        : AppColors.borderSoft,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded,
                        size: 13, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: getOutfitStyle(
                    color: isSelected
                        ? AppColors.brand
                        : AppColors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.store_rounded,
                    size: 18, color: AppColors.brand),
            ],
          ),
        ),
      ),
    );
  }
}
