/// Plan code → the name merchants see. Kept in one place so the plan badge,
/// the billing page and any future surface never drift on what to call a tier.
String planLabelOf(String planCode) => switch (planCode) {
  'starter' => 'Starter',
  'growth' => 'Growth',
  'business' => 'Business',
  'enterprise' => 'Enterprise',
  _ => 'Free',
};
