/// In-memory single source of truth for the currently-active account/business.
///
/// Set the moment an account authenticates with a resolved business; cleared on
/// logout and on account switch. Every tenant-sensitive operation (sync pulls,
/// audit writes, permission/module resolution) must read the active business
/// from HERE — never from a tenant-agnostic "first cached row" lookup, which is
/// how data leaked between accounts on shared devices.
class ActiveBusinessContext {
  String? _userId;
  String? _businessId;
  String? _branchId;
  String? _branchName;
  String? _roleName;
  String? _fullName;

  String? get userId => _userId;
  String? get businessId => _businessId;
  String? get branchId => _branchId;
  String? get branchName => _branchName;
  String? get roleName => _roleName;
  String? get fullName => _fullName;

  /// True only when a non-empty business is bound to the active session.
  bool get hasBusiness => _businessId != null && _businessId!.trim().isNotEmpty;

  bool _isBlank(String? v) => v == null || v.trim().isEmpty;

  /// Bind the active session. A blank [businessId] is normalised to null so
  /// `hasBusiness` stays a reliable guard during the pre-onboarding window.
  void set({
    required String userId,
    String? businessId,
    String? branchId,
    String? branchName,
    String? roleName,
    String? fullName,
  }) {
    _userId = userId;
    _businessId = _isBlank(businessId) ? null : businessId;
    _branchId = branchId;
    _branchName = branchName;
    _roleName = roleName;
    _fullName = fullName;
  }

  void clear() {
    _userId = null;
    _businessId = null;
    _branchId = null;
    _branchName = null;
    _roleName = null;
    _fullName = null;
  }
}
