class Validators {
  Validators._();

  // basic
  static String? required(String? v, {String fieldName = "This field"}) {
    final value = v?.trim() ?? "";
    if (value.isEmpty) return "$fieldName is required.";
    return null;
  }

  static String? minLength(
    String? v,
    int min, {
    String fieldName = "This field",
  }) {
    final value = v?.trim() ?? "";
    if (value.isEmpty) return null;
    if (value.length < min) {
      return "$fieldName must be at least $min characters.";
    }
    return null;
  }

  static String? maxLength(
    String? v,
    int max, {
    String fieldName = "This field",
  }) {
    final value = v?.trim() ?? "";
    if (value.isEmpty) return null;
    if (value.length > max) {
      return "$fieldName must be at most $max characters.";
    }
    return null;
  }

  // email 
  static final RegExp _email = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  static String? email(String? v) {
    final value = v?.trim() ?? "";
    if (value.isEmpty) return null; 
    if (!_email.hasMatch(value)) return "Enter a valid email address.";
    return null;
  }

  // strong password ngani
  // Rules:
  // - min 8
  // - 1 uppercase
  // - 1 lowercase
  // - 1 number
  // - 1 special char
  static final RegExp _hasUpper = RegExp(r'[A-Z]');
  static final RegExp _hasLower = RegExp(r'[a-z]');
  static final RegExp _hasDigit = RegExp(r'\d');
  static final RegExp _hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/]');
  static String? strongPassword(String? v, {int min = 8}) {
    final value = v ?? "";
    if (value.isEmpty) return null;
    if (value.length < min) return "Password must be at least $min characters.";
    if (!_hasUpper.hasMatch(value)) return "Add at least 1 uppercase letter.";
    if (!_hasLower.hasMatch(value)) return "Add at least 1 lowercase letter.";
    if (!_hasDigit.hasMatch(value)) return "Add at least 1 number.";
    if (!_hasSpecial.hasMatch(value)) {
      return "Add at least 1 special character.";
    }
    return null;
  }

  static String? confirmPassword(String? v, String originalPassword) {
    final value = v ?? "";
    if (value.isEmpty) return null;
    if (value != originalPassword) return "Passwords do not match.";
    return null;
  }

  // Numbers / Digits only 
  static final RegExp _digitsOnly = RegExp(r'^\d+$');

  static String? digitsOnly(String? v, {String fieldName = "This field"}) {
    final value = v?.trim() ?? "";
    if (value.isEmpty) return null;
    if (!_digitsOnly.hasMatch(value)) {
      return "$fieldName must contain digits only.";
    }
    return null;
  }

  // Amount (2 decimals max) 
  static final RegExp _amount = RegExp(r'^\d+(\.\d{1,2})?$');

  static String? amount(String? v, {String fieldName = "Amount"}) {
    final value = v?.trim() ?? "";
    if (value.isEmpty) return null;
    if (!_amount.hasMatch(value)) {
      return "Enter a valid $fieldName (e.g., 99.99).";
    }
    return null;
  }

  static String? minAmount(
    String? v,
    double min, {
    String fieldName = "Amount",
  }) {
    final value = v?.trim() ?? "";
    if (value.isEmpty) return null;
    final parsed = double.tryParse(value);
    if (parsed == null) return "Enter a valid $fieldName.";
    if (parsed < min) return "$fieldName must be at least $min.";
    return null;
  }

  // Phone (basic) 
  static final RegExp _phone = RegExp(r'^\+?\d{10,15}$');

  static String? phone(String? v) {
    final value = (v ?? "").replaceAll(" ", "");
    if (value.isEmpty) return null;
    if (!_phone.hasMatch(value)) return "Enter a valid phone number.";
    return null;
  }

  //  Combine multiple validators
  static String? combine(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final validator in validators) {
      final res = validator(value);
      if (res != null) return res;
    }
    return null;
  }
}
