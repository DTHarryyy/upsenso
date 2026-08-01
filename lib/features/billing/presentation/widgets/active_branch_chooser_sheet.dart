import 'package:flutter/material.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/permissions/entitlement_enforcement_service.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/permissions/plan_display.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/core/widgets/app_filled_button.dart';

/// Lets the owner say which branches stay active when the plan covers fewer
/// than they have.
///
/// A safe default is already applied by [EntitlementEnforcementService] before
/// this ever opens — the branch currently open in POS is never the one locked —
/// so this is a correction, not a gate. Nothing is blocked while it's up and
/// nothing is deleted by any choice made here.
class ActiveBranchChooserSheet extends StatefulWidget {
  const ActiveBranchChooserSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) => const ActiveBranchChooserSheet(),
    );
  }

  @override
  State<ActiveBranchChooserSheet> createState() =>
      _ActiveBranchChooserSheetState();
}

class _ActiveBranchChooserSheetState extends State<ActiveBranchChooserSheet> {
  List<BranchesTableData>? _branches;
  Set<String> _selected = {};
  bool _saving = false;

  int? get _cap =>
      sl<EntitlementService>().effectiveMax(EntitlementResource.branches);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final businessId = sl<ActiveBusinessContext>().businessId;
    if (businessId == null || businessId.isEmpty) {
      if (mounted) setState(() => _branches = const []);
      return;
    }
    try {
      final rows = await sl<BranchesDao>().getByBusinessId(businessId);
      final locked = sl<EntitlementEnforcementService>().lockedBranchIds;
      if (!mounted) return;
      setState(() {
        _branches = rows;
        _selected = rows
            .map((b) => b.id)
            .where((id) => !locked.contains(id))
            .toSet();
      });
    } catch (e, st) {
      debugPrint('[ActiveBranchChooser] Error in _load: $e\n$st');
      if (mounted) setState(() => _branches = const []);
    }
  }

  void _toggle(String id) {
    final cap = _cap;
    setState(() {
      if (_selected.contains(id)) {
        // Never let them deselect everything — the till needs somewhere to go.
        if (_selected.length > 1) _selected.remove(id);
        return;
      }
      if (cap != null && _selected.length >= cap) {
        // At the cap, picking a new one swaps out the oldest pick rather than
        // making them deselect first — fewer taps, same result.
        _selected.remove(_selected.first);
      }
      _selected.add(id);
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await sl<EntitlementEnforcementService>().chooseActiveBranches(
      _selected,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn\'t save that selection.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final branches = _branches;
    final cap = _cap;
    final plan = planLabelOf(sl<EntitlementService>().planCode);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cap == null
                ? 'Choose your active branches'
                : 'Your $plan plan covers $cap '
                      '${cap == 1 ? 'branch' : 'branches'}',
            style: getOutfitStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pick which ones stay open for selling. The rest become read-only — '
            'their sales history and reports stay exactly where they are, and '
            'upgrading brings them all back.',
            style: getOutfitStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          if (branches == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.brand),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: branches.length,
                itemBuilder: (context, i) {
                  final b = branches[i];
                  final on = _selected.contains(b.id);
                  return CheckboxListTile(
                    value: on,
                    onChanged: _saving ? null : (_) => _toggle(b.id),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.brand,
                    title: Text(
                      b.name,
                      style: getOutfitStyle(
                        fontSize: 14,
                        fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                        color: on
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    subtitle: on
                        ? null
                        : Text(
                            'Read-only',
                            style: getOutfitStyle(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          AppFilledButton(
            label: _saving ? 'Saving…' : 'Save',
            onPressed: _saving || branches == null ? null : _save,
          ),
        ],
      ),
    );
  }
}
