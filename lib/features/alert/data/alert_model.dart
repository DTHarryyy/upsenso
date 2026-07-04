import 'dart:convert';

import 'package:pos/core/database/app_database.dart';

enum AlertSeverity { critical, high, medium, low }

enum AlertStatus { newAlert, investigating, resolved, dismissed, falsePositive }

extension AlertSeverityX on AlertSeverity {
  static AlertSeverity fromDb(String value) {
    switch (value) {
      case 'critical':
        return AlertSeverity.critical;
      case 'high':
        return AlertSeverity.high;
      case 'medium':
        return AlertSeverity.medium;
      default:
        return AlertSeverity.low;
    }
  }
}

extension AlertStatusX on AlertStatus {
  static AlertStatus fromDb(String value) {
    switch (value) {
      case 'investigating':
        return AlertStatus.investigating;
      case 'resolved':
        return AlertStatus.resolved;
      case 'dismissed':
        return AlertStatus.dismissed;
      case 'false_positive':
        return AlertStatus.falsePositive;
      default:
        return AlertStatus.newAlert;
    }
  }

  String get dbValue {
    switch (this) {
      case AlertStatus.newAlert:
        return 'new';
      case AlertStatus.investigating:
        return 'investigating';
      case AlertStatus.resolved:
        return 'resolved';
      case AlertStatus.dismissed:
        return 'dismissed';
      case AlertStatus.falsePositive:
        return 'false_positive';
    }
  }

  /// Short label for the triage UI.
  String get label {
    switch (this) {
      case AlertStatus.newAlert:
        return 'New';
      case AlertStatus.investigating:
        return 'Investigating';
      case AlertStatus.resolved:
        return 'Resolved';
      case AlertStatus.dismissed:
        return 'Dismissed';
      case AlertStatus.falsePositive:
        return 'False positive';
    }
  }
}

/// Display model for one fraud flag. Alerts are LEADS whose evidence is the
/// linked records — the UI presents facts to review, never verdicts.
class FraudAlert {
  final String id;
  final String ruleCode;
  final String title;
  final String description;
  final AlertSeverity severity;
  final AlertStatus status;

  /// Implicated employee's display name (resolved by the cubit) — '—' when
  /// no single subject.
  final String author;

  /// Raw subject user id; drives the client mirror of the server's
  /// self-resolution block.
  final String? subjectUserId;
  final String store;
  final DateTime date;
  final Map<String, String> evidence;
  final List<String> relatedRecords;
  final String? resolutionNote;

  const FraudAlert({
    required this.id,
    required this.ruleCode,
    required this.title,
    required this.description,
    required this.severity,
    required this.status,
    required this.author,
    required this.subjectUserId,
    required this.store,
    required this.date,
    required this.evidence,
    required this.relatedRecords,
    this.resolutionNote,
  });

  factory FraudAlert.fromRow(
    FraudFlagRow row, {
    required String Function(String userId) nameFor,
    required String Function(String? branchId) branchNameFor,
  }) {
    return FraudAlert(
      id: row.id,
      ruleCode: row.ruleCode,
      title: row.title,
      description: row.description,
      severity: AlertSeverityX.fromDb(row.severity),
      status: AlertStatusX.fromDb(row.status),
      author:
          row.subjectUserId == null ? '—' : nameFor(row.subjectUserId!),
      subjectUserId: row.subjectUserId,
      store: branchNameFor(row.branchId),
      date: row.detectedAt,
      evidence: _evidenceMap(row.evidence),
      relatedRecords: _relatedIds(row.relatedIds),
      resolutionNote: row.resolutionNote,
    );
  }

  /// Structured factor list → display rows. Each factor is
  /// {fact, value, baseline?, window?, ...}; extra keys fold into the value.
  static Map<String, String> _evidenceMap(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) return const {};
      final map = <String, String>{};
      for (final item in decoded) {
        if (item is! Map) continue;
        final fact = item['fact']?.toString();
        if (fact == null) continue;
        // Machine-readable diagnostics (e.g. _debug) stay in the stored
        // evidence for investigation but are not shown to the operator.
        if (fact.startsWith('_')) continue;
        final parts = <String>[
          if (item['value'] != null) item['value'].toString(),
          for (final e in item.entries)
            if (e.key != 'fact' && e.key != 'value' && e.value != null)
              '${e.key}: ${e.value}',
        ];
        map[fact] = parts.isEmpty ? '—' : parts.join(' · ');
      }
      return map;
    } catch (_) {
      return const {};
    }
  }

  static List<String> _relatedIds(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) return const [];
      return [for (final v in decoded) v.toString()];
    } catch (_) {
      return const [];
    }
  }
}
