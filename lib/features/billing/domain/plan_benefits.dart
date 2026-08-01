import 'package:pos/features/billing/domain/billing_models.dart';

/// One line of a plan's "what you get" list.
///
/// [detail] is the plain-language gloss shown under the label — "3 devices" on
/// its own means nothing to a shop owner deciding between tiers. Where it names
/// examples it must say so ("including…", "and more"): a closed list reads as
/// the definition of the feature and quietly caps what people think they get.
typedef PlanBenefit = ({
  String label,
  String? detail,
  bool changed,
});

/// The capability rows for [plan], derived entirely from the limits the server
/// sent — nothing here is a hardcoded price or cap.
///
/// Every row is something the tier gives you; a plan card is not the place to
/// enumerate what it withholds. The one consequence worth stating — that a
/// device-only tier isn't backed up anywhere — rides on its own capability row.
///
/// When [previous] is given, each row's `changed` marks whether it differs from
/// the tier below, which is what lets the top card render an "Everything in
/// {previous}" delta list instead of repeating the whole ladder.
List<PlanBenefit> planBenefits(PlanOption plan, {PlanOption? previous}) {
  final rows = <PlanBenefit>[];

  void add(String label, bool changed, {String? detail}) =>
      rows.add((label: label, detail: detail, changed: changed));

  add(
    plan.cloudEnabled ? 'Cloud backup & sync' : 'Works fully offline',
    previous == null || plan.cloudEnabled != previous.cloudEnabled,
    // The offline gloss states the consequence, not just the fact — a tier that
    // only lists what it has reads as complete, and people lose data they
    // assumed was backed up.
    detail: plan.cloudEnabled
        ? 'Your sales and stock are safe even if this device is lost'
        : 'Stays on this device — lose or reset it and the data goes with it',
  );
  add(
    _count(plan.maxDevices, 'device', 'devices'),
    previous == null || plan.maxDevices != previous.maxDevices,
    detail: 'Phones, tablets or computers signed in at the same time',
  );
  add(
    _count(plan.maxBranches, 'branch', 'branches'),
    previous == null || plan.maxBranches != previous.maxBranches,
    detail: 'Separate store locations with their own stock and sales',
  );
  add(
    _count(plan.maxSeats, 'team member', 'team members'),
    previous == null || plan.maxSeats != previous.maxSeats,
    detail: 'Staff accounts that can log in and sell',
  );

  final crm = _crmRank(plan.featureFlags['crm']);
  if (crm > 0) {
    add(
      crm == 2 ? 'Full CRM & customer insights' : 'Customer directory (CRM)',
      previous == null || crm != _crmRank(previous.featureFlags['crm']),
      detail: crm == 2
          ? 'Everything in the customer directory, plus what each customer '
              'buys and how often'
          // Closed on purpose — basic CRM really is only names and contacts.
          : 'Save customer names and contact details on a sale',
    );
  }
  if (plan.featureFlags['procurement'] == true) {
    add(
      'Procurement & suppliers',
      previous == null || previous.featureFlags['procurement'] != true,
      detail: 'Raise purchase orders, keep supplier records and receive '
          'stock in',
    );
  }
  final reports = _reportsRank(plan.featureFlags['reports']);
  add(
    reports == 2 ? 'Advanced reports & export' : 'Sales & inventory reports',
    previous == null ||
        reports != _reportsRank(previous.featureFlags['reports']),
    detail: reports == 2
        ? 'Compare branches and export any report to PDF or Excel'
        : 'Daily sales, best sellers, stock on hand, profit and more',
  );
  final audit = _auditRank(plan.featureFlags['audit']);
  if (audit > 0) {
    // Both rungs share the "audit log" noun — two different nouns read as two
    // unrelated products. They differ on what sits ON TOP of the log: `cloud`
    // (Starter) records, backs up and lets you open it; `full` (Growth) adds
    // the Unusual Activity dashboard. Growth still names the log so a
    // standalone Growth card doesn't read as having lost it.
    add(
      audit == 2 ? 'Audit log & unusual-activity alerts' : 'Audit log',
      previous == null || audit != _auditRank(previous.featureFlags['audit']),
      // "including" is load-bearing: the old copy listed three actions and read
      // as the whole of what the audit log covers.
      detail: audit == 2
          ? 'Everything in the log, plus automatic warnings when voids, '
              'discounts or refunds look wrong'
          : 'Open every action in-app — who did it and when, including '
              'voids, refunds and discounts',
    );
  }

  return rows;
}

int _crmRank(Object? v) => v == 'full' ? 2 : (v == 'basic' ? 1 : 0);

int _reportsRank(Object? v) => v == 'full' ? 2 : 1;

/// local = 0 (no row — the on-device chain isn't a selling point),
/// cloud = 1 (backed up and browsable), full = 2 (adds unusual-activity alerts).
int _auditRank(Object? v) => v == 'full' ? 2 : (v == 'cloud' ? 1 : 0);

String _count(int? n, String one, String many) =>
    n == null ? 'Unlimited $many' : '$n ${n == 1 ? one : many}';
