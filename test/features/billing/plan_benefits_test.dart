import 'package:flutter_test/flutter_test.dart';

import 'package:pos/features/billing/domain/billing_models.dart';
import 'package:pos/features/billing/domain/plan_benefits.dart';

const _free = PlanOption(
  code: 'free',
  version: 1,
  name: 'Free',
  priceMonthly: 0,
  isActive: true,
  cloudEnabled: false,
  maxBranches: 1,
  maxSeats: 2,
  maxDevices: 1,
  featureFlags: {
    'crm': false,
    'procurement': false,
    'reports': 'basic',
    'audit': 'local',
  },
);

const _starter = PlanOption(
  code: 'starter',
  version: 1,
  name: 'Starter',
  priceMonthly: 199,
  isActive: true,
  cloudEnabled: true,
  maxBranches: 1,
  maxSeats: 3,
  maxDevices: 3,
  featureFlags: {'crm': 'basic', 'reports': 'basic', 'audit': 'cloud'},
);

const _growth = PlanOption(
  code: 'growth',
  version: 1,
  name: 'Growth',
  priceMonthly: 499,
  isActive: true,
  cloudEnabled: true,
  maxBranches: 5,
  maxSeats: 15,
  maxDevices: null, // unlimited
  featureFlags: {
    'crm': 'full',
    'procurement': true,
    'reports': 'full',
    'audit': 'full',
  },
);

List<String> _labels(Iterable<PlanBenefit> rows) =>
    rows.map((r) => r.label).toList();

void main() {
  group('planBenefits', () {
    test('lists every capability when there is no tier below', () {
      final labels = _labels(planBenefits(_starter));

      expect(labels, contains('Cloud backup & sync'));
      expect(labels, contains('3 devices'));
      expect(labels, contains('1 branch'));
      expect(labels, contains('3 team members'));
      expect(labels, contains('Customer directory (CRM)'));
      expect(labels, contains('Audit log'));
    });

    test('every capability row carries a plain-language gloss', () {
      final rows = planBenefits(_starter);
      expect(rows.every((r) => r.detail != null && r.detail!.isNotEmpty), isTrue);
    });

    // The on-device chain runs on every tier, so it is not a reason to upgrade.
    test('local-only audit is not sold as a row', () {
      final labels = _labels(planBenefits(_free));
      expect(labels.any((l) => l.toLowerCase().contains('audit')), isFalse);
    });

    test('unlimited caps read as "Unlimited", not a number', () {
      expect(_labels(planBenefits(_growth)), contains('Unlimited devices'));
    });

    test('singular and plural counts agree with the number', () {
      final labels = _labels(planBenefits(_free));
      expect(labels, contains('1 device'));
      expect(labels, contains('1 branch'));
      expect(labels, contains('2 team members'));
    });

    group('against a previous tier', () {
      test('marks only the rows that actually differ as changed', () {
        final changed = _labels(
          planBenefits(_growth, previous: _starter).where((r) => r.changed),
        );

        expect(changed, contains('5 branches'));
        expect(changed, contains('Unlimited devices'));
        expect(changed, contains('Procurement & suppliers'));
        expect(changed, contains('Audit log & unusual-activity alerts'));
        // Both tiers have cloud — repeating it is what the "Everything in
        // {previous}" lead line already covers.
        expect(changed, isNot(contains('Cloud backup & sync')));
      });

      test('a deepened flag counts as changed, not as unchanged', () {
        final rows = planBenefits(_growth, previous: _starter);
        final crm =
            rows.firstWhere((r) => r.label == 'Full CRM & customer insights');
        expect(crm.changed, isTrue);
      });
    });

    // A card states what a tier gives you. The entry tier used to append grey
    // "No cloud backup" / "No customer records" rows, which read as a crippled
    // product — and the CRM one sat oddly next to a Starter card that has CRM.
    test('the entry tier sells only what it has, never what it lacks', () {
      final labels = _labels(planBenefits(_free));

      expect(labels, isNot(contains('No cloud backup')));
      expect(labels, isNot(contains('One device only')));
      expect(labels, isNot(contains('No customer records')));
    });

    // This is the disclosure the removed exclusions used to carry: without it a
    // Free card reads as complete and people lose data they thought was safe.
    test('an offline tier still states the data-loss consequence', () {
      final offline =
          planBenefits(_free).firstWhere((r) => r.label == 'Works fully offline');

      expect(offline.detail, contains('lose or reset'));
    });

    group('glosses name examples, never the whole feature', () {
      // "See every void, refund and discount" read as the definition of the
      // audit log rather than three instances of it. The hedge lives on the
      // Starter row now — that's where the log's own gloss moved when the
      // viewer dropped a rung.
      test('the audit gloss is explicitly open-ended', () {
        final audit =
            planBenefits(_starter).firstWhere((r) => r.label == 'Audit log');

        expect(audit.detail, contains('Open every action'));
        expect(audit.detail, contains('including'));
      });

      // Two different nouns across the rungs read as two unrelated products.
      // Growth keeps naming the log so a standalone Growth card doesn't look
      // like it lost the thing Starter has.
      test('both audit rungs share the same noun', () {
        String auditLabel(PlanOption p) =>
            _labels(planBenefits(p)).firstWhere((l) => l.contains('udit'));

        expect(auditLabel(_starter).toLowerCase(), contains('audit log'));
        expect(auditLabel(_growth).toLowerCase(), contains('audit log'));
      });

      // Starter can now OPEN the log, not just have it backed up — the gloss
      // has to say so, or the tier looks like it did before the split.
      test('the Starter rung promises you can read it in-app', () {
        final audit =
            planBenefits(_starter).firstWhere((r) => r.label == 'Audit log');

        expect(audit.detail, contains('Open every action in-app'));
      });

      // Growth's row is a delta on top of Starter's, so it must sell the
      // alerts rather than re-describing the log.
      test('the Growth rung sells the alerts, not the log again', () {
        final audit = planBenefits(_growth)
            .firstWhere((r) => r.label == 'Audit log & unusual-activity alerts');

        expect(audit.detail, contains('plus'));
        expect(audit.detail, contains('look wrong'));
      });

      test('the reports gloss does not cap what you can report on', () {
        final reports = planBenefits(_free)
            .firstWhere((r) => r.label == 'Sales & inventory reports');

        expect(reports.detail, endsWith('and more'));
      });
    });
  });
}
