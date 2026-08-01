import 'package:flutter_test/flutter_test.dart';

import 'package:pos/features/billing/domain/billing_models.dart';
import 'package:pos/features/billing/domain/upgrade_pitch.dart';

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
  maxDevices: 10,
);

void main() {
  test('names the tier being sold, not the one already held', () {
    final pitch = upgradePitch(_starter, _growth);

    expect(pitch.title, 'Get more with Growth');
    expect(pitch.body, endsWith('on Growth.'));
  });

  // The copy is derived so it can never promise something the catalog doesn't
  // actually grant.
  test('body names real gains taken from the catalog', () {
    final pitch = upgradePitch(_starter, _growth);

    expect(pitch.body, 'Unlock 10 devices and 5 branches on Growth.');
  });

  test('caps the gains at two so the banner stays one line of prose', () {
    final pitch = upgradePitch(_starter, _growth);

    // Three gains differ (devices, branches, seats) — only two are named.
    expect(' and '.allMatches(pitch.body).length, 1);
    expect(pitch.body, isNot(contains(',')));
  });

  test('lower-cases the labels so they read mid-sentence', () {
    final pitch = upgradePitch(_starter, _growth);

    expect(pitch.body, isNot(contains('Unlock 10 Devices')));
    expect(pitch.body, startsWith('Unlock '));
  });

  // Two tiers with identical limits would otherwise pitch an empty list.
  test('falls back to a generic line when nothing measurable differs', () {
    const twin = PlanOption(
      code: 'growth_v2',
      version: 2,
      name: 'Growth',
      priceMonthly: 599,
      isActive: true,
      cloudEnabled: true,
      maxBranches: 5,
      maxSeats: 15,
      maxDevices: 10,
    );
    final pitch = upgradePitch(_growth, twin);

    expect(pitch.body, 'Move up to Growth for more room to grow.');
  });
}
