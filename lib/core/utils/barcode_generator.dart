import 'dart:math';

/// Generates a valid **EAN-13** barcode. Uses GS1 prefix `2` (the 20–29
/// "restricted distribution / in-store" range reserved for internal use), 11
/// random payload digits, and a computed check digit — so it scans on standard
/// retail hardware without colliding with real manufacturer GTINs.
String generateEan13({Random? random}) {
  final rng = random ?? Random.secure();
  final digits = <int>[2]; // in-store prefix
  for (var i = 0; i < 11; i++) {
    digits.add(rng.nextInt(10));
  }
  digits.add(_ean13CheckDigit(digits));
  return digits.join();
}

/// EAN-13 check digit from the first 12 digits: odd positions (1-indexed)
/// weight 1, even positions weight 3; check = (10 − sum % 10) % 10.
int _ean13CheckDigit(List<int> first12) {
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    sum += first12[i] * (i.isEven ? 1 : 3);
  }
  final mod = sum % 10;
  return mod == 0 ? 0 : 10 - mod;
}
