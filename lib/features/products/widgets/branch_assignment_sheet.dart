import 'package:flutter/material.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/branches_dao.dart';

class BranchAssignmentSheet extends StatefulWidget {
  final String businessId;
  final VoidCallback onSkip;
  final Future<void> Function(String branchId) onAssign;

  const BranchAssignmentSheet({
    super.key,
    required this.businessId,
    required this.onSkip,
    required this.onAssign,
  });

  @override
  State<BranchAssignmentSheet> createState() => _BranchAssignmentSheetState();
}

class _BranchAssignmentSheetState extends State<BranchAssignmentSheet> {
  List<BranchesTableData>? _branches;
  String? _selectedBranchId;
  bool _assigning = false;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    final branches =
        await sl<BranchesDao>().getByBusinessId(widget.businessId);
    if (!mounted) return;
    setState(() {
      _branches = branches;
      _selectedBranchId = branches.isNotEmpty ? branches.first.id : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSoft,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Assign Opening Inventory',
              style: AppTextStyles.title(context)),
          const SizedBox(height: 6),
          Text(
            'You\'re viewing All Branches. Choose which branch should receive the initial inventory you entered.',
            style: AppTextStyles.body(context)
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          if (_branches == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(
                  color: AppColors.brand,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_branches!.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No active branches found.',
                style: AppTextStyles.body(context)
                    .copyWith(color: AppColors.textSecondary),
              ),
            )
          else
            RadioGroup<String>(
              groupValue: _selectedBranchId,
              onChanged: (v) => setState(() => _selectedBranchId = v),
              child: Column(
                children: _branches!
                    .map(
                      (branch) => RadioListTile<String>(
                        value: branch.id,
                        title: Text(
                          branch.name,
                          style: AppTextStyles.body(context).copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        activeColor: AppColors.brand,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                    .toList(),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _assigning ? null : widget.onSkip,
                  child: Text(
                    'Skip',
                    style: AppTextStyles.body(context).copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_selectedBranchId == null || _assigning)
                      ? null
                      : () async {
                          setState(() => _assigning = true);
                          await widget.onAssign(_selectedBranchId!);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.brand.withAlpha(80),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _assigning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Assign',
                          style: getOutfitStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
