import 'dart:math';

/// Generates a temporary login password for a newly-created employee.
///
/// 12 characters from an alphabet that excludes glyphs that are easy to
/// misread when copied off an email (`0 O o 1 l I`), grouped into three
/// dash-separated blocks of 4 so it can be read aloud or retyped accurately
/// (e.g. `K7mp-Qx4z-Rt9w`). 12 chars clears the server RPC's 8-character floor
/// (`create_employee_auth_account`, `WEAK_PASSWORD`) with headroom.
String generateTemporaryPassword({Random? random}) {
  final rng = random ?? Random.secure();
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
  final chars = List.generate(
    12,
    (_) => alphabet[rng.nextInt(alphabet.length)],
  );
  return [
    chars.sublist(0, 4).join(),
    chars.sublist(4, 8).join(),
    chars.sublist(8, 12).join(),
  ].join('-');
}
