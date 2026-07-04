import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:pos/core/services/fraud_rules/fraud_flag_draft.dart';
import 'package:pos/core/services/fraud_rules/fraud_rule.dart';

/// Watch the watchers: the control plane is exactly where a knowledgeable
/// insider goes first. Flags (from the already-audit-logged events):
///  • the audit module being switched OFF,
///  • refund approval being disabled or its threshold raised,
///  • a role change,
///  • an override granting a sensitive permission, or ANY self-targeted
///    override regardless of key.
class ControlChangeRule implements FraudRule {
  @override
  String get code => 'CONTROL_CHANGE';

  @override
  bool get requiresFullAuditMirror => false;

  @override
  Future<List<FraudFlagDraft>> evaluate(FraudScanContext ctx) async {
    final rows = await ctx.db
        .customSelect(
          'SELECT id, action_type, user_id, entity_id, metadata, branch_id, '
          'created_at FROM audit_logs '
          'WHERE business_id = ? AND created_at >= ? AND action_type IN '
          "('BUSINESS_MODULE_CHANGED','REFUND_SETTINGS_CHANGED',"
          "'PERMISSION_OVERRIDE_SET','EMPLOYEE_ROLE_CHANGED')",
          variables: [
            Variable.withString(ctx.businessId),
            Variable<int>(ctx.windowStartUnix),
          ],
        )
        .get();

    final drafts = <FraudFlagDraft>[];
    // A bulk permission grant fires one audit row per key — 45 of them on
    // 2026-07-03 produced a wall of near-identical flags. Override grants by
    // one actor on one local day collapse into a single digest flag listing
    // the keys; everything else (module/threshold/role) stays one-per-event.
    final overrideGroups = <String, _OverrideGroup>{};

    for (final r in rows) {
      Map<String, dynamic> meta;
      try {
        meta = Map<String, dynamic>.from(
          jsonDecode(r.read<String>('metadata')) as Map,
        );
      } catch (_) {
        meta = const {};
      }

      final concern = await _concernFor(ctx, r, meta);
      if (concern == null) continue;

      final actionType = r.read<String>('action_type');
      final id = r.read<String>('id');
      final createdAt = DateTime.fromMillisecondsSinceEpoch(
        r.read<int>('created_at') * 1000,
      );
      final branchId = (r.readNullable<String>('branch_id') ?? '').isEmpty
          ? null
          : r.read<String>('branch_id');
      final subjectUserId = (r.readNullable<String>('user_id') ?? '').isEmpty
          ? null
          : r.read<String>('user_id');

      if (actionType == 'PERMISSION_OVERRIDE_SET') {
        final actor = subjectUserId ?? 'unknown';
        final day = localDayString(createdAt);
        final key = '$actor|$day';
        final group = overrideGroups.putIfAbsent(
          key,
          () => _OverrideGroup(actor: actor, day: day, branchId: branchId),
        );
        group.add(
          id: id,
          at: createdAt,
          permissionCode: meta['permission_code']?.toString(),
          concern: concern,
        );
        continue;
      }

      drafts.add(FraudFlagDraft(
        ruleCode: code,
        severity: FraudSeverity.medium,
        title: 'Fraud-control setting changed',
        description: concern,
        dedupeKey: '$code|$id',
        detectedAt: createdAt,
        branchId: branchId,
        subjectUserId: subjectUserId,
        evidence: [
          {'fact': 'Audit action', 'value': actionType},
          for (final e in meta.entries.take(8))
            if (!e.key.startsWith('_'))
              {'fact': e.key, 'value': e.value?.toString()},
        ],
        relatedIds: [id],
      ));
    }

    for (final g in overrideGroups.values) {
      drafts.add(g.toDraft(code));
    }
    return drafts;
  }

  /// Returns a human description when the event weakens a fraud control;
  /// null when it's benign (module re-enabled, threshold lowered, etc.).
  Future<String?> _concernFor(
    FraudScanContext ctx,
    QueryRow r,
    Map<String, dynamic> meta,
  ) async {
    switch (r.read<String>('action_type')) {
      case 'BUSINESS_MODULE_CHANGED':
        if (meta['module'] == 'audit' && meta['enabled'] == false) {
          return 'The Audit module was switched OFF — audit and fraud UI '
              'surfaces are hidden while it stays off (detection itself keeps '
              'running).';
        }
        return null;

      case 'REFUND_SETTINGS_CHANGED':
        final before = (meta['threshold_before'] as num?)?.toDouble();
        final after = (meta['threshold'] as num?)?.toDouble();
        final approvalOff = meta['require_approval'] == false &&
            meta['require_approval_before'] == true;
        if (approvalOff) {
          return 'Refund manager-approval was turned OFF.';
        }
        if (before != null && after != null && after > before) {
          return 'The refund approval threshold was raised from '
              '₱${before.toStringAsFixed(2)} to ₱${after.toStringAsFixed(2)} — '
              'larger refunds now need no approval.';
        }
        return null;

      case 'EMPLOYEE_ROLE_CHANGED':
        return 'An employee\'s role was changed — role changes redefine what '
            'they can do everywhere.';

      case 'PERMISSION_OVERRIDE_SET':
        final key = meta['permission_code']?.toString() ?? '';
        final granted = meta['granted'] == true;
        if (granted && FraudDefaults.sensitiveOverrideKeys.contains(key)) {
          return 'A sensitive permission ("$key") was granted to an employee '
              'via override, beyond their role\'s defaults.';
        }
        if (granted && await _isSelfTargeted(ctx, r)) {
          return 'An employee granted a permission override ("$key") to '
              'THEMSELVES.';
        }
        return null;

      default:
        return null;
    }
  }

  /// entity_id is the employees.id being modified; the actor is user_id
  /// (auth uid). Self-targeted = the modified employee IS the actor.
  Future<bool> _isSelfTargeted(FraudScanContext ctx, QueryRow r) async {
    final employeeId = r.readNullable<String>('entity_id');
    final actor = r.readNullable<String>('user_id');
    if (employeeId == null || actor == null || actor.isEmpty) return false;
    final row = await ctx.db
        .customSelect(
          'SELECT auth_user_id, user_id FROM employees WHERE id = ? LIMIT 1',
          variables: [Variable.withString(employeeId)],
        )
        .getSingleOrNull();
    if (row == null) return false;
    return row.readNullable<String>('auth_user_id') == actor ||
        row.readNullable<String>('user_id') == actor;
  }
}

/// Accumulates one actor's permission-override grants on one local day into a
/// single digest flag. A lone grant reads as one flag; a burst reads as one
/// flag that lists the keys, instead of N near-identical flags.
class _OverrideGroup {
  _OverrideGroup({
    required this.actor,
    required this.day,
    required this.branchId,
  });

  final String actor;
  final String day;
  final String? branchId;
  final List<String> _ids = [];
  final Set<String> _codes = {};
  final List<String> _singleConcerns = [];
  DateTime? _latestAt;

  void add({
    required String id,
    required DateTime at,
    String? permissionCode,
    required String concern,
  }) {
    _ids.add(id);
    if (permissionCode != null && permissionCode.isNotEmpty) {
      _codes.add(permissionCode);
    }
    _singleConcerns.add(concern);
    if (_latestAt == null || at.isAfter(_latestAt!)) _latestAt = at;
  }

  FraudFlagDraft toDraft(String code) {
    final count = _ids.length;
    final keys = _codes.toList()..sort();
    final description = count == 1
        ? _singleConcerns.first
        : '$count sensitive permission override(s) were granted by one '
            'employee on $day (${keys.join(', ')}). A burst of grants is how an '
            'insider widens their own access quickly.';
    return FraudFlagDraft(
      ruleCode: code,
      severity: FraudSeverity.medium,
      title: 'Fraud-control setting changed',
      description: description,
      // Day-scoped so the same burst re-detects to one flag, not N.
      dedupeKey: '$code|override|$actor|$day',
      detectedAt: _latestAt ?? DateTime.now(),
      branchId: branchId,
      subjectUserId: actor == 'unknown' ? null : actor,
      evidence: [
        {'fact': 'Granted permission(s)', 'value': keys.join(', ')},
        {'fact': 'Grant count', 'value': count},
        {'fact': 'Day', 'value': day},
      ],
      relatedIds: _ids.take(20).toList(),
    );
  }
}
