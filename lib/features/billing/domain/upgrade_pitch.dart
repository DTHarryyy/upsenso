import 'package:pos/features/billing/domain/billing_models.dart';
import 'package:pos/features/billing/domain/plan_benefits.dart';

/// Headline and one-line body for the upgrade nudge.
typedef UpgradePitch = ({String title, String body});

/// How many gains the nudge names. The banner body is width-constrained, and a
/// list of three reads as a spec sheet rather than a reason — the sheet behind
/// the tap carries the full comparison.
const _maxGains = 2;

/// What moving from [current] to [next] actually buys you, in the tenant's own
/// terms. Derived from the benefit rows rather than written per tier, so the
/// copy can never claim something the catalog doesn't back.
UpgradePitch upgradePitch(PlanOption current, PlanOption next) {
  final gains = planBenefits(next, previous: current)
      .where((r) => r.changed)
      .map((r) => _lowerFirst(r.label))
      .take(_maxGains)
      .toList();

  final body = gains.isEmpty
      ? 'Move up to ${next.name} for more room to grow.'
      : 'Unlock ${_join(gains)} on ${next.name}.';

  return (title: 'Get more with ${next.name}', body: body);
}

String _join(List<String> parts) =>
    parts.length == 1 ? parts.first : '${parts.first} and ${parts.last}';

/// Benefit labels are sentence-cased for their own list; mid-sentence they need
/// to read as prose. Safe here because no label opens with an acronym.
String _lowerFirst(String s) =>
    s.isEmpty ? s : '${s[0].toLowerCase()}${s.substring(1)}';
