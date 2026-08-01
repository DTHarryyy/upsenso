import 'package:flutter_test/flutter_test.dart';

import 'package:pos/core/permissions/plan_display.dart';

void main() {
  test('maps each known plan code to its display name', () {
    expect(planLabelOf('starter'), 'Starter');
    expect(planLabelOf('growth'), 'Growth');
    expect(planLabelOf('business'), 'Business');
    expect(planLabelOf('enterprise'), 'Enterprise');
  });

  test('free and any unknown code fall back to Free', () {
    expect(planLabelOf('free'), 'Free');
    expect(planLabelOf('lapsed'), 'Free');
    expect(planLabelOf(''), 'Free');
    expect(planLabelOf('not_a_real_plan'), 'Free');
  });
}
