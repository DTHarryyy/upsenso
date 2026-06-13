import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';

enum PoStatus {
  draft,
  submitted,
  approved,
  partiallyReceived,
  received,
  cancelled;

  static PoStatus fromString(String s) => switch (s) {
    'submitted' => submitted,
    'approved' => approved,
    'partially_received' => partiallyReceived,
    'received' => received,
    'cancelled' => cancelled,
    _ => draft,
  };

  String get value => switch (this) {
    draft => 'draft',
    submitted => 'submitted',
    approved => 'approved',
    partiallyReceived => 'partially_received',
    received => 'received',
    cancelled => 'cancelled',
  };

  String get label => switch (this) {
    draft => 'Draft',
    submitted => 'Submitted',
    approved => 'Approved',
    partiallyReceived => 'Partial',
    received => 'Received',
    cancelled => 'Cancelled',
  };

  Color get color => switch (this) {
    draft => AppColors.textMuted,
    submitted => Colors.orange,
    approved => Colors.blue,
    partiallyReceived => Colors.purple,
    received => AppColors.success,
    cancelled => AppColors.error,
  };

  bool get canSubmit => this == draft;
  bool get canApprove => this == submitted;
  bool get canReceive => this == approved || this == partiallyReceived;
  bool get canCancel =>
      this == draft || this == submitted || this == approved;
  bool get isClosed => this == received || this == cancelled;
}
