/// Profile fields a user may attempt to edit.
///
/// [RolePermissionMatrix.editableProfileFieldsFor] returns the set of fields
/// a role is allowed to modify on their OWN profile.
/// Editing ANOTHER user's profile always requires [AppPermission.editEmployee].
enum ProfileField {
  /// Display name / full name.
  fullName,

  /// Phone number.
  phone,

  /// Avatar / profile picture.
  profilePicture,

  /// Password change.
  password,

  /// Assigned role (only managers/owners can change this).
  role,

  /// Assigned branch (only managers/owners can reassign).
  branchAssignment,

  /// Email address (system-level, typically locked post-registration).
  email,
}

extension ProfileFieldX on ProfileField {
  String get displayLabel {
    switch (this) {
      case ProfileField.fullName:
        return 'Full Name';
      case ProfileField.phone:
        return 'Phone Number';
      case ProfileField.profilePicture:
        return 'Profile Picture';
      case ProfileField.password:
        return 'Password';
      case ProfileField.role:
        return 'Role';
      case ProfileField.branchAssignment:
        return 'Branch Assignment';
      case ProfileField.email:
        return 'Email';
    }
  }
}
