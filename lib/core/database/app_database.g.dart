// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AuthContextTableTable extends AuthContextTable
    with TableInfo<$AuthContextTableTable, AuthContextTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuthContextTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleIdMeta = const VerificationMeta('roleId');
  @override
  late final GeneratedColumn<String> roleId = GeneratedColumn<String>(
    'role_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleNameMeta = const VerificationMeta(
    'roleName',
  );
  @override
  late final GeneratedColumn<String> roleName = GeneratedColumn<String>(
    'role_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _businessNameMeta = const VerificationMeta(
    'businessName',
  );
  @override
  late final GeneratedColumn<String> businessName = GeneratedColumn<String>(
    'business_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _branchNameMeta = const VerificationMeta(
    'branchName',
  );
  @override
  late final GeneratedColumn<String> branchName = GeneratedColumn<String>(
    'branch_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _businessTemplateIdMeta =
      const VerificationMeta('businessTemplateId');
  @override
  late final GeneratedColumn<String> businessTemplateId =
      GeneratedColumn<String>(
        'business_template_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _businessTemplateNameMeta =
      const VerificationMeta('businessTemplateName');
  @override
  late final GeneratedColumn<String> businessTemplateName =
      GeneratedColumn<String>(
        'business_template_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    email,
    fullName,
    avatarUrl,
    businessId,
    roleId,
    roleName,
    businessName,
    branchId,
    branchName,
    businessTemplateId,
    businessTemplateName,
    localUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'auth_context';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuthContextTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    }
    if (data.containsKey('role_id')) {
      context.handle(
        _roleIdMeta,
        roleId.isAcceptableOrUnknown(data['role_id']!, _roleIdMeta),
      );
    }
    if (data.containsKey('role_name')) {
      context.handle(
        _roleNameMeta,
        roleName.isAcceptableOrUnknown(data['role_name']!, _roleNameMeta),
      );
    }
    if (data.containsKey('business_name')) {
      context.handle(
        _businessNameMeta,
        businessName.isAcceptableOrUnknown(
          data['business_name']!,
          _businessNameMeta,
        ),
      );
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    }
    if (data.containsKey('branch_name')) {
      context.handle(
        _branchNameMeta,
        branchName.isAcceptableOrUnknown(data['branch_name']!, _branchNameMeta),
      );
    }
    if (data.containsKey('business_template_id')) {
      context.handle(
        _businessTemplateIdMeta,
        businessTemplateId.isAcceptableOrUnknown(
          data['business_template_id']!,
          _businessTemplateIdMeta,
        ),
      );
    }
    if (data.containsKey('business_template_name')) {
      context.handle(
        _businessTemplateNameMeta,
        businessTemplateName.isAcceptableOrUnknown(
          data['business_template_name']!,
          _businessTemplateNameMeta,
        ),
      );
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  AuthContextTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuthContextTableData(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      ),
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      ),
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      ),
      roleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role_id'],
      ),
      roleName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role_name'],
      ),
      businessName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_name'],
      ),
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      ),
      branchName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_name'],
      ),
      businessTemplateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_template_id'],
      ),
      businessTemplateName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_template_name'],
      ),
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
    );
  }

  @override
  $AuthContextTableTable createAlias(String alias) {
    return $AuthContextTableTable(attachedDatabase, alias);
  }
}

class AuthContextTableData extends DataClass
    implements Insertable<AuthContextTableData> {
  /// User's Supabase Auth UID (primary key for single current user)
  final String userId;

  /// User's email address
  final String? email;

  /// User's full name
  final String? fullName;

  /// User's avatar URL (Supabase Storage public URL)
  final String? avatarUrl;

  /// Associated business ID (from database trigger context)
  final String? businessId;

  /// User's role ID in the business
  final String? roleId;

  /// User's role name (e.g., "Business Owner", "Manager")
  final String? roleName;

  /// Associated business name
  final String? businessName;

  /// User's default/primary branch ID
  final String? branchId;

  /// User's default/primary branch name
  final String? branchName;

  /// Business template ID (cached to avoid repeated DB lookups)
  final String? businessTemplateId;

  /// Business template name / category label (e.g. "Restaurant", "Coffee Shop")
  final String? businessTemplateName;

  /// Last time this context was updated locally
  final DateTime localUpdatedAt;
  const AuthContextTableData({
    required this.userId,
    this.email,
    this.fullName,
    this.avatarUrl,
    this.businessId,
    this.roleId,
    this.roleName,
    this.businessName,
    this.branchId,
    this.branchName,
    this.businessTemplateId,
    this.businessTemplateName,
    required this.localUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || fullName != null) {
      map['full_name'] = Variable<String>(fullName);
    }
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    if (!nullToAbsent || businessId != null) {
      map['business_id'] = Variable<String>(businessId);
    }
    if (!nullToAbsent || roleId != null) {
      map['role_id'] = Variable<String>(roleId);
    }
    if (!nullToAbsent || roleName != null) {
      map['role_name'] = Variable<String>(roleName);
    }
    if (!nullToAbsent || businessName != null) {
      map['business_name'] = Variable<String>(businessName);
    }
    if (!nullToAbsent || branchId != null) {
      map['branch_id'] = Variable<String>(branchId);
    }
    if (!nullToAbsent || branchName != null) {
      map['branch_name'] = Variable<String>(branchName);
    }
    if (!nullToAbsent || businessTemplateId != null) {
      map['business_template_id'] = Variable<String>(businessTemplateId);
    }
    if (!nullToAbsent || businessTemplateName != null) {
      map['business_template_name'] = Variable<String>(businessTemplateName);
    }
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    return map;
  }

  AuthContextTableCompanion toCompanion(bool nullToAbsent) {
    return AuthContextTableCompanion(
      userId: Value(userId),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      fullName: fullName == null && nullToAbsent
          ? const Value.absent()
          : Value(fullName),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      businessId: businessId == null && nullToAbsent
          ? const Value.absent()
          : Value(businessId),
      roleId: roleId == null && nullToAbsent
          ? const Value.absent()
          : Value(roleId),
      roleName: roleName == null && nullToAbsent
          ? const Value.absent()
          : Value(roleName),
      businessName: businessName == null && nullToAbsent
          ? const Value.absent()
          : Value(businessName),
      branchId: branchId == null && nullToAbsent
          ? const Value.absent()
          : Value(branchId),
      branchName: branchName == null && nullToAbsent
          ? const Value.absent()
          : Value(branchName),
      businessTemplateId: businessTemplateId == null && nullToAbsent
          ? const Value.absent()
          : Value(businessTemplateId),
      businessTemplateName: businessTemplateName == null && nullToAbsent
          ? const Value.absent()
          : Value(businessTemplateName),
      localUpdatedAt: Value(localUpdatedAt),
    );
  }

  factory AuthContextTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuthContextTableData(
      userId: serializer.fromJson<String>(json['userId']),
      email: serializer.fromJson<String?>(json['email']),
      fullName: serializer.fromJson<String?>(json['fullName']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      businessId: serializer.fromJson<String?>(json['businessId']),
      roleId: serializer.fromJson<String?>(json['roleId']),
      roleName: serializer.fromJson<String?>(json['roleName']),
      businessName: serializer.fromJson<String?>(json['businessName']),
      branchId: serializer.fromJson<String?>(json['branchId']),
      branchName: serializer.fromJson<String?>(json['branchName']),
      businessTemplateId: serializer.fromJson<String?>(
        json['businessTemplateId'],
      ),
      businessTemplateName: serializer.fromJson<String?>(
        json['businessTemplateName'],
      ),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'email': serializer.toJson<String?>(email),
      'fullName': serializer.toJson<String?>(fullName),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'businessId': serializer.toJson<String?>(businessId),
      'roleId': serializer.toJson<String?>(roleId),
      'roleName': serializer.toJson<String?>(roleName),
      'businessName': serializer.toJson<String?>(businessName),
      'branchId': serializer.toJson<String?>(branchId),
      'branchName': serializer.toJson<String?>(branchName),
      'businessTemplateId': serializer.toJson<String?>(businessTemplateId),
      'businessTemplateName': serializer.toJson<String?>(businessTemplateName),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
    };
  }

  AuthContextTableData copyWith({
    String? userId,
    Value<String?> email = const Value.absent(),
    Value<String?> fullName = const Value.absent(),
    Value<String?> avatarUrl = const Value.absent(),
    Value<String?> businessId = const Value.absent(),
    Value<String?> roleId = const Value.absent(),
    Value<String?> roleName = const Value.absent(),
    Value<String?> businessName = const Value.absent(),
    Value<String?> branchId = const Value.absent(),
    Value<String?> branchName = const Value.absent(),
    Value<String?> businessTemplateId = const Value.absent(),
    Value<String?> businessTemplateName = const Value.absent(),
    DateTime? localUpdatedAt,
  }) => AuthContextTableData(
    userId: userId ?? this.userId,
    email: email.present ? email.value : this.email,
    fullName: fullName.present ? fullName.value : this.fullName,
    avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
    businessId: businessId.present ? businessId.value : this.businessId,
    roleId: roleId.present ? roleId.value : this.roleId,
    roleName: roleName.present ? roleName.value : this.roleName,
    businessName: businessName.present ? businessName.value : this.businessName,
    branchId: branchId.present ? branchId.value : this.branchId,
    branchName: branchName.present ? branchName.value : this.branchName,
    businessTemplateId: businessTemplateId.present
        ? businessTemplateId.value
        : this.businessTemplateId,
    businessTemplateName: businessTemplateName.present
        ? businessTemplateName.value
        : this.businessTemplateName,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
  );
  AuthContextTableData copyWithCompanion(AuthContextTableCompanion data) {
    return AuthContextTableData(
      userId: data.userId.present ? data.userId.value : this.userId,
      email: data.email.present ? data.email.value : this.email,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      roleId: data.roleId.present ? data.roleId.value : this.roleId,
      roleName: data.roleName.present ? data.roleName.value : this.roleName,
      businessName: data.businessName.present
          ? data.businessName.value
          : this.businessName,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      branchName: data.branchName.present
          ? data.branchName.value
          : this.branchName,
      businessTemplateId: data.businessTemplateId.present
          ? data.businessTemplateId.value
          : this.businessTemplateId,
      businessTemplateName: data.businessTemplateName.present
          ? data.businessTemplateName.value
          : this.businessTemplateName,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuthContextTableData(')
          ..write('userId: $userId, ')
          ..write('email: $email, ')
          ..write('fullName: $fullName, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('businessId: $businessId, ')
          ..write('roleId: $roleId, ')
          ..write('roleName: $roleName, ')
          ..write('businessName: $businessName, ')
          ..write('branchId: $branchId, ')
          ..write('branchName: $branchName, ')
          ..write('businessTemplateId: $businessTemplateId, ')
          ..write('businessTemplateName: $businessTemplateName, ')
          ..write('localUpdatedAt: $localUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    email,
    fullName,
    avatarUrl,
    businessId,
    roleId,
    roleName,
    businessName,
    branchId,
    branchName,
    businessTemplateId,
    businessTemplateName,
    localUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuthContextTableData &&
          other.userId == this.userId &&
          other.email == this.email &&
          other.fullName == this.fullName &&
          other.avatarUrl == this.avatarUrl &&
          other.businessId == this.businessId &&
          other.roleId == this.roleId &&
          other.roleName == this.roleName &&
          other.businessName == this.businessName &&
          other.branchId == this.branchId &&
          other.branchName == this.branchName &&
          other.businessTemplateId == this.businessTemplateId &&
          other.businessTemplateName == this.businessTemplateName &&
          other.localUpdatedAt == this.localUpdatedAt);
}

class AuthContextTableCompanion extends UpdateCompanion<AuthContextTableData> {
  final Value<String> userId;
  final Value<String?> email;
  final Value<String?> fullName;
  final Value<String?> avatarUrl;
  final Value<String?> businessId;
  final Value<String?> roleId;
  final Value<String?> roleName;
  final Value<String?> businessName;
  final Value<String?> branchId;
  final Value<String?> branchName;
  final Value<String?> businessTemplateId;
  final Value<String?> businessTemplateName;
  final Value<DateTime> localUpdatedAt;
  final Value<int> rowid;
  const AuthContextTableCompanion({
    this.userId = const Value.absent(),
    this.email = const Value.absent(),
    this.fullName = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.businessId = const Value.absent(),
    this.roleId = const Value.absent(),
    this.roleName = const Value.absent(),
    this.businessName = const Value.absent(),
    this.branchId = const Value.absent(),
    this.branchName = const Value.absent(),
    this.businessTemplateId = const Value.absent(),
    this.businessTemplateName = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuthContextTableCompanion.insert({
    required String userId,
    this.email = const Value.absent(),
    this.fullName = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.businessId = const Value.absent(),
    this.roleId = const Value.absent(),
    this.roleName = const Value.absent(),
    this.businessName = const Value.absent(),
    this.branchId = const Value.absent(),
    this.branchName = const Value.absent(),
    this.businessTemplateId = const Value.absent(),
    this.businessTemplateName = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<AuthContextTableData> custom({
    Expression<String>? userId,
    Expression<String>? email,
    Expression<String>? fullName,
    Expression<String>? avatarUrl,
    Expression<String>? businessId,
    Expression<String>? roleId,
    Expression<String>? roleName,
    Expression<String>? businessName,
    Expression<String>? branchId,
    Expression<String>? branchName,
    Expression<String>? businessTemplateId,
    Expression<String>? businessTemplateName,
    Expression<DateTime>? localUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (email != null) 'email': email,
      if (fullName != null) 'full_name': fullName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (businessId != null) 'business_id': businessId,
      if (roleId != null) 'role_id': roleId,
      if (roleName != null) 'role_name': roleName,
      if (businessName != null) 'business_name': businessName,
      if (branchId != null) 'branch_id': branchId,
      if (branchName != null) 'branch_name': branchName,
      if (businessTemplateId != null)
        'business_template_id': businessTemplateId,
      if (businessTemplateName != null)
        'business_template_name': businessTemplateName,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuthContextTableCompanion copyWith({
    Value<String>? userId,
    Value<String?>? email,
    Value<String?>? fullName,
    Value<String?>? avatarUrl,
    Value<String?>? businessId,
    Value<String?>? roleId,
    Value<String?>? roleName,
    Value<String?>? businessName,
    Value<String?>? branchId,
    Value<String?>? branchName,
    Value<String?>? businessTemplateId,
    Value<String?>? businessTemplateName,
    Value<DateTime>? localUpdatedAt,
    Value<int>? rowid,
  }) {
    return AuthContextTableCompanion(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      businessId: businessId ?? this.businessId,
      roleId: roleId ?? this.roleId,
      roleName: roleName ?? this.roleName,
      businessName: businessName ?? this.businessName,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      businessTemplateId: businessTemplateId ?? this.businessTemplateId,
      businessTemplateName: businessTemplateName ?? this.businessTemplateName,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (roleId.present) {
      map['role_id'] = Variable<String>(roleId.value);
    }
    if (roleName.present) {
      map['role_name'] = Variable<String>(roleName.value);
    }
    if (businessName.present) {
      map['business_name'] = Variable<String>(businessName.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (branchName.present) {
      map['branch_name'] = Variable<String>(branchName.value);
    }
    if (businessTemplateId.present) {
      map['business_template_id'] = Variable<String>(businessTemplateId.value);
    }
    if (businessTemplateName.present) {
      map['business_template_name'] = Variable<String>(
        businessTemplateName.value,
      );
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuthContextTableCompanion(')
          ..write('userId: $userId, ')
          ..write('email: $email, ')
          ..write('fullName: $fullName, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('businessId: $businessId, ')
          ..write('roleId: $roleId, ')
          ..write('roleName: $roleName, ')
          ..write('businessName: $businessName, ')
          ..write('branchId: $branchId, ')
          ..write('branchName: $branchName, ')
          ..write('businessTemplateId: $businessTemplateId, ')
          ..write('businessTemplateName: $businessTemplateName, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BusinessTemplatesTableTable extends BusinessTemplatesTable
    with TableInfo<$BusinessTemplatesTableTable, BusinessTemplatesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BusinessTemplatesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    name,
    version,
    isActive,
    createdAt,
    localUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'business_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<BusinessTemplatesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BusinessTemplatesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BusinessTemplatesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
    );
  }

  @override
  $BusinessTemplatesTableTable createAlias(String alias) {
    return $BusinessTemplatesTableTable(attachedDatabase, alias);
  }
}

class BusinessTemplatesTableData extends DataClass
    implements Insertable<BusinessTemplatesTableData> {
  final String id;

  /// Stable machine-readable key matching business_templates.code on server.
  final String code;
  final String name;
  final int version;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime localUpdatedAt;
  const BusinessTemplatesTableData({
    required this.id,
    required this.code,
    required this.name,
    required this.version,
    required this.isActive,
    this.createdAt,
    required this.localUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['version'] = Variable<int>(version);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    return map;
  }

  BusinessTemplatesTableCompanion toCompanion(bool nullToAbsent) {
    return BusinessTemplatesTableCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      version: Value(version),
      isActive: Value(isActive),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      localUpdatedAt: Value(localUpdatedAt),
    );
  }

  factory BusinessTemplatesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BusinessTemplatesTableData(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      version: serializer.fromJson<int>(json['version']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'version': serializer.toJson<int>(version),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
    };
  }

  BusinessTemplatesTableData copyWith({
    String? id,
    String? code,
    String? name,
    int? version,
    bool? isActive,
    Value<DateTime?> createdAt = const Value.absent(),
    DateTime? localUpdatedAt,
  }) => BusinessTemplatesTableData(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    version: version ?? this.version,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
  );
  BusinessTemplatesTableData copyWithCompanion(
    BusinessTemplatesTableCompanion data,
  ) {
    return BusinessTemplatesTableData(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      version: data.version.present ? data.version.value : this.version,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BusinessTemplatesTableData(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('version: $version, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('localUpdatedAt: $localUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, code, name, version, isActive, createdAt, localUpdatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BusinessTemplatesTableData &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.version == this.version &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.localUpdatedAt == this.localUpdatedAt);
}

class BusinessTemplatesTableCompanion
    extends UpdateCompanion<BusinessTemplatesTableData> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> name;
  final Value<int> version;
  final Value<bool> isActive;
  final Value<DateTime?> createdAt;
  final Value<DateTime> localUpdatedAt;
  final Value<int> rowid;
  const BusinessTemplatesTableCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.version = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BusinessTemplatesTableCompanion.insert({
    required String id,
    this.code = const Value.absent(),
    required String name,
    this.version = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<BusinessTemplatesTableData> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<int>? version,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? localUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (version != null) 'version': version,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BusinessTemplatesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? code,
    Value<String>? name,
    Value<int>? version,
    Value<bool>? isActive,
    Value<DateTime?>? createdAt,
    Value<DateTime>? localUpdatedAt,
    Value<int>? rowid,
  }) {
    return BusinessTemplatesTableCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      version: version ?? this.version,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BusinessTemplatesTableCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('version: $version, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BusinessesTableTable extends BusinessesTable
    with TableInfo<$BusinessesTableTable, BusinessesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BusinessesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncAttemptMeta = const VerificationMeta(
    'lastSyncAttempt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAttempt =
      GeneratedColumn<DateTime>(
        'last_sync_attempt',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    ownerId,
    templateId,
    createdAt,
    isActive,
    syncStatus,
    lastSyncAttempt,
    syncError,
    localUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'businesses';
  @override
  VerificationContext validateIntegrity(
    Insertable<BusinessesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('last_sync_attempt')) {
      context.handle(
        _lastSyncAttemptMeta,
        lastSyncAttempt.isAcceptableOrUnknown(
          data['last_sync_attempt']!,
          _lastSyncAttemptMeta,
        ),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BusinessesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BusinessesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      lastSyncAttempt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_attempt'],
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
    );
  }

  @override
  $BusinessesTableTable createAlias(String alias) {
    return $BusinessesTableTable(attachedDatabase, alias);
  }
}

class BusinessesTableData extends DataClass
    implements Insertable<BusinessesTableData> {
  /// UUID - generated locally, should match Supabase after sync
  final String id;
  final String name;
  final String ownerId;
  final String templateId;
  final DateTime createdAt;
  final bool isActive;

  /// Sync tracking fields
  /// 0=pendingUpload, 1=pendingUpdate, 2=pendingDelete, 3=synced, 4=failed
  final int syncStatus;
  final DateTime? lastSyncAttempt;
  final String? syncError;
  final DateTime localUpdatedAt;
  const BusinessesTableData({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.templateId,
    required this.createdAt,
    required this.isActive,
    required this.syncStatus,
    this.lastSyncAttempt,
    this.syncError,
    required this.localUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['owner_id'] = Variable<String>(ownerId);
    map['template_id'] = Variable<String>(templateId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_active'] = Variable<bool>(isActive);
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || lastSyncAttempt != null) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt);
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    return map;
  }

  BusinessesTableCompanion toCompanion(bool nullToAbsent) {
    return BusinessesTableCompanion(
      id: Value(id),
      name: Value(name),
      ownerId: Value(ownerId),
      templateId: Value(templateId),
      createdAt: Value(createdAt),
      isActive: Value(isActive),
      syncStatus: Value(syncStatus),
      lastSyncAttempt: lastSyncAttempt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAttempt),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      localUpdatedAt: Value(localUpdatedAt),
    );
  }

  factory BusinessesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BusinessesTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      templateId: serializer.fromJson<String>(json['templateId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      lastSyncAttempt: serializer.fromJson<DateTime?>(json['lastSyncAttempt']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'ownerId': serializer.toJson<String>(ownerId),
      'templateId': serializer.toJson<String>(templateId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isActive': serializer.toJson<bool>(isActive),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'lastSyncAttempt': serializer.toJson<DateTime?>(lastSyncAttempt),
      'syncError': serializer.toJson<String?>(syncError),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
    };
  }

  BusinessesTableData copyWith({
    String? id,
    String? name,
    String? ownerId,
    String? templateId,
    DateTime? createdAt,
    bool? isActive,
    int? syncStatus,
    Value<DateTime?> lastSyncAttempt = const Value.absent(),
    Value<String?> syncError = const Value.absent(),
    DateTime? localUpdatedAt,
  }) => BusinessesTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    ownerId: ownerId ?? this.ownerId,
    templateId: templateId ?? this.templateId,
    createdAt: createdAt ?? this.createdAt,
    isActive: isActive ?? this.isActive,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncAttempt: lastSyncAttempt.present
        ? lastSyncAttempt.value
        : this.lastSyncAttempt,
    syncError: syncError.present ? syncError.value : this.syncError,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
  );
  BusinessesTableData copyWithCompanion(BusinessesTableCompanion data) {
    return BusinessesTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastSyncAttempt: data.lastSyncAttempt.present
          ? data.lastSyncAttempt.value
          : this.lastSyncAttempt,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BusinessesTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ownerId: $ownerId, ')
          ..write('templateId: $templateId, ')
          ..write('createdAt: $createdAt, ')
          ..write('isActive: $isActive, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError, ')
          ..write('localUpdatedAt: $localUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    ownerId,
    templateId,
    createdAt,
    isActive,
    syncStatus,
    lastSyncAttempt,
    syncError,
    localUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BusinessesTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.ownerId == this.ownerId &&
          other.templateId == this.templateId &&
          other.createdAt == this.createdAt &&
          other.isActive == this.isActive &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncAttempt == this.lastSyncAttempt &&
          other.syncError == this.syncError &&
          other.localUpdatedAt == this.localUpdatedAt);
}

class BusinessesTableCompanion extends UpdateCompanion<BusinessesTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> ownerId;
  final Value<String> templateId;
  final Value<DateTime> createdAt;
  final Value<bool> isActive;
  final Value<int> syncStatus;
  final Value<DateTime?> lastSyncAttempt;
  final Value<String?> syncError;
  final Value<DateTime> localUpdatedAt;
  final Value<int> rowid;
  const BusinessesTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.templateId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BusinessesTableCompanion.insert({
    required String id,
    required String name,
    required String ownerId,
    required String templateId,
    required DateTime createdAt,
    this.isActive = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       ownerId = Value(ownerId),
       templateId = Value(templateId),
       createdAt = Value(createdAt);
  static Insertable<BusinessesTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? ownerId,
    Expression<String>? templateId,
    Expression<DateTime>? createdAt,
    Expression<bool>? isActive,
    Expression<int>? syncStatus,
    Expression<DateTime>? lastSyncAttempt,
    Expression<String>? syncError,
    Expression<DateTime>? localUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (ownerId != null) 'owner_id': ownerId,
      if (templateId != null) 'template_id': templateId,
      if (createdAt != null) 'created_at': createdAt,
      if (isActive != null) 'is_active': isActive,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncAttempt != null) 'last_sync_attempt': lastSyncAttempt,
      if (syncError != null) 'sync_error': syncError,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BusinessesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? ownerId,
    Value<String>? templateId,
    Value<DateTime>? createdAt,
    Value<bool>? isActive,
    Value<int>? syncStatus,
    Value<DateTime?>? lastSyncAttempt,
    Value<String?>? syncError,
    Value<DateTime>? localUpdatedAt,
    Value<int>? rowid,
  }) {
    return BusinessesTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      templateId: templateId ?? this.templateId,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      syncError: syncError ?? this.syncError,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (lastSyncAttempt.present) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BusinessesTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ownerId: $ownerId, ')
          ..write('templateId: $templateId, ')
          ..write('createdAt: $createdAt, ')
          ..write('isActive: $isActive, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BranchesTableTable extends BranchesTable
    with TableInfo<$BranchesTableTable, BranchesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BranchesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncAttemptMeta = const VerificationMeta(
    'lastSyncAttempt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAttempt =
      GeneratedColumn<DateTime>(
        'last_sync_attempt',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    name,
    location,
    syncStatus,
    lastSyncAttempt,
    syncError,
    localUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'branches';
  @override
  VerificationContext validateIntegrity(
    Insertable<BranchesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('last_sync_attempt')) {
      context.handle(
        _lastSyncAttemptMeta,
        lastSyncAttempt.isAcceptableOrUnknown(
          data['last_sync_attempt']!,
          _lastSyncAttemptMeta,
        ),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BranchesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BranchesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      lastSyncAttempt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_attempt'],
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
    );
  }

  @override
  $BranchesTableTable createAlias(String alias) {
    return $BranchesTableTable(attachedDatabase, alias);
  }
}

class BranchesTableData extends DataClass
    implements Insertable<BranchesTableData> {
  /// UUID - generated locally, should match Supabase after sync
  final String id;

  /// Foreign key to businesses table
  final String businessId;

  /// Branch name (required)
  final String name;

  /// Branch location/address (optional)
  final String? location;

  /// Sync tracking fields
  /// 0=pendingUpload, 1=pendingUpdate, 2=pendingDelete, 3=synced, 4=failed
  final int syncStatus;
  final DateTime? lastSyncAttempt;
  final String? syncError;
  final DateTime localUpdatedAt;
  const BranchesTableData({
    required this.id,
    required this.businessId,
    required this.name,
    this.location,
    required this.syncStatus,
    this.lastSyncAttempt,
    this.syncError,
    required this.localUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || lastSyncAttempt != null) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt);
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    return map;
  }

  BranchesTableCompanion toCompanion(bool nullToAbsent) {
    return BranchesTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      name: Value(name),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      syncStatus: Value(syncStatus),
      lastSyncAttempt: lastSyncAttempt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAttempt),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      localUpdatedAt: Value(localUpdatedAt),
    );
  }

  factory BranchesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BranchesTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      name: serializer.fromJson<String>(json['name']),
      location: serializer.fromJson<String?>(json['location']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      lastSyncAttempt: serializer.fromJson<DateTime?>(json['lastSyncAttempt']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'name': serializer.toJson<String>(name),
      'location': serializer.toJson<String?>(location),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'lastSyncAttempt': serializer.toJson<DateTime?>(lastSyncAttempt),
      'syncError': serializer.toJson<String?>(syncError),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
    };
  }

  BranchesTableData copyWith({
    String? id,
    String? businessId,
    String? name,
    Value<String?> location = const Value.absent(),
    int? syncStatus,
    Value<DateTime?> lastSyncAttempt = const Value.absent(),
    Value<String?> syncError = const Value.absent(),
    DateTime? localUpdatedAt,
  }) => BranchesTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    name: name ?? this.name,
    location: location.present ? location.value : this.location,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncAttempt: lastSyncAttempt.present
        ? lastSyncAttempt.value
        : this.lastSyncAttempt,
    syncError: syncError.present ? syncError.value : this.syncError,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
  );
  BranchesTableData copyWithCompanion(BranchesTableCompanion data) {
    return BranchesTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      location: data.location.present ? data.location.value : this.location,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastSyncAttempt: data.lastSyncAttempt.present
          ? data.lastSyncAttempt.value
          : this.lastSyncAttempt,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BranchesTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('location: $location, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError, ')
          ..write('localUpdatedAt: $localUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    name,
    location,
    syncStatus,
    lastSyncAttempt,
    syncError,
    localUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BranchesTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.location == this.location &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncAttempt == this.lastSyncAttempt &&
          other.syncError == this.syncError &&
          other.localUpdatedAt == this.localUpdatedAt);
}

class BranchesTableCompanion extends UpdateCompanion<BranchesTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> name;
  final Value<String?> location;
  final Value<int> syncStatus;
  final Value<DateTime?> lastSyncAttempt;
  final Value<String?> syncError;
  final Value<DateTime> localUpdatedAt;
  final Value<int> rowid;
  const BranchesTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.location = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BranchesTableCompanion.insert({
    required String id,
    required String businessId,
    required String name,
    this.location = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       name = Value(name);
  static Insertable<BranchesTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<String>? location,
    Expression<int>? syncStatus,
    Expression<DateTime>? lastSyncAttempt,
    Expression<String>? syncError,
    Expression<DateTime>? localUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (location != null) 'location': location,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncAttempt != null) 'last_sync_attempt': lastSyncAttempt,
      if (syncError != null) 'sync_error': syncError,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BranchesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? name,
    Value<String?>? location,
    Value<int>? syncStatus,
    Value<DateTime?>? lastSyncAttempt,
    Value<String?>? syncError,
    Value<DateTime>? localUpdatedAt,
    Value<int>? rowid,
  }) {
    return BranchesTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      location: location ?? this.location,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      syncError: syncError ?? this.syncError,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (lastSyncAttempt.present) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BranchesTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('location: $location, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTableTable extends CategoriesTable
    with TableInfo<$CategoriesTableTable, CategoriesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncAttemptMeta = const VerificationMeta(
    'lastSyncAttempt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAttempt =
      GeneratedColumn<DateTime>(
        'last_sync_attempt',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    name,
    sortOrder,
    syncStatus,
    lastSyncAttempt,
    syncError,
    localUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoriesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('last_sync_attempt')) {
      context.handle(
        _lastSyncAttemptMeta,
        lastSyncAttempt.isAcceptableOrUnknown(
          data['last_sync_attempt']!,
          _lastSyncAttemptMeta,
        ),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoriesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoriesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      lastSyncAttempt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_attempt'],
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
    );
  }

  @override
  $CategoriesTableTable createAlias(String alias) {
    return $CategoriesTableTable(attachedDatabase, alias);
  }
}

class CategoriesTableData extends DataClass
    implements Insertable<CategoriesTableData> {
  final String id;
  final String businessId;
  final String name;
  final int sortOrder;

  /// 0=pendingUpload, 1=pendingUpdate, 2=pendingDelete, 3=synced, 4=failed
  final int syncStatus;
  final DateTime? lastSyncAttempt;
  final String? syncError;
  final DateTime localUpdatedAt;
  const CategoriesTableData({
    required this.id,
    required this.businessId,
    required this.name,
    required this.sortOrder,
    required this.syncStatus,
    this.lastSyncAttempt,
    this.syncError,
    required this.localUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || lastSyncAttempt != null) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt);
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    return map;
  }

  CategoriesTableCompanion toCompanion(bool nullToAbsent) {
    return CategoriesTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      name: Value(name),
      sortOrder: Value(sortOrder),
      syncStatus: Value(syncStatus),
      lastSyncAttempt: lastSyncAttempt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAttempt),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      localUpdatedAt: Value(localUpdatedAt),
    );
  }

  factory CategoriesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoriesTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      lastSyncAttempt: serializer.fromJson<DateTime?>(json['lastSyncAttempt']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'lastSyncAttempt': serializer.toJson<DateTime?>(lastSyncAttempt),
      'syncError': serializer.toJson<String?>(syncError),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
    };
  }

  CategoriesTableData copyWith({
    String? id,
    String? businessId,
    String? name,
    int? sortOrder,
    int? syncStatus,
    Value<DateTime?> lastSyncAttempt = const Value.absent(),
    Value<String?> syncError = const Value.absent(),
    DateTime? localUpdatedAt,
  }) => CategoriesTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncAttempt: lastSyncAttempt.present
        ? lastSyncAttempt.value
        : this.lastSyncAttempt,
    syncError: syncError.present ? syncError.value : this.syncError,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
  );
  CategoriesTableData copyWithCompanion(CategoriesTableCompanion data) {
    return CategoriesTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastSyncAttempt: data.lastSyncAttempt.present
          ? data.lastSyncAttempt.value
          : this.lastSyncAttempt,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError, ')
          ..write('localUpdatedAt: $localUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    name,
    sortOrder,
    syncStatus,
    lastSyncAttempt,
    syncError,
    localUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoriesTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncAttempt == this.lastSyncAttempt &&
          other.syncError == this.syncError &&
          other.localUpdatedAt == this.localUpdatedAt);
}

class CategoriesTableCompanion extends UpdateCompanion<CategoriesTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<int> syncStatus;
  final Value<DateTime?> lastSyncAttempt;
  final Value<String?> syncError;
  final Value<DateTime> localUpdatedAt;
  final Value<int> rowid;
  const CategoriesTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesTableCompanion.insert({
    required String id,
    required String businessId,
    required String name,
    this.sortOrder = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       name = Value(name);
  static Insertable<CategoriesTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<int>? syncStatus,
    Expression<DateTime>? lastSyncAttempt,
    Expression<String>? syncError,
    Expression<DateTime>? localUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncAttempt != null) 'last_sync_attempt': lastSyncAttempt,
      if (syncError != null) 'sync_error': syncError,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<int>? syncStatus,
    Value<DateTime?>? lastSyncAttempt,
    Value<String?>? syncError,
    Value<DateTime>? localUpdatedAt,
    Value<int>? rowid,
  }) {
    return CategoriesTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      syncError: syncError ?? this.syncError,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (lastSyncAttempt.present) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTableTable extends ExpensesTable
    with TableInfo<$ExpensesTableTable, ExpenseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _branchNameMeta = const VerificationMeta(
    'branchName',
  );
  @override
  late final GeneratedColumn<String> branchName = GeneratedColumn<String>(
    'branch_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vendorMeta = const VerificationMeta('vendor');
  @override
  late final GeneratedColumn<String> vendor = GeneratedColumn<String>(
    'vendor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _submittedByIdMeta = const VerificationMeta(
    'submittedById',
  );
  @override
  late final GeneratedColumn<String> submittedById = GeneratedColumn<String>(
    'submitted_by_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _submittedByNameMeta = const VerificationMeta(
    'submittedByName',
  );
  @override
  late final GeneratedColumn<String> submittedByName = GeneratedColumn<String>(
    'submitted_by_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _approvedByIdMeta = const VerificationMeta(
    'approvedById',
  );
  @override
  late final GeneratedColumn<String> approvedById = GeneratedColumn<String>(
    'approved_by_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _approvedByNameMeta = const VerificationMeta(
    'approvedByName',
  );
  @override
  late final GeneratedColumn<String> approvedByName = GeneratedColumn<String>(
    'approved_by_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expenseDateMeta = const VerificationMeta(
    'expenseDate',
  );
  @override
  late final GeneratedColumn<DateTime> expenseDate = GeneratedColumn<DateTime>(
    'expense_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncAttemptMeta = const VerificationMeta(
    'lastSyncAttempt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAttempt =
      GeneratedColumn<DateTime>(
        'last_sync_attempt',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    branchId,
    branchName,
    category,
    vendor,
    amount,
    status,
    submittedById,
    submittedByName,
    approvedById,
    approvedByName,
    note,
    expenseDate,
    createdAt,
    updatedAt,
    syncStatus,
    lastSyncAttempt,
    syncError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpenseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    }
    if (data.containsKey('branch_name')) {
      context.handle(
        _branchNameMeta,
        branchName.isAcceptableOrUnknown(data['branch_name']!, _branchNameMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('vendor')) {
      context.handle(
        _vendorMeta,
        vendor.isAcceptableOrUnknown(data['vendor']!, _vendorMeta),
      );
    } else if (isInserting) {
      context.missing(_vendorMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('submitted_by_id')) {
      context.handle(
        _submittedByIdMeta,
        submittedById.isAcceptableOrUnknown(
          data['submitted_by_id']!,
          _submittedByIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_submittedByIdMeta);
    }
    if (data.containsKey('submitted_by_name')) {
      context.handle(
        _submittedByNameMeta,
        submittedByName.isAcceptableOrUnknown(
          data['submitted_by_name']!,
          _submittedByNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_submittedByNameMeta);
    }
    if (data.containsKey('approved_by_id')) {
      context.handle(
        _approvedByIdMeta,
        approvedById.isAcceptableOrUnknown(
          data['approved_by_id']!,
          _approvedByIdMeta,
        ),
      );
    }
    if (data.containsKey('approved_by_name')) {
      context.handle(
        _approvedByNameMeta,
        approvedByName.isAcceptableOrUnknown(
          data['approved_by_name']!,
          _approvedByNameMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('expense_date')) {
      context.handle(
        _expenseDateMeta,
        expenseDate.isAcceptableOrUnknown(
          data['expense_date']!,
          _expenseDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expenseDateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('last_sync_attempt')) {
      context.handle(
        _lastSyncAttemptMeta,
        lastSyncAttempt.isAcceptableOrUnknown(
          data['last_sync_attempt']!,
          _lastSyncAttemptMeta,
        ),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExpenseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      ),
      branchName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_name'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      vendor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vendor'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      submittedById: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}submitted_by_id'],
      )!,
      submittedByName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}submitted_by_name'],
      )!,
      approvedById: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approved_by_id'],
      ),
      approvedByName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approved_by_name'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      expenseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expense_date'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      lastSyncAttempt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_attempt'],
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
    );
  }

  @override
  $ExpensesTableTable createAlias(String alias) {
    return $ExpensesTableTable(attachedDatabase, alias);
  }
}

class ExpenseRow extends DataClass implements Insertable<ExpenseRow> {
  final String id;
  final String businessId;
  final String? branchId;
  final String? branchName;
  final String category;
  final String vendor;
  final double amount;

  /// 'pending' | 'approved' | 'rejected' | 'draft'
  final String status;
  final String submittedById;
  final String submittedByName;
  final String? approvedById;
  final String? approvedByName;
  final String? note;
  final DateTime expenseDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 0=pendingUpload, 1=pendingUpdate, 2=pendingDelete, 3=synced, 4=failed
  final int syncStatus;
  final DateTime? lastSyncAttempt;
  final String? syncError;
  const ExpenseRow({
    required this.id,
    required this.businessId,
    this.branchId,
    this.branchName,
    required this.category,
    required this.vendor,
    required this.amount,
    required this.status,
    required this.submittedById,
    required this.submittedByName,
    this.approvedById,
    this.approvedByName,
    this.note,
    required this.expenseDate,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.lastSyncAttempt,
    this.syncError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    if (!nullToAbsent || branchId != null) {
      map['branch_id'] = Variable<String>(branchId);
    }
    if (!nullToAbsent || branchName != null) {
      map['branch_name'] = Variable<String>(branchName);
    }
    map['category'] = Variable<String>(category);
    map['vendor'] = Variable<String>(vendor);
    map['amount'] = Variable<double>(amount);
    map['status'] = Variable<String>(status);
    map['submitted_by_id'] = Variable<String>(submittedById);
    map['submitted_by_name'] = Variable<String>(submittedByName);
    if (!nullToAbsent || approvedById != null) {
      map['approved_by_id'] = Variable<String>(approvedById);
    }
    if (!nullToAbsent || approvedByName != null) {
      map['approved_by_name'] = Variable<String>(approvedByName);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['expense_date'] = Variable<DateTime>(expenseDate);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || lastSyncAttempt != null) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt);
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    return map;
  }

  ExpensesTableCompanion toCompanion(bool nullToAbsent) {
    return ExpensesTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      branchId: branchId == null && nullToAbsent
          ? const Value.absent()
          : Value(branchId),
      branchName: branchName == null && nullToAbsent
          ? const Value.absent()
          : Value(branchName),
      category: Value(category),
      vendor: Value(vendor),
      amount: Value(amount),
      status: Value(status),
      submittedById: Value(submittedById),
      submittedByName: Value(submittedByName),
      approvedById: approvedById == null && nullToAbsent
          ? const Value.absent()
          : Value(approvedById),
      approvedByName: approvedByName == null && nullToAbsent
          ? const Value.absent()
          : Value(approvedByName),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      expenseDate: Value(expenseDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      lastSyncAttempt: lastSyncAttempt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAttempt),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
    );
  }

  factory ExpenseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseRow(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      branchId: serializer.fromJson<String?>(json['branchId']),
      branchName: serializer.fromJson<String?>(json['branchName']),
      category: serializer.fromJson<String>(json['category']),
      vendor: serializer.fromJson<String>(json['vendor']),
      amount: serializer.fromJson<double>(json['amount']),
      status: serializer.fromJson<String>(json['status']),
      submittedById: serializer.fromJson<String>(json['submittedById']),
      submittedByName: serializer.fromJson<String>(json['submittedByName']),
      approvedById: serializer.fromJson<String?>(json['approvedById']),
      approvedByName: serializer.fromJson<String?>(json['approvedByName']),
      note: serializer.fromJson<String?>(json['note']),
      expenseDate: serializer.fromJson<DateTime>(json['expenseDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      lastSyncAttempt: serializer.fromJson<DateTime?>(json['lastSyncAttempt']),
      syncError: serializer.fromJson<String?>(json['syncError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'branchId': serializer.toJson<String?>(branchId),
      'branchName': serializer.toJson<String?>(branchName),
      'category': serializer.toJson<String>(category),
      'vendor': serializer.toJson<String>(vendor),
      'amount': serializer.toJson<double>(amount),
      'status': serializer.toJson<String>(status),
      'submittedById': serializer.toJson<String>(submittedById),
      'submittedByName': serializer.toJson<String>(submittedByName),
      'approvedById': serializer.toJson<String?>(approvedById),
      'approvedByName': serializer.toJson<String?>(approvedByName),
      'note': serializer.toJson<String?>(note),
      'expenseDate': serializer.toJson<DateTime>(expenseDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'lastSyncAttempt': serializer.toJson<DateTime?>(lastSyncAttempt),
      'syncError': serializer.toJson<String?>(syncError),
    };
  }

  ExpenseRow copyWith({
    String? id,
    String? businessId,
    Value<String?> branchId = const Value.absent(),
    Value<String?> branchName = const Value.absent(),
    String? category,
    String? vendor,
    double? amount,
    String? status,
    String? submittedById,
    String? submittedByName,
    Value<String?> approvedById = const Value.absent(),
    Value<String?> approvedByName = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? expenseDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? syncStatus,
    Value<DateTime?> lastSyncAttempt = const Value.absent(),
    Value<String?> syncError = const Value.absent(),
  }) => ExpenseRow(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    branchId: branchId.present ? branchId.value : this.branchId,
    branchName: branchName.present ? branchName.value : this.branchName,
    category: category ?? this.category,
    vendor: vendor ?? this.vendor,
    amount: amount ?? this.amount,
    status: status ?? this.status,
    submittedById: submittedById ?? this.submittedById,
    submittedByName: submittedByName ?? this.submittedByName,
    approvedById: approvedById.present ? approvedById.value : this.approvedById,
    approvedByName: approvedByName.present
        ? approvedByName.value
        : this.approvedByName,
    note: note.present ? note.value : this.note,
    expenseDate: expenseDate ?? this.expenseDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncAttempt: lastSyncAttempt.present
        ? lastSyncAttempt.value
        : this.lastSyncAttempt,
    syncError: syncError.present ? syncError.value : this.syncError,
  );
  ExpenseRow copyWithCompanion(ExpensesTableCompanion data) {
    return ExpenseRow(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      branchName: data.branchName.present
          ? data.branchName.value
          : this.branchName,
      category: data.category.present ? data.category.value : this.category,
      vendor: data.vendor.present ? data.vendor.value : this.vendor,
      amount: data.amount.present ? data.amount.value : this.amount,
      status: data.status.present ? data.status.value : this.status,
      submittedById: data.submittedById.present
          ? data.submittedById.value
          : this.submittedById,
      submittedByName: data.submittedByName.present
          ? data.submittedByName.value
          : this.submittedByName,
      approvedById: data.approvedById.present
          ? data.approvedById.value
          : this.approvedById,
      approvedByName: data.approvedByName.present
          ? data.approvedByName.value
          : this.approvedByName,
      note: data.note.present ? data.note.value : this.note,
      expenseDate: data.expenseDate.present
          ? data.expenseDate.value
          : this.expenseDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastSyncAttempt: data.lastSyncAttempt.present
          ? data.lastSyncAttempt.value
          : this.lastSyncAttempt,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseRow(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('branchId: $branchId, ')
          ..write('branchName: $branchName, ')
          ..write('category: $category, ')
          ..write('vendor: $vendor, ')
          ..write('amount: $amount, ')
          ..write('status: $status, ')
          ..write('submittedById: $submittedById, ')
          ..write('submittedByName: $submittedByName, ')
          ..write('approvedById: $approvedById, ')
          ..write('approvedByName: $approvedByName, ')
          ..write('note: $note, ')
          ..write('expenseDate: $expenseDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    branchId,
    branchName,
    category,
    vendor,
    amount,
    status,
    submittedById,
    submittedByName,
    approvedById,
    approvedByName,
    note,
    expenseDate,
    createdAt,
    updatedAt,
    syncStatus,
    lastSyncAttempt,
    syncError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseRow &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.branchId == this.branchId &&
          other.branchName == this.branchName &&
          other.category == this.category &&
          other.vendor == this.vendor &&
          other.amount == this.amount &&
          other.status == this.status &&
          other.submittedById == this.submittedById &&
          other.submittedByName == this.submittedByName &&
          other.approvedById == this.approvedById &&
          other.approvedByName == this.approvedByName &&
          other.note == this.note &&
          other.expenseDate == this.expenseDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncAttempt == this.lastSyncAttempt &&
          other.syncError == this.syncError);
}

class ExpensesTableCompanion extends UpdateCompanion<ExpenseRow> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String?> branchId;
  final Value<String?> branchName;
  final Value<String> category;
  final Value<String> vendor;
  final Value<double> amount;
  final Value<String> status;
  final Value<String> submittedById;
  final Value<String> submittedByName;
  final Value<String?> approvedById;
  final Value<String?> approvedByName;
  final Value<String?> note;
  final Value<DateTime> expenseDate;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> syncStatus;
  final Value<DateTime?> lastSyncAttempt;
  final Value<String?> syncError;
  final Value<int> rowid;
  const ExpensesTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.branchName = const Value.absent(),
    this.category = const Value.absent(),
    this.vendor = const Value.absent(),
    this.amount = const Value.absent(),
    this.status = const Value.absent(),
    this.submittedById = const Value.absent(),
    this.submittedByName = const Value.absent(),
    this.approvedById = const Value.absent(),
    this.approvedByName = const Value.absent(),
    this.note = const Value.absent(),
    this.expenseDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensesTableCompanion.insert({
    required String id,
    required String businessId,
    this.branchId = const Value.absent(),
    this.branchName = const Value.absent(),
    required String category,
    required String vendor,
    required double amount,
    this.status = const Value.absent(),
    required String submittedById,
    required String submittedByName,
    this.approvedById = const Value.absent(),
    this.approvedByName = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime expenseDate,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       category = Value(category),
       vendor = Value(vendor),
       amount = Value(amount),
       submittedById = Value(submittedById),
       submittedByName = Value(submittedByName),
       expenseDate = Value(expenseDate);
  static Insertable<ExpenseRow> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? branchId,
    Expression<String>? branchName,
    Expression<String>? category,
    Expression<String>? vendor,
    Expression<double>? amount,
    Expression<String>? status,
    Expression<String>? submittedById,
    Expression<String>? submittedByName,
    Expression<String>? approvedById,
    Expression<String>? approvedByName,
    Expression<String>? note,
    Expression<DateTime>? expenseDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? syncStatus,
    Expression<DateTime>? lastSyncAttempt,
    Expression<String>? syncError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (branchId != null) 'branch_id': branchId,
      if (branchName != null) 'branch_name': branchName,
      if (category != null) 'category': category,
      if (vendor != null) 'vendor': vendor,
      if (amount != null) 'amount': amount,
      if (status != null) 'status': status,
      if (submittedById != null) 'submitted_by_id': submittedById,
      if (submittedByName != null) 'submitted_by_name': submittedByName,
      if (approvedById != null) 'approved_by_id': approvedById,
      if (approvedByName != null) 'approved_by_name': approvedByName,
      if (note != null) 'note': note,
      if (expenseDate != null) 'expense_date': expenseDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncAttempt != null) 'last_sync_attempt': lastSyncAttempt,
      if (syncError != null) 'sync_error': syncError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String?>? branchId,
    Value<String?>? branchName,
    Value<String>? category,
    Value<String>? vendor,
    Value<double>? amount,
    Value<String>? status,
    Value<String>? submittedById,
    Value<String>? submittedByName,
    Value<String?>? approvedById,
    Value<String?>? approvedByName,
    Value<String?>? note,
    Value<DateTime>? expenseDate,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? syncStatus,
    Value<DateTime?>? lastSyncAttempt,
    Value<String?>? syncError,
    Value<int>? rowid,
  }) {
    return ExpensesTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      category: category ?? this.category,
      vendor: vendor ?? this.vendor,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      submittedById: submittedById ?? this.submittedById,
      submittedByName: submittedByName ?? this.submittedByName,
      approvedById: approvedById ?? this.approvedById,
      approvedByName: approvedByName ?? this.approvedByName,
      note: note ?? this.note,
      expenseDate: expenseDate ?? this.expenseDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      syncError: syncError ?? this.syncError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (branchName.present) {
      map['branch_name'] = Variable<String>(branchName.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (vendor.present) {
      map['vendor'] = Variable<String>(vendor.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (submittedById.present) {
      map['submitted_by_id'] = Variable<String>(submittedById.value);
    }
    if (submittedByName.present) {
      map['submitted_by_name'] = Variable<String>(submittedByName.value);
    }
    if (approvedById.present) {
      map['approved_by_id'] = Variable<String>(approvedById.value);
    }
    if (approvedByName.present) {
      map['approved_by_name'] = Variable<String>(approvedByName.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (expenseDate.present) {
      map['expense_date'] = Variable<DateTime>(expenseDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (lastSyncAttempt.present) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('branchId: $branchId, ')
          ..write('branchName: $branchName, ')
          ..write('category: $category, ')
          ..write('vendor: $vendor, ')
          ..write('amount: $amount, ')
          ..write('status: $status, ')
          ..write('submittedById: $submittedById, ')
          ..write('submittedByName: $submittedByName, ')
          ..write('approvedById: $approvedById, ')
          ..write('approvedByName: $approvedByName, ')
          ..write('note: $note, ')
          ..write('expenseDate: $expenseDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTableTable extends ProductsTable
    with TableInfo<$ProductsTableTable, ProductsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('product'),
  );
  static const VerificationMeta _trackingMethodMeta = const VerificationMeta(
    'trackingMethod',
  );
  @override
  late final GeneratedColumn<String> trackingMethod = GeneratedColumn<String>(
    'tracking_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('product_stock'),
  );
  static const VerificationMeta _taxMeta = const VerificationMeta('tax');
  @override
  late final GeneratedColumn<double> tax = GeneratedColumn<double>(
    'tax',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sellByMeta = const VerificationMeta('sellBy');
  @override
  late final GeneratedColumn<String> sellBy = GeneratedColumn<String>(
    'sell_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unit'),
  );
  static const VerificationMeta _hasVariantsMeta = const VerificationMeta(
    'hasVariants',
  );
  @override
  late final GeneratedColumn<bool> hasVariants = GeneratedColumn<bool>(
    'has_variants',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_variants" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncAttemptMeta = const VerificationMeta(
    'lastSyncAttempt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAttempt =
      GeneratedColumn<DateTime>(
        'last_sync_attempt',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    categoryId,
    name,
    sku,
    barcode,
    type,
    trackingMethod,
    tax,
    sellBy,
    hasVariants,
    imagePath,
    isActive,
    syncStatus,
    lastSyncAttempt,
    syncError,
    localUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('tracking_method')) {
      context.handle(
        _trackingMethodMeta,
        trackingMethod.isAcceptableOrUnknown(
          data['tracking_method']!,
          _trackingMethodMeta,
        ),
      );
    }
    if (data.containsKey('tax')) {
      context.handle(
        _taxMeta,
        tax.isAcceptableOrUnknown(data['tax']!, _taxMeta),
      );
    }
    if (data.containsKey('sell_by')) {
      context.handle(
        _sellByMeta,
        sellBy.isAcceptableOrUnknown(data['sell_by']!, _sellByMeta),
      );
    }
    if (data.containsKey('has_variants')) {
      context.handle(
        _hasVariantsMeta,
        hasVariants.isAcceptableOrUnknown(
          data['has_variants']!,
          _hasVariantsMeta,
        ),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('last_sync_attempt')) {
      context.handle(
        _lastSyncAttemptMeta,
        lastSyncAttempt.isAcceptableOrUnknown(
          data['last_sync_attempt']!,
          _lastSyncAttemptMeta,
        ),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      ),
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      trackingMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tracking_method'],
      )!,
      tax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tax'],
      ),
      sellBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sell_by'],
      )!,
      hasVariants: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_variants'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      lastSyncAttempt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_attempt'],
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
    );
  }

  @override
  $ProductsTableTable createAlias(String alias) {
    return $ProductsTableTable(attachedDatabase, alias);
  }
}

class ProductsTableData extends DataClass
    implements Insertable<ProductsTableData> {
  final String id;
  final String businessId;
  final String? categoryId;
  final String name;
  final String? sku;
  final String? barcode;

  /// 'product' (sellable) | 'ingredient' (consumed by recipes, never sold).
  /// Ingredients reuse the variant/levels/ledger stack but are excluded from
  /// the POS catalogue. Defaults to 'product' so existing rows are unchanged.
  final String type;

  /// How sales affect inventory for this product:
  /// 'product_stock' (deduct own stock) | 'recipe' (deduct ingredients) |
  /// 'service' (no inventory). Defaults to 'product_stock' so existing rows
  /// keep behaving exactly as before (deduction still gated by variant.trackStock).
  final String trackingMethod;
  final double? tax;
  final String sellBy;
  final bool hasVariants;

  /// Local file path to the product image, stored in app documents directory.
  /// Null means no image. Offline-first — no network required.
  final String? imagePath;
  final bool isActive;

  /// 0=pendingUpload, 1=pendingUpdate, 2=pendingDelete, 3=synced, 4=failed
  final int syncStatus;
  final DateTime? lastSyncAttempt;
  final String? syncError;
  final DateTime localUpdatedAt;
  const ProductsTableData({
    required this.id,
    required this.businessId,
    this.categoryId,
    required this.name,
    this.sku,
    this.barcode,
    required this.type,
    required this.trackingMethod,
    this.tax,
    required this.sellBy,
    required this.hasVariants,
    this.imagePath,
    required this.isActive,
    required this.syncStatus,
    this.lastSyncAttempt,
    this.syncError,
    required this.localUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['type'] = Variable<String>(type);
    map['tracking_method'] = Variable<String>(trackingMethod);
    if (!nullToAbsent || tax != null) {
      map['tax'] = Variable<double>(tax);
    }
    map['sell_by'] = Variable<String>(sellBy);
    map['has_variants'] = Variable<bool>(hasVariants);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || lastSyncAttempt != null) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt);
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    return map;
  }

  ProductsTableCompanion toCompanion(bool nullToAbsent) {
    return ProductsTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      name: Value(name),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      type: Value(type),
      trackingMethod: Value(trackingMethod),
      tax: tax == null && nullToAbsent ? const Value.absent() : Value(tax),
      sellBy: Value(sellBy),
      hasVariants: Value(hasVariants),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      isActive: Value(isActive),
      syncStatus: Value(syncStatus),
      lastSyncAttempt: lastSyncAttempt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAttempt),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      localUpdatedAt: Value(localUpdatedAt),
    );
  }

  factory ProductsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductsTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      name: serializer.fromJson<String>(json['name']),
      sku: serializer.fromJson<String?>(json['sku']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      type: serializer.fromJson<String>(json['type']),
      trackingMethod: serializer.fromJson<String>(json['trackingMethod']),
      tax: serializer.fromJson<double?>(json['tax']),
      sellBy: serializer.fromJson<String>(json['sellBy']),
      hasVariants: serializer.fromJson<bool>(json['hasVariants']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      lastSyncAttempt: serializer.fromJson<DateTime?>(json['lastSyncAttempt']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'name': serializer.toJson<String>(name),
      'sku': serializer.toJson<String?>(sku),
      'barcode': serializer.toJson<String?>(barcode),
      'type': serializer.toJson<String>(type),
      'trackingMethod': serializer.toJson<String>(trackingMethod),
      'tax': serializer.toJson<double?>(tax),
      'sellBy': serializer.toJson<String>(sellBy),
      'hasVariants': serializer.toJson<bool>(hasVariants),
      'imagePath': serializer.toJson<String?>(imagePath),
      'isActive': serializer.toJson<bool>(isActive),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'lastSyncAttempt': serializer.toJson<DateTime?>(lastSyncAttempt),
      'syncError': serializer.toJson<String?>(syncError),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
    };
  }

  ProductsTableData copyWith({
    String? id,
    String? businessId,
    Value<String?> categoryId = const Value.absent(),
    String? name,
    Value<String?> sku = const Value.absent(),
    Value<String?> barcode = const Value.absent(),
    String? type,
    String? trackingMethod,
    Value<double?> tax = const Value.absent(),
    String? sellBy,
    bool? hasVariants,
    Value<String?> imagePath = const Value.absent(),
    bool? isActive,
    int? syncStatus,
    Value<DateTime?> lastSyncAttempt = const Value.absent(),
    Value<String?> syncError = const Value.absent(),
    DateTime? localUpdatedAt,
  }) => ProductsTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    name: name ?? this.name,
    sku: sku.present ? sku.value : this.sku,
    barcode: barcode.present ? barcode.value : this.barcode,
    type: type ?? this.type,
    trackingMethod: trackingMethod ?? this.trackingMethod,
    tax: tax.present ? tax.value : this.tax,
    sellBy: sellBy ?? this.sellBy,
    hasVariants: hasVariants ?? this.hasVariants,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    isActive: isActive ?? this.isActive,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncAttempt: lastSyncAttempt.present
        ? lastSyncAttempt.value
        : this.lastSyncAttempt,
    syncError: syncError.present ? syncError.value : this.syncError,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
  );
  ProductsTableData copyWithCompanion(ProductsTableCompanion data) {
    return ProductsTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      name: data.name.present ? data.name.value : this.name,
      sku: data.sku.present ? data.sku.value : this.sku,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      type: data.type.present ? data.type.value : this.type,
      trackingMethod: data.trackingMethod.present
          ? data.trackingMethod.value
          : this.trackingMethod,
      tax: data.tax.present ? data.tax.value : this.tax,
      sellBy: data.sellBy.present ? data.sellBy.value : this.sellBy,
      hasVariants: data.hasVariants.present
          ? data.hasVariants.value
          : this.hasVariants,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastSyncAttempt: data.lastSyncAttempt.present
          ? data.lastSyncAttempt.value
          : this.lastSyncAttempt,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductsTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('type: $type, ')
          ..write('trackingMethod: $trackingMethod, ')
          ..write('tax: $tax, ')
          ..write('sellBy: $sellBy, ')
          ..write('hasVariants: $hasVariants, ')
          ..write('imagePath: $imagePath, ')
          ..write('isActive: $isActive, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError, ')
          ..write('localUpdatedAt: $localUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    categoryId,
    name,
    sku,
    barcode,
    type,
    trackingMethod,
    tax,
    sellBy,
    hasVariants,
    imagePath,
    isActive,
    syncStatus,
    lastSyncAttempt,
    syncError,
    localUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductsTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.categoryId == this.categoryId &&
          other.name == this.name &&
          other.sku == this.sku &&
          other.barcode == this.barcode &&
          other.type == this.type &&
          other.trackingMethod == this.trackingMethod &&
          other.tax == this.tax &&
          other.sellBy == this.sellBy &&
          other.hasVariants == this.hasVariants &&
          other.imagePath == this.imagePath &&
          other.isActive == this.isActive &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncAttempt == this.lastSyncAttempt &&
          other.syncError == this.syncError &&
          other.localUpdatedAt == this.localUpdatedAt);
}

class ProductsTableCompanion extends UpdateCompanion<ProductsTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String?> categoryId;
  final Value<String> name;
  final Value<String?> sku;
  final Value<String?> barcode;
  final Value<String> type;
  final Value<String> trackingMethod;
  final Value<double?> tax;
  final Value<String> sellBy;
  final Value<bool> hasVariants;
  final Value<String?> imagePath;
  final Value<bool> isActive;
  final Value<int> syncStatus;
  final Value<DateTime?> lastSyncAttempt;
  final Value<String?> syncError;
  final Value<DateTime> localUpdatedAt;
  final Value<int> rowid;
  const ProductsTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.sku = const Value.absent(),
    this.barcode = const Value.absent(),
    this.type = const Value.absent(),
    this.trackingMethod = const Value.absent(),
    this.tax = const Value.absent(),
    this.sellBy = const Value.absent(),
    this.hasVariants = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.isActive = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsTableCompanion.insert({
    required String id,
    required String businessId,
    this.categoryId = const Value.absent(),
    required String name,
    this.sku = const Value.absent(),
    this.barcode = const Value.absent(),
    this.type = const Value.absent(),
    this.trackingMethod = const Value.absent(),
    this.tax = const Value.absent(),
    this.sellBy = const Value.absent(),
    this.hasVariants = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.isActive = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       name = Value(name);
  static Insertable<ProductsTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? categoryId,
    Expression<String>? name,
    Expression<String>? sku,
    Expression<String>? barcode,
    Expression<String>? type,
    Expression<String>? trackingMethod,
    Expression<double>? tax,
    Expression<String>? sellBy,
    Expression<bool>? hasVariants,
    Expression<String>? imagePath,
    Expression<bool>? isActive,
    Expression<int>? syncStatus,
    Expression<DateTime>? lastSyncAttempt,
    Expression<String>? syncError,
    Expression<DateTime>? localUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,
      if (type != null) 'type': type,
      if (trackingMethod != null) 'tracking_method': trackingMethod,
      if (tax != null) 'tax': tax,
      if (sellBy != null) 'sell_by': sellBy,
      if (hasVariants != null) 'has_variants': hasVariants,
      if (imagePath != null) 'image_path': imagePath,
      if (isActive != null) 'is_active': isActive,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncAttempt != null) 'last_sync_attempt': lastSyncAttempt,
      if (syncError != null) 'sync_error': syncError,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String?>? categoryId,
    Value<String>? name,
    Value<String?>? sku,
    Value<String?>? barcode,
    Value<String>? type,
    Value<String>? trackingMethod,
    Value<double?>? tax,
    Value<String>? sellBy,
    Value<bool>? hasVariants,
    Value<String?>? imagePath,
    Value<bool>? isActive,
    Value<int>? syncStatus,
    Value<DateTime?>? lastSyncAttempt,
    Value<String?>? syncError,
    Value<DateTime>? localUpdatedAt,
    Value<int>? rowid,
  }) {
    return ProductsTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      type: type ?? this.type,
      trackingMethod: trackingMethod ?? this.trackingMethod,
      tax: tax ?? this.tax,
      sellBy: sellBy ?? this.sellBy,
      hasVariants: hasVariants ?? this.hasVariants,
      imagePath: imagePath ?? this.imagePath,
      isActive: isActive ?? this.isActive,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      syncError: syncError ?? this.syncError,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (trackingMethod.present) {
      map['tracking_method'] = Variable<String>(trackingMethod.value);
    }
    if (tax.present) {
      map['tax'] = Variable<double>(tax.value);
    }
    if (sellBy.present) {
      map['sell_by'] = Variable<String>(sellBy.value);
    }
    if (hasVariants.present) {
      map['has_variants'] = Variable<bool>(hasVariants.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (lastSyncAttempt.present) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('type: $type, ')
          ..write('trackingMethod: $trackingMethod, ')
          ..write('tax: $tax, ')
          ..write('sellBy: $sellBy, ')
          ..write('hasVariants: $hasVariants, ')
          ..write('imagePath: $imagePath, ')
          ..write('isActive: $isActive, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductVariantsTableTable extends ProductVariantsTable
    with TableInfo<$ProductVariantsTableTable, ProductVariantsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductVariantsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _costPriceMeta = const VerificationMeta(
    'costPrice',
  );
  @override
  late final GeneratedColumn<double> costPrice = GeneratedColumn<double>(
    'cost_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retailPriceMeta = const VerificationMeta(
    'retailPrice',
  );
  @override
  late final GeneratedColumn<double> retailPrice = GeneratedColumn<double>(
    'retail_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stockMeta = const VerificationMeta('stock');
  @override
  late final GeneratedColumn<int> stock = GeneratedColumn<int>(
    'stock',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stockDecimalMeta = const VerificationMeta(
    'stockDecimal',
  );
  @override
  late final GeneratedColumn<double> stockDecimal = GeneratedColumn<double>(
    'stock_decimal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lowStockAlertMeta = const VerificationMeta(
    'lowStockAlert',
  );
  @override
  late final GeneratedColumn<int> lowStockAlert = GeneratedColumn<int>(
    'low_stock_alert',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trackStockMeta = const VerificationMeta(
    'trackStock',
  );
  @override
  late final GeneratedColumn<bool> trackStock = GeneratedColumn<bool>(
    'track_stock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("track_stock" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _trackExpiryMeta = const VerificationMeta(
    'trackExpiry',
  );
  @override
  late final GeneratedColumn<bool> trackExpiry = GeneratedColumn<bool>(
    'track_expiry',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("track_expiry" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _expiryDateMeta = const VerificationMeta(
    'expiryDate',
  );
  @override
  late final GeneratedColumn<DateTime> expiryDate = GeneratedColumn<DateTime>(
    'expiry_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncAttemptMeta = const VerificationMeta(
    'lastSyncAttempt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAttempt =
      GeneratedColumn<DateTime>(
        'last_sync_attempt',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    businessId,
    name,
    price,
    costPrice,
    retailPrice,
    stock,
    sku,
    barcode,
    unit,
    stockDecimal,
    lowStockAlert,
    trackStock,
    trackExpiry,
    expiryDate,
    isActive,
    syncStatus,
    lastSyncAttempt,
    syncError,
    localUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_variants';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductVariantsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    }
    if (data.containsKey('cost_price')) {
      context.handle(
        _costPriceMeta,
        costPrice.isAcceptableOrUnknown(data['cost_price']!, _costPriceMeta),
      );
    }
    if (data.containsKey('retail_price')) {
      context.handle(
        _retailPriceMeta,
        retailPrice.isAcceptableOrUnknown(
          data['retail_price']!,
          _retailPriceMeta,
        ),
      );
    }
    if (data.containsKey('stock')) {
      context.handle(
        _stockMeta,
        stock.isAcceptableOrUnknown(data['stock']!, _stockMeta),
      );
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('stock_decimal')) {
      context.handle(
        _stockDecimalMeta,
        stockDecimal.isAcceptableOrUnknown(
          data['stock_decimal']!,
          _stockDecimalMeta,
        ),
      );
    }
    if (data.containsKey('low_stock_alert')) {
      context.handle(
        _lowStockAlertMeta,
        lowStockAlert.isAcceptableOrUnknown(
          data['low_stock_alert']!,
          _lowStockAlertMeta,
        ),
      );
    }
    if (data.containsKey('track_stock')) {
      context.handle(
        _trackStockMeta,
        trackStock.isAcceptableOrUnknown(data['track_stock']!, _trackStockMeta),
      );
    }
    if (data.containsKey('track_expiry')) {
      context.handle(
        _trackExpiryMeta,
        trackExpiry.isAcceptableOrUnknown(
          data['track_expiry']!,
          _trackExpiryMeta,
        ),
      );
    }
    if (data.containsKey('expiry_date')) {
      context.handle(
        _expiryDateMeta,
        expiryDate.isAcceptableOrUnknown(data['expiry_date']!, _expiryDateMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('last_sync_attempt')) {
      context.handle(
        _lastSyncAttemptMeta,
        lastSyncAttempt.isAcceptableOrUnknown(
          data['last_sync_attempt']!,
          _lastSyncAttemptMeta,
        ),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductVariantsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductVariantsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      )!,
      costPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost_price'],
      ),
      retailPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}retail_price'],
      ),
      stock: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stock'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      ),
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      stockDecimal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stock_decimal'],
      ),
      lowStockAlert: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}low_stock_alert'],
      ),
      trackStock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}track_stock'],
      )!,
      trackExpiry: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}track_expiry'],
      )!,
      expiryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expiry_date'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      lastSyncAttempt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_attempt'],
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
    );
  }

  @override
  $ProductVariantsTableTable createAlias(String alias) {
    return $ProductVariantsTableTable(attachedDatabase, alias);
  }
}

class ProductVariantsTableData extends DataClass
    implements Insertable<ProductVariantsTableData> {
  final String id;
  final String productId;
  final String businessId;

  /// Variant label: "Default" for simple products, "Small"/"Large"/etc. for variants.
  final String name;
  final double price;
  final double? costPrice;

  /// Suggested retail price / SRP. Optional on all product types.
  final double? retailPrice;
  final int stock;
  final String? sku;
  final String? barcode;

  /// Unit of measure for stock quantities (g, kg, ml, L, pcs). Null = 'pcs'.
  /// Used by ingredients and recipe lines; harmless for normal stock products.
  final String? unit;
  final double? stockDecimal;

  /// Optional threshold below which a low-stock alert should be triggered.
  final int? lowStockAlert;
  final bool trackStock;
  final bool trackExpiry;

  /// Expiry date for the variant. Stored as Unix epoch ms (Drift DateTimeColumn).
  /// Migrated from TEXT (ISO 8601) in schema v19.
  final DateTime? expiryDate;
  final bool isActive;

  /// 0=pendingUpload, 1=pendingUpdate, 2=pendingDelete, 3=synced, 4=failed
  final int syncStatus;
  final DateTime? lastSyncAttempt;
  final String? syncError;
  final DateTime localUpdatedAt;
  const ProductVariantsTableData({
    required this.id,
    required this.productId,
    required this.businessId,
    required this.name,
    required this.price,
    this.costPrice,
    this.retailPrice,
    required this.stock,
    this.sku,
    this.barcode,
    this.unit,
    this.stockDecimal,
    this.lowStockAlert,
    required this.trackStock,
    required this.trackExpiry,
    this.expiryDate,
    required this.isActive,
    required this.syncStatus,
    this.lastSyncAttempt,
    this.syncError,
    required this.localUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    map['business_id'] = Variable<String>(businessId);
    map['name'] = Variable<String>(name);
    map['price'] = Variable<double>(price);
    if (!nullToAbsent || costPrice != null) {
      map['cost_price'] = Variable<double>(costPrice);
    }
    if (!nullToAbsent || retailPrice != null) {
      map['retail_price'] = Variable<double>(retailPrice);
    }
    map['stock'] = Variable<int>(stock);
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || stockDecimal != null) {
      map['stock_decimal'] = Variable<double>(stockDecimal);
    }
    if (!nullToAbsent || lowStockAlert != null) {
      map['low_stock_alert'] = Variable<int>(lowStockAlert);
    }
    map['track_stock'] = Variable<bool>(trackStock);
    map['track_expiry'] = Variable<bool>(trackExpiry);
    if (!nullToAbsent || expiryDate != null) {
      map['expiry_date'] = Variable<DateTime>(expiryDate);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || lastSyncAttempt != null) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt);
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    return map;
  }

  ProductVariantsTableCompanion toCompanion(bool nullToAbsent) {
    return ProductVariantsTableCompanion(
      id: Value(id),
      productId: Value(productId),
      businessId: Value(businessId),
      name: Value(name),
      price: Value(price),
      costPrice: costPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(costPrice),
      retailPrice: retailPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(retailPrice),
      stock: Value(stock),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      stockDecimal: stockDecimal == null && nullToAbsent
          ? const Value.absent()
          : Value(stockDecimal),
      lowStockAlert: lowStockAlert == null && nullToAbsent
          ? const Value.absent()
          : Value(lowStockAlert),
      trackStock: Value(trackStock),
      trackExpiry: Value(trackExpiry),
      expiryDate: expiryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expiryDate),
      isActive: Value(isActive),
      syncStatus: Value(syncStatus),
      lastSyncAttempt: lastSyncAttempt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAttempt),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      localUpdatedAt: Value(localUpdatedAt),
    );
  }

  factory ProductVariantsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductVariantsTableData(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      businessId: serializer.fromJson<String>(json['businessId']),
      name: serializer.fromJson<String>(json['name']),
      price: serializer.fromJson<double>(json['price']),
      costPrice: serializer.fromJson<double?>(json['costPrice']),
      retailPrice: serializer.fromJson<double?>(json['retailPrice']),
      stock: serializer.fromJson<int>(json['stock']),
      sku: serializer.fromJson<String?>(json['sku']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      unit: serializer.fromJson<String?>(json['unit']),
      stockDecimal: serializer.fromJson<double?>(json['stockDecimal']),
      lowStockAlert: serializer.fromJson<int?>(json['lowStockAlert']),
      trackStock: serializer.fromJson<bool>(json['trackStock']),
      trackExpiry: serializer.fromJson<bool>(json['trackExpiry']),
      expiryDate: serializer.fromJson<DateTime?>(json['expiryDate']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      lastSyncAttempt: serializer.fromJson<DateTime?>(json['lastSyncAttempt']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'businessId': serializer.toJson<String>(businessId),
      'name': serializer.toJson<String>(name),
      'price': serializer.toJson<double>(price),
      'costPrice': serializer.toJson<double?>(costPrice),
      'retailPrice': serializer.toJson<double?>(retailPrice),
      'stock': serializer.toJson<int>(stock),
      'sku': serializer.toJson<String?>(sku),
      'barcode': serializer.toJson<String?>(barcode),
      'unit': serializer.toJson<String?>(unit),
      'stockDecimal': serializer.toJson<double?>(stockDecimal),
      'lowStockAlert': serializer.toJson<int?>(lowStockAlert),
      'trackStock': serializer.toJson<bool>(trackStock),
      'trackExpiry': serializer.toJson<bool>(trackExpiry),
      'expiryDate': serializer.toJson<DateTime?>(expiryDate),
      'isActive': serializer.toJson<bool>(isActive),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'lastSyncAttempt': serializer.toJson<DateTime?>(lastSyncAttempt),
      'syncError': serializer.toJson<String?>(syncError),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
    };
  }

  ProductVariantsTableData copyWith({
    String? id,
    String? productId,
    String? businessId,
    String? name,
    double? price,
    Value<double?> costPrice = const Value.absent(),
    Value<double?> retailPrice = const Value.absent(),
    int? stock,
    Value<String?> sku = const Value.absent(),
    Value<String?> barcode = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    Value<double?> stockDecimal = const Value.absent(),
    Value<int?> lowStockAlert = const Value.absent(),
    bool? trackStock,
    bool? trackExpiry,
    Value<DateTime?> expiryDate = const Value.absent(),
    bool? isActive,
    int? syncStatus,
    Value<DateTime?> lastSyncAttempt = const Value.absent(),
    Value<String?> syncError = const Value.absent(),
    DateTime? localUpdatedAt,
  }) => ProductVariantsTableData(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    businessId: businessId ?? this.businessId,
    name: name ?? this.name,
    price: price ?? this.price,
    costPrice: costPrice.present ? costPrice.value : this.costPrice,
    retailPrice: retailPrice.present ? retailPrice.value : this.retailPrice,
    stock: stock ?? this.stock,
    sku: sku.present ? sku.value : this.sku,
    barcode: barcode.present ? barcode.value : this.barcode,
    unit: unit.present ? unit.value : this.unit,
    stockDecimal: stockDecimal.present ? stockDecimal.value : this.stockDecimal,
    lowStockAlert: lowStockAlert.present
        ? lowStockAlert.value
        : this.lowStockAlert,
    trackStock: trackStock ?? this.trackStock,
    trackExpiry: trackExpiry ?? this.trackExpiry,
    expiryDate: expiryDate.present ? expiryDate.value : this.expiryDate,
    isActive: isActive ?? this.isActive,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncAttempt: lastSyncAttempt.present
        ? lastSyncAttempt.value
        : this.lastSyncAttempt,
    syncError: syncError.present ? syncError.value : this.syncError,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
  );
  ProductVariantsTableData copyWithCompanion(
    ProductVariantsTableCompanion data,
  ) {
    return ProductVariantsTableData(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      price: data.price.present ? data.price.value : this.price,
      costPrice: data.costPrice.present ? data.costPrice.value : this.costPrice,
      retailPrice: data.retailPrice.present
          ? data.retailPrice.value
          : this.retailPrice,
      stock: data.stock.present ? data.stock.value : this.stock,
      sku: data.sku.present ? data.sku.value : this.sku,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      unit: data.unit.present ? data.unit.value : this.unit,
      stockDecimal: data.stockDecimal.present
          ? data.stockDecimal.value
          : this.stockDecimal,
      lowStockAlert: data.lowStockAlert.present
          ? data.lowStockAlert.value
          : this.lowStockAlert,
      trackStock: data.trackStock.present
          ? data.trackStock.value
          : this.trackStock,
      trackExpiry: data.trackExpiry.present
          ? data.trackExpiry.value
          : this.trackExpiry,
      expiryDate: data.expiryDate.present
          ? data.expiryDate.value
          : this.expiryDate,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastSyncAttempt: data.lastSyncAttempt.present
          ? data.lastSyncAttempt.value
          : this.lastSyncAttempt,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductVariantsTableData(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('costPrice: $costPrice, ')
          ..write('retailPrice: $retailPrice, ')
          ..write('stock: $stock, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('unit: $unit, ')
          ..write('stockDecimal: $stockDecimal, ')
          ..write('lowStockAlert: $lowStockAlert, ')
          ..write('trackStock: $trackStock, ')
          ..write('trackExpiry: $trackExpiry, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('isActive: $isActive, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError, ')
          ..write('localUpdatedAt: $localUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    productId,
    businessId,
    name,
    price,
    costPrice,
    retailPrice,
    stock,
    sku,
    barcode,
    unit,
    stockDecimal,
    lowStockAlert,
    trackStock,
    trackExpiry,
    expiryDate,
    isActive,
    syncStatus,
    lastSyncAttempt,
    syncError,
    localUpdatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductVariantsTableData &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.price == this.price &&
          other.costPrice == this.costPrice &&
          other.retailPrice == this.retailPrice &&
          other.stock == this.stock &&
          other.sku == this.sku &&
          other.barcode == this.barcode &&
          other.unit == this.unit &&
          other.stockDecimal == this.stockDecimal &&
          other.lowStockAlert == this.lowStockAlert &&
          other.trackStock == this.trackStock &&
          other.trackExpiry == this.trackExpiry &&
          other.expiryDate == this.expiryDate &&
          other.isActive == this.isActive &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncAttempt == this.lastSyncAttempt &&
          other.syncError == this.syncError &&
          other.localUpdatedAt == this.localUpdatedAt);
}

class ProductVariantsTableCompanion
    extends UpdateCompanion<ProductVariantsTableData> {
  final Value<String> id;
  final Value<String> productId;
  final Value<String> businessId;
  final Value<String> name;
  final Value<double> price;
  final Value<double?> costPrice;
  final Value<double?> retailPrice;
  final Value<int> stock;
  final Value<String?> sku;
  final Value<String?> barcode;
  final Value<String?> unit;
  final Value<double?> stockDecimal;
  final Value<int?> lowStockAlert;
  final Value<bool> trackStock;
  final Value<bool> trackExpiry;
  final Value<DateTime?> expiryDate;
  final Value<bool> isActive;
  final Value<int> syncStatus;
  final Value<DateTime?> lastSyncAttempt;
  final Value<String?> syncError;
  final Value<DateTime> localUpdatedAt;
  final Value<int> rowid;
  const ProductVariantsTableCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.price = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.retailPrice = const Value.absent(),
    this.stock = const Value.absent(),
    this.sku = const Value.absent(),
    this.barcode = const Value.absent(),
    this.unit = const Value.absent(),
    this.stockDecimal = const Value.absent(),
    this.lowStockAlert = const Value.absent(),
    this.trackStock = const Value.absent(),
    this.trackExpiry = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.isActive = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductVariantsTableCompanion.insert({
    required String id,
    required String productId,
    required String businessId,
    required String name,
    this.price = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.retailPrice = const Value.absent(),
    this.stock = const Value.absent(),
    this.sku = const Value.absent(),
    this.barcode = const Value.absent(),
    this.unit = const Value.absent(),
    this.stockDecimal = const Value.absent(),
    this.lowStockAlert = const Value.absent(),
    this.trackStock = const Value.absent(),
    this.trackExpiry = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.isActive = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productId = Value(productId),
       businessId = Value(businessId),
       name = Value(name);
  static Insertable<ProductVariantsTableData> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<double>? price,
    Expression<double>? costPrice,
    Expression<double>? retailPrice,
    Expression<int>? stock,
    Expression<String>? sku,
    Expression<String>? barcode,
    Expression<String>? unit,
    Expression<double>? stockDecimal,
    Expression<int>? lowStockAlert,
    Expression<bool>? trackStock,
    Expression<bool>? trackExpiry,
    Expression<DateTime>? expiryDate,
    Expression<bool>? isActive,
    Expression<int>? syncStatus,
    Expression<DateTime>? lastSyncAttempt,
    Expression<String>? syncError,
    Expression<DateTime>? localUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (costPrice != null) 'cost_price': costPrice,
      if (retailPrice != null) 'retail_price': retailPrice,
      if (stock != null) 'stock': stock,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,
      if (unit != null) 'unit': unit,
      if (stockDecimal != null) 'stock_decimal': stockDecimal,
      if (lowStockAlert != null) 'low_stock_alert': lowStockAlert,
      if (trackStock != null) 'track_stock': trackStock,
      if (trackExpiry != null) 'track_expiry': trackExpiry,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (isActive != null) 'is_active': isActive,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncAttempt != null) 'last_sync_attempt': lastSyncAttempt,
      if (syncError != null) 'sync_error': syncError,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductVariantsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? productId,
    Value<String>? businessId,
    Value<String>? name,
    Value<double>? price,
    Value<double?>? costPrice,
    Value<double?>? retailPrice,
    Value<int>? stock,
    Value<String?>? sku,
    Value<String?>? barcode,
    Value<String?>? unit,
    Value<double?>? stockDecimal,
    Value<int?>? lowStockAlert,
    Value<bool>? trackStock,
    Value<bool>? trackExpiry,
    Value<DateTime?>? expiryDate,
    Value<bool>? isActive,
    Value<int>? syncStatus,
    Value<DateTime?>? lastSyncAttempt,
    Value<String?>? syncError,
    Value<DateTime>? localUpdatedAt,
    Value<int>? rowid,
  }) {
    return ProductVariantsTableCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      retailPrice: retailPrice ?? this.retailPrice,
      stock: stock ?? this.stock,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      unit: unit ?? this.unit,
      stockDecimal: stockDecimal ?? this.stockDecimal,
      lowStockAlert: lowStockAlert ?? this.lowStockAlert,
      trackStock: trackStock ?? this.trackStock,
      trackExpiry: trackExpiry ?? this.trackExpiry,
      expiryDate: expiryDate ?? this.expiryDate,
      isActive: isActive ?? this.isActive,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      syncError: syncError ?? this.syncError,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (costPrice.present) {
      map['cost_price'] = Variable<double>(costPrice.value);
    }
    if (retailPrice.present) {
      map['retail_price'] = Variable<double>(retailPrice.value);
    }
    if (stock.present) {
      map['stock'] = Variable<int>(stock.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (stockDecimal.present) {
      map['stock_decimal'] = Variable<double>(stockDecimal.value);
    }
    if (lowStockAlert.present) {
      map['low_stock_alert'] = Variable<int>(lowStockAlert.value);
    }
    if (trackStock.present) {
      map['track_stock'] = Variable<bool>(trackStock.value);
    }
    if (trackExpiry.present) {
      map['track_expiry'] = Variable<bool>(trackExpiry.value);
    }
    if (expiryDate.present) {
      map['expiry_date'] = Variable<DateTime>(expiryDate.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (lastSyncAttempt.present) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductVariantsTableCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('costPrice: $costPrice, ')
          ..write('retailPrice: $retailPrice, ')
          ..write('stock: $stock, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('unit: $unit, ')
          ..write('stockDecimal: $stockDecimal, ')
          ..write('lowStockAlert: $lowStockAlert, ')
          ..write('trackStock: $trackStock, ')
          ..write('trackExpiry: $trackExpiry, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('isActive: $isActive, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTableTable extends TransactionsTable
    with TableInfo<$TransactionsTableTable, TransactionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cashierIdMeta = const VerificationMeta(
    'cashierId',
  );
  @override
  late final GeneratedColumn<String> cashierId = GeneratedColumn<String>(
    'cashier_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shiftIdMeta = const VerificationMeta(
    'shiftId',
  );
  @override
  late final GeneratedColumn<String> shiftId = GeneratedColumn<String>(
    'shift_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountAmountMeta = const VerificationMeta(
    'discountAmount',
  );
  @override
  late final GeneratedColumn<double> discountAmount = GeneratedColumn<double>(
    'discount_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _taxAmountMeta = const VerificationMeta(
    'taxAmount',
  );
  @override
  late final GeneratedColumn<double> taxAmount = GeneratedColumn<double>(
    'tax_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('completed'),
  );
  static const VerificationMeta _transactionHashMeta = const VerificationMeta(
    'transactionHash',
  );
  @override
  late final GeneratedColumn<String> transactionHash = GeneratedColumn<String>(
    'transaction_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('cash'),
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountReceivedMeta = const VerificationMeta(
    'amountReceived',
  );
  @override
  late final GeneratedColumn<double> amountReceived = GeneratedColumn<double>(
    'amount_received',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _changeDueMeta = const VerificationMeta(
    'changeDue',
  );
  @override
  late final GeneratedColumn<double> changeDue = GeneratedColumn<double>(
    'change_due',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemCountMeta = const VerificationMeta(
    'itemCount',
  );
  @override
  late final GeneratedColumn<int> itemCount = GeneratedColumn<int>(
    'item_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncAttemptMeta = const VerificationMeta(
    'lastSyncAttempt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAttempt =
      GeneratedColumn<DateTime>(
        'last_sync_attempt',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    branchId,
    cashierId,
    shiftId,
    totalAmount,
    discountAmount,
    taxAmount,
    status,
    transactionHash,
    createdAt,
    customerName,
    paymentMethod,
    subtotal,
    amountReceived,
    changeDue,
    itemCount,
    syncStatus,
    lastSyncAttempt,
    syncError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    }
    if (data.containsKey('cashier_id')) {
      context.handle(
        _cashierIdMeta,
        cashierId.isAcceptableOrUnknown(data['cashier_id']!, _cashierIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cashierIdMeta);
    }
    if (data.containsKey('shift_id')) {
      context.handle(
        _shiftIdMeta,
        shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('discount_amount')) {
      context.handle(
        _discountAmountMeta,
        discountAmount.isAcceptableOrUnknown(
          data['discount_amount']!,
          _discountAmountMeta,
        ),
      );
    }
    if (data.containsKey('tax_amount')) {
      context.handle(
        _taxAmountMeta,
        taxAmount.isAcceptableOrUnknown(data['tax_amount']!, _taxAmountMeta),
      );
    } else if (isInserting) {
      context.missing(_taxAmountMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('transaction_hash')) {
      context.handle(
        _transactionHashMeta,
        transactionHash.isAcceptableOrUnknown(
          data['transaction_hash']!,
          _transactionHashMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    } else if (isInserting) {
      context.missing(_subtotalMeta);
    }
    if (data.containsKey('amount_received')) {
      context.handle(
        _amountReceivedMeta,
        amountReceived.isAcceptableOrUnknown(
          data['amount_received']!,
          _amountReceivedMeta,
        ),
      );
    }
    if (data.containsKey('change_due')) {
      context.handle(
        _changeDueMeta,
        changeDue.isAcceptableOrUnknown(data['change_due']!, _changeDueMeta),
      );
    }
    if (data.containsKey('item_count')) {
      context.handle(
        _itemCountMeta,
        itemCount.isAcceptableOrUnknown(data['item_count']!, _itemCountMeta),
      );
    } else if (isInserting) {
      context.missing(_itemCountMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('last_sync_attempt')) {
      context.handle(
        _lastSyncAttemptMeta,
        lastSyncAttempt.isAcceptableOrUnknown(
          data['last_sync_attempt']!,
          _lastSyncAttemptMeta,
        ),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      ),
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      ),
      cashierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashier_id'],
      )!,
      shiftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift_id'],
      ),
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      discountAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}discount_amount'],
      )!,
      taxAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tax_amount'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      transactionHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_hash'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      ),
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}subtotal'],
      )!,
      amountReceived: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount_received'],
      ),
      changeDue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}change_due'],
      ),
      itemCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_count'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      lastSyncAttempt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_attempt'],
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
    );
  }

  @override
  $TransactionsTableTable createAlias(String alias) {
    return $TransactionsTableTable(attachedDatabase, alias);
  }
}

class TransactionsTableData extends DataClass
    implements Insertable<TransactionsTableData> {
  final String id;
  final String? businessId;
  final String? branchId;
  final String cashierId;
  final String? shiftId;
  final double totalAmount;
  final double discountAmount;
  final double taxAmount;
  final String status;
  final String? transactionHash;
  final DateTime createdAt;
  final String? customerName;
  final String paymentMethod;
  final double subtotal;
  final double? amountReceived;
  final double? changeDue;
  final int itemCount;

  /// 0=pendingUpload, 1=pendingUpdate, 2=pendingDelete, 3=synced, 4=failed
  final int syncStatus;
  final DateTime? lastSyncAttempt;
  final String? syncError;
  const TransactionsTableData({
    required this.id,
    this.businessId,
    this.branchId,
    required this.cashierId,
    this.shiftId,
    required this.totalAmount,
    required this.discountAmount,
    required this.taxAmount,
    required this.status,
    this.transactionHash,
    required this.createdAt,
    this.customerName,
    required this.paymentMethod,
    required this.subtotal,
    this.amountReceived,
    this.changeDue,
    required this.itemCount,
    required this.syncStatus,
    this.lastSyncAttempt,
    this.syncError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || businessId != null) {
      map['business_id'] = Variable<String>(businessId);
    }
    if (!nullToAbsent || branchId != null) {
      map['branch_id'] = Variable<String>(branchId);
    }
    map['cashier_id'] = Variable<String>(cashierId);
    if (!nullToAbsent || shiftId != null) {
      map['shift_id'] = Variable<String>(shiftId);
    }
    map['total_amount'] = Variable<double>(totalAmount);
    map['discount_amount'] = Variable<double>(discountAmount);
    map['tax_amount'] = Variable<double>(taxAmount);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || transactionHash != null) {
      map['transaction_hash'] = Variable<String>(transactionHash);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || customerName != null) {
      map['customer_name'] = Variable<String>(customerName);
    }
    map['payment_method'] = Variable<String>(paymentMethod);
    map['subtotal'] = Variable<double>(subtotal);
    if (!nullToAbsent || amountReceived != null) {
      map['amount_received'] = Variable<double>(amountReceived);
    }
    if (!nullToAbsent || changeDue != null) {
      map['change_due'] = Variable<double>(changeDue);
    }
    map['item_count'] = Variable<int>(itemCount);
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || lastSyncAttempt != null) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt);
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    return map;
  }

  TransactionsTableCompanion toCompanion(bool nullToAbsent) {
    return TransactionsTableCompanion(
      id: Value(id),
      businessId: businessId == null && nullToAbsent
          ? const Value.absent()
          : Value(businessId),
      branchId: branchId == null && nullToAbsent
          ? const Value.absent()
          : Value(branchId),
      cashierId: Value(cashierId),
      shiftId: shiftId == null && nullToAbsent
          ? const Value.absent()
          : Value(shiftId),
      totalAmount: Value(totalAmount),
      discountAmount: Value(discountAmount),
      taxAmount: Value(taxAmount),
      status: Value(status),
      transactionHash: transactionHash == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionHash),
      createdAt: Value(createdAt),
      customerName: customerName == null && nullToAbsent
          ? const Value.absent()
          : Value(customerName),
      paymentMethod: Value(paymentMethod),
      subtotal: Value(subtotal),
      amountReceived: amountReceived == null && nullToAbsent
          ? const Value.absent()
          : Value(amountReceived),
      changeDue: changeDue == null && nullToAbsent
          ? const Value.absent()
          : Value(changeDue),
      itemCount: Value(itemCount),
      syncStatus: Value(syncStatus),
      lastSyncAttempt: lastSyncAttempt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAttempt),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
    );
  }

  factory TransactionsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionsTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String?>(json['businessId']),
      branchId: serializer.fromJson<String?>(json['branchId']),
      cashierId: serializer.fromJson<String>(json['cashierId']),
      shiftId: serializer.fromJson<String?>(json['shiftId']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      discountAmount: serializer.fromJson<double>(json['discountAmount']),
      taxAmount: serializer.fromJson<double>(json['taxAmount']),
      status: serializer.fromJson<String>(json['status']),
      transactionHash: serializer.fromJson<String?>(json['transactionHash']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      customerName: serializer.fromJson<String?>(json['customerName']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      amountReceived: serializer.fromJson<double?>(json['amountReceived']),
      changeDue: serializer.fromJson<double?>(json['changeDue']),
      itemCount: serializer.fromJson<int>(json['itemCount']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      lastSyncAttempt: serializer.fromJson<DateTime?>(json['lastSyncAttempt']),
      syncError: serializer.fromJson<String?>(json['syncError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String?>(businessId),
      'branchId': serializer.toJson<String?>(branchId),
      'cashierId': serializer.toJson<String>(cashierId),
      'shiftId': serializer.toJson<String?>(shiftId),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'discountAmount': serializer.toJson<double>(discountAmount),
      'taxAmount': serializer.toJson<double>(taxAmount),
      'status': serializer.toJson<String>(status),
      'transactionHash': serializer.toJson<String?>(transactionHash),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'customerName': serializer.toJson<String?>(customerName),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'subtotal': serializer.toJson<double>(subtotal),
      'amountReceived': serializer.toJson<double?>(amountReceived),
      'changeDue': serializer.toJson<double?>(changeDue),
      'itemCount': serializer.toJson<int>(itemCount),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'lastSyncAttempt': serializer.toJson<DateTime?>(lastSyncAttempt),
      'syncError': serializer.toJson<String?>(syncError),
    };
  }

  TransactionsTableData copyWith({
    String? id,
    Value<String?> businessId = const Value.absent(),
    Value<String?> branchId = const Value.absent(),
    String? cashierId,
    Value<String?> shiftId = const Value.absent(),
    double? totalAmount,
    double? discountAmount,
    double? taxAmount,
    String? status,
    Value<String?> transactionHash = const Value.absent(),
    DateTime? createdAt,
    Value<String?> customerName = const Value.absent(),
    String? paymentMethod,
    double? subtotal,
    Value<double?> amountReceived = const Value.absent(),
    Value<double?> changeDue = const Value.absent(),
    int? itemCount,
    int? syncStatus,
    Value<DateTime?> lastSyncAttempt = const Value.absent(),
    Value<String?> syncError = const Value.absent(),
  }) => TransactionsTableData(
    id: id ?? this.id,
    businessId: businessId.present ? businessId.value : this.businessId,
    branchId: branchId.present ? branchId.value : this.branchId,
    cashierId: cashierId ?? this.cashierId,
    shiftId: shiftId.present ? shiftId.value : this.shiftId,
    totalAmount: totalAmount ?? this.totalAmount,
    discountAmount: discountAmount ?? this.discountAmount,
    taxAmount: taxAmount ?? this.taxAmount,
    status: status ?? this.status,
    transactionHash: transactionHash.present
        ? transactionHash.value
        : this.transactionHash,
    createdAt: createdAt ?? this.createdAt,
    customerName: customerName.present ? customerName.value : this.customerName,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    subtotal: subtotal ?? this.subtotal,
    amountReceived: amountReceived.present
        ? amountReceived.value
        : this.amountReceived,
    changeDue: changeDue.present ? changeDue.value : this.changeDue,
    itemCount: itemCount ?? this.itemCount,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncAttempt: lastSyncAttempt.present
        ? lastSyncAttempt.value
        : this.lastSyncAttempt,
    syncError: syncError.present ? syncError.value : this.syncError,
  );
  TransactionsTableData copyWithCompanion(TransactionsTableCompanion data) {
    return TransactionsTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      cashierId: data.cashierId.present ? data.cashierId.value : this.cashierId,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      discountAmount: data.discountAmount.present
          ? data.discountAmount.value
          : this.discountAmount,
      taxAmount: data.taxAmount.present ? data.taxAmount.value : this.taxAmount,
      status: data.status.present ? data.status.value : this.status,
      transactionHash: data.transactionHash.present
          ? data.transactionHash.value
          : this.transactionHash,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      amountReceived: data.amountReceived.present
          ? data.amountReceived.value
          : this.amountReceived,
      changeDue: data.changeDue.present ? data.changeDue.value : this.changeDue,
      itemCount: data.itemCount.present ? data.itemCount.value : this.itemCount,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastSyncAttempt: data.lastSyncAttempt.present
          ? data.lastSyncAttempt.value
          : this.lastSyncAttempt,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('branchId: $branchId, ')
          ..write('cashierId: $cashierId, ')
          ..write('shiftId: $shiftId, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('status: $status, ')
          ..write('transactionHash: $transactionHash, ')
          ..write('createdAt: $createdAt, ')
          ..write('customerName: $customerName, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('subtotal: $subtotal, ')
          ..write('amountReceived: $amountReceived, ')
          ..write('changeDue: $changeDue, ')
          ..write('itemCount: $itemCount, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    branchId,
    cashierId,
    shiftId,
    totalAmount,
    discountAmount,
    taxAmount,
    status,
    transactionHash,
    createdAt,
    customerName,
    paymentMethod,
    subtotal,
    amountReceived,
    changeDue,
    itemCount,
    syncStatus,
    lastSyncAttempt,
    syncError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionsTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.branchId == this.branchId &&
          other.cashierId == this.cashierId &&
          other.shiftId == this.shiftId &&
          other.totalAmount == this.totalAmount &&
          other.discountAmount == this.discountAmount &&
          other.taxAmount == this.taxAmount &&
          other.status == this.status &&
          other.transactionHash == this.transactionHash &&
          other.createdAt == this.createdAt &&
          other.customerName == this.customerName &&
          other.paymentMethod == this.paymentMethod &&
          other.subtotal == this.subtotal &&
          other.amountReceived == this.amountReceived &&
          other.changeDue == this.changeDue &&
          other.itemCount == this.itemCount &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncAttempt == this.lastSyncAttempt &&
          other.syncError == this.syncError);
}

class TransactionsTableCompanion
    extends UpdateCompanion<TransactionsTableData> {
  final Value<String> id;
  final Value<String?> businessId;
  final Value<String?> branchId;
  final Value<String> cashierId;
  final Value<String?> shiftId;
  final Value<double> totalAmount;
  final Value<double> discountAmount;
  final Value<double> taxAmount;
  final Value<String> status;
  final Value<String?> transactionHash;
  final Value<DateTime> createdAt;
  final Value<String?> customerName;
  final Value<String> paymentMethod;
  final Value<double> subtotal;
  final Value<double?> amountReceived;
  final Value<double?> changeDue;
  final Value<int> itemCount;
  final Value<int> syncStatus;
  final Value<DateTime?> lastSyncAttempt;
  final Value<String?> syncError;
  final Value<int> rowid;
  const TransactionsTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.cashierId = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.status = const Value.absent(),
    this.transactionHash = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.customerName = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.amountReceived = const Value.absent(),
    this.changeDue = const Value.absent(),
    this.itemCount = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsTableCompanion.insert({
    required String id,
    this.businessId = const Value.absent(),
    this.branchId = const Value.absent(),
    required String cashierId,
    this.shiftId = const Value.absent(),
    required double totalAmount,
    this.discountAmount = const Value.absent(),
    required double taxAmount,
    this.status = const Value.absent(),
    this.transactionHash = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.customerName = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    required double subtotal,
    this.amountReceived = const Value.absent(),
    this.changeDue = const Value.absent(),
    required int itemCount,
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       cashierId = Value(cashierId),
       totalAmount = Value(totalAmount),
       taxAmount = Value(taxAmount),
       subtotal = Value(subtotal),
       itemCount = Value(itemCount);
  static Insertable<TransactionsTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? branchId,
    Expression<String>? cashierId,
    Expression<String>? shiftId,
    Expression<double>? totalAmount,
    Expression<double>? discountAmount,
    Expression<double>? taxAmount,
    Expression<String>? status,
    Expression<String>? transactionHash,
    Expression<DateTime>? createdAt,
    Expression<String>? customerName,
    Expression<String>? paymentMethod,
    Expression<double>? subtotal,
    Expression<double>? amountReceived,
    Expression<double>? changeDue,
    Expression<int>? itemCount,
    Expression<int>? syncStatus,
    Expression<DateTime>? lastSyncAttempt,
    Expression<String>? syncError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (branchId != null) 'branch_id': branchId,
      if (cashierId != null) 'cashier_id': cashierId,
      if (shiftId != null) 'shift_id': shiftId,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (taxAmount != null) 'tax_amount': taxAmount,
      if (status != null) 'status': status,
      if (transactionHash != null) 'transaction_hash': transactionHash,
      if (createdAt != null) 'created_at': createdAt,
      if (customerName != null) 'customer_name': customerName,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (subtotal != null) 'subtotal': subtotal,
      if (amountReceived != null) 'amount_received': amountReceived,
      if (changeDue != null) 'change_due': changeDue,
      if (itemCount != null) 'item_count': itemCount,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncAttempt != null) 'last_sync_attempt': lastSyncAttempt,
      if (syncError != null) 'sync_error': syncError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? businessId,
    Value<String?>? branchId,
    Value<String>? cashierId,
    Value<String?>? shiftId,
    Value<double>? totalAmount,
    Value<double>? discountAmount,
    Value<double>? taxAmount,
    Value<String>? status,
    Value<String?>? transactionHash,
    Value<DateTime>? createdAt,
    Value<String?>? customerName,
    Value<String>? paymentMethod,
    Value<double>? subtotal,
    Value<double?>? amountReceived,
    Value<double?>? changeDue,
    Value<int>? itemCount,
    Value<int>? syncStatus,
    Value<DateTime?>? lastSyncAttempt,
    Value<String?>? syncError,
    Value<int>? rowid,
  }) {
    return TransactionsTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      branchId: branchId ?? this.branchId,
      cashierId: cashierId ?? this.cashierId,
      shiftId: shiftId ?? this.shiftId,
      totalAmount: totalAmount ?? this.totalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      status: status ?? this.status,
      transactionHash: transactionHash ?? this.transactionHash,
      createdAt: createdAt ?? this.createdAt,
      customerName: customerName ?? this.customerName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      subtotal: subtotal ?? this.subtotal,
      amountReceived: amountReceived ?? this.amountReceived,
      changeDue: changeDue ?? this.changeDue,
      itemCount: itemCount ?? this.itemCount,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      syncError: syncError ?? this.syncError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (cashierId.present) {
      map['cashier_id'] = Variable<String>(cashierId.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<String>(shiftId.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (discountAmount.present) {
      map['discount_amount'] = Variable<double>(discountAmount.value);
    }
    if (taxAmount.present) {
      map['tax_amount'] = Variable<double>(taxAmount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (transactionHash.present) {
      map['transaction_hash'] = Variable<String>(transactionHash.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (amountReceived.present) {
      map['amount_received'] = Variable<double>(amountReceived.value);
    }
    if (changeDue.present) {
      map['change_due'] = Variable<double>(changeDue.value);
    }
    if (itemCount.present) {
      map['item_count'] = Variable<int>(itemCount.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (lastSyncAttempt.present) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('branchId: $branchId, ')
          ..write('cashierId: $cashierId, ')
          ..write('shiftId: $shiftId, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('status: $status, ')
          ..write('transactionHash: $transactionHash, ')
          ..write('createdAt: $createdAt, ')
          ..write('customerName: $customerName, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('subtotal: $subtotal, ')
          ..write('amountReceived: $amountReceived, ')
          ..write('changeDue: $changeDue, ')
          ..write('itemCount: $itemCount, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionItemsTableTable extends TransactionItemsTable
    with TableInfo<$TransactionItemsTableTable, TransactionItemsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionItemsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variantIdMeta = const VerificationMeta(
    'variantId',
  );
  @override
  late final GeneratedColumn<String> variantId = GeneratedColumn<String>(
    'variant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variantNameMeta = const VerificationMeta(
    'variantName',
  );
  @override
  late final GeneratedColumn<String> variantName = GeneratedColumn<String>(
    'variant_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxRateMeta = const VerificationMeta(
    'taxRate',
  );
  @override
  late final GeneratedColumn<double> taxRate = GeneratedColumn<double>(
    'tax_rate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<double> qty = GeneratedColumn<double>(
    'qty',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineTotalMeta = const VerificationMeta(
    'lineTotal',
  );
  @override
  late final GeneratedColumn<double> lineTotal = GeneratedColumn<double>(
    'line_total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineTaxMeta = const VerificationMeta(
    'lineTax',
  );
  @override
  late final GeneratedColumn<double> lineTax = GeneratedColumn<double>(
    'line_tax',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transactionId,
    variantId,
    productName,
    variantName,
    unitPrice,
    taxRate,
    qty,
    lineTotal,
    lineTax,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionItemsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('variant_id')) {
      context.handle(
        _variantIdMeta,
        variantId.isAcceptableOrUnknown(data['variant_id']!, _variantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_variantIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('variant_name')) {
      context.handle(
        _variantNameMeta,
        variantName.isAcceptableOrUnknown(
          data['variant_name']!,
          _variantNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_variantNameMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('tax_rate')) {
      context.handle(
        _taxRateMeta,
        taxRate.isAcceptableOrUnknown(data['tax_rate']!, _taxRateMeta),
      );
    }
    if (data.containsKey('qty')) {
      context.handle(
        _qtyMeta,
        qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMeta);
    }
    if (data.containsKey('line_total')) {
      context.handle(
        _lineTotalMeta,
        lineTotal.isAcceptableOrUnknown(data['line_total']!, _lineTotalMeta),
      );
    } else if (isInserting) {
      context.missing(_lineTotalMeta);
    }
    if (data.containsKey('line_tax')) {
      context.handle(
        _lineTaxMeta,
        lineTax.isAcceptableOrUnknown(data['line_tax']!, _lineTaxMeta),
      );
    } else if (isInserting) {
      context.missing(_lineTaxMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionItemsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionItemsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      )!,
      variantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_id'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      variantName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_name'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_price'],
      )!,
      taxRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tax_rate'],
      ),
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}qty'],
      )!,
      lineTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}line_total'],
      )!,
      lineTax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}line_tax'],
      )!,
    );
  }

  @override
  $TransactionItemsTableTable createAlias(String alias) {
    return $TransactionItemsTableTable(attachedDatabase, alias);
  }
}

class TransactionItemsTableData extends DataClass
    implements Insertable<TransactionItemsTableData> {
  final String id;
  final String transactionId;
  final String variantId;
  final String productName;
  final String variantName;
  final double unitPrice;
  final double? taxRate;
  final double qty;
  final double lineTotal;
  final double lineTax;
  const TransactionItemsTableData({
    required this.id,
    required this.transactionId,
    required this.variantId,
    required this.productName,
    required this.variantName,
    required this.unitPrice,
    this.taxRate,
    required this.qty,
    required this.lineTotal,
    required this.lineTax,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['transaction_id'] = Variable<String>(transactionId);
    map['variant_id'] = Variable<String>(variantId);
    map['product_name'] = Variable<String>(productName);
    map['variant_name'] = Variable<String>(variantName);
    map['unit_price'] = Variable<double>(unitPrice);
    if (!nullToAbsent || taxRate != null) {
      map['tax_rate'] = Variable<double>(taxRate);
    }
    map['qty'] = Variable<double>(qty);
    map['line_total'] = Variable<double>(lineTotal);
    map['line_tax'] = Variable<double>(lineTax);
    return map;
  }

  TransactionItemsTableCompanion toCompanion(bool nullToAbsent) {
    return TransactionItemsTableCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      variantId: Value(variantId),
      productName: Value(productName),
      variantName: Value(variantName),
      unitPrice: Value(unitPrice),
      taxRate: taxRate == null && nullToAbsent
          ? const Value.absent()
          : Value(taxRate),
      qty: Value(qty),
      lineTotal: Value(lineTotal),
      lineTax: Value(lineTax),
    );
  }

  factory TransactionItemsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionItemsTableData(
      id: serializer.fromJson<String>(json['id']),
      transactionId: serializer.fromJson<String>(json['transactionId']),
      variantId: serializer.fromJson<String>(json['variantId']),
      productName: serializer.fromJson<String>(json['productName']),
      variantName: serializer.fromJson<String>(json['variantName']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
      taxRate: serializer.fromJson<double?>(json['taxRate']),
      qty: serializer.fromJson<double>(json['qty']),
      lineTotal: serializer.fromJson<double>(json['lineTotal']),
      lineTax: serializer.fromJson<double>(json['lineTax']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transactionId': serializer.toJson<String>(transactionId),
      'variantId': serializer.toJson<String>(variantId),
      'productName': serializer.toJson<String>(productName),
      'variantName': serializer.toJson<String>(variantName),
      'unitPrice': serializer.toJson<double>(unitPrice),
      'taxRate': serializer.toJson<double?>(taxRate),
      'qty': serializer.toJson<double>(qty),
      'lineTotal': serializer.toJson<double>(lineTotal),
      'lineTax': serializer.toJson<double>(lineTax),
    };
  }

  TransactionItemsTableData copyWith({
    String? id,
    String? transactionId,
    String? variantId,
    String? productName,
    String? variantName,
    double? unitPrice,
    Value<double?> taxRate = const Value.absent(),
    double? qty,
    double? lineTotal,
    double? lineTax,
  }) => TransactionItemsTableData(
    id: id ?? this.id,
    transactionId: transactionId ?? this.transactionId,
    variantId: variantId ?? this.variantId,
    productName: productName ?? this.productName,
    variantName: variantName ?? this.variantName,
    unitPrice: unitPrice ?? this.unitPrice,
    taxRate: taxRate.present ? taxRate.value : this.taxRate,
    qty: qty ?? this.qty,
    lineTotal: lineTotal ?? this.lineTotal,
    lineTax: lineTax ?? this.lineTax,
  );
  TransactionItemsTableData copyWithCompanion(
    TransactionItemsTableCompanion data,
  ) {
    return TransactionItemsTableData(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      variantId: data.variantId.present ? data.variantId.value : this.variantId,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      variantName: data.variantName.present
          ? data.variantName.value
          : this.variantName,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      taxRate: data.taxRate.present ? data.taxRate.value : this.taxRate,
      qty: data.qty.present ? data.qty.value : this.qty,
      lineTotal: data.lineTotal.present ? data.lineTotal.value : this.lineTotal,
      lineTax: data.lineTax.present ? data.lineTax.value : this.lineTax,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionItemsTableData(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('variantId: $variantId, ')
          ..write('productName: $productName, ')
          ..write('variantName: $variantName, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('taxRate: $taxRate, ')
          ..write('qty: $qty, ')
          ..write('lineTotal: $lineTotal, ')
          ..write('lineTax: $lineTax')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    transactionId,
    variantId,
    productName,
    variantName,
    unitPrice,
    taxRate,
    qty,
    lineTotal,
    lineTax,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionItemsTableData &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.variantId == this.variantId &&
          other.productName == this.productName &&
          other.variantName == this.variantName &&
          other.unitPrice == this.unitPrice &&
          other.taxRate == this.taxRate &&
          other.qty == this.qty &&
          other.lineTotal == this.lineTotal &&
          other.lineTax == this.lineTax);
}

class TransactionItemsTableCompanion
    extends UpdateCompanion<TransactionItemsTableData> {
  final Value<String> id;
  final Value<String> transactionId;
  final Value<String> variantId;
  final Value<String> productName;
  final Value<String> variantName;
  final Value<double> unitPrice;
  final Value<double?> taxRate;
  final Value<double> qty;
  final Value<double> lineTotal;
  final Value<double> lineTax;
  final Value<int> rowid;
  const TransactionItemsTableCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.variantId = const Value.absent(),
    this.productName = const Value.absent(),
    this.variantName = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.taxRate = const Value.absent(),
    this.qty = const Value.absent(),
    this.lineTotal = const Value.absent(),
    this.lineTax = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionItemsTableCompanion.insert({
    required String id,
    required String transactionId,
    required String variantId,
    required String productName,
    required String variantName,
    required double unitPrice,
    this.taxRate = const Value.absent(),
    required double qty,
    required double lineTotal,
    required double lineTax,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       transactionId = Value(transactionId),
       variantId = Value(variantId),
       productName = Value(productName),
       variantName = Value(variantName),
       unitPrice = Value(unitPrice),
       qty = Value(qty),
       lineTotal = Value(lineTotal),
       lineTax = Value(lineTax);
  static Insertable<TransactionItemsTableData> custom({
    Expression<String>? id,
    Expression<String>? transactionId,
    Expression<String>? variantId,
    Expression<String>? productName,
    Expression<String>? variantName,
    Expression<double>? unitPrice,
    Expression<double>? taxRate,
    Expression<double>? qty,
    Expression<double>? lineTotal,
    Expression<double>? lineTax,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (variantId != null) 'variant_id': variantId,
      if (productName != null) 'product_name': productName,
      if (variantName != null) 'variant_name': variantName,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (taxRate != null) 'tax_rate': taxRate,
      if (qty != null) 'qty': qty,
      if (lineTotal != null) 'line_total': lineTotal,
      if (lineTax != null) 'line_tax': lineTax,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionItemsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? transactionId,
    Value<String>? variantId,
    Value<String>? productName,
    Value<String>? variantName,
    Value<double>? unitPrice,
    Value<double?>? taxRate,
    Value<double>? qty,
    Value<double>? lineTotal,
    Value<double>? lineTax,
    Value<int>? rowid,
  }) {
    return TransactionItemsTableCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      variantId: variantId ?? this.variantId,
      productName: productName ?? this.productName,
      variantName: variantName ?? this.variantName,
      unitPrice: unitPrice ?? this.unitPrice,
      taxRate: taxRate ?? this.taxRate,
      qty: qty ?? this.qty,
      lineTotal: lineTotal ?? this.lineTotal,
      lineTax: lineTax ?? this.lineTax,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (variantId.present) {
      map['variant_id'] = Variable<String>(variantId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (variantName.present) {
      map['variant_name'] = Variable<String>(variantName.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (taxRate.present) {
      map['tax_rate'] = Variable<double>(taxRate.value);
    }
    if (qty.present) {
      map['qty'] = Variable<double>(qty.value);
    }
    if (lineTotal.present) {
      map['line_total'] = Variable<double>(lineTotal.value);
    }
    if (lineTax.present) {
      map['line_tax'] = Variable<double>(lineTax.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionItemsTableCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('variantId: $variantId, ')
          ..write('productName: $productName, ')
          ..write('variantName: $variantName, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('taxRate: $taxRate, ')
          ..write('qty: $qty, ')
          ..write('lineTotal: $lineTotal, ')
          ..write('lineTax: $lineTax, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DraftSalesTableTable extends DraftSalesTable
    with TableInfo<$DraftSalesTableTable, DraftSalesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DraftSalesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cashierIdMeta = const VerificationMeta(
    'cashierId',
  );
  @override
  late final GeneratedColumn<String> cashierId = GeneratedColumn<String>(
    'cashier_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxAmountMeta = const VerificationMeta(
    'taxAmount',
  );
  @override
  late final GeneratedColumn<double> taxAmount = GeneratedColumn<double>(
    'tax_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountAmountMeta = const VerificationMeta(
    'discountAmount',
  );
  @override
  late final GeneratedColumn<double> discountAmount = GeneratedColumn<double>(
    'discount_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemCountMeta = const VerificationMeta(
    'itemCount',
  );
  @override
  late final GeneratedColumn<int> itemCount = GeneratedColumn<int>(
    'item_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountTypeMeta = const VerificationMeta(
    'discountType',
  );
  @override
  late final GeneratedColumn<String> discountType = GeneratedColumn<String>(
    'discount_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _discountValueMeta = const VerificationMeta(
    'discountValue',
  );
  @override
  late final GeneratedColumn<double> discountValue = GeneratedColumn<double>(
    'discount_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('open'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncAttemptMeta = const VerificationMeta(
    'lastSyncAttempt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAttempt =
      GeneratedColumn<DateTime>(
        'last_sync_attempt',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    branchId,
    cashierId,
    label,
    customerName,
    subtotal,
    taxAmount,
    discountAmount,
    totalAmount,
    itemCount,
    discountType,
    discountValue,
    status,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
    lastSyncAttempt,
    syncError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'draft_sales';
  @override
  VerificationContext validateIntegrity(
    Insertable<DraftSalesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    }
    if (data.containsKey('cashier_id')) {
      context.handle(
        _cashierIdMeta,
        cashierId.isAcceptableOrUnknown(data['cashier_id']!, _cashierIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cashierIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    } else if (isInserting) {
      context.missing(_subtotalMeta);
    }
    if (data.containsKey('tax_amount')) {
      context.handle(
        _taxAmountMeta,
        taxAmount.isAcceptableOrUnknown(data['tax_amount']!, _taxAmountMeta),
      );
    } else if (isInserting) {
      context.missing(_taxAmountMeta);
    }
    if (data.containsKey('discount_amount')) {
      context.handle(
        _discountAmountMeta,
        discountAmount.isAcceptableOrUnknown(
          data['discount_amount']!,
          _discountAmountMeta,
        ),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('item_count')) {
      context.handle(
        _itemCountMeta,
        itemCount.isAcceptableOrUnknown(data['item_count']!, _itemCountMeta),
      );
    } else if (isInserting) {
      context.missing(_itemCountMeta);
    }
    if (data.containsKey('discount_type')) {
      context.handle(
        _discountTypeMeta,
        discountType.isAcceptableOrUnknown(
          data['discount_type']!,
          _discountTypeMeta,
        ),
      );
    }
    if (data.containsKey('discount_value')) {
      context.handle(
        _discountValueMeta,
        discountValue.isAcceptableOrUnknown(
          data['discount_value']!,
          _discountValueMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('last_sync_attempt')) {
      context.handle(
        _lastSyncAttemptMeta,
        lastSyncAttempt.isAcceptableOrUnknown(
          data['last_sync_attempt']!,
          _lastSyncAttemptMeta,
        ),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DraftSalesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DraftSalesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      ),
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      ),
      cashierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashier_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      ),
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}subtotal'],
      )!,
      taxAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tax_amount'],
      )!,
      discountAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}discount_amount'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      itemCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_count'],
      )!,
      discountType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discount_type'],
      ),
      discountValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}discount_value'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      lastSyncAttempt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_attempt'],
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
    );
  }

  @override
  $DraftSalesTableTable createAlias(String alias) {
    return $DraftSalesTableTable(attachedDatabase, alias);
  }
}

class DraftSalesTableData extends DataClass
    implements Insertable<DraftSalesTableData> {
  final String id;
  final String? businessId;
  final String? branchId;
  final String cashierId;

  /// Optional human label e.g. "Table 5", "Mrs. Cruz".
  final String? label;
  final String? customerName;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final int itemCount;

  /// 'percentage' | 'fixed' | null
  final String? discountType;
  final double? discountValue;

  /// open | converted | voided
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Soft delete — set when converted or discarded.
  final DateTime? deletedAt;
  final int syncStatus;
  final DateTime? lastSyncAttempt;
  final String? syncError;
  const DraftSalesTableData({
    required this.id,
    this.businessId,
    this.branchId,
    required this.cashierId,
    this.label,
    this.customerName,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.itemCount,
    this.discountType,
    this.discountValue,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
    this.lastSyncAttempt,
    this.syncError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || businessId != null) {
      map['business_id'] = Variable<String>(businessId);
    }
    if (!nullToAbsent || branchId != null) {
      map['branch_id'] = Variable<String>(branchId);
    }
    map['cashier_id'] = Variable<String>(cashierId);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    if (!nullToAbsent || customerName != null) {
      map['customer_name'] = Variable<String>(customerName);
    }
    map['subtotal'] = Variable<double>(subtotal);
    map['tax_amount'] = Variable<double>(taxAmount);
    map['discount_amount'] = Variable<double>(discountAmount);
    map['total_amount'] = Variable<double>(totalAmount);
    map['item_count'] = Variable<int>(itemCount);
    if (!nullToAbsent || discountType != null) {
      map['discount_type'] = Variable<String>(discountType);
    }
    if (!nullToAbsent || discountValue != null) {
      map['discount_value'] = Variable<double>(discountValue);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || lastSyncAttempt != null) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt);
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    return map;
  }

  DraftSalesTableCompanion toCompanion(bool nullToAbsent) {
    return DraftSalesTableCompanion(
      id: Value(id),
      businessId: businessId == null && nullToAbsent
          ? const Value.absent()
          : Value(businessId),
      branchId: branchId == null && nullToAbsent
          ? const Value.absent()
          : Value(branchId),
      cashierId: Value(cashierId),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      customerName: customerName == null && nullToAbsent
          ? const Value.absent()
          : Value(customerName),
      subtotal: Value(subtotal),
      taxAmount: Value(taxAmount),
      discountAmount: Value(discountAmount),
      totalAmount: Value(totalAmount),
      itemCount: Value(itemCount),
      discountType: discountType == null && nullToAbsent
          ? const Value.absent()
          : Value(discountType),
      discountValue: discountValue == null && nullToAbsent
          ? const Value.absent()
          : Value(discountValue),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
      lastSyncAttempt: lastSyncAttempt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAttempt),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
    );
  }

  factory DraftSalesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DraftSalesTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String?>(json['businessId']),
      branchId: serializer.fromJson<String?>(json['branchId']),
      cashierId: serializer.fromJson<String>(json['cashierId']),
      label: serializer.fromJson<String?>(json['label']),
      customerName: serializer.fromJson<String?>(json['customerName']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      taxAmount: serializer.fromJson<double>(json['taxAmount']),
      discountAmount: serializer.fromJson<double>(json['discountAmount']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      itemCount: serializer.fromJson<int>(json['itemCount']),
      discountType: serializer.fromJson<String?>(json['discountType']),
      discountValue: serializer.fromJson<double?>(json['discountValue']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      lastSyncAttempt: serializer.fromJson<DateTime?>(json['lastSyncAttempt']),
      syncError: serializer.fromJson<String?>(json['syncError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String?>(businessId),
      'branchId': serializer.toJson<String?>(branchId),
      'cashierId': serializer.toJson<String>(cashierId),
      'label': serializer.toJson<String?>(label),
      'customerName': serializer.toJson<String?>(customerName),
      'subtotal': serializer.toJson<double>(subtotal),
      'taxAmount': serializer.toJson<double>(taxAmount),
      'discountAmount': serializer.toJson<double>(discountAmount),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'itemCount': serializer.toJson<int>(itemCount),
      'discountType': serializer.toJson<String?>(discountType),
      'discountValue': serializer.toJson<double?>(discountValue),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'lastSyncAttempt': serializer.toJson<DateTime?>(lastSyncAttempt),
      'syncError': serializer.toJson<String?>(syncError),
    };
  }

  DraftSalesTableData copyWith({
    String? id,
    Value<String?> businessId = const Value.absent(),
    Value<String?> branchId = const Value.absent(),
    String? cashierId,
    Value<String?> label = const Value.absent(),
    Value<String?> customerName = const Value.absent(),
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? totalAmount,
    int? itemCount,
    Value<String?> discountType = const Value.absent(),
    Value<double?> discountValue = const Value.absent(),
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? syncStatus,
    Value<DateTime?> lastSyncAttempt = const Value.absent(),
    Value<String?> syncError = const Value.absent(),
  }) => DraftSalesTableData(
    id: id ?? this.id,
    businessId: businessId.present ? businessId.value : this.businessId,
    branchId: branchId.present ? branchId.value : this.branchId,
    cashierId: cashierId ?? this.cashierId,
    label: label.present ? label.value : this.label,
    customerName: customerName.present ? customerName.value : this.customerName,
    subtotal: subtotal ?? this.subtotal,
    taxAmount: taxAmount ?? this.taxAmount,
    discountAmount: discountAmount ?? this.discountAmount,
    totalAmount: totalAmount ?? this.totalAmount,
    itemCount: itemCount ?? this.itemCount,
    discountType: discountType.present ? discountType.value : this.discountType,
    discountValue: discountValue.present
        ? discountValue.value
        : this.discountValue,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncAttempt: lastSyncAttempt.present
        ? lastSyncAttempt.value
        : this.lastSyncAttempt,
    syncError: syncError.present ? syncError.value : this.syncError,
  );
  DraftSalesTableData copyWithCompanion(DraftSalesTableCompanion data) {
    return DraftSalesTableData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      cashierId: data.cashierId.present ? data.cashierId.value : this.cashierId,
      label: data.label.present ? data.label.value : this.label,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      taxAmount: data.taxAmount.present ? data.taxAmount.value : this.taxAmount,
      discountAmount: data.discountAmount.present
          ? data.discountAmount.value
          : this.discountAmount,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      itemCount: data.itemCount.present ? data.itemCount.value : this.itemCount,
      discountType: data.discountType.present
          ? data.discountType.value
          : this.discountType,
      discountValue: data.discountValue.present
          ? data.discountValue.value
          : this.discountValue,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastSyncAttempt: data.lastSyncAttempt.present
          ? data.lastSyncAttempt.value
          : this.lastSyncAttempt,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DraftSalesTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('branchId: $branchId, ')
          ..write('cashierId: $cashierId, ')
          ..write('label: $label, ')
          ..write('customerName: $customerName, ')
          ..write('subtotal: $subtotal, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('itemCount: $itemCount, ')
          ..write('discountType: $discountType, ')
          ..write('discountValue: $discountValue, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    branchId,
    cashierId,
    label,
    customerName,
    subtotal,
    taxAmount,
    discountAmount,
    totalAmount,
    itemCount,
    discountType,
    discountValue,
    status,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
    lastSyncAttempt,
    syncError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DraftSalesTableData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.branchId == this.branchId &&
          other.cashierId == this.cashierId &&
          other.label == this.label &&
          other.customerName == this.customerName &&
          other.subtotal == this.subtotal &&
          other.taxAmount == this.taxAmount &&
          other.discountAmount == this.discountAmount &&
          other.totalAmount == this.totalAmount &&
          other.itemCount == this.itemCount &&
          other.discountType == this.discountType &&
          other.discountValue == this.discountValue &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncAttempt == this.lastSyncAttempt &&
          other.syncError == this.syncError);
}

class DraftSalesTableCompanion extends UpdateCompanion<DraftSalesTableData> {
  final Value<String> id;
  final Value<String?> businessId;
  final Value<String?> branchId;
  final Value<String> cashierId;
  final Value<String?> label;
  final Value<String?> customerName;
  final Value<double> subtotal;
  final Value<double> taxAmount;
  final Value<double> discountAmount;
  final Value<double> totalAmount;
  final Value<int> itemCount;
  final Value<String?> discountType;
  final Value<double?> discountValue;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> syncStatus;
  final Value<DateTime?> lastSyncAttempt;
  final Value<String?> syncError;
  final Value<int> rowid;
  const DraftSalesTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.cashierId = const Value.absent(),
    this.label = const Value.absent(),
    this.customerName = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.itemCount = const Value.absent(),
    this.discountType = const Value.absent(),
    this.discountValue = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DraftSalesTableCompanion.insert({
    required String id,
    this.businessId = const Value.absent(),
    this.branchId = const Value.absent(),
    required String cashierId,
    this.label = const Value.absent(),
    this.customerName = const Value.absent(),
    required double subtotal,
    required double taxAmount,
    this.discountAmount = const Value.absent(),
    required double totalAmount,
    required int itemCount,
    this.discountType = const Value.absent(),
    this.discountValue = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       cashierId = Value(cashierId),
       subtotal = Value(subtotal),
       taxAmount = Value(taxAmount),
       totalAmount = Value(totalAmount),
       itemCount = Value(itemCount);
  static Insertable<DraftSalesTableData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? branchId,
    Expression<String>? cashierId,
    Expression<String>? label,
    Expression<String>? customerName,
    Expression<double>? subtotal,
    Expression<double>? taxAmount,
    Expression<double>? discountAmount,
    Expression<double>? totalAmount,
    Expression<int>? itemCount,
    Expression<String>? discountType,
    Expression<double>? discountValue,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? syncStatus,
    Expression<DateTime>? lastSyncAttempt,
    Expression<String>? syncError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (branchId != null) 'branch_id': branchId,
      if (cashierId != null) 'cashier_id': cashierId,
      if (label != null) 'label': label,
      if (customerName != null) 'customer_name': customerName,
      if (subtotal != null) 'subtotal': subtotal,
      if (taxAmount != null) 'tax_amount': taxAmount,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (itemCount != null) 'item_count': itemCount,
      if (discountType != null) 'discount_type': discountType,
      if (discountValue != null) 'discount_value': discountValue,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncAttempt != null) 'last_sync_attempt': lastSyncAttempt,
      if (syncError != null) 'sync_error': syncError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DraftSalesTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? businessId,
    Value<String?>? branchId,
    Value<String>? cashierId,
    Value<String?>? label,
    Value<String?>? customerName,
    Value<double>? subtotal,
    Value<double>? taxAmount,
    Value<double>? discountAmount,
    Value<double>? totalAmount,
    Value<int>? itemCount,
    Value<String?>? discountType,
    Value<double?>? discountValue,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? syncStatus,
    Value<DateTime?>? lastSyncAttempt,
    Value<String?>? syncError,
    Value<int>? rowid,
  }) {
    return DraftSalesTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      branchId: branchId ?? this.branchId,
      cashierId: cashierId ?? this.cashierId,
      label: label ?? this.label,
      customerName: customerName ?? this.customerName,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      itemCount: itemCount ?? this.itemCount,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      syncError: syncError ?? this.syncError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (cashierId.present) {
      map['cashier_id'] = Variable<String>(cashierId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (taxAmount.present) {
      map['tax_amount'] = Variable<double>(taxAmount.value);
    }
    if (discountAmount.present) {
      map['discount_amount'] = Variable<double>(discountAmount.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (itemCount.present) {
      map['item_count'] = Variable<int>(itemCount.value);
    }
    if (discountType.present) {
      map['discount_type'] = Variable<String>(discountType.value);
    }
    if (discountValue.present) {
      map['discount_value'] = Variable<double>(discountValue.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (lastSyncAttempt.present) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DraftSalesTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('branchId: $branchId, ')
          ..write('cashierId: $cashierId, ')
          ..write('label: $label, ')
          ..write('customerName: $customerName, ')
          ..write('subtotal: $subtotal, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('itemCount: $itemCount, ')
          ..write('discountType: $discountType, ')
          ..write('discountValue: $discountValue, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DraftSaleItemsTableTable extends DraftSaleItemsTable
    with TableInfo<$DraftSaleItemsTableTable, DraftSaleItemsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DraftSaleItemsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _draftIdMeta = const VerificationMeta(
    'draftId',
  );
  @override
  late final GeneratedColumn<String> draftId = GeneratedColumn<String>(
    'draft_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variantIdMeta = const VerificationMeta(
    'variantId',
  );
  @override
  late final GeneratedColumn<String> variantId = GeneratedColumn<String>(
    'variant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variantNameMeta = const VerificationMeta(
    'variantName',
  );
  @override
  late final GeneratedColumn<String> variantName = GeneratedColumn<String>(
    'variant_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxRateMeta = const VerificationMeta(
    'taxRate',
  );
  @override
  late final GeneratedColumn<double> taxRate = GeneratedColumn<double>(
    'tax_rate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<double> qty = GeneratedColumn<double>(
    'qty',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineTotalMeta = const VerificationMeta(
    'lineTotal',
  );
  @override
  late final GeneratedColumn<double> lineTotal = GeneratedColumn<double>(
    'line_total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineTaxMeta = const VerificationMeta(
    'lineTax',
  );
  @override
  late final GeneratedColumn<double> lineTax = GeneratedColumn<double>(
    'line_tax',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    draftId,
    variantId,
    productName,
    variantName,
    unitPrice,
    taxRate,
    qty,
    lineTotal,
    lineTax,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'draft_sale_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<DraftSaleItemsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('draft_id')) {
      context.handle(
        _draftIdMeta,
        draftId.isAcceptableOrUnknown(data['draft_id']!, _draftIdMeta),
      );
    } else if (isInserting) {
      context.missing(_draftIdMeta);
    }
    if (data.containsKey('variant_id')) {
      context.handle(
        _variantIdMeta,
        variantId.isAcceptableOrUnknown(data['variant_id']!, _variantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_variantIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('variant_name')) {
      context.handle(
        _variantNameMeta,
        variantName.isAcceptableOrUnknown(
          data['variant_name']!,
          _variantNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_variantNameMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('tax_rate')) {
      context.handle(
        _taxRateMeta,
        taxRate.isAcceptableOrUnknown(data['tax_rate']!, _taxRateMeta),
      );
    }
    if (data.containsKey('qty')) {
      context.handle(
        _qtyMeta,
        qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMeta);
    }
    if (data.containsKey('line_total')) {
      context.handle(
        _lineTotalMeta,
        lineTotal.isAcceptableOrUnknown(data['line_total']!, _lineTotalMeta),
      );
    } else if (isInserting) {
      context.missing(_lineTotalMeta);
    }
    if (data.containsKey('line_tax')) {
      context.handle(
        _lineTaxMeta,
        lineTax.isAcceptableOrUnknown(data['line_tax']!, _lineTaxMeta),
      );
    } else if (isInserting) {
      context.missing(_lineTaxMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DraftSaleItemsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DraftSaleItemsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      draftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}draft_id'],
      )!,
      variantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_id'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      variantName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_name'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_price'],
      )!,
      taxRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tax_rate'],
      ),
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}qty'],
      )!,
      lineTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}line_total'],
      )!,
      lineTax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}line_tax'],
      )!,
    );
  }

  @override
  $DraftSaleItemsTableTable createAlias(String alias) {
    return $DraftSaleItemsTableTable(attachedDatabase, alias);
  }
}

class DraftSaleItemsTableData extends DataClass
    implements Insertable<DraftSaleItemsTableData> {
  final String id;
  final String draftId;
  final String variantId;
  final String productName;
  final String variantName;
  final double unitPrice;
  final double? taxRate;
  final double qty;
  final double lineTotal;
  final double lineTax;
  const DraftSaleItemsTableData({
    required this.id,
    required this.draftId,
    required this.variantId,
    required this.productName,
    required this.variantName,
    required this.unitPrice,
    this.taxRate,
    required this.qty,
    required this.lineTotal,
    required this.lineTax,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['draft_id'] = Variable<String>(draftId);
    map['variant_id'] = Variable<String>(variantId);
    map['product_name'] = Variable<String>(productName);
    map['variant_name'] = Variable<String>(variantName);
    map['unit_price'] = Variable<double>(unitPrice);
    if (!nullToAbsent || taxRate != null) {
      map['tax_rate'] = Variable<double>(taxRate);
    }
    map['qty'] = Variable<double>(qty);
    map['line_total'] = Variable<double>(lineTotal);
    map['line_tax'] = Variable<double>(lineTax);
    return map;
  }

  DraftSaleItemsTableCompanion toCompanion(bool nullToAbsent) {
    return DraftSaleItemsTableCompanion(
      id: Value(id),
      draftId: Value(draftId),
      variantId: Value(variantId),
      productName: Value(productName),
      variantName: Value(variantName),
      unitPrice: Value(unitPrice),
      taxRate: taxRate == null && nullToAbsent
          ? const Value.absent()
          : Value(taxRate),
      qty: Value(qty),
      lineTotal: Value(lineTotal),
      lineTax: Value(lineTax),
    );
  }

  factory DraftSaleItemsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DraftSaleItemsTableData(
      id: serializer.fromJson<String>(json['id']),
      draftId: serializer.fromJson<String>(json['draftId']),
      variantId: serializer.fromJson<String>(json['variantId']),
      productName: serializer.fromJson<String>(json['productName']),
      variantName: serializer.fromJson<String>(json['variantName']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
      taxRate: serializer.fromJson<double?>(json['taxRate']),
      qty: serializer.fromJson<double>(json['qty']),
      lineTotal: serializer.fromJson<double>(json['lineTotal']),
      lineTax: serializer.fromJson<double>(json['lineTax']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'draftId': serializer.toJson<String>(draftId),
      'variantId': serializer.toJson<String>(variantId),
      'productName': serializer.toJson<String>(productName),
      'variantName': serializer.toJson<String>(variantName),
      'unitPrice': serializer.toJson<double>(unitPrice),
      'taxRate': serializer.toJson<double?>(taxRate),
      'qty': serializer.toJson<double>(qty),
      'lineTotal': serializer.toJson<double>(lineTotal),
      'lineTax': serializer.toJson<double>(lineTax),
    };
  }

  DraftSaleItemsTableData copyWith({
    String? id,
    String? draftId,
    String? variantId,
    String? productName,
    String? variantName,
    double? unitPrice,
    Value<double?> taxRate = const Value.absent(),
    double? qty,
    double? lineTotal,
    double? lineTax,
  }) => DraftSaleItemsTableData(
    id: id ?? this.id,
    draftId: draftId ?? this.draftId,
    variantId: variantId ?? this.variantId,
    productName: productName ?? this.productName,
    variantName: variantName ?? this.variantName,
    unitPrice: unitPrice ?? this.unitPrice,
    taxRate: taxRate.present ? taxRate.value : this.taxRate,
    qty: qty ?? this.qty,
    lineTotal: lineTotal ?? this.lineTotal,
    lineTax: lineTax ?? this.lineTax,
  );
  DraftSaleItemsTableData copyWithCompanion(DraftSaleItemsTableCompanion data) {
    return DraftSaleItemsTableData(
      id: data.id.present ? data.id.value : this.id,
      draftId: data.draftId.present ? data.draftId.value : this.draftId,
      variantId: data.variantId.present ? data.variantId.value : this.variantId,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      variantName: data.variantName.present
          ? data.variantName.value
          : this.variantName,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      taxRate: data.taxRate.present ? data.taxRate.value : this.taxRate,
      qty: data.qty.present ? data.qty.value : this.qty,
      lineTotal: data.lineTotal.present ? data.lineTotal.value : this.lineTotal,
      lineTax: data.lineTax.present ? data.lineTax.value : this.lineTax,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DraftSaleItemsTableData(')
          ..write('id: $id, ')
          ..write('draftId: $draftId, ')
          ..write('variantId: $variantId, ')
          ..write('productName: $productName, ')
          ..write('variantName: $variantName, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('taxRate: $taxRate, ')
          ..write('qty: $qty, ')
          ..write('lineTotal: $lineTotal, ')
          ..write('lineTax: $lineTax')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    draftId,
    variantId,
    productName,
    variantName,
    unitPrice,
    taxRate,
    qty,
    lineTotal,
    lineTax,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DraftSaleItemsTableData &&
          other.id == this.id &&
          other.draftId == this.draftId &&
          other.variantId == this.variantId &&
          other.productName == this.productName &&
          other.variantName == this.variantName &&
          other.unitPrice == this.unitPrice &&
          other.taxRate == this.taxRate &&
          other.qty == this.qty &&
          other.lineTotal == this.lineTotal &&
          other.lineTax == this.lineTax);
}

class DraftSaleItemsTableCompanion
    extends UpdateCompanion<DraftSaleItemsTableData> {
  final Value<String> id;
  final Value<String> draftId;
  final Value<String> variantId;
  final Value<String> productName;
  final Value<String> variantName;
  final Value<double> unitPrice;
  final Value<double?> taxRate;
  final Value<double> qty;
  final Value<double> lineTotal;
  final Value<double> lineTax;
  final Value<int> rowid;
  const DraftSaleItemsTableCompanion({
    this.id = const Value.absent(),
    this.draftId = const Value.absent(),
    this.variantId = const Value.absent(),
    this.productName = const Value.absent(),
    this.variantName = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.taxRate = const Value.absent(),
    this.qty = const Value.absent(),
    this.lineTotal = const Value.absent(),
    this.lineTax = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DraftSaleItemsTableCompanion.insert({
    required String id,
    required String draftId,
    required String variantId,
    required String productName,
    required String variantName,
    required double unitPrice,
    this.taxRate = const Value.absent(),
    required double qty,
    required double lineTotal,
    required double lineTax,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       draftId = Value(draftId),
       variantId = Value(variantId),
       productName = Value(productName),
       variantName = Value(variantName),
       unitPrice = Value(unitPrice),
       qty = Value(qty),
       lineTotal = Value(lineTotal),
       lineTax = Value(lineTax);
  static Insertable<DraftSaleItemsTableData> custom({
    Expression<String>? id,
    Expression<String>? draftId,
    Expression<String>? variantId,
    Expression<String>? productName,
    Expression<String>? variantName,
    Expression<double>? unitPrice,
    Expression<double>? taxRate,
    Expression<double>? qty,
    Expression<double>? lineTotal,
    Expression<double>? lineTax,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (draftId != null) 'draft_id': draftId,
      if (variantId != null) 'variant_id': variantId,
      if (productName != null) 'product_name': productName,
      if (variantName != null) 'variant_name': variantName,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (taxRate != null) 'tax_rate': taxRate,
      if (qty != null) 'qty': qty,
      if (lineTotal != null) 'line_total': lineTotal,
      if (lineTax != null) 'line_tax': lineTax,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DraftSaleItemsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? draftId,
    Value<String>? variantId,
    Value<String>? productName,
    Value<String>? variantName,
    Value<double>? unitPrice,
    Value<double?>? taxRate,
    Value<double>? qty,
    Value<double>? lineTotal,
    Value<double>? lineTax,
    Value<int>? rowid,
  }) {
    return DraftSaleItemsTableCompanion(
      id: id ?? this.id,
      draftId: draftId ?? this.draftId,
      variantId: variantId ?? this.variantId,
      productName: productName ?? this.productName,
      variantName: variantName ?? this.variantName,
      unitPrice: unitPrice ?? this.unitPrice,
      taxRate: taxRate ?? this.taxRate,
      qty: qty ?? this.qty,
      lineTotal: lineTotal ?? this.lineTotal,
      lineTax: lineTax ?? this.lineTax,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (draftId.present) {
      map['draft_id'] = Variable<String>(draftId.value);
    }
    if (variantId.present) {
      map['variant_id'] = Variable<String>(variantId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (variantName.present) {
      map['variant_name'] = Variable<String>(variantName.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (taxRate.present) {
      map['tax_rate'] = Variable<double>(taxRate.value);
    }
    if (qty.present) {
      map['qty'] = Variable<double>(qty.value);
    }
    if (lineTotal.present) {
      map['line_total'] = Variable<double>(lineTotal.value);
    }
    if (lineTax.present) {
      map['line_tax'] = Variable<double>(lineTax.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DraftSaleItemsTableCompanion(')
          ..write('id: $id, ')
          ..write('draftId: $draftId, ')
          ..write('variantId: $variantId, ')
          ..write('productName: $productName, ')
          ..write('variantName: $variantName, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('taxRate: $taxRate, ')
          ..write('qty: $qty, ')
          ..write('lineTotal: $lineTotal, ')
          ..write('lineTax: $lineTax, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InventoryLevelsTableTable extends InventoryLevelsTable
    with TableInfo<$InventoryLevelsTableTable, InventoryLevelsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryLevelsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variantIdMeta = const VerificationMeta(
    'variantId',
  );
  @override
  late final GeneratedColumn<String> variantId = GeneratedColumn<String>(
    'variant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _quantityDecimalMeta = const VerificationMeta(
    'quantityDecimal',
  );
  @override
  late final GeneratedColumn<double> quantityDecimal = GeneratedColumn<double>(
    'quantity_decimal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lowStockAlertOverrideMeta =
      const VerificationMeta('lowStockAlertOverride');
  @override
  late final GeneratedColumn<int> lowStockAlertOverride = GeneratedColumn<int>(
    'low_stock_alert_override',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    variantId,
    branchId,
    businessId,
    quantity,
    quantityDecimal,
    lowStockAlertOverride,
    syncStatus,
    localUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_levels';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryLevelsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('variant_id')) {
      context.handle(
        _variantIdMeta,
        variantId.isAcceptableOrUnknown(data['variant_id']!, _variantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_variantIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('quantity_decimal')) {
      context.handle(
        _quantityDecimalMeta,
        quantityDecimal.isAcceptableOrUnknown(
          data['quantity_decimal']!,
          _quantityDecimalMeta,
        ),
      );
    }
    if (data.containsKey('low_stock_alert_override')) {
      context.handle(
        _lowStockAlertOverrideMeta,
        lowStockAlertOverride.isAcceptableOrUnknown(
          data['low_stock_alert_override']!,
          _lowStockAlertOverrideMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryLevelsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryLevelsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      variantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      quantityDecimal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity_decimal'],
      ),
      lowStockAlertOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}low_stock_alert_override'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
    );
  }

  @override
  $InventoryLevelsTableTable createAlias(String alias) {
    return $InventoryLevelsTableTable(attachedDatabase, alias);
  }
}

class InventoryLevelsTableData extends DataClass
    implements Insertable<InventoryLevelsTableData> {
  /// Composite key: "$variantId:$branchId"
  final String id;
  final String variantId;

  /// NOT NULL — every stock row must belong to a specific branch.
  final String branchId;
  final String businessId;

  /// Integer quantity for unit products (sellBy='unit').
  final int quantity;

  /// Decimal quantity for fractional products (sellBy='fraction'). Null for unit products.
  final double? quantityDecimal;

  /// Per-branch low stock alert threshold.
  /// NULL means fall back to [product_variants.lowStockAlert] as the global default.
  final int? lowStockAlertOverride;

  /// 0=pendingUpload, 1=pendingUpdate, 3=synced, 4=failed
  final int syncStatus;
  final DateTime localUpdatedAt;
  const InventoryLevelsTableData({
    required this.id,
    required this.variantId,
    required this.branchId,
    required this.businessId,
    required this.quantity,
    this.quantityDecimal,
    this.lowStockAlertOverride,
    required this.syncStatus,
    required this.localUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['variant_id'] = Variable<String>(variantId);
    map['branch_id'] = Variable<String>(branchId);
    map['business_id'] = Variable<String>(businessId);
    map['quantity'] = Variable<int>(quantity);
    if (!nullToAbsent || quantityDecimal != null) {
      map['quantity_decimal'] = Variable<double>(quantityDecimal);
    }
    if (!nullToAbsent || lowStockAlertOverride != null) {
      map['low_stock_alert_override'] = Variable<int>(lowStockAlertOverride);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    return map;
  }

  InventoryLevelsTableCompanion toCompanion(bool nullToAbsent) {
    return InventoryLevelsTableCompanion(
      id: Value(id),
      variantId: Value(variantId),
      branchId: Value(branchId),
      businessId: Value(businessId),
      quantity: Value(quantity),
      quantityDecimal: quantityDecimal == null && nullToAbsent
          ? const Value.absent()
          : Value(quantityDecimal),
      lowStockAlertOverride: lowStockAlertOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(lowStockAlertOverride),
      syncStatus: Value(syncStatus),
      localUpdatedAt: Value(localUpdatedAt),
    );
  }

  factory InventoryLevelsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryLevelsTableData(
      id: serializer.fromJson<String>(json['id']),
      variantId: serializer.fromJson<String>(json['variantId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      businessId: serializer.fromJson<String>(json['businessId']),
      quantity: serializer.fromJson<int>(json['quantity']),
      quantityDecimal: serializer.fromJson<double?>(json['quantityDecimal']),
      lowStockAlertOverride: serializer.fromJson<int?>(
        json['lowStockAlertOverride'],
      ),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'variantId': serializer.toJson<String>(variantId),
      'branchId': serializer.toJson<String>(branchId),
      'businessId': serializer.toJson<String>(businessId),
      'quantity': serializer.toJson<int>(quantity),
      'quantityDecimal': serializer.toJson<double?>(quantityDecimal),
      'lowStockAlertOverride': serializer.toJson<int?>(lowStockAlertOverride),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
    };
  }

  InventoryLevelsTableData copyWith({
    String? id,
    String? variantId,
    String? branchId,
    String? businessId,
    int? quantity,
    Value<double?> quantityDecimal = const Value.absent(),
    Value<int?> lowStockAlertOverride = const Value.absent(),
    int? syncStatus,
    DateTime? localUpdatedAt,
  }) => InventoryLevelsTableData(
    id: id ?? this.id,
    variantId: variantId ?? this.variantId,
    branchId: branchId ?? this.branchId,
    businessId: businessId ?? this.businessId,
    quantity: quantity ?? this.quantity,
    quantityDecimal: quantityDecimal.present
        ? quantityDecimal.value
        : this.quantityDecimal,
    lowStockAlertOverride: lowStockAlertOverride.present
        ? lowStockAlertOverride.value
        : this.lowStockAlertOverride,
    syncStatus: syncStatus ?? this.syncStatus,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
  );
  InventoryLevelsTableData copyWithCompanion(
    InventoryLevelsTableCompanion data,
  ) {
    return InventoryLevelsTableData(
      id: data.id.present ? data.id.value : this.id,
      variantId: data.variantId.present ? data.variantId.value : this.variantId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      quantityDecimal: data.quantityDecimal.present
          ? data.quantityDecimal.value
          : this.quantityDecimal,
      lowStockAlertOverride: data.lowStockAlertOverride.present
          ? data.lowStockAlertOverride.value
          : this.lowStockAlertOverride,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryLevelsTableData(')
          ..write('id: $id, ')
          ..write('variantId: $variantId, ')
          ..write('branchId: $branchId, ')
          ..write('businessId: $businessId, ')
          ..write('quantity: $quantity, ')
          ..write('quantityDecimal: $quantityDecimal, ')
          ..write('lowStockAlertOverride: $lowStockAlertOverride, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localUpdatedAt: $localUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    variantId,
    branchId,
    businessId,
    quantity,
    quantityDecimal,
    lowStockAlertOverride,
    syncStatus,
    localUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryLevelsTableData &&
          other.id == this.id &&
          other.variantId == this.variantId &&
          other.branchId == this.branchId &&
          other.businessId == this.businessId &&
          other.quantity == this.quantity &&
          other.quantityDecimal == this.quantityDecimal &&
          other.lowStockAlertOverride == this.lowStockAlertOverride &&
          other.syncStatus == this.syncStatus &&
          other.localUpdatedAt == this.localUpdatedAt);
}

class InventoryLevelsTableCompanion
    extends UpdateCompanion<InventoryLevelsTableData> {
  final Value<String> id;
  final Value<String> variantId;
  final Value<String> branchId;
  final Value<String> businessId;
  final Value<int> quantity;
  final Value<double?> quantityDecimal;
  final Value<int?> lowStockAlertOverride;
  final Value<int> syncStatus;
  final Value<DateTime> localUpdatedAt;
  final Value<int> rowid;
  const InventoryLevelsTableCompanion({
    this.id = const Value.absent(),
    this.variantId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.businessId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.quantityDecimal = const Value.absent(),
    this.lowStockAlertOverride = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InventoryLevelsTableCompanion.insert({
    required String id,
    required String variantId,
    required String branchId,
    required String businessId,
    this.quantity = const Value.absent(),
    this.quantityDecimal = const Value.absent(),
    this.lowStockAlertOverride = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       variantId = Value(variantId),
       branchId = Value(branchId),
       businessId = Value(businessId);
  static Insertable<InventoryLevelsTableData> custom({
    Expression<String>? id,
    Expression<String>? variantId,
    Expression<String>? branchId,
    Expression<String>? businessId,
    Expression<int>? quantity,
    Expression<double>? quantityDecimal,
    Expression<int>? lowStockAlertOverride,
    Expression<int>? syncStatus,
    Expression<DateTime>? localUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (variantId != null) 'variant_id': variantId,
      if (branchId != null) 'branch_id': branchId,
      if (businessId != null) 'business_id': businessId,
      if (quantity != null) 'quantity': quantity,
      if (quantityDecimal != null) 'quantity_decimal': quantityDecimal,
      if (lowStockAlertOverride != null)
        'low_stock_alert_override': lowStockAlertOverride,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InventoryLevelsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? variantId,
    Value<String>? branchId,
    Value<String>? businessId,
    Value<int>? quantity,
    Value<double?>? quantityDecimal,
    Value<int?>? lowStockAlertOverride,
    Value<int>? syncStatus,
    Value<DateTime>? localUpdatedAt,
    Value<int>? rowid,
  }) {
    return InventoryLevelsTableCompanion(
      id: id ?? this.id,
      variantId: variantId ?? this.variantId,
      branchId: branchId ?? this.branchId,
      businessId: businessId ?? this.businessId,
      quantity: quantity ?? this.quantity,
      quantityDecimal: quantityDecimal ?? this.quantityDecimal,
      lowStockAlertOverride:
          lowStockAlertOverride ?? this.lowStockAlertOverride,
      syncStatus: syncStatus ?? this.syncStatus,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (variantId.present) {
      map['variant_id'] = Variable<String>(variantId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (quantityDecimal.present) {
      map['quantity_decimal'] = Variable<double>(quantityDecimal.value);
    }
    if (lowStockAlertOverride.present) {
      map['low_stock_alert_override'] = Variable<int>(
        lowStockAlertOverride.value,
      );
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryLevelsTableCompanion(')
          ..write('id: $id, ')
          ..write('variantId: $variantId, ')
          ..write('branchId: $branchId, ')
          ..write('businessId: $businessId, ')
          ..write('quantity: $quantity, ')
          ..write('quantityDecimal: $quantityDecimal, ')
          ..write('lowStockAlertOverride: $lowStockAlertOverride, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockLedgerTableTable extends StockLedgerTable
    with TableInfo<$StockLedgerTableTable, StockLedgerTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockLedgerTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variantIdMeta = const VerificationMeta(
    'variantId',
  );
  @override
  late final GeneratedColumn<String> variantId = GeneratedColumn<String>(
    'variant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _changeTypeMeta = const VerificationMeta(
    'changeType',
  );
  @override
  late final GeneratedColumn<String> changeType = GeneratedColumn<String>(
    'change_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityBeforeMeta = const VerificationMeta(
    'quantityBefore',
  );
  @override
  late final GeneratedColumn<double> quantityBefore = GeneratedColumn<double>(
    'quantity_before',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityAfterMeta = const VerificationMeta(
    'quantityAfter',
  );
  @override
  late final GeneratedColumn<double> quantityAfter = GeneratedColumn<double>(
    'quantity_after',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    variantId,
    productId,
    branchId,
    businessId,
    changeType,
    quantity,
    quantityBefore,
    quantityAfter,
    reason,
    note,
    sourceType,
    sourceId,
    createdAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_ledger';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockLedgerTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('variant_id')) {
      context.handle(
        _variantIdMeta,
        variantId.isAcceptableOrUnknown(data['variant_id']!, _variantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_variantIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('change_type')) {
      context.handle(
        _changeTypeMeta,
        changeType.isAcceptableOrUnknown(data['change_type']!, _changeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_changeTypeMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('quantity_before')) {
      context.handle(
        _quantityBeforeMeta,
        quantityBefore.isAcceptableOrUnknown(
          data['quantity_before']!,
          _quantityBeforeMeta,
        ),
      );
    }
    if (data.containsKey('quantity_after')) {
      context.handle(
        _quantityAfterMeta,
        quantityAfter.isAcceptableOrUnknown(
          data['quantity_after']!,
          _quantityAfterMeta,
        ),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockLedgerTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockLedgerTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      variantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      changeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}change_type'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      quantityBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity_before'],
      ),
      quantityAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity_after'],
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      ),
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $StockLedgerTableTable createAlias(String alias) {
    return $StockLedgerTableTable(attachedDatabase, alias);
  }
}

class StockLedgerTableData extends DataClass
    implements Insertable<StockLedgerTableData> {
  final String id;
  final String variantId;
  final String productId;

  /// NOT NULL — every movement must be traced to a specific branch.
  /// Historical rows migrated from v17 carry the sentinel value 'unknown'.
  final String branchId;
  final String businessId;

  /// 'IN' for incoming stock, 'OUT' for outgoing stock.
  final String changeType;

  /// Always a positive value (direction determined by [changeType]).
  /// REAL to support fractional products (sellBy='fraction').
  final double quantity;

  /// Stock level for this variant+branch immediately before this movement.
  /// Null for rows migrated from v17 (pre-snapshot era).
  final double? quantityBefore;

  /// Stock level for this variant+branch immediately after this movement.
  /// Null for rows migrated from v17 (pre-snapshot era).
  final double? quantityAfter;

  /// One of: 'Sale', 'Restock', 'Damage', 'Transfer', 'Adjustment'
  final String reason;
  final String? note;

  /// Traceability of what caused this movement: 'sale', 'purchase_order',
  /// 'recipe_consumption', 'manual', etc. Lets audit/fraud queries tell a sale
  /// apart from a manual adjustment. Local-only for now — not synced until the
  /// Supabase stock_ledger schema is confirmed to have these columns.
  final String? sourceType;

  /// ID of the originating document (transaction id, PO id, …). No foreign key.
  final String? sourceId;
  final DateTime createdAt;

  /// 0=pendingUpload, 3=synced, 4=failed
  final int syncStatus;
  const StockLedgerTableData({
    required this.id,
    required this.variantId,
    required this.productId,
    required this.branchId,
    required this.businessId,
    required this.changeType,
    required this.quantity,
    this.quantityBefore,
    this.quantityAfter,
    required this.reason,
    this.note,
    this.sourceType,
    this.sourceId,
    required this.createdAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['variant_id'] = Variable<String>(variantId);
    map['product_id'] = Variable<String>(productId);
    map['branch_id'] = Variable<String>(branchId);
    map['business_id'] = Variable<String>(businessId);
    map['change_type'] = Variable<String>(changeType);
    map['quantity'] = Variable<double>(quantity);
    if (!nullToAbsent || quantityBefore != null) {
      map['quantity_before'] = Variable<double>(quantityBefore);
    }
    if (!nullToAbsent || quantityAfter != null) {
      map['quantity_after'] = Variable<double>(quantityAfter);
    }
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || sourceType != null) {
      map['source_type'] = Variable<String>(sourceType);
    }
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  StockLedgerTableCompanion toCompanion(bool nullToAbsent) {
    return StockLedgerTableCompanion(
      id: Value(id),
      variantId: Value(variantId),
      productId: Value(productId),
      branchId: Value(branchId),
      businessId: Value(businessId),
      changeType: Value(changeType),
      quantity: Value(quantity),
      quantityBefore: quantityBefore == null && nullToAbsent
          ? const Value.absent()
          : Value(quantityBefore),
      quantityAfter: quantityAfter == null && nullToAbsent
          ? const Value.absent()
          : Value(quantityAfter),
      reason: Value(reason),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      sourceType: sourceType == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceType),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      createdAt: Value(createdAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory StockLedgerTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockLedgerTableData(
      id: serializer.fromJson<String>(json['id']),
      variantId: serializer.fromJson<String>(json['variantId']),
      productId: serializer.fromJson<String>(json['productId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      businessId: serializer.fromJson<String>(json['businessId']),
      changeType: serializer.fromJson<String>(json['changeType']),
      quantity: serializer.fromJson<double>(json['quantity']),
      quantityBefore: serializer.fromJson<double?>(json['quantityBefore']),
      quantityAfter: serializer.fromJson<double?>(json['quantityAfter']),
      reason: serializer.fromJson<String>(json['reason']),
      note: serializer.fromJson<String?>(json['note']),
      sourceType: serializer.fromJson<String?>(json['sourceType']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'variantId': serializer.toJson<String>(variantId),
      'productId': serializer.toJson<String>(productId),
      'branchId': serializer.toJson<String>(branchId),
      'businessId': serializer.toJson<String>(businessId),
      'changeType': serializer.toJson<String>(changeType),
      'quantity': serializer.toJson<double>(quantity),
      'quantityBefore': serializer.toJson<double?>(quantityBefore),
      'quantityAfter': serializer.toJson<double?>(quantityAfter),
      'reason': serializer.toJson<String>(reason),
      'note': serializer.toJson<String?>(note),
      'sourceType': serializer.toJson<String?>(sourceType),
      'sourceId': serializer.toJson<String?>(sourceId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  StockLedgerTableData copyWith({
    String? id,
    String? variantId,
    String? productId,
    String? branchId,
    String? businessId,
    String? changeType,
    double? quantity,
    Value<double?> quantityBefore = const Value.absent(),
    Value<double?> quantityAfter = const Value.absent(),
    String? reason,
    Value<String?> note = const Value.absent(),
    Value<String?> sourceType = const Value.absent(),
    Value<String?> sourceId = const Value.absent(),
    DateTime? createdAt,
    int? syncStatus,
  }) => StockLedgerTableData(
    id: id ?? this.id,
    variantId: variantId ?? this.variantId,
    productId: productId ?? this.productId,
    branchId: branchId ?? this.branchId,
    businessId: businessId ?? this.businessId,
    changeType: changeType ?? this.changeType,
    quantity: quantity ?? this.quantity,
    quantityBefore: quantityBefore.present
        ? quantityBefore.value
        : this.quantityBefore,
    quantityAfter: quantityAfter.present
        ? quantityAfter.value
        : this.quantityAfter,
    reason: reason ?? this.reason,
    note: note.present ? note.value : this.note,
    sourceType: sourceType.present ? sourceType.value : this.sourceType,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    createdAt: createdAt ?? this.createdAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  StockLedgerTableData copyWithCompanion(StockLedgerTableCompanion data) {
    return StockLedgerTableData(
      id: data.id.present ? data.id.value : this.id,
      variantId: data.variantId.present ? data.variantId.value : this.variantId,
      productId: data.productId.present ? data.productId.value : this.productId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      changeType: data.changeType.present
          ? data.changeType.value
          : this.changeType,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      quantityBefore: data.quantityBefore.present
          ? data.quantityBefore.value
          : this.quantityBefore,
      quantityAfter: data.quantityAfter.present
          ? data.quantityAfter.value
          : this.quantityAfter,
      reason: data.reason.present ? data.reason.value : this.reason,
      note: data.note.present ? data.note.value : this.note,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockLedgerTableData(')
          ..write('id: $id, ')
          ..write('variantId: $variantId, ')
          ..write('productId: $productId, ')
          ..write('branchId: $branchId, ')
          ..write('businessId: $businessId, ')
          ..write('changeType: $changeType, ')
          ..write('quantity: $quantity, ')
          ..write('quantityBefore: $quantityBefore, ')
          ..write('quantityAfter: $quantityAfter, ')
          ..write('reason: $reason, ')
          ..write('note: $note, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    variantId,
    productId,
    branchId,
    businessId,
    changeType,
    quantity,
    quantityBefore,
    quantityAfter,
    reason,
    note,
    sourceType,
    sourceId,
    createdAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockLedgerTableData &&
          other.id == this.id &&
          other.variantId == this.variantId &&
          other.productId == this.productId &&
          other.branchId == this.branchId &&
          other.businessId == this.businessId &&
          other.changeType == this.changeType &&
          other.quantity == this.quantity &&
          other.quantityBefore == this.quantityBefore &&
          other.quantityAfter == this.quantityAfter &&
          other.reason == this.reason &&
          other.note == this.note &&
          other.sourceType == this.sourceType &&
          other.sourceId == this.sourceId &&
          other.createdAt == this.createdAt &&
          other.syncStatus == this.syncStatus);
}

class StockLedgerTableCompanion extends UpdateCompanion<StockLedgerTableData> {
  final Value<String> id;
  final Value<String> variantId;
  final Value<String> productId;
  final Value<String> branchId;
  final Value<String> businessId;
  final Value<String> changeType;
  final Value<double> quantity;
  final Value<double?> quantityBefore;
  final Value<double?> quantityAfter;
  final Value<String> reason;
  final Value<String?> note;
  final Value<String?> sourceType;
  final Value<String?> sourceId;
  final Value<DateTime> createdAt;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const StockLedgerTableCompanion({
    this.id = const Value.absent(),
    this.variantId = const Value.absent(),
    this.productId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.businessId = const Value.absent(),
    this.changeType = const Value.absent(),
    this.quantity = const Value.absent(),
    this.quantityBefore = const Value.absent(),
    this.quantityAfter = const Value.absent(),
    this.reason = const Value.absent(),
    this.note = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StockLedgerTableCompanion.insert({
    required String id,
    required String variantId,
    required String productId,
    required String branchId,
    required String businessId,
    required String changeType,
    required double quantity,
    this.quantityBefore = const Value.absent(),
    this.quantityAfter = const Value.absent(),
    required String reason,
    this.note = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       variantId = Value(variantId),
       productId = Value(productId),
       branchId = Value(branchId),
       businessId = Value(businessId),
       changeType = Value(changeType),
       quantity = Value(quantity),
       reason = Value(reason);
  static Insertable<StockLedgerTableData> custom({
    Expression<String>? id,
    Expression<String>? variantId,
    Expression<String>? productId,
    Expression<String>? branchId,
    Expression<String>? businessId,
    Expression<String>? changeType,
    Expression<double>? quantity,
    Expression<double>? quantityBefore,
    Expression<double>? quantityAfter,
    Expression<String>? reason,
    Expression<String>? note,
    Expression<String>? sourceType,
    Expression<String>? sourceId,
    Expression<DateTime>? createdAt,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (variantId != null) 'variant_id': variantId,
      if (productId != null) 'product_id': productId,
      if (branchId != null) 'branch_id': branchId,
      if (businessId != null) 'business_id': businessId,
      if (changeType != null) 'change_type': changeType,
      if (quantity != null) 'quantity': quantity,
      if (quantityBefore != null) 'quantity_before': quantityBefore,
      if (quantityAfter != null) 'quantity_after': quantityAfter,
      if (reason != null) 'reason': reason,
      if (note != null) 'note': note,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceId != null) 'source_id': sourceId,
      if (createdAt != null) 'created_at': createdAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StockLedgerTableCompanion copyWith({
    Value<String>? id,
    Value<String>? variantId,
    Value<String>? productId,
    Value<String>? branchId,
    Value<String>? businessId,
    Value<String>? changeType,
    Value<double>? quantity,
    Value<double?>? quantityBefore,
    Value<double?>? quantityAfter,
    Value<String>? reason,
    Value<String?>? note,
    Value<String?>? sourceType,
    Value<String?>? sourceId,
    Value<DateTime>? createdAt,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return StockLedgerTableCompanion(
      id: id ?? this.id,
      variantId: variantId ?? this.variantId,
      productId: productId ?? this.productId,
      branchId: branchId ?? this.branchId,
      businessId: businessId ?? this.businessId,
      changeType: changeType ?? this.changeType,
      quantity: quantity ?? this.quantity,
      quantityBefore: quantityBefore ?? this.quantityBefore,
      quantityAfter: quantityAfter ?? this.quantityAfter,
      reason: reason ?? this.reason,
      note: note ?? this.note,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (variantId.present) {
      map['variant_id'] = Variable<String>(variantId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (changeType.present) {
      map['change_type'] = Variable<String>(changeType.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (quantityBefore.present) {
      map['quantity_before'] = Variable<double>(quantityBefore.value);
    }
    if (quantityAfter.present) {
      map['quantity_after'] = Variable<double>(quantityAfter.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockLedgerTableCompanion(')
          ..write('id: $id, ')
          ..write('variantId: $variantId, ')
          ..write('productId: $productId, ')
          ..write('branchId: $branchId, ')
          ..write('businessId: $businessId, ')
          ..write('changeType: $changeType, ')
          ..write('quantity: $quantity, ')
          ..write('quantityBefore: $quantityBefore, ')
          ..write('quantityAfter: $quantityAfter, ')
          ..write('reason: $reason, ')
          ..write('note: $note, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReceiptSettingsTableTable extends ReceiptSettingsTable
    with TableInfo<$ReceiptSettingsTableTable, ReceiptSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessNameMeta = const VerificationMeta(
    'businessName',
  );
  @override
  late final GeneratedColumn<String> businessName = GeneratedColumn<String>(
    'business_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _storeNameMeta = const VerificationMeta(
    'storeName',
  );
  @override
  late final GeneratedColumn<String> storeName = GeneratedColumn<String>(
    'store_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _ownerNameMeta = const VerificationMeta(
    'ownerName',
  );
  @override
  late final GeneratedColumn<String> ownerName = GeneratedColumn<String>(
    'owner_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contactNumberMeta = const VerificationMeta(
    'contactNumber',
  );
  @override
  late final GeneratedColumn<String> contactNumber = GeneratedColumn<String>(
    'contact_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _websiteMeta = const VerificationMeta(
    'website',
  );
  @override
  late final GeneratedColumn<String> website = GeneratedColumn<String>(
    'website',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _tinNumberMeta = const VerificationMeta(
    'tinNumber',
  );
  @override
  late final GeneratedColumn<String> tinNumber = GeneratedColumn<String>(
    'tin_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _permitNumberMeta = const VerificationMeta(
    'permitNumber',
  );
  @override
  late final GeneratedColumn<String> permitNumber = GeneratedColumn<String>(
    'permit_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _headerTextMeta = const VerificationMeta(
    'headerText',
  );
  @override
  late final GeneratedColumn<String> headerText = GeneratedColumn<String>(
    'header_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _footerTextMeta = const VerificationMeta(
    'footerText',
  );
  @override
  late final GeneratedColumn<String> footerText = GeneratedColumn<String>(
    'footer_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Thank you for your purchase!'),
  );
  static const VerificationMeta _returnPolicyMeta = const VerificationMeta(
    'returnPolicy',
  );
  @override
  late final GeneratedColumn<String> returnPolicy = GeneratedColumn<String>(
    'return_policy',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _customNotesMeta = const VerificationMeta(
    'customNotes',
  );
  @override
  late final GeneratedColumn<String> customNotes = GeneratedColumn<String>(
    'custom_notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _showLogoMeta = const VerificationMeta(
    'showLogo',
  );
  @override
  late final GeneratedColumn<bool> showLogo = GeneratedColumn<bool>(
    'show_logo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_logo" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _logoLocalPathMeta = const VerificationMeta(
    'logoLocalPath',
  );
  @override
  late final GeneratedColumn<String> logoLocalPath = GeneratedColumn<String>(
    'logo_local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _logoUrlMeta = const VerificationMeta(
    'logoUrl',
  );
  @override
  late final GeneratedColumn<String> logoUrl = GeneratedColumn<String>(
    'logo_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _showQrCodeMeta = const VerificationMeta(
    'showQrCode',
  );
  @override
  late final GeneratedColumn<bool> showQrCode = GeneratedColumn<bool>(
    'show_qr_code',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_qr_code" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _showTaxBreakdownMeta = const VerificationMeta(
    'showTaxBreakdown',
  );
  @override
  late final GeneratedColumn<bool> showTaxBreakdown = GeneratedColumn<bool>(
    'show_tax_breakdown',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_tax_breakdown" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _showCashierNameMeta = const VerificationMeta(
    'showCashierName',
  );
  @override
  late final GeneratedColumn<bool> showCashierName = GeneratedColumn<bool>(
    'show_cashier_name',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_cashier_name" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _showCustomerNameMeta = const VerificationMeta(
    'showCustomerName',
  );
  @override
  late final GeneratedColumn<bool> showCustomerName = GeneratedColumn<bool>(
    'show_customer_name',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_customer_name" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _showDateTimeMeta = const VerificationMeta(
    'showDateTime',
  );
  @override
  late final GeneratedColumn<bool> showDateTime = GeneratedColumn<bool>(
    'show_date_time',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_date_time" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _showOrderIdMeta = const VerificationMeta(
    'showOrderId',
  );
  @override
  late final GeneratedColumn<bool> showOrderId = GeneratedColumn<bool>(
    'show_order_id',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_order_id" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _paperSizeMeta = const VerificationMeta(
    'paperSize',
  );
  @override
  late final GeneratedColumn<String> paperSize = GeneratedColumn<String>(
    'paper_size',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('80mm'),
  );
  static const VerificationMeta _fontSizeMeta = const VerificationMeta(
    'fontSize',
  );
  @override
  late final GeneratedColumn<String> fontSize = GeneratedColumn<String>(
    'font_size',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('medium'),
  );
  static const VerificationMeta _textAlignmentMeta = const VerificationMeta(
    'textAlignment',
  );
  @override
  late final GeneratedColumn<String> textAlignment = GeneratedColumn<String>(
    'text_alignment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('center'),
  );
  static const VerificationMeta _autoPrintAfterCheckoutMeta =
      const VerificationMeta('autoPrintAfterCheckout');
  @override
  late final GeneratedColumn<bool> autoPrintAfterCheckout =
      GeneratedColumn<bool>(
        'auto_print_after_checkout',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("auto_print_after_checkout" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _printDuplicateCopyMeta =
      const VerificationMeta('printDuplicateCopy');
  @override
  late final GeneratedColumn<bool> printDuplicateCopy = GeneratedColumn<bool>(
    'print_duplicate_copy',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("print_duplicate_copy" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _thermalPrinterEnabledMeta =
      const VerificationMeta('thermalPrinterEnabled');
  @override
  late final GeneratedColumn<bool> thermalPrinterEnabled =
      GeneratedColumn<bool>(
        'thermal_printer_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("thermal_printer_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _currencySymbolMeta = const VerificationMeta(
    'currencySymbol',
  );
  @override
  late final GeneratedColumn<String> currencySymbol = GeneratedColumn<String>(
    'currency_symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('₱'),
  );
  static const VerificationMeta _taxPercentageMeta = const VerificationMeta(
    'taxPercentage',
  );
  @override
  late final GeneratedColumn<double> taxPercentage = GeneratedColumn<double>(
    'tax_percentage',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _serviceChargePercentageMeta =
      const VerificationMeta('serviceChargePercentage');
  @override
  late final GeneratedColumn<double> serviceChargePercentage =
      GeneratedColumn<double>(
        'service_charge_percentage',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0.0),
      );
  static const VerificationMeta _vatInclusiveMeta = const VerificationMeta(
    'vatInclusive',
  );
  @override
  late final GeneratedColumn<bool> vatInclusive = GeneratedColumn<bool>(
    'vat_inclusive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("vat_inclusive" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncAttemptMeta = const VerificationMeta(
    'lastSyncAttempt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAttempt =
      GeneratedColumn<DateTime>(
        'last_sync_attempt',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    businessName,
    storeName,
    ownerName,
    address,
    contactNumber,
    email,
    website,
    tinNumber,
    permitNumber,
    headerText,
    footerText,
    returnPolicy,
    customNotes,
    showLogo,
    logoLocalPath,
    logoUrl,
    showQrCode,
    showTaxBreakdown,
    showCashierName,
    showCustomerName,
    showDateTime,
    showOrderId,
    paperSize,
    fontSize,
    textAlignment,
    autoPrintAfterCheckout,
    printDuplicateCopy,
    thermalPrinterEnabled,
    currencySymbol,
    taxPercentage,
    serviceChargePercentage,
    vatInclusive,
    createdAt,
    updatedAt,
    syncStatus,
    lastSyncAttempt,
    syncError,
    localUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipt_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReceiptSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('business_name')) {
      context.handle(
        _businessNameMeta,
        businessName.isAcceptableOrUnknown(
          data['business_name']!,
          _businessNameMeta,
        ),
      );
    }
    if (data.containsKey('store_name')) {
      context.handle(
        _storeNameMeta,
        storeName.isAcceptableOrUnknown(data['store_name']!, _storeNameMeta),
      );
    }
    if (data.containsKey('owner_name')) {
      context.handle(
        _ownerNameMeta,
        ownerName.isAcceptableOrUnknown(data['owner_name']!, _ownerNameMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('contact_number')) {
      context.handle(
        _contactNumberMeta,
        contactNumber.isAcceptableOrUnknown(
          data['contact_number']!,
          _contactNumberMeta,
        ),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('website')) {
      context.handle(
        _websiteMeta,
        website.isAcceptableOrUnknown(data['website']!, _websiteMeta),
      );
    }
    if (data.containsKey('tin_number')) {
      context.handle(
        _tinNumberMeta,
        tinNumber.isAcceptableOrUnknown(data['tin_number']!, _tinNumberMeta),
      );
    }
    if (data.containsKey('permit_number')) {
      context.handle(
        _permitNumberMeta,
        permitNumber.isAcceptableOrUnknown(
          data['permit_number']!,
          _permitNumberMeta,
        ),
      );
    }
    if (data.containsKey('header_text')) {
      context.handle(
        _headerTextMeta,
        headerText.isAcceptableOrUnknown(data['header_text']!, _headerTextMeta),
      );
    }
    if (data.containsKey('footer_text')) {
      context.handle(
        _footerTextMeta,
        footerText.isAcceptableOrUnknown(data['footer_text']!, _footerTextMeta),
      );
    }
    if (data.containsKey('return_policy')) {
      context.handle(
        _returnPolicyMeta,
        returnPolicy.isAcceptableOrUnknown(
          data['return_policy']!,
          _returnPolicyMeta,
        ),
      );
    }
    if (data.containsKey('custom_notes')) {
      context.handle(
        _customNotesMeta,
        customNotes.isAcceptableOrUnknown(
          data['custom_notes']!,
          _customNotesMeta,
        ),
      );
    }
    if (data.containsKey('show_logo')) {
      context.handle(
        _showLogoMeta,
        showLogo.isAcceptableOrUnknown(data['show_logo']!, _showLogoMeta),
      );
    }
    if (data.containsKey('logo_local_path')) {
      context.handle(
        _logoLocalPathMeta,
        logoLocalPath.isAcceptableOrUnknown(
          data['logo_local_path']!,
          _logoLocalPathMeta,
        ),
      );
    }
    if (data.containsKey('logo_url')) {
      context.handle(
        _logoUrlMeta,
        logoUrl.isAcceptableOrUnknown(data['logo_url']!, _logoUrlMeta),
      );
    }
    if (data.containsKey('show_qr_code')) {
      context.handle(
        _showQrCodeMeta,
        showQrCode.isAcceptableOrUnknown(
          data['show_qr_code']!,
          _showQrCodeMeta,
        ),
      );
    }
    if (data.containsKey('show_tax_breakdown')) {
      context.handle(
        _showTaxBreakdownMeta,
        showTaxBreakdown.isAcceptableOrUnknown(
          data['show_tax_breakdown']!,
          _showTaxBreakdownMeta,
        ),
      );
    }
    if (data.containsKey('show_cashier_name')) {
      context.handle(
        _showCashierNameMeta,
        showCashierName.isAcceptableOrUnknown(
          data['show_cashier_name']!,
          _showCashierNameMeta,
        ),
      );
    }
    if (data.containsKey('show_customer_name')) {
      context.handle(
        _showCustomerNameMeta,
        showCustomerName.isAcceptableOrUnknown(
          data['show_customer_name']!,
          _showCustomerNameMeta,
        ),
      );
    }
    if (data.containsKey('show_date_time')) {
      context.handle(
        _showDateTimeMeta,
        showDateTime.isAcceptableOrUnknown(
          data['show_date_time']!,
          _showDateTimeMeta,
        ),
      );
    }
    if (data.containsKey('show_order_id')) {
      context.handle(
        _showOrderIdMeta,
        showOrderId.isAcceptableOrUnknown(
          data['show_order_id']!,
          _showOrderIdMeta,
        ),
      );
    }
    if (data.containsKey('paper_size')) {
      context.handle(
        _paperSizeMeta,
        paperSize.isAcceptableOrUnknown(data['paper_size']!, _paperSizeMeta),
      );
    }
    if (data.containsKey('font_size')) {
      context.handle(
        _fontSizeMeta,
        fontSize.isAcceptableOrUnknown(data['font_size']!, _fontSizeMeta),
      );
    }
    if (data.containsKey('text_alignment')) {
      context.handle(
        _textAlignmentMeta,
        textAlignment.isAcceptableOrUnknown(
          data['text_alignment']!,
          _textAlignmentMeta,
        ),
      );
    }
    if (data.containsKey('auto_print_after_checkout')) {
      context.handle(
        _autoPrintAfterCheckoutMeta,
        autoPrintAfterCheckout.isAcceptableOrUnknown(
          data['auto_print_after_checkout']!,
          _autoPrintAfterCheckoutMeta,
        ),
      );
    }
    if (data.containsKey('print_duplicate_copy')) {
      context.handle(
        _printDuplicateCopyMeta,
        printDuplicateCopy.isAcceptableOrUnknown(
          data['print_duplicate_copy']!,
          _printDuplicateCopyMeta,
        ),
      );
    }
    if (data.containsKey('thermal_printer_enabled')) {
      context.handle(
        _thermalPrinterEnabledMeta,
        thermalPrinterEnabled.isAcceptableOrUnknown(
          data['thermal_printer_enabled']!,
          _thermalPrinterEnabledMeta,
        ),
      );
    }
    if (data.containsKey('currency_symbol')) {
      context.handle(
        _currencySymbolMeta,
        currencySymbol.isAcceptableOrUnknown(
          data['currency_symbol']!,
          _currencySymbolMeta,
        ),
      );
    }
    if (data.containsKey('tax_percentage')) {
      context.handle(
        _taxPercentageMeta,
        taxPercentage.isAcceptableOrUnknown(
          data['tax_percentage']!,
          _taxPercentageMeta,
        ),
      );
    }
    if (data.containsKey('service_charge_percentage')) {
      context.handle(
        _serviceChargePercentageMeta,
        serviceChargePercentage.isAcceptableOrUnknown(
          data['service_charge_percentage']!,
          _serviceChargePercentageMeta,
        ),
      );
    }
    if (data.containsKey('vat_inclusive')) {
      context.handle(
        _vatInclusiveMeta,
        vatInclusive.isAcceptableOrUnknown(
          data['vat_inclusive']!,
          _vatInclusiveMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('last_sync_attempt')) {
      context.handle(
        _lastSyncAttemptMeta,
        lastSyncAttempt.isAcceptableOrUnknown(
          data['last_sync_attempt']!,
          _lastSyncAttemptMeta,
        ),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReceiptSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReceiptSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      businessName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_name'],
      )!,
      storeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_name'],
      )!,
      ownerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_name'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      contactNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_number'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      website: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}website'],
      )!,
      tinNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tin_number'],
      )!,
      permitNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}permit_number'],
      )!,
      headerText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}header_text'],
      )!,
      footerText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}footer_text'],
      )!,
      returnPolicy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}return_policy'],
      )!,
      customNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_notes'],
      )!,
      showLogo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_logo'],
      )!,
      logoLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo_local_path'],
      )!,
      logoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo_url'],
      )!,
      showQrCode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_qr_code'],
      )!,
      showTaxBreakdown: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_tax_breakdown'],
      )!,
      showCashierName: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_cashier_name'],
      )!,
      showCustomerName: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_customer_name'],
      )!,
      showDateTime: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_date_time'],
      )!,
      showOrderId: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_order_id'],
      )!,
      paperSize: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paper_size'],
      )!,
      fontSize: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}font_size'],
      )!,
      textAlignment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_alignment'],
      )!,
      autoPrintAfterCheckout: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_print_after_checkout'],
      )!,
      printDuplicateCopy: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}print_duplicate_copy'],
      )!,
      thermalPrinterEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}thermal_printer_enabled'],
      )!,
      currencySymbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_symbol'],
      )!,
      taxPercentage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tax_percentage'],
      )!,
      serviceChargePercentage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}service_charge_percentage'],
      )!,
      vatInclusive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}vat_inclusive'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      lastSyncAttempt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_attempt'],
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
    );
  }

  @override
  $ReceiptSettingsTableTable createAlias(String alias) {
    return $ReceiptSettingsTableTable(attachedDatabase, alias);
  }
}

class ReceiptSettingsRow extends DataClass
    implements Insertable<ReceiptSettingsRow> {
  final String id;
  final String businessId;
  final String businessName;
  final String storeName;
  final String ownerName;
  final String address;
  final String contactNumber;
  final String email;
  final String website;
  final String tinNumber;
  final String permitNumber;
  final String headerText;
  final String footerText;
  final String returnPolicy;
  final String customNotes;
  final bool showLogo;

  /// Local file path (may be empty). Supabase public URL stored in logoUrl.
  final String logoLocalPath;
  final String logoUrl;
  final bool showQrCode;
  final bool showTaxBreakdown;
  final bool showCashierName;
  final bool showCustomerName;
  final bool showDateTime;
  final bool showOrderId;

  /// '58mm' | '80mm'
  final String paperSize;

  /// 'small' | 'medium' | 'large'
  final String fontSize;

  /// 'left' | 'center' | 'right'
  final String textAlignment;
  final bool autoPrintAfterCheckout;
  final bool printDuplicateCopy;
  final bool thermalPrinterEnabled;
  final String currencySymbol;
  final double taxPercentage;
  final double serviceChargePercentage;
  final bool vatInclusive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 0=pendingUpload 1=pendingUpdate 2=pendingDelete 3=synced 4=failed
  final int syncStatus;
  final DateTime? lastSyncAttempt;
  final String? syncError;
  final DateTime localUpdatedAt;
  const ReceiptSettingsRow({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.storeName,
    required this.ownerName,
    required this.address,
    required this.contactNumber,
    required this.email,
    required this.website,
    required this.tinNumber,
    required this.permitNumber,
    required this.headerText,
    required this.footerText,
    required this.returnPolicy,
    required this.customNotes,
    required this.showLogo,
    required this.logoLocalPath,
    required this.logoUrl,
    required this.showQrCode,
    required this.showTaxBreakdown,
    required this.showCashierName,
    required this.showCustomerName,
    required this.showDateTime,
    required this.showOrderId,
    required this.paperSize,
    required this.fontSize,
    required this.textAlignment,
    required this.autoPrintAfterCheckout,
    required this.printDuplicateCopy,
    required this.thermalPrinterEnabled,
    required this.currencySymbol,
    required this.taxPercentage,
    required this.serviceChargePercentage,
    required this.vatInclusive,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.lastSyncAttempt,
    this.syncError,
    required this.localUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['business_name'] = Variable<String>(businessName);
    map['store_name'] = Variable<String>(storeName);
    map['owner_name'] = Variable<String>(ownerName);
    map['address'] = Variable<String>(address);
    map['contact_number'] = Variable<String>(contactNumber);
    map['email'] = Variable<String>(email);
    map['website'] = Variable<String>(website);
    map['tin_number'] = Variable<String>(tinNumber);
    map['permit_number'] = Variable<String>(permitNumber);
    map['header_text'] = Variable<String>(headerText);
    map['footer_text'] = Variable<String>(footerText);
    map['return_policy'] = Variable<String>(returnPolicy);
    map['custom_notes'] = Variable<String>(customNotes);
    map['show_logo'] = Variable<bool>(showLogo);
    map['logo_local_path'] = Variable<String>(logoLocalPath);
    map['logo_url'] = Variable<String>(logoUrl);
    map['show_qr_code'] = Variable<bool>(showQrCode);
    map['show_tax_breakdown'] = Variable<bool>(showTaxBreakdown);
    map['show_cashier_name'] = Variable<bool>(showCashierName);
    map['show_customer_name'] = Variable<bool>(showCustomerName);
    map['show_date_time'] = Variable<bool>(showDateTime);
    map['show_order_id'] = Variable<bool>(showOrderId);
    map['paper_size'] = Variable<String>(paperSize);
    map['font_size'] = Variable<String>(fontSize);
    map['text_alignment'] = Variable<String>(textAlignment);
    map['auto_print_after_checkout'] = Variable<bool>(autoPrintAfterCheckout);
    map['print_duplicate_copy'] = Variable<bool>(printDuplicateCopy);
    map['thermal_printer_enabled'] = Variable<bool>(thermalPrinterEnabled);
    map['currency_symbol'] = Variable<String>(currencySymbol);
    map['tax_percentage'] = Variable<double>(taxPercentage);
    map['service_charge_percentage'] = Variable<double>(
      serviceChargePercentage,
    );
    map['vat_inclusive'] = Variable<bool>(vatInclusive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || lastSyncAttempt != null) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt);
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    return map;
  }

  ReceiptSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return ReceiptSettingsTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      businessName: Value(businessName),
      storeName: Value(storeName),
      ownerName: Value(ownerName),
      address: Value(address),
      contactNumber: Value(contactNumber),
      email: Value(email),
      website: Value(website),
      tinNumber: Value(tinNumber),
      permitNumber: Value(permitNumber),
      headerText: Value(headerText),
      footerText: Value(footerText),
      returnPolicy: Value(returnPolicy),
      customNotes: Value(customNotes),
      showLogo: Value(showLogo),
      logoLocalPath: Value(logoLocalPath),
      logoUrl: Value(logoUrl),
      showQrCode: Value(showQrCode),
      showTaxBreakdown: Value(showTaxBreakdown),
      showCashierName: Value(showCashierName),
      showCustomerName: Value(showCustomerName),
      showDateTime: Value(showDateTime),
      showOrderId: Value(showOrderId),
      paperSize: Value(paperSize),
      fontSize: Value(fontSize),
      textAlignment: Value(textAlignment),
      autoPrintAfterCheckout: Value(autoPrintAfterCheckout),
      printDuplicateCopy: Value(printDuplicateCopy),
      thermalPrinterEnabled: Value(thermalPrinterEnabled),
      currencySymbol: Value(currencySymbol),
      taxPercentage: Value(taxPercentage),
      serviceChargePercentage: Value(serviceChargePercentage),
      vatInclusive: Value(vatInclusive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      lastSyncAttempt: lastSyncAttempt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAttempt),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      localUpdatedAt: Value(localUpdatedAt),
    );
  }

  factory ReceiptSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReceiptSettingsRow(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      businessName: serializer.fromJson<String>(json['businessName']),
      storeName: serializer.fromJson<String>(json['storeName']),
      ownerName: serializer.fromJson<String>(json['ownerName']),
      address: serializer.fromJson<String>(json['address']),
      contactNumber: serializer.fromJson<String>(json['contactNumber']),
      email: serializer.fromJson<String>(json['email']),
      website: serializer.fromJson<String>(json['website']),
      tinNumber: serializer.fromJson<String>(json['tinNumber']),
      permitNumber: serializer.fromJson<String>(json['permitNumber']),
      headerText: serializer.fromJson<String>(json['headerText']),
      footerText: serializer.fromJson<String>(json['footerText']),
      returnPolicy: serializer.fromJson<String>(json['returnPolicy']),
      customNotes: serializer.fromJson<String>(json['customNotes']),
      showLogo: serializer.fromJson<bool>(json['showLogo']),
      logoLocalPath: serializer.fromJson<String>(json['logoLocalPath']),
      logoUrl: serializer.fromJson<String>(json['logoUrl']),
      showQrCode: serializer.fromJson<bool>(json['showQrCode']),
      showTaxBreakdown: serializer.fromJson<bool>(json['showTaxBreakdown']),
      showCashierName: serializer.fromJson<bool>(json['showCashierName']),
      showCustomerName: serializer.fromJson<bool>(json['showCustomerName']),
      showDateTime: serializer.fromJson<bool>(json['showDateTime']),
      showOrderId: serializer.fromJson<bool>(json['showOrderId']),
      paperSize: serializer.fromJson<String>(json['paperSize']),
      fontSize: serializer.fromJson<String>(json['fontSize']),
      textAlignment: serializer.fromJson<String>(json['textAlignment']),
      autoPrintAfterCheckout: serializer.fromJson<bool>(
        json['autoPrintAfterCheckout'],
      ),
      printDuplicateCopy: serializer.fromJson<bool>(json['printDuplicateCopy']),
      thermalPrinterEnabled: serializer.fromJson<bool>(
        json['thermalPrinterEnabled'],
      ),
      currencySymbol: serializer.fromJson<String>(json['currencySymbol']),
      taxPercentage: serializer.fromJson<double>(json['taxPercentage']),
      serviceChargePercentage: serializer.fromJson<double>(
        json['serviceChargePercentage'],
      ),
      vatInclusive: serializer.fromJson<bool>(json['vatInclusive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      lastSyncAttempt: serializer.fromJson<DateTime?>(json['lastSyncAttempt']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'businessName': serializer.toJson<String>(businessName),
      'storeName': serializer.toJson<String>(storeName),
      'ownerName': serializer.toJson<String>(ownerName),
      'address': serializer.toJson<String>(address),
      'contactNumber': serializer.toJson<String>(contactNumber),
      'email': serializer.toJson<String>(email),
      'website': serializer.toJson<String>(website),
      'tinNumber': serializer.toJson<String>(tinNumber),
      'permitNumber': serializer.toJson<String>(permitNumber),
      'headerText': serializer.toJson<String>(headerText),
      'footerText': serializer.toJson<String>(footerText),
      'returnPolicy': serializer.toJson<String>(returnPolicy),
      'customNotes': serializer.toJson<String>(customNotes),
      'showLogo': serializer.toJson<bool>(showLogo),
      'logoLocalPath': serializer.toJson<String>(logoLocalPath),
      'logoUrl': serializer.toJson<String>(logoUrl),
      'showQrCode': serializer.toJson<bool>(showQrCode),
      'showTaxBreakdown': serializer.toJson<bool>(showTaxBreakdown),
      'showCashierName': serializer.toJson<bool>(showCashierName),
      'showCustomerName': serializer.toJson<bool>(showCustomerName),
      'showDateTime': serializer.toJson<bool>(showDateTime),
      'showOrderId': serializer.toJson<bool>(showOrderId),
      'paperSize': serializer.toJson<String>(paperSize),
      'fontSize': serializer.toJson<String>(fontSize),
      'textAlignment': serializer.toJson<String>(textAlignment),
      'autoPrintAfterCheckout': serializer.toJson<bool>(autoPrintAfterCheckout),
      'printDuplicateCopy': serializer.toJson<bool>(printDuplicateCopy),
      'thermalPrinterEnabled': serializer.toJson<bool>(thermalPrinterEnabled),
      'currencySymbol': serializer.toJson<String>(currencySymbol),
      'taxPercentage': serializer.toJson<double>(taxPercentage),
      'serviceChargePercentage': serializer.toJson<double>(
        serviceChargePercentage,
      ),
      'vatInclusive': serializer.toJson<bool>(vatInclusive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'lastSyncAttempt': serializer.toJson<DateTime?>(lastSyncAttempt),
      'syncError': serializer.toJson<String?>(syncError),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
    };
  }

  ReceiptSettingsRow copyWith({
    String? id,
    String? businessId,
    String? businessName,
    String? storeName,
    String? ownerName,
    String? address,
    String? contactNumber,
    String? email,
    String? website,
    String? tinNumber,
    String? permitNumber,
    String? headerText,
    String? footerText,
    String? returnPolicy,
    String? customNotes,
    bool? showLogo,
    String? logoLocalPath,
    String? logoUrl,
    bool? showQrCode,
    bool? showTaxBreakdown,
    bool? showCashierName,
    bool? showCustomerName,
    bool? showDateTime,
    bool? showOrderId,
    String? paperSize,
    String? fontSize,
    String? textAlignment,
    bool? autoPrintAfterCheckout,
    bool? printDuplicateCopy,
    bool? thermalPrinterEnabled,
    String? currencySymbol,
    double? taxPercentage,
    double? serviceChargePercentage,
    bool? vatInclusive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? syncStatus,
    Value<DateTime?> lastSyncAttempt = const Value.absent(),
    Value<String?> syncError = const Value.absent(),
    DateTime? localUpdatedAt,
  }) => ReceiptSettingsRow(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    businessName: businessName ?? this.businessName,
    storeName: storeName ?? this.storeName,
    ownerName: ownerName ?? this.ownerName,
    address: address ?? this.address,
    contactNumber: contactNumber ?? this.contactNumber,
    email: email ?? this.email,
    website: website ?? this.website,
    tinNumber: tinNumber ?? this.tinNumber,
    permitNumber: permitNumber ?? this.permitNumber,
    headerText: headerText ?? this.headerText,
    footerText: footerText ?? this.footerText,
    returnPolicy: returnPolicy ?? this.returnPolicy,
    customNotes: customNotes ?? this.customNotes,
    showLogo: showLogo ?? this.showLogo,
    logoLocalPath: logoLocalPath ?? this.logoLocalPath,
    logoUrl: logoUrl ?? this.logoUrl,
    showQrCode: showQrCode ?? this.showQrCode,
    showTaxBreakdown: showTaxBreakdown ?? this.showTaxBreakdown,
    showCashierName: showCashierName ?? this.showCashierName,
    showCustomerName: showCustomerName ?? this.showCustomerName,
    showDateTime: showDateTime ?? this.showDateTime,
    showOrderId: showOrderId ?? this.showOrderId,
    paperSize: paperSize ?? this.paperSize,
    fontSize: fontSize ?? this.fontSize,
    textAlignment: textAlignment ?? this.textAlignment,
    autoPrintAfterCheckout:
        autoPrintAfterCheckout ?? this.autoPrintAfterCheckout,
    printDuplicateCopy: printDuplicateCopy ?? this.printDuplicateCopy,
    thermalPrinterEnabled: thermalPrinterEnabled ?? this.thermalPrinterEnabled,
    currencySymbol: currencySymbol ?? this.currencySymbol,
    taxPercentage: taxPercentage ?? this.taxPercentage,
    serviceChargePercentage:
        serviceChargePercentage ?? this.serviceChargePercentage,
    vatInclusive: vatInclusive ?? this.vatInclusive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncAttempt: lastSyncAttempt.present
        ? lastSyncAttempt.value
        : this.lastSyncAttempt,
    syncError: syncError.present ? syncError.value : this.syncError,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
  );
  ReceiptSettingsRow copyWithCompanion(ReceiptSettingsTableCompanion data) {
    return ReceiptSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      businessName: data.businessName.present
          ? data.businessName.value
          : this.businessName,
      storeName: data.storeName.present ? data.storeName.value : this.storeName,
      ownerName: data.ownerName.present ? data.ownerName.value : this.ownerName,
      address: data.address.present ? data.address.value : this.address,
      contactNumber: data.contactNumber.present
          ? data.contactNumber.value
          : this.contactNumber,
      email: data.email.present ? data.email.value : this.email,
      website: data.website.present ? data.website.value : this.website,
      tinNumber: data.tinNumber.present ? data.tinNumber.value : this.tinNumber,
      permitNumber: data.permitNumber.present
          ? data.permitNumber.value
          : this.permitNumber,
      headerText: data.headerText.present
          ? data.headerText.value
          : this.headerText,
      footerText: data.footerText.present
          ? data.footerText.value
          : this.footerText,
      returnPolicy: data.returnPolicy.present
          ? data.returnPolicy.value
          : this.returnPolicy,
      customNotes: data.customNotes.present
          ? data.customNotes.value
          : this.customNotes,
      showLogo: data.showLogo.present ? data.showLogo.value : this.showLogo,
      logoLocalPath: data.logoLocalPath.present
          ? data.logoLocalPath.value
          : this.logoLocalPath,
      logoUrl: data.logoUrl.present ? data.logoUrl.value : this.logoUrl,
      showQrCode: data.showQrCode.present
          ? data.showQrCode.value
          : this.showQrCode,
      showTaxBreakdown: data.showTaxBreakdown.present
          ? data.showTaxBreakdown.value
          : this.showTaxBreakdown,
      showCashierName: data.showCashierName.present
          ? data.showCashierName.value
          : this.showCashierName,
      showCustomerName: data.showCustomerName.present
          ? data.showCustomerName.value
          : this.showCustomerName,
      showDateTime: data.showDateTime.present
          ? data.showDateTime.value
          : this.showDateTime,
      showOrderId: data.showOrderId.present
          ? data.showOrderId.value
          : this.showOrderId,
      paperSize: data.paperSize.present ? data.paperSize.value : this.paperSize,
      fontSize: data.fontSize.present ? data.fontSize.value : this.fontSize,
      textAlignment: data.textAlignment.present
          ? data.textAlignment.value
          : this.textAlignment,
      autoPrintAfterCheckout: data.autoPrintAfterCheckout.present
          ? data.autoPrintAfterCheckout.value
          : this.autoPrintAfterCheckout,
      printDuplicateCopy: data.printDuplicateCopy.present
          ? data.printDuplicateCopy.value
          : this.printDuplicateCopy,
      thermalPrinterEnabled: data.thermalPrinterEnabled.present
          ? data.thermalPrinterEnabled.value
          : this.thermalPrinterEnabled,
      currencySymbol: data.currencySymbol.present
          ? data.currencySymbol.value
          : this.currencySymbol,
      taxPercentage: data.taxPercentage.present
          ? data.taxPercentage.value
          : this.taxPercentage,
      serviceChargePercentage: data.serviceChargePercentage.present
          ? data.serviceChargePercentage.value
          : this.serviceChargePercentage,
      vatInclusive: data.vatInclusive.present
          ? data.vatInclusive.value
          : this.vatInclusive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastSyncAttempt: data.lastSyncAttempt.present
          ? data.lastSyncAttempt.value
          : this.lastSyncAttempt,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptSettingsRow(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('businessName: $businessName, ')
          ..write('storeName: $storeName, ')
          ..write('ownerName: $ownerName, ')
          ..write('address: $address, ')
          ..write('contactNumber: $contactNumber, ')
          ..write('email: $email, ')
          ..write('website: $website, ')
          ..write('tinNumber: $tinNumber, ')
          ..write('permitNumber: $permitNumber, ')
          ..write('headerText: $headerText, ')
          ..write('footerText: $footerText, ')
          ..write('returnPolicy: $returnPolicy, ')
          ..write('customNotes: $customNotes, ')
          ..write('showLogo: $showLogo, ')
          ..write('logoLocalPath: $logoLocalPath, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('showQrCode: $showQrCode, ')
          ..write('showTaxBreakdown: $showTaxBreakdown, ')
          ..write('showCashierName: $showCashierName, ')
          ..write('showCustomerName: $showCustomerName, ')
          ..write('showDateTime: $showDateTime, ')
          ..write('showOrderId: $showOrderId, ')
          ..write('paperSize: $paperSize, ')
          ..write('fontSize: $fontSize, ')
          ..write('textAlignment: $textAlignment, ')
          ..write('autoPrintAfterCheckout: $autoPrintAfterCheckout, ')
          ..write('printDuplicateCopy: $printDuplicateCopy, ')
          ..write('thermalPrinterEnabled: $thermalPrinterEnabled, ')
          ..write('currencySymbol: $currencySymbol, ')
          ..write('taxPercentage: $taxPercentage, ')
          ..write('serviceChargePercentage: $serviceChargePercentage, ')
          ..write('vatInclusive: $vatInclusive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError, ')
          ..write('localUpdatedAt: $localUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    businessId,
    businessName,
    storeName,
    ownerName,
    address,
    contactNumber,
    email,
    website,
    tinNumber,
    permitNumber,
    headerText,
    footerText,
    returnPolicy,
    customNotes,
    showLogo,
    logoLocalPath,
    logoUrl,
    showQrCode,
    showTaxBreakdown,
    showCashierName,
    showCustomerName,
    showDateTime,
    showOrderId,
    paperSize,
    fontSize,
    textAlignment,
    autoPrintAfterCheckout,
    printDuplicateCopy,
    thermalPrinterEnabled,
    currencySymbol,
    taxPercentage,
    serviceChargePercentage,
    vatInclusive,
    createdAt,
    updatedAt,
    syncStatus,
    lastSyncAttempt,
    syncError,
    localUpdatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReceiptSettingsRow &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.businessName == this.businessName &&
          other.storeName == this.storeName &&
          other.ownerName == this.ownerName &&
          other.address == this.address &&
          other.contactNumber == this.contactNumber &&
          other.email == this.email &&
          other.website == this.website &&
          other.tinNumber == this.tinNumber &&
          other.permitNumber == this.permitNumber &&
          other.headerText == this.headerText &&
          other.footerText == this.footerText &&
          other.returnPolicy == this.returnPolicy &&
          other.customNotes == this.customNotes &&
          other.showLogo == this.showLogo &&
          other.logoLocalPath == this.logoLocalPath &&
          other.logoUrl == this.logoUrl &&
          other.showQrCode == this.showQrCode &&
          other.showTaxBreakdown == this.showTaxBreakdown &&
          other.showCashierName == this.showCashierName &&
          other.showCustomerName == this.showCustomerName &&
          other.showDateTime == this.showDateTime &&
          other.showOrderId == this.showOrderId &&
          other.paperSize == this.paperSize &&
          other.fontSize == this.fontSize &&
          other.textAlignment == this.textAlignment &&
          other.autoPrintAfterCheckout == this.autoPrintAfterCheckout &&
          other.printDuplicateCopy == this.printDuplicateCopy &&
          other.thermalPrinterEnabled == this.thermalPrinterEnabled &&
          other.currencySymbol == this.currencySymbol &&
          other.taxPercentage == this.taxPercentage &&
          other.serviceChargePercentage == this.serviceChargePercentage &&
          other.vatInclusive == this.vatInclusive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncAttempt == this.lastSyncAttempt &&
          other.syncError == this.syncError &&
          other.localUpdatedAt == this.localUpdatedAt);
}

class ReceiptSettingsTableCompanion
    extends UpdateCompanion<ReceiptSettingsRow> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> businessName;
  final Value<String> storeName;
  final Value<String> ownerName;
  final Value<String> address;
  final Value<String> contactNumber;
  final Value<String> email;
  final Value<String> website;
  final Value<String> tinNumber;
  final Value<String> permitNumber;
  final Value<String> headerText;
  final Value<String> footerText;
  final Value<String> returnPolicy;
  final Value<String> customNotes;
  final Value<bool> showLogo;
  final Value<String> logoLocalPath;
  final Value<String> logoUrl;
  final Value<bool> showQrCode;
  final Value<bool> showTaxBreakdown;
  final Value<bool> showCashierName;
  final Value<bool> showCustomerName;
  final Value<bool> showDateTime;
  final Value<bool> showOrderId;
  final Value<String> paperSize;
  final Value<String> fontSize;
  final Value<String> textAlignment;
  final Value<bool> autoPrintAfterCheckout;
  final Value<bool> printDuplicateCopy;
  final Value<bool> thermalPrinterEnabled;
  final Value<String> currencySymbol;
  final Value<double> taxPercentage;
  final Value<double> serviceChargePercentage;
  final Value<bool> vatInclusive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> syncStatus;
  final Value<DateTime?> lastSyncAttempt;
  final Value<String?> syncError;
  final Value<DateTime> localUpdatedAt;
  final Value<int> rowid;
  const ReceiptSettingsTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.businessName = const Value.absent(),
    this.storeName = const Value.absent(),
    this.ownerName = const Value.absent(),
    this.address = const Value.absent(),
    this.contactNumber = const Value.absent(),
    this.email = const Value.absent(),
    this.website = const Value.absent(),
    this.tinNumber = const Value.absent(),
    this.permitNumber = const Value.absent(),
    this.headerText = const Value.absent(),
    this.footerText = const Value.absent(),
    this.returnPolicy = const Value.absent(),
    this.customNotes = const Value.absent(),
    this.showLogo = const Value.absent(),
    this.logoLocalPath = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.showQrCode = const Value.absent(),
    this.showTaxBreakdown = const Value.absent(),
    this.showCashierName = const Value.absent(),
    this.showCustomerName = const Value.absent(),
    this.showDateTime = const Value.absent(),
    this.showOrderId = const Value.absent(),
    this.paperSize = const Value.absent(),
    this.fontSize = const Value.absent(),
    this.textAlignment = const Value.absent(),
    this.autoPrintAfterCheckout = const Value.absent(),
    this.printDuplicateCopy = const Value.absent(),
    this.thermalPrinterEnabled = const Value.absent(),
    this.currencySymbol = const Value.absent(),
    this.taxPercentage = const Value.absent(),
    this.serviceChargePercentage = const Value.absent(),
    this.vatInclusive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReceiptSettingsTableCompanion.insert({
    required String id,
    required String businessId,
    this.businessName = const Value.absent(),
    this.storeName = const Value.absent(),
    this.ownerName = const Value.absent(),
    this.address = const Value.absent(),
    this.contactNumber = const Value.absent(),
    this.email = const Value.absent(),
    this.website = const Value.absent(),
    this.tinNumber = const Value.absent(),
    this.permitNumber = const Value.absent(),
    this.headerText = const Value.absent(),
    this.footerText = const Value.absent(),
    this.returnPolicy = const Value.absent(),
    this.customNotes = const Value.absent(),
    this.showLogo = const Value.absent(),
    this.logoLocalPath = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.showQrCode = const Value.absent(),
    this.showTaxBreakdown = const Value.absent(),
    this.showCashierName = const Value.absent(),
    this.showCustomerName = const Value.absent(),
    this.showDateTime = const Value.absent(),
    this.showOrderId = const Value.absent(),
    this.paperSize = const Value.absent(),
    this.fontSize = const Value.absent(),
    this.textAlignment = const Value.absent(),
    this.autoPrintAfterCheckout = const Value.absent(),
    this.printDuplicateCopy = const Value.absent(),
    this.thermalPrinterEnabled = const Value.absent(),
    this.currencySymbol = const Value.absent(),
    this.taxPercentage = const Value.absent(),
    this.serviceChargePercentage = const Value.absent(),
    this.vatInclusive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId);
  static Insertable<ReceiptSettingsRow> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? businessName,
    Expression<String>? storeName,
    Expression<String>? ownerName,
    Expression<String>? address,
    Expression<String>? contactNumber,
    Expression<String>? email,
    Expression<String>? website,
    Expression<String>? tinNumber,
    Expression<String>? permitNumber,
    Expression<String>? headerText,
    Expression<String>? footerText,
    Expression<String>? returnPolicy,
    Expression<String>? customNotes,
    Expression<bool>? showLogo,
    Expression<String>? logoLocalPath,
    Expression<String>? logoUrl,
    Expression<bool>? showQrCode,
    Expression<bool>? showTaxBreakdown,
    Expression<bool>? showCashierName,
    Expression<bool>? showCustomerName,
    Expression<bool>? showDateTime,
    Expression<bool>? showOrderId,
    Expression<String>? paperSize,
    Expression<String>? fontSize,
    Expression<String>? textAlignment,
    Expression<bool>? autoPrintAfterCheckout,
    Expression<bool>? printDuplicateCopy,
    Expression<bool>? thermalPrinterEnabled,
    Expression<String>? currencySymbol,
    Expression<double>? taxPercentage,
    Expression<double>? serviceChargePercentage,
    Expression<bool>? vatInclusive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? syncStatus,
    Expression<DateTime>? lastSyncAttempt,
    Expression<String>? syncError,
    Expression<DateTime>? localUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (businessName != null) 'business_name': businessName,
      if (storeName != null) 'store_name': storeName,
      if (ownerName != null) 'owner_name': ownerName,
      if (address != null) 'address': address,
      if (contactNumber != null) 'contact_number': contactNumber,
      if (email != null) 'email': email,
      if (website != null) 'website': website,
      if (tinNumber != null) 'tin_number': tinNumber,
      if (permitNumber != null) 'permit_number': permitNumber,
      if (headerText != null) 'header_text': headerText,
      if (footerText != null) 'footer_text': footerText,
      if (returnPolicy != null) 'return_policy': returnPolicy,
      if (customNotes != null) 'custom_notes': customNotes,
      if (showLogo != null) 'show_logo': showLogo,
      if (logoLocalPath != null) 'logo_local_path': logoLocalPath,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (showQrCode != null) 'show_qr_code': showQrCode,
      if (showTaxBreakdown != null) 'show_tax_breakdown': showTaxBreakdown,
      if (showCashierName != null) 'show_cashier_name': showCashierName,
      if (showCustomerName != null) 'show_customer_name': showCustomerName,
      if (showDateTime != null) 'show_date_time': showDateTime,
      if (showOrderId != null) 'show_order_id': showOrderId,
      if (paperSize != null) 'paper_size': paperSize,
      if (fontSize != null) 'font_size': fontSize,
      if (textAlignment != null) 'text_alignment': textAlignment,
      if (autoPrintAfterCheckout != null)
        'auto_print_after_checkout': autoPrintAfterCheckout,
      if (printDuplicateCopy != null)
        'print_duplicate_copy': printDuplicateCopy,
      if (thermalPrinterEnabled != null)
        'thermal_printer_enabled': thermalPrinterEnabled,
      if (currencySymbol != null) 'currency_symbol': currencySymbol,
      if (taxPercentage != null) 'tax_percentage': taxPercentage,
      if (serviceChargePercentage != null)
        'service_charge_percentage': serviceChargePercentage,
      if (vatInclusive != null) 'vat_inclusive': vatInclusive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncAttempt != null) 'last_sync_attempt': lastSyncAttempt,
      if (syncError != null) 'sync_error': syncError,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReceiptSettingsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? businessName,
    Value<String>? storeName,
    Value<String>? ownerName,
    Value<String>? address,
    Value<String>? contactNumber,
    Value<String>? email,
    Value<String>? website,
    Value<String>? tinNumber,
    Value<String>? permitNumber,
    Value<String>? headerText,
    Value<String>? footerText,
    Value<String>? returnPolicy,
    Value<String>? customNotes,
    Value<bool>? showLogo,
    Value<String>? logoLocalPath,
    Value<String>? logoUrl,
    Value<bool>? showQrCode,
    Value<bool>? showTaxBreakdown,
    Value<bool>? showCashierName,
    Value<bool>? showCustomerName,
    Value<bool>? showDateTime,
    Value<bool>? showOrderId,
    Value<String>? paperSize,
    Value<String>? fontSize,
    Value<String>? textAlignment,
    Value<bool>? autoPrintAfterCheckout,
    Value<bool>? printDuplicateCopy,
    Value<bool>? thermalPrinterEnabled,
    Value<String>? currencySymbol,
    Value<double>? taxPercentage,
    Value<double>? serviceChargePercentage,
    Value<bool>? vatInclusive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? syncStatus,
    Value<DateTime?>? lastSyncAttempt,
    Value<String?>? syncError,
    Value<DateTime>? localUpdatedAt,
    Value<int>? rowid,
  }) {
    return ReceiptSettingsTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      storeName: storeName ?? this.storeName,
      ownerName: ownerName ?? this.ownerName,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      website: website ?? this.website,
      tinNumber: tinNumber ?? this.tinNumber,
      permitNumber: permitNumber ?? this.permitNumber,
      headerText: headerText ?? this.headerText,
      footerText: footerText ?? this.footerText,
      returnPolicy: returnPolicy ?? this.returnPolicy,
      customNotes: customNotes ?? this.customNotes,
      showLogo: showLogo ?? this.showLogo,
      logoLocalPath: logoLocalPath ?? this.logoLocalPath,
      logoUrl: logoUrl ?? this.logoUrl,
      showQrCode: showQrCode ?? this.showQrCode,
      showTaxBreakdown: showTaxBreakdown ?? this.showTaxBreakdown,
      showCashierName: showCashierName ?? this.showCashierName,
      showCustomerName: showCustomerName ?? this.showCustomerName,
      showDateTime: showDateTime ?? this.showDateTime,
      showOrderId: showOrderId ?? this.showOrderId,
      paperSize: paperSize ?? this.paperSize,
      fontSize: fontSize ?? this.fontSize,
      textAlignment: textAlignment ?? this.textAlignment,
      autoPrintAfterCheckout:
          autoPrintAfterCheckout ?? this.autoPrintAfterCheckout,
      printDuplicateCopy: printDuplicateCopy ?? this.printDuplicateCopy,
      thermalPrinterEnabled:
          thermalPrinterEnabled ?? this.thermalPrinterEnabled,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      serviceChargePercentage:
          serviceChargePercentage ?? this.serviceChargePercentage,
      vatInclusive: vatInclusive ?? this.vatInclusive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      syncError: syncError ?? this.syncError,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (businessName.present) {
      map['business_name'] = Variable<String>(businessName.value);
    }
    if (storeName.present) {
      map['store_name'] = Variable<String>(storeName.value);
    }
    if (ownerName.present) {
      map['owner_name'] = Variable<String>(ownerName.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (contactNumber.present) {
      map['contact_number'] = Variable<String>(contactNumber.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (website.present) {
      map['website'] = Variable<String>(website.value);
    }
    if (tinNumber.present) {
      map['tin_number'] = Variable<String>(tinNumber.value);
    }
    if (permitNumber.present) {
      map['permit_number'] = Variable<String>(permitNumber.value);
    }
    if (headerText.present) {
      map['header_text'] = Variable<String>(headerText.value);
    }
    if (footerText.present) {
      map['footer_text'] = Variable<String>(footerText.value);
    }
    if (returnPolicy.present) {
      map['return_policy'] = Variable<String>(returnPolicy.value);
    }
    if (customNotes.present) {
      map['custom_notes'] = Variable<String>(customNotes.value);
    }
    if (showLogo.present) {
      map['show_logo'] = Variable<bool>(showLogo.value);
    }
    if (logoLocalPath.present) {
      map['logo_local_path'] = Variable<String>(logoLocalPath.value);
    }
    if (logoUrl.present) {
      map['logo_url'] = Variable<String>(logoUrl.value);
    }
    if (showQrCode.present) {
      map['show_qr_code'] = Variable<bool>(showQrCode.value);
    }
    if (showTaxBreakdown.present) {
      map['show_tax_breakdown'] = Variable<bool>(showTaxBreakdown.value);
    }
    if (showCashierName.present) {
      map['show_cashier_name'] = Variable<bool>(showCashierName.value);
    }
    if (showCustomerName.present) {
      map['show_customer_name'] = Variable<bool>(showCustomerName.value);
    }
    if (showDateTime.present) {
      map['show_date_time'] = Variable<bool>(showDateTime.value);
    }
    if (showOrderId.present) {
      map['show_order_id'] = Variable<bool>(showOrderId.value);
    }
    if (paperSize.present) {
      map['paper_size'] = Variable<String>(paperSize.value);
    }
    if (fontSize.present) {
      map['font_size'] = Variable<String>(fontSize.value);
    }
    if (textAlignment.present) {
      map['text_alignment'] = Variable<String>(textAlignment.value);
    }
    if (autoPrintAfterCheckout.present) {
      map['auto_print_after_checkout'] = Variable<bool>(
        autoPrintAfterCheckout.value,
      );
    }
    if (printDuplicateCopy.present) {
      map['print_duplicate_copy'] = Variable<bool>(printDuplicateCopy.value);
    }
    if (thermalPrinterEnabled.present) {
      map['thermal_printer_enabled'] = Variable<bool>(
        thermalPrinterEnabled.value,
      );
    }
    if (currencySymbol.present) {
      map['currency_symbol'] = Variable<String>(currencySymbol.value);
    }
    if (taxPercentage.present) {
      map['tax_percentage'] = Variable<double>(taxPercentage.value);
    }
    if (serviceChargePercentage.present) {
      map['service_charge_percentage'] = Variable<double>(
        serviceChargePercentage.value,
      );
    }
    if (vatInclusive.present) {
      map['vat_inclusive'] = Variable<bool>(vatInclusive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (lastSyncAttempt.present) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('businessName: $businessName, ')
          ..write('storeName: $storeName, ')
          ..write('ownerName: $ownerName, ')
          ..write('address: $address, ')
          ..write('contactNumber: $contactNumber, ')
          ..write('email: $email, ')
          ..write('website: $website, ')
          ..write('tinNumber: $tinNumber, ')
          ..write('permitNumber: $permitNumber, ')
          ..write('headerText: $headerText, ')
          ..write('footerText: $footerText, ')
          ..write('returnPolicy: $returnPolicy, ')
          ..write('customNotes: $customNotes, ')
          ..write('showLogo: $showLogo, ')
          ..write('logoLocalPath: $logoLocalPath, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('showQrCode: $showQrCode, ')
          ..write('showTaxBreakdown: $showTaxBreakdown, ')
          ..write('showCashierName: $showCashierName, ')
          ..write('showCustomerName: $showCustomerName, ')
          ..write('showDateTime: $showDateTime, ')
          ..write('showOrderId: $showOrderId, ')
          ..write('paperSize: $paperSize, ')
          ..write('fontSize: $fontSize, ')
          ..write('textAlignment: $textAlignment, ')
          ..write('autoPrintAfterCheckout: $autoPrintAfterCheckout, ')
          ..write('printDuplicateCopy: $printDuplicateCopy, ')
          ..write('thermalPrinterEnabled: $thermalPrinterEnabled, ')
          ..write('currencySymbol: $currencySymbol, ')
          ..write('taxPercentage: $taxPercentage, ')
          ..write('serviceChargePercentage: $serviceChargePercentage, ')
          ..write('vatInclusive: $vatInclusive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditLogsTableTable extends AuditLogsTable
    with TableInfo<$AuditLogsTableTable, AuditLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionTypeMeta = const VerificationMeta(
    'actionType',
  );
  @override
  late final GeneratedColumn<String> actionType = GeneratedColumn<String>(
    'action_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unknown'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncAttemptMeta = const VerificationMeta(
    'lastSyncAttempt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAttempt =
      GeneratedColumn<DateTime>(
        'last_sync_attempt',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    branchId,
    userId,
    actionType,
    entityType,
    entityId,
    description,
    metadata,
    deviceId,
    createdAt,
    syncStatus,
    lastSyncAttempt,
    syncError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('action_type')) {
      context.handle(
        _actionTypeMeta,
        actionType.isAcceptableOrUnknown(data['action_type']!, _actionTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_actionTypeMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('last_sync_attempt')) {
      context.handle(
        _lastSyncAttemptMeta,
        lastSyncAttempt.isAcceptableOrUnknown(
          data['last_sync_attempt']!,
          _lastSyncAttemptMeta,
        ),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      actionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_type'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      lastSyncAttempt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_attempt'],
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
    );
  }

  @override
  $AuditLogsTableTable createAlias(String alias) {
    return $AuditLogsTableTable(attachedDatabase, alias);
  }
}

class AuditLogRow extends DataClass implements Insertable<AuditLogRow> {
  final String id;
  final String businessId;
  final String branchId;
  final String userId;
  final String actionType;
  final String entityType;
  final String? entityId;
  final String description;

  /// JSON-encoded map of additional context (amounts, names, etc.)
  final String metadata;
  final String deviceId;
  final DateTime createdAt;

  /// 0=pendingUpload, 3=synced, 4=failed  (audit logs are append-only)
  final int syncStatus;
  final DateTime? lastSyncAttempt;
  final String? syncError;
  const AuditLogRow({
    required this.id,
    required this.businessId,
    required this.branchId,
    required this.userId,
    required this.actionType,
    required this.entityType,
    this.entityId,
    required this.description,
    required this.metadata,
    required this.deviceId,
    required this.createdAt,
    required this.syncStatus,
    this.lastSyncAttempt,
    this.syncError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['branch_id'] = Variable<String>(branchId);
    map['user_id'] = Variable<String>(userId);
    map['action_type'] = Variable<String>(actionType);
    map['entity_type'] = Variable<String>(entityType);
    if (!nullToAbsent || entityId != null) {
      map['entity_id'] = Variable<String>(entityId);
    }
    map['description'] = Variable<String>(description);
    map['metadata'] = Variable<String>(metadata);
    map['device_id'] = Variable<String>(deviceId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || lastSyncAttempt != null) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt);
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    return map;
  }

  AuditLogsTableCompanion toCompanion(bool nullToAbsent) {
    return AuditLogsTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      branchId: Value(branchId),
      userId: Value(userId),
      actionType: Value(actionType),
      entityType: Value(entityType),
      entityId: entityId == null && nullToAbsent
          ? const Value.absent()
          : Value(entityId),
      description: Value(description),
      metadata: Value(metadata),
      deviceId: Value(deviceId),
      createdAt: Value(createdAt),
      syncStatus: Value(syncStatus),
      lastSyncAttempt: lastSyncAttempt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAttempt),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
    );
  }

  factory AuditLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLogRow(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      userId: serializer.fromJson<String>(json['userId']),
      actionType: serializer.fromJson<String>(json['actionType']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String?>(json['entityId']),
      description: serializer.fromJson<String>(json['description']),
      metadata: serializer.fromJson<String>(json['metadata']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      lastSyncAttempt: serializer.fromJson<DateTime?>(json['lastSyncAttempt']),
      syncError: serializer.fromJson<String?>(json['syncError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'branchId': serializer.toJson<String>(branchId),
      'userId': serializer.toJson<String>(userId),
      'actionType': serializer.toJson<String>(actionType),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String?>(entityId),
      'description': serializer.toJson<String>(description),
      'metadata': serializer.toJson<String>(metadata),
      'deviceId': serializer.toJson<String>(deviceId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'lastSyncAttempt': serializer.toJson<DateTime?>(lastSyncAttempt),
      'syncError': serializer.toJson<String?>(syncError),
    };
  }

  AuditLogRow copyWith({
    String? id,
    String? businessId,
    String? branchId,
    String? userId,
    String? actionType,
    String? entityType,
    Value<String?> entityId = const Value.absent(),
    String? description,
    String? metadata,
    String? deviceId,
    DateTime? createdAt,
    int? syncStatus,
    Value<DateTime?> lastSyncAttempt = const Value.absent(),
    Value<String?> syncError = const Value.absent(),
  }) => AuditLogRow(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    branchId: branchId ?? this.branchId,
    userId: userId ?? this.userId,
    actionType: actionType ?? this.actionType,
    entityType: entityType ?? this.entityType,
    entityId: entityId.present ? entityId.value : this.entityId,
    description: description ?? this.description,
    metadata: metadata ?? this.metadata,
    deviceId: deviceId ?? this.deviceId,
    createdAt: createdAt ?? this.createdAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncAttempt: lastSyncAttempt.present
        ? lastSyncAttempt.value
        : this.lastSyncAttempt,
    syncError: syncError.present ? syncError.value : this.syncError,
  );
  AuditLogRow copyWithCompanion(AuditLogsTableCompanion data) {
    return AuditLogRow(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      userId: data.userId.present ? data.userId.value : this.userId,
      actionType: data.actionType.present
          ? data.actionType.value
          : this.actionType,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      description: data.description.present
          ? data.description.value
          : this.description,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastSyncAttempt: data.lastSyncAttempt.present
          ? data.lastSyncAttempt.value
          : this.lastSyncAttempt,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogRow(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('branchId: $branchId, ')
          ..write('userId: $userId, ')
          ..write('actionType: $actionType, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('description: $description, ')
          ..write('metadata: $metadata, ')
          ..write('deviceId: $deviceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    branchId,
    userId,
    actionType,
    entityType,
    entityId,
    description,
    metadata,
    deviceId,
    createdAt,
    syncStatus,
    lastSyncAttempt,
    syncError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLogRow &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.branchId == this.branchId &&
          other.userId == this.userId &&
          other.actionType == this.actionType &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.description == this.description &&
          other.metadata == this.metadata &&
          other.deviceId == this.deviceId &&
          other.createdAt == this.createdAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncAttempt == this.lastSyncAttempt &&
          other.syncError == this.syncError);
}

class AuditLogsTableCompanion extends UpdateCompanion<AuditLogRow> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> branchId;
  final Value<String> userId;
  final Value<String> actionType;
  final Value<String> entityType;
  final Value<String?> entityId;
  final Value<String> description;
  final Value<String> metadata;
  final Value<String> deviceId;
  final Value<DateTime> createdAt;
  final Value<int> syncStatus;
  final Value<DateTime?> lastSyncAttempt;
  final Value<String?> syncError;
  final Value<int> rowid;
  const AuditLogsTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.userId = const Value.absent(),
    this.actionType = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.description = const Value.absent(),
    this.metadata = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditLogsTableCompanion.insert({
    required String id,
    required String businessId,
    required String branchId,
    required String userId,
    required String actionType,
    required String entityType,
    this.entityId = const Value.absent(),
    required String description,
    this.metadata = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       branchId = Value(branchId),
       userId = Value(userId),
       actionType = Value(actionType),
       entityType = Value(entityType),
       description = Value(description);
  static Insertable<AuditLogRow> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? branchId,
    Expression<String>? userId,
    Expression<String>? actionType,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? description,
    Expression<String>? metadata,
    Expression<String>? deviceId,
    Expression<DateTime>? createdAt,
    Expression<int>? syncStatus,
    Expression<DateTime>? lastSyncAttempt,
    Expression<String>? syncError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (branchId != null) 'branch_id': branchId,
      if (userId != null) 'user_id': userId,
      if (actionType != null) 'action_type': actionType,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (description != null) 'description': description,
      if (metadata != null) 'metadata': metadata,
      if (deviceId != null) 'device_id': deviceId,
      if (createdAt != null) 'created_at': createdAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncAttempt != null) 'last_sync_attempt': lastSyncAttempt,
      if (syncError != null) 'sync_error': syncError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditLogsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? branchId,
    Value<String>? userId,
    Value<String>? actionType,
    Value<String>? entityType,
    Value<String?>? entityId,
    Value<String>? description,
    Value<String>? metadata,
    Value<String>? deviceId,
    Value<DateTime>? createdAt,
    Value<int>? syncStatus,
    Value<DateTime?>? lastSyncAttempt,
    Value<String?>? syncError,
    Value<int>? rowid,
  }) {
    return AuditLogsTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      branchId: branchId ?? this.branchId,
      userId: userId ?? this.userId,
      actionType: actionType ?? this.actionType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      syncError: syncError ?? this.syncError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (actionType.present) {
      map['action_type'] = Variable<String>(actionType.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (lastSyncAttempt.present) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogsTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('branchId: $branchId, ')
          ..write('userId: $userId, ')
          ..write('actionType: $actionType, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('description: $description, ')
          ..write('metadata: $metadata, ')
          ..write('deviceId: $deviceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EmployeesTableTable extends EmployeesTable
    with TableInfo<$EmployeesTableTable, EmployeeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmployeesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authUserIdMeta = const VerificationMeta(
    'authUserId',
  );
  @override
  late final GeneratedColumn<String> authUserId = GeneratedColumn<String>(
    'auth_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleIdMeta = const VerificationMeta('roleId');
  @override
  late final GeneratedColumn<String> roleId = GeneratedColumn<String>(
    'role_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleNameMeta = const VerificationMeta(
    'roleName',
  );
  @override
  late final GeneratedColumn<String> roleName = GeneratedColumn<String>(
    'role_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncAttemptMeta = const VerificationMeta(
    'lastSyncAttempt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAttempt =
      GeneratedColumn<DateTime>(
        'last_sync_attempt',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    userId,
    authUserId,
    email,
    fullName,
    roleId,
    roleName,
    branchId,
    isActive,
    createdAt,
    syncStatus,
    lastSyncAttempt,
    syncError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'employees';
  @override
  VerificationContext validateIntegrity(
    Insertable<EmployeeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('auth_user_id')) {
      context.handle(
        _authUserIdMeta,
        authUserId.isAcceptableOrUnknown(
          data['auth_user_id']!,
          _authUserIdMeta,
        ),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    }
    if (data.containsKey('role_id')) {
      context.handle(
        _roleIdMeta,
        roleId.isAcceptableOrUnknown(data['role_id']!, _roleIdMeta),
      );
    }
    if (data.containsKey('role_name')) {
      context.handle(
        _roleNameMeta,
        roleName.isAcceptableOrUnknown(data['role_name']!, _roleNameMeta),
      );
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('last_sync_attempt')) {
      context.handle(
        _lastSyncAttemptMeta,
        lastSyncAttempt.isAcceptableOrUnknown(
          data['last_sync_attempt']!,
          _lastSyncAttemptMeta,
        ),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EmployeeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmployeeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      authUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auth_user_id'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      ),
      roleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role_id'],
      ),
      roleName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role_name'],
      ),
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      lastSyncAttempt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_attempt'],
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
    );
  }

  @override
  $EmployeesTableTable createAlias(String alias) {
    return $EmployeesTableTable(attachedDatabase, alias);
  }
}

class EmployeeRow extends DataClass implements Insertable<EmployeeRow> {
  final String id;
  final String businessId;
  final String? userId;
  final String? authUserId;
  final String? email;
  final String? fullName;
  final String? roleId;

  /// Denormalized from roles join — avoids a local join on every read.
  final String? roleName;

  /// Denormalized primary branch from employee_branches join table.
  final String? branchId;
  final bool isActive;
  final DateTime? createdAt;

  /// 0=pendingUpload, 1=pendingUpdate, 2=pendingDelete, 3=synced, 4=failed
  final int syncStatus;
  final DateTime? lastSyncAttempt;
  final String? syncError;
  const EmployeeRow({
    required this.id,
    required this.businessId,
    this.userId,
    this.authUserId,
    this.email,
    this.fullName,
    this.roleId,
    this.roleName,
    this.branchId,
    required this.isActive,
    this.createdAt,
    required this.syncStatus,
    this.lastSyncAttempt,
    this.syncError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || authUserId != null) {
      map['auth_user_id'] = Variable<String>(authUserId);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || fullName != null) {
      map['full_name'] = Variable<String>(fullName);
    }
    if (!nullToAbsent || roleId != null) {
      map['role_id'] = Variable<String>(roleId);
    }
    if (!nullToAbsent || roleName != null) {
      map['role_name'] = Variable<String>(roleName);
    }
    if (!nullToAbsent || branchId != null) {
      map['branch_id'] = Variable<String>(branchId);
    }
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || lastSyncAttempt != null) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt);
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    return map;
  }

  EmployeesTableCompanion toCompanion(bool nullToAbsent) {
    return EmployeesTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      authUserId: authUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(authUserId),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      fullName: fullName == null && nullToAbsent
          ? const Value.absent()
          : Value(fullName),
      roleId: roleId == null && nullToAbsent
          ? const Value.absent()
          : Value(roleId),
      roleName: roleName == null && nullToAbsent
          ? const Value.absent()
          : Value(roleName),
      branchId: branchId == null && nullToAbsent
          ? const Value.absent()
          : Value(branchId),
      isActive: Value(isActive),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      syncStatus: Value(syncStatus),
      lastSyncAttempt: lastSyncAttempt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAttempt),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
    );
  }

  factory EmployeeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmployeeRow(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      userId: serializer.fromJson<String?>(json['userId']),
      authUserId: serializer.fromJson<String?>(json['authUserId']),
      email: serializer.fromJson<String?>(json['email']),
      fullName: serializer.fromJson<String?>(json['fullName']),
      roleId: serializer.fromJson<String?>(json['roleId']),
      roleName: serializer.fromJson<String?>(json['roleName']),
      branchId: serializer.fromJson<String?>(json['branchId']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      lastSyncAttempt: serializer.fromJson<DateTime?>(json['lastSyncAttempt']),
      syncError: serializer.fromJson<String?>(json['syncError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'userId': serializer.toJson<String?>(userId),
      'authUserId': serializer.toJson<String?>(authUserId),
      'email': serializer.toJson<String?>(email),
      'fullName': serializer.toJson<String?>(fullName),
      'roleId': serializer.toJson<String?>(roleId),
      'roleName': serializer.toJson<String?>(roleName),
      'branchId': serializer.toJson<String?>(branchId),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'lastSyncAttempt': serializer.toJson<DateTime?>(lastSyncAttempt),
      'syncError': serializer.toJson<String?>(syncError),
    };
  }

  EmployeeRow copyWith({
    String? id,
    String? businessId,
    Value<String?> userId = const Value.absent(),
    Value<String?> authUserId = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> fullName = const Value.absent(),
    Value<String?> roleId = const Value.absent(),
    Value<String?> roleName = const Value.absent(),
    Value<String?> branchId = const Value.absent(),
    bool? isActive,
    Value<DateTime?> createdAt = const Value.absent(),
    int? syncStatus,
    Value<DateTime?> lastSyncAttempt = const Value.absent(),
    Value<String?> syncError = const Value.absent(),
  }) => EmployeeRow(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    userId: userId.present ? userId.value : this.userId,
    authUserId: authUserId.present ? authUserId.value : this.authUserId,
    email: email.present ? email.value : this.email,
    fullName: fullName.present ? fullName.value : this.fullName,
    roleId: roleId.present ? roleId.value : this.roleId,
    roleName: roleName.present ? roleName.value : this.roleName,
    branchId: branchId.present ? branchId.value : this.branchId,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncAttempt: lastSyncAttempt.present
        ? lastSyncAttempt.value
        : this.lastSyncAttempt,
    syncError: syncError.present ? syncError.value : this.syncError,
  );
  EmployeeRow copyWithCompanion(EmployeesTableCompanion data) {
    return EmployeeRow(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      userId: data.userId.present ? data.userId.value : this.userId,
      authUserId: data.authUserId.present
          ? data.authUserId.value
          : this.authUserId,
      email: data.email.present ? data.email.value : this.email,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      roleId: data.roleId.present ? data.roleId.value : this.roleId,
      roleName: data.roleName.present ? data.roleName.value : this.roleName,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastSyncAttempt: data.lastSyncAttempt.present
          ? data.lastSyncAttempt.value
          : this.lastSyncAttempt,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmployeeRow(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('userId: $userId, ')
          ..write('authUserId: $authUserId, ')
          ..write('email: $email, ')
          ..write('fullName: $fullName, ')
          ..write('roleId: $roleId, ')
          ..write('roleName: $roleName, ')
          ..write('branchId: $branchId, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    userId,
    authUserId,
    email,
    fullName,
    roleId,
    roleName,
    branchId,
    isActive,
    createdAt,
    syncStatus,
    lastSyncAttempt,
    syncError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmployeeRow &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.userId == this.userId &&
          other.authUserId == this.authUserId &&
          other.email == this.email &&
          other.fullName == this.fullName &&
          other.roleId == this.roleId &&
          other.roleName == this.roleName &&
          other.branchId == this.branchId &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncAttempt == this.lastSyncAttempt &&
          other.syncError == this.syncError);
}

class EmployeesTableCompanion extends UpdateCompanion<EmployeeRow> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String?> userId;
  final Value<String?> authUserId;
  final Value<String?> email;
  final Value<String?> fullName;
  final Value<String?> roleId;
  final Value<String?> roleName;
  final Value<String?> branchId;
  final Value<bool> isActive;
  final Value<DateTime?> createdAt;
  final Value<int> syncStatus;
  final Value<DateTime?> lastSyncAttempt;
  final Value<String?> syncError;
  final Value<int> rowid;
  const EmployeesTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.userId = const Value.absent(),
    this.authUserId = const Value.absent(),
    this.email = const Value.absent(),
    this.fullName = const Value.absent(),
    this.roleId = const Value.absent(),
    this.roleName = const Value.absent(),
    this.branchId = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EmployeesTableCompanion.insert({
    required String id,
    required String businessId,
    this.userId = const Value.absent(),
    this.authUserId = const Value.absent(),
    this.email = const Value.absent(),
    this.fullName = const Value.absent(),
    this.roleId = const Value.absent(),
    this.roleName = const Value.absent(),
    this.branchId = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId);
  static Insertable<EmployeeRow> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? userId,
    Expression<String>? authUserId,
    Expression<String>? email,
    Expression<String>? fullName,
    Expression<String>? roleId,
    Expression<String>? roleName,
    Expression<String>? branchId,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<int>? syncStatus,
    Expression<DateTime>? lastSyncAttempt,
    Expression<String>? syncError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (userId != null) 'user_id': userId,
      if (authUserId != null) 'auth_user_id': authUserId,
      if (email != null) 'email': email,
      if (fullName != null) 'full_name': fullName,
      if (roleId != null) 'role_id': roleId,
      if (roleName != null) 'role_name': roleName,
      if (branchId != null) 'branch_id': branchId,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncAttempt != null) 'last_sync_attempt': lastSyncAttempt,
      if (syncError != null) 'sync_error': syncError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EmployeesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String?>? userId,
    Value<String?>? authUserId,
    Value<String?>? email,
    Value<String?>? fullName,
    Value<String?>? roleId,
    Value<String?>? roleName,
    Value<String?>? branchId,
    Value<bool>? isActive,
    Value<DateTime?>? createdAt,
    Value<int>? syncStatus,
    Value<DateTime?>? lastSyncAttempt,
    Value<String?>? syncError,
    Value<int>? rowid,
  }) {
    return EmployeesTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      userId: userId ?? this.userId,
      authUserId: authUserId ?? this.authUserId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      roleId: roleId ?? this.roleId,
      roleName: roleName ?? this.roleName,
      branchId: branchId ?? this.branchId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      syncError: syncError ?? this.syncError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (authUserId.present) {
      map['auth_user_id'] = Variable<String>(authUserId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (roleId.present) {
      map['role_id'] = Variable<String>(roleId.value);
    }
    if (roleName.present) {
      map['role_name'] = Variable<String>(roleName.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (lastSyncAttempt.present) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmployeesTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('userId: $userId, ')
          ..write('authUserId: $authUserId, ')
          ..write('email: $email, ')
          ..write('fullName: $fullName, ')
          ..write('roleId: $roleId, ')
          ..write('roleName: $roleName, ')
          ..write('branchId: $branchId, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EmployeePermissionsTableTable extends EmployeePermissionsTable
    with TableInfo<$EmployeePermissionsTableTable, EmployeePermissionsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmployeePermissionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _authUserIdMeta = const VerificationMeta(
    'authUserId',
  );
  @override
  late final GeneratedColumn<String> authUserId = GeneratedColumn<String>(
    'auth_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _employeeIdMeta = const VerificationMeta(
    'employeeId',
  );
  @override
  late final GeneratedColumn<String> employeeId = GeneratedColumn<String>(
    'employee_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _permissionsJsonMeta = const VerificationMeta(
    'permissionsJson',
  );
  @override
  late final GeneratedColumn<String> permissionsJson = GeneratedColumn<String>(
    'permissions_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    authUserId,
    employeeId,
    permissionsJson,
    syncedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'employee_permissions_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<EmployeePermissionsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('auth_user_id')) {
      context.handle(
        _authUserIdMeta,
        authUserId.isAcceptableOrUnknown(
          data['auth_user_id']!,
          _authUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_authUserIdMeta);
    }
    if (data.containsKey('employee_id')) {
      context.handle(
        _employeeIdMeta,
        employeeId.isAcceptableOrUnknown(data['employee_id']!, _employeeIdMeta),
      );
    }
    if (data.containsKey('permissions_json')) {
      context.handle(
        _permissionsJsonMeta,
        permissionsJson.isAcceptableOrUnknown(
          data['permissions_json']!,
          _permissionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {authUserId};
  @override
  EmployeePermissionsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmployeePermissionsRow(
      authUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auth_user_id'],
      )!,
      employeeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employee_id'],
      ),
      permissionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}permissions_json'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $EmployeePermissionsTableTable createAlias(String alias) {
    return $EmployeePermissionsTableTable(attachedDatabase, alias);
  }
}

class EmployeePermissionsRow extends DataClass
    implements Insertable<EmployeePermissionsRow> {
  /// Supabase auth.uid() — also the Drift primary key.
  final String authUserId;

  /// The employee record UUID in the employees table.
  /// Nullable for the rare case where the record hasn't synced yet.
  final String? employeeId;

  /// JSON-encoded `Map<String, bool>`: `{"pos.use": true, ...}`.
  final String permissionsJson;

  /// Timestamp of the last successful sync from Supabase.
  /// Null when the row was seeded locally from the role matrix.
  final DateTime? syncedAt;

  /// Last time this row was written (by load or sync).
  final DateTime updatedAt;
  const EmployeePermissionsRow({
    required this.authUserId,
    this.employeeId,
    required this.permissionsJson,
    this.syncedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['auth_user_id'] = Variable<String>(authUserId);
    if (!nullToAbsent || employeeId != null) {
      map['employee_id'] = Variable<String>(employeeId);
    }
    map['permissions_json'] = Variable<String>(permissionsJson);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EmployeePermissionsTableCompanion toCompanion(bool nullToAbsent) {
    return EmployeePermissionsTableCompanion(
      authUserId: Value(authUserId),
      employeeId: employeeId == null && nullToAbsent
          ? const Value.absent()
          : Value(employeeId),
      permissionsJson: Value(permissionsJson),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory EmployeePermissionsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmployeePermissionsRow(
      authUserId: serializer.fromJson<String>(json['authUserId']),
      employeeId: serializer.fromJson<String?>(json['employeeId']),
      permissionsJson: serializer.fromJson<String>(json['permissionsJson']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'authUserId': serializer.toJson<String>(authUserId),
      'employeeId': serializer.toJson<String?>(employeeId),
      'permissionsJson': serializer.toJson<String>(permissionsJson),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  EmployeePermissionsRow copyWith({
    String? authUserId,
    Value<String?> employeeId = const Value.absent(),
    String? permissionsJson,
    Value<DateTime?> syncedAt = const Value.absent(),
    DateTime? updatedAt,
  }) => EmployeePermissionsRow(
    authUserId: authUserId ?? this.authUserId,
    employeeId: employeeId.present ? employeeId.value : this.employeeId,
    permissionsJson: permissionsJson ?? this.permissionsJson,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  EmployeePermissionsRow copyWithCompanion(
    EmployeePermissionsTableCompanion data,
  ) {
    return EmployeePermissionsRow(
      authUserId: data.authUserId.present
          ? data.authUserId.value
          : this.authUserId,
      employeeId: data.employeeId.present
          ? data.employeeId.value
          : this.employeeId,
      permissionsJson: data.permissionsJson.present
          ? data.permissionsJson.value
          : this.permissionsJson,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmployeePermissionsRow(')
          ..write('authUserId: $authUserId, ')
          ..write('employeeId: $employeeId, ')
          ..write('permissionsJson: $permissionsJson, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(authUserId, employeeId, permissionsJson, syncedAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmployeePermissionsRow &&
          other.authUserId == this.authUserId &&
          other.employeeId == this.employeeId &&
          other.permissionsJson == this.permissionsJson &&
          other.syncedAt == this.syncedAt &&
          other.updatedAt == this.updatedAt);
}

class EmployeePermissionsTableCompanion
    extends UpdateCompanion<EmployeePermissionsRow> {
  final Value<String> authUserId;
  final Value<String?> employeeId;
  final Value<String> permissionsJson;
  final Value<DateTime?> syncedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const EmployeePermissionsTableCompanion({
    this.authUserId = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.permissionsJson = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EmployeePermissionsTableCompanion.insert({
    required String authUserId,
    this.employeeId = const Value.absent(),
    this.permissionsJson = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : authUserId = Value(authUserId);
  static Insertable<EmployeePermissionsRow> custom({
    Expression<String>? authUserId,
    Expression<String>? employeeId,
    Expression<String>? permissionsJson,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (authUserId != null) 'auth_user_id': authUserId,
      if (employeeId != null) 'employee_id': employeeId,
      if (permissionsJson != null) 'permissions_json': permissionsJson,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EmployeePermissionsTableCompanion copyWith({
    Value<String>? authUserId,
    Value<String?>? employeeId,
    Value<String>? permissionsJson,
    Value<DateTime?>? syncedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return EmployeePermissionsTableCompanion(
      authUserId: authUserId ?? this.authUserId,
      employeeId: employeeId ?? this.employeeId,
      permissionsJson: permissionsJson ?? this.permissionsJson,
      syncedAt: syncedAt ?? this.syncedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (authUserId.present) {
      map['auth_user_id'] = Variable<String>(authUserId.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<String>(employeeId.value);
    }
    if (permissionsJson.present) {
      map['permissions_json'] = Variable<String>(permissionsJson.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmployeePermissionsTableCompanion(')
          ..write('authUserId: $authUserId, ')
          ..write('employeeId: $employeeId, ')
          ..write('permissionsJson: $permissionsJson, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BusinessModulesTableTable extends BusinessModulesTable
    with TableInfo<$BusinessModulesTableTable, BusinessModuleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BusinessModulesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _moduleCodeMeta = const VerificationMeta(
    'moduleCode',
  );
  @override
  late final GeneratedColumn<String> moduleCode = GeneratedColumn<String>(
    'module_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    businessId,
    moduleCode,
    enabled,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'business_modules_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<BusinessModuleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('module_code')) {
      context.handle(
        _moduleCodeMeta,
        moduleCode.isAcceptableOrUnknown(data['module_code']!, _moduleCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_moduleCodeMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {businessId, moduleCode};
  @override
  BusinessModuleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BusinessModuleRow(
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      moduleCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}module_code'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $BusinessModulesTableTable createAlias(String alias) {
    return $BusinessModulesTableTable(attachedDatabase, alias);
  }
}

class BusinessModuleRow extends DataClass
    implements Insertable<BusinessModuleRow> {
  final String businessId;
  final String moduleCode;
  final bool enabled;

  /// Last time this row was written from Supabase.
  final DateTime syncedAt;
  const BusinessModuleRow({
    required this.businessId,
    required this.moduleCode,
    required this.enabled,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['business_id'] = Variable<String>(businessId);
    map['module_code'] = Variable<String>(moduleCode);
    map['enabled'] = Variable<bool>(enabled);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  BusinessModulesTableCompanion toCompanion(bool nullToAbsent) {
    return BusinessModulesTableCompanion(
      businessId: Value(businessId),
      moduleCode: Value(moduleCode),
      enabled: Value(enabled),
      syncedAt: Value(syncedAt),
    );
  }

  factory BusinessModuleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BusinessModuleRow(
      businessId: serializer.fromJson<String>(json['businessId']),
      moduleCode: serializer.fromJson<String>(json['moduleCode']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'businessId': serializer.toJson<String>(businessId),
      'moduleCode': serializer.toJson<String>(moduleCode),
      'enabled': serializer.toJson<bool>(enabled),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  BusinessModuleRow copyWith({
    String? businessId,
    String? moduleCode,
    bool? enabled,
    DateTime? syncedAt,
  }) => BusinessModuleRow(
    businessId: businessId ?? this.businessId,
    moduleCode: moduleCode ?? this.moduleCode,
    enabled: enabled ?? this.enabled,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  BusinessModuleRow copyWithCompanion(BusinessModulesTableCompanion data) {
    return BusinessModuleRow(
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      moduleCode: data.moduleCode.present
          ? data.moduleCode.value
          : this.moduleCode,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BusinessModuleRow(')
          ..write('businessId: $businessId, ')
          ..write('moduleCode: $moduleCode, ')
          ..write('enabled: $enabled, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(businessId, moduleCode, enabled, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BusinessModuleRow &&
          other.businessId == this.businessId &&
          other.moduleCode == this.moduleCode &&
          other.enabled == this.enabled &&
          other.syncedAt == this.syncedAt);
}

class BusinessModulesTableCompanion extends UpdateCompanion<BusinessModuleRow> {
  final Value<String> businessId;
  final Value<String> moduleCode;
  final Value<bool> enabled;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const BusinessModulesTableCompanion({
    this.businessId = const Value.absent(),
    this.moduleCode = const Value.absent(),
    this.enabled = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BusinessModulesTableCompanion.insert({
    required String businessId,
    required String moduleCode,
    this.enabled = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : businessId = Value(businessId),
       moduleCode = Value(moduleCode);
  static Insertable<BusinessModuleRow> custom({
    Expression<String>? businessId,
    Expression<String>? moduleCode,
    Expression<bool>? enabled,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (businessId != null) 'business_id': businessId,
      if (moduleCode != null) 'module_code': moduleCode,
      if (enabled != null) 'enabled': enabled,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BusinessModulesTableCompanion copyWith({
    Value<String>? businessId,
    Value<String>? moduleCode,
    Value<bool>? enabled,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return BusinessModulesTableCompanion(
      businessId: businessId ?? this.businessId,
      moduleCode: moduleCode ?? this.moduleCode,
      enabled: enabled ?? this.enabled,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (moduleCode.present) {
      map['module_code'] = Variable<String>(moduleCode.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BusinessModulesTableCompanion(')
          ..write('businessId: $businessId, ')
          ..write('moduleCode: $moduleCode, ')
          ..write('enabled: $enabled, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SuppliersTableTable extends SuppliersTable
    with TableInfo<$SuppliersTableTable, SupplierRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SuppliersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contactNameMeta = const VerificationMeta(
    'contactName',
  );
  @override
  late final GeneratedColumn<String> contactName = GeneratedColumn<String>(
    'contact_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taxIdMeta = const VerificationMeta('taxId');
  @override
  late final GeneratedColumn<String> taxId = GeneratedColumn<String>(
    'tax_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncAttemptMeta = const VerificationMeta(
    'lastSyncAttempt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAttempt =
      GeneratedColumn<DateTime>(
        'last_sync_attempt',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    name,
    contactName,
    phone,
    email,
    address,
    taxId,
    notes,
    isActive,
    isDeleted,
    deletedAt,
    syncStatus,
    lastSyncAttempt,
    syncError,
    createdAt,
    localUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'suppliers';
  @override
  VerificationContext validateIntegrity(
    Insertable<SupplierRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('contact_name')) {
      context.handle(
        _contactNameMeta,
        contactName.isAcceptableOrUnknown(
          data['contact_name']!,
          _contactNameMeta,
        ),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('tax_id')) {
      context.handle(
        _taxIdMeta,
        taxId.isAcceptableOrUnknown(data['tax_id']!, _taxIdMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('last_sync_attempt')) {
      context.handle(
        _lastSyncAttemptMeta,
        lastSyncAttempt.isAcceptableOrUnknown(
          data['last_sync_attempt']!,
          _lastSyncAttemptMeta,
        ),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SupplierRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SupplierRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      contactName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_name'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      taxId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tax_id'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      lastSyncAttempt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_attempt'],
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
    );
  }

  @override
  $SuppliersTableTable createAlias(String alias) {
    return $SuppliersTableTable(attachedDatabase, alias);
  }
}

class SupplierRow extends DataClass implements Insertable<SupplierRow> {
  final String id;
  final String businessId;
  final String name;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? address;
  final String? taxId;
  final String? notes;
  final bool isActive;

  /// Soft delete — never hard-delete supplier records; they may be referenced
  /// by historical purchase orders.
  final bool isDeleted;
  final DateTime? deletedAt;

  /// 0=pendingUpload, 1=pendingUpdate, 2=pendingDelete, 3=synced, 4=failed
  final int syncStatus;
  final DateTime? lastSyncAttempt;
  final String? syncError;
  final DateTime createdAt;
  final DateTime localUpdatedAt;
  const SupplierRow({
    required this.id,
    required this.businessId,
    required this.name,
    this.contactName,
    this.phone,
    this.email,
    this.address,
    this.taxId,
    this.notes,
    required this.isActive,
    required this.isDeleted,
    this.deletedAt,
    required this.syncStatus,
    this.lastSyncAttempt,
    this.syncError,
    required this.createdAt,
    required this.localUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || contactName != null) {
      map['contact_name'] = Variable<String>(contactName);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || taxId != null) {
      map['tax_id'] = Variable<String>(taxId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || lastSyncAttempt != null) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt);
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    return map;
  }

  SuppliersTableCompanion toCompanion(bool nullToAbsent) {
    return SuppliersTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      name: Value(name),
      contactName: contactName == null && nullToAbsent
          ? const Value.absent()
          : Value(contactName),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      taxId: taxId == null && nullToAbsent
          ? const Value.absent()
          : Value(taxId),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isActive: Value(isActive),
      isDeleted: Value(isDeleted),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
      lastSyncAttempt: lastSyncAttempt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAttempt),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      createdAt: Value(createdAt),
      localUpdatedAt: Value(localUpdatedAt),
    );
  }

  factory SupplierRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SupplierRow(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      name: serializer.fromJson<String>(json['name']),
      contactName: serializer.fromJson<String?>(json['contactName']),
      phone: serializer.fromJson<String?>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      address: serializer.fromJson<String?>(json['address']),
      taxId: serializer.fromJson<String?>(json['taxId']),
      notes: serializer.fromJson<String?>(json['notes']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      lastSyncAttempt: serializer.fromJson<DateTime?>(json['lastSyncAttempt']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'name': serializer.toJson<String>(name),
      'contactName': serializer.toJson<String?>(contactName),
      'phone': serializer.toJson<String?>(phone),
      'email': serializer.toJson<String?>(email),
      'address': serializer.toJson<String?>(address),
      'taxId': serializer.toJson<String?>(taxId),
      'notes': serializer.toJson<String?>(notes),
      'isActive': serializer.toJson<bool>(isActive),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'lastSyncAttempt': serializer.toJson<DateTime?>(lastSyncAttempt),
      'syncError': serializer.toJson<String?>(syncError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
    };
  }

  SupplierRow copyWith({
    String? id,
    String? businessId,
    String? name,
    Value<String?> contactName = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> address = const Value.absent(),
    Value<String?> taxId = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? isActive,
    bool? isDeleted,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? syncStatus,
    Value<DateTime?> lastSyncAttempt = const Value.absent(),
    Value<String?> syncError = const Value.absent(),
    DateTime? createdAt,
    DateTime? localUpdatedAt,
  }) => SupplierRow(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    name: name ?? this.name,
    contactName: contactName.present ? contactName.value : this.contactName,
    phone: phone.present ? phone.value : this.phone,
    email: email.present ? email.value : this.email,
    address: address.present ? address.value : this.address,
    taxId: taxId.present ? taxId.value : this.taxId,
    notes: notes.present ? notes.value : this.notes,
    isActive: isActive ?? this.isActive,
    isDeleted: isDeleted ?? this.isDeleted,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncAttempt: lastSyncAttempt.present
        ? lastSyncAttempt.value
        : this.lastSyncAttempt,
    syncError: syncError.present ? syncError.value : this.syncError,
    createdAt: createdAt ?? this.createdAt,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
  );
  SupplierRow copyWithCompanion(SuppliersTableCompanion data) {
    return SupplierRow(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      contactName: data.contactName.present
          ? data.contactName.value
          : this.contactName,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      address: data.address.present ? data.address.value : this.address,
      taxId: data.taxId.present ? data.taxId.value : this.taxId,
      notes: data.notes.present ? data.notes.value : this.notes,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastSyncAttempt: data.lastSyncAttempt.present
          ? data.lastSyncAttempt.value
          : this.lastSyncAttempt,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SupplierRow(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('contactName: $contactName, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('taxId: $taxId, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError, ')
          ..write('createdAt: $createdAt, ')
          ..write('localUpdatedAt: $localUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    name,
    contactName,
    phone,
    email,
    address,
    taxId,
    notes,
    isActive,
    isDeleted,
    deletedAt,
    syncStatus,
    lastSyncAttempt,
    syncError,
    createdAt,
    localUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SupplierRow &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.contactName == this.contactName &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.address == this.address &&
          other.taxId == this.taxId &&
          other.notes == this.notes &&
          other.isActive == this.isActive &&
          other.isDeleted == this.isDeleted &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncAttempt == this.lastSyncAttempt &&
          other.syncError == this.syncError &&
          other.createdAt == this.createdAt &&
          other.localUpdatedAt == this.localUpdatedAt);
}

class SuppliersTableCompanion extends UpdateCompanion<SupplierRow> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> name;
  final Value<String?> contactName;
  final Value<String?> phone;
  final Value<String?> email;
  final Value<String?> address;
  final Value<String?> taxId;
  final Value<String?> notes;
  final Value<bool> isActive;
  final Value<bool> isDeleted;
  final Value<DateTime?> deletedAt;
  final Value<int> syncStatus;
  final Value<DateTime?> lastSyncAttempt;
  final Value<String?> syncError;
  final Value<DateTime> createdAt;
  final Value<DateTime> localUpdatedAt;
  final Value<int> rowid;
  const SuppliersTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.contactName = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.taxId = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SuppliersTableCompanion.insert({
    required String id,
    required String businessId,
    required String name,
    this.contactName = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.taxId = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       name = Value(name);
  static Insertable<SupplierRow> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<String>? contactName,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? address,
    Expression<String>? taxId,
    Expression<String>? notes,
    Expression<bool>? isActive,
    Expression<bool>? isDeleted,
    Expression<DateTime>? deletedAt,
    Expression<int>? syncStatus,
    Expression<DateTime>? lastSyncAttempt,
    Expression<String>? syncError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? localUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (contactName != null) 'contact_name': contactName,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (taxId != null) 'tax_id': taxId,
      if (notes != null) 'notes': notes,
      if (isActive != null) 'is_active': isActive,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncAttempt != null) 'last_sync_attempt': lastSyncAttempt,
      if (syncError != null) 'sync_error': syncError,
      if (createdAt != null) 'created_at': createdAt,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SuppliersTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? name,
    Value<String?>? contactName,
    Value<String?>? phone,
    Value<String?>? email,
    Value<String?>? address,
    Value<String?>? taxId,
    Value<String?>? notes,
    Value<bool>? isActive,
    Value<bool>? isDeleted,
    Value<DateTime?>? deletedAt,
    Value<int>? syncStatus,
    Value<DateTime?>? lastSyncAttempt,
    Value<String?>? syncError,
    Value<DateTime>? createdAt,
    Value<DateTime>? localUpdatedAt,
    Value<int>? rowid,
  }) {
    return SuppliersTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      contactName: contactName ?? this.contactName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      taxId: taxId ?? this.taxId,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      syncError: syncError ?? this.syncError,
      createdAt: createdAt ?? this.createdAt,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (contactName.present) {
      map['contact_name'] = Variable<String>(contactName.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (taxId.present) {
      map['tax_id'] = Variable<String>(taxId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (lastSyncAttempt.present) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SuppliersTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('contactName: $contactName, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('taxId: $taxId, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError, ')
          ..write('createdAt: $createdAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PurchaseOrdersTableTable extends PurchaseOrdersTable
    with TableInfo<$PurchaseOrdersTableTable, PurchaseOrderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PurchaseOrdersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _supplierIdMeta = const VerificationMeta(
    'supplierId',
  );
  @override
  late final GeneratedColumn<String> supplierId = GeneratedColumn<String>(
    'supplier_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _supplierNameMeta = const VerificationMeta(
    'supplierName',
  );
  @override
  late final GeneratedColumn<String> supplierName = GeneratedColumn<String>(
    'supplier_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _poNumberMeta = const VerificationMeta(
    'poNumber',
  );
  @override
  late final GeneratedColumn<String> poNumber = GeneratedColumn<String>(
    'po_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expectedDeliveryMeta = const VerificationMeta(
    'expectedDelivery',
  );
  @override
  late final GeneratedColumn<DateTime> expectedDelivery =
      GeneratedColumn<DateTime>(
        'expected_delivery',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _createdByIdMeta = const VerificationMeta(
    'createdById',
  );
  @override
  late final GeneratedColumn<String> createdById = GeneratedColumn<String>(
    'created_by_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByNameMeta = const VerificationMeta(
    'createdByName',
  );
  @override
  late final GeneratedColumn<String> createdByName = GeneratedColumn<String>(
    'created_by_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _submittedAtMeta = const VerificationMeta(
    'submittedAt',
  );
  @override
  late final GeneratedColumn<DateTime> submittedAt = GeneratedColumn<DateTime>(
    'submitted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _approvedAtMeta = const VerificationMeta(
    'approvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> approvedAt = GeneratedColumn<DateTime>(
    'approved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _approvedByIdMeta = const VerificationMeta(
    'approvedById',
  );
  @override
  late final GeneratedColumn<String> approvedById = GeneratedColumn<String>(
    'approved_by_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _approvedByNameMeta = const VerificationMeta(
    'approvedByName',
  );
  @override
  late final GeneratedColumn<String> approvedByName = GeneratedColumn<String>(
    'approved_by_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncAttemptMeta = const VerificationMeta(
    'lastSyncAttempt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAttempt =
      GeneratedColumn<DateTime>(
        'last_sync_attempt',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    branchId,
    supplierId,
    supplierName,
    status,
    poNumber,
    notes,
    expectedDelivery,
    totalAmount,
    createdById,
    createdByName,
    submittedAt,
    approvedAt,
    approvedById,
    approvedByName,
    isDeleted,
    deletedAt,
    syncStatus,
    lastSyncAttempt,
    syncError,
    createdAt,
    localUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchase_orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<PurchaseOrderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    }
    if (data.containsKey('supplier_id')) {
      context.handle(
        _supplierIdMeta,
        supplierId.isAcceptableOrUnknown(data['supplier_id']!, _supplierIdMeta),
      );
    }
    if (data.containsKey('supplier_name')) {
      context.handle(
        _supplierNameMeta,
        supplierName.isAcceptableOrUnknown(
          data['supplier_name']!,
          _supplierNameMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('po_number')) {
      context.handle(
        _poNumberMeta,
        poNumber.isAcceptableOrUnknown(data['po_number']!, _poNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_poNumberMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('expected_delivery')) {
      context.handle(
        _expectedDeliveryMeta,
        expectedDelivery.isAcceptableOrUnknown(
          data['expected_delivery']!,
          _expectedDeliveryMeta,
        ),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    }
    if (data.containsKey('created_by_id')) {
      context.handle(
        _createdByIdMeta,
        createdById.isAcceptableOrUnknown(
          data['created_by_id']!,
          _createdByIdMeta,
        ),
      );
    }
    if (data.containsKey('created_by_name')) {
      context.handle(
        _createdByNameMeta,
        createdByName.isAcceptableOrUnknown(
          data['created_by_name']!,
          _createdByNameMeta,
        ),
      );
    }
    if (data.containsKey('submitted_at')) {
      context.handle(
        _submittedAtMeta,
        submittedAt.isAcceptableOrUnknown(
          data['submitted_at']!,
          _submittedAtMeta,
        ),
      );
    }
    if (data.containsKey('approved_at')) {
      context.handle(
        _approvedAtMeta,
        approvedAt.isAcceptableOrUnknown(data['approved_at']!, _approvedAtMeta),
      );
    }
    if (data.containsKey('approved_by_id')) {
      context.handle(
        _approvedByIdMeta,
        approvedById.isAcceptableOrUnknown(
          data['approved_by_id']!,
          _approvedByIdMeta,
        ),
      );
    }
    if (data.containsKey('approved_by_name')) {
      context.handle(
        _approvedByNameMeta,
        approvedByName.isAcceptableOrUnknown(
          data['approved_by_name']!,
          _approvedByNameMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('last_sync_attempt')) {
      context.handle(
        _lastSyncAttemptMeta,
        lastSyncAttempt.isAcceptableOrUnknown(
          data['last_sync_attempt']!,
          _lastSyncAttemptMeta,
        ),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PurchaseOrderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PurchaseOrderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      ),
      supplierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier_id'],
      ),
      supplierName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier_name'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      poNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}po_number'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      expectedDelivery: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expected_delivery'],
      ),
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      createdById: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by_id'],
      ),
      createdByName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by_name'],
      ),
      submittedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}submitted_at'],
      ),
      approvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}approved_at'],
      ),
      approvedById: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approved_by_id'],
      ),
      approvedByName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approved_by_name'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      lastSyncAttempt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_attempt'],
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
    );
  }

  @override
  $PurchaseOrdersTableTable createAlias(String alias) {
    return $PurchaseOrdersTableTable(attachedDatabase, alias);
  }
}

class PurchaseOrderRow extends DataClass
    implements Insertable<PurchaseOrderRow> {
  final String id;
  final String businessId;
  final String? branchId;
  final String? supplierId;
  final String? supplierName;
  final String status;
  final String poNumber;
  final String? notes;
  final DateTime? expectedDelivery;
  final double totalAmount;
  final String? createdById;
  final String? createdByName;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final String? approvedById;
  final String? approvedByName;
  final bool isDeleted;
  final DateTime? deletedAt;
  final int syncStatus;
  final DateTime? lastSyncAttempt;
  final String? syncError;
  final DateTime createdAt;
  final DateTime localUpdatedAt;
  const PurchaseOrderRow({
    required this.id,
    required this.businessId,
    this.branchId,
    this.supplierId,
    this.supplierName,
    required this.status,
    required this.poNumber,
    this.notes,
    this.expectedDelivery,
    required this.totalAmount,
    this.createdById,
    this.createdByName,
    this.submittedAt,
    this.approvedAt,
    this.approvedById,
    this.approvedByName,
    required this.isDeleted,
    this.deletedAt,
    required this.syncStatus,
    this.lastSyncAttempt,
    this.syncError,
    required this.createdAt,
    required this.localUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    if (!nullToAbsent || branchId != null) {
      map['branch_id'] = Variable<String>(branchId);
    }
    if (!nullToAbsent || supplierId != null) {
      map['supplier_id'] = Variable<String>(supplierId);
    }
    if (!nullToAbsent || supplierName != null) {
      map['supplier_name'] = Variable<String>(supplierName);
    }
    map['status'] = Variable<String>(status);
    map['po_number'] = Variable<String>(poNumber);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || expectedDelivery != null) {
      map['expected_delivery'] = Variable<DateTime>(expectedDelivery);
    }
    map['total_amount'] = Variable<double>(totalAmount);
    if (!nullToAbsent || createdById != null) {
      map['created_by_id'] = Variable<String>(createdById);
    }
    if (!nullToAbsent || createdByName != null) {
      map['created_by_name'] = Variable<String>(createdByName);
    }
    if (!nullToAbsent || submittedAt != null) {
      map['submitted_at'] = Variable<DateTime>(submittedAt);
    }
    if (!nullToAbsent || approvedAt != null) {
      map['approved_at'] = Variable<DateTime>(approvedAt);
    }
    if (!nullToAbsent || approvedById != null) {
      map['approved_by_id'] = Variable<String>(approvedById);
    }
    if (!nullToAbsent || approvedByName != null) {
      map['approved_by_name'] = Variable<String>(approvedByName);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || lastSyncAttempt != null) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt);
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    return map;
  }

  PurchaseOrdersTableCompanion toCompanion(bool nullToAbsent) {
    return PurchaseOrdersTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      branchId: branchId == null && nullToAbsent
          ? const Value.absent()
          : Value(branchId),
      supplierId: supplierId == null && nullToAbsent
          ? const Value.absent()
          : Value(supplierId),
      supplierName: supplierName == null && nullToAbsent
          ? const Value.absent()
          : Value(supplierName),
      status: Value(status),
      poNumber: Value(poNumber),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      expectedDelivery: expectedDelivery == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedDelivery),
      totalAmount: Value(totalAmount),
      createdById: createdById == null && nullToAbsent
          ? const Value.absent()
          : Value(createdById),
      createdByName: createdByName == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByName),
      submittedAt: submittedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(submittedAt),
      approvedAt: approvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(approvedAt),
      approvedById: approvedById == null && nullToAbsent
          ? const Value.absent()
          : Value(approvedById),
      approvedByName: approvedByName == null && nullToAbsent
          ? const Value.absent()
          : Value(approvedByName),
      isDeleted: Value(isDeleted),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
      lastSyncAttempt: lastSyncAttempt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAttempt),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      createdAt: Value(createdAt),
      localUpdatedAt: Value(localUpdatedAt),
    );
  }

  factory PurchaseOrderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PurchaseOrderRow(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      branchId: serializer.fromJson<String?>(json['branchId']),
      supplierId: serializer.fromJson<String?>(json['supplierId']),
      supplierName: serializer.fromJson<String?>(json['supplierName']),
      status: serializer.fromJson<String>(json['status']),
      poNumber: serializer.fromJson<String>(json['poNumber']),
      notes: serializer.fromJson<String?>(json['notes']),
      expectedDelivery: serializer.fromJson<DateTime?>(
        json['expectedDelivery'],
      ),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      createdById: serializer.fromJson<String?>(json['createdById']),
      createdByName: serializer.fromJson<String?>(json['createdByName']),
      submittedAt: serializer.fromJson<DateTime?>(json['submittedAt']),
      approvedAt: serializer.fromJson<DateTime?>(json['approvedAt']),
      approvedById: serializer.fromJson<String?>(json['approvedById']),
      approvedByName: serializer.fromJson<String?>(json['approvedByName']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      lastSyncAttempt: serializer.fromJson<DateTime?>(json['lastSyncAttempt']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'branchId': serializer.toJson<String?>(branchId),
      'supplierId': serializer.toJson<String?>(supplierId),
      'supplierName': serializer.toJson<String?>(supplierName),
      'status': serializer.toJson<String>(status),
      'poNumber': serializer.toJson<String>(poNumber),
      'notes': serializer.toJson<String?>(notes),
      'expectedDelivery': serializer.toJson<DateTime?>(expectedDelivery),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'createdById': serializer.toJson<String?>(createdById),
      'createdByName': serializer.toJson<String?>(createdByName),
      'submittedAt': serializer.toJson<DateTime?>(submittedAt),
      'approvedAt': serializer.toJson<DateTime?>(approvedAt),
      'approvedById': serializer.toJson<String?>(approvedById),
      'approvedByName': serializer.toJson<String?>(approvedByName),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'lastSyncAttempt': serializer.toJson<DateTime?>(lastSyncAttempt),
      'syncError': serializer.toJson<String?>(syncError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
    };
  }

  PurchaseOrderRow copyWith({
    String? id,
    String? businessId,
    Value<String?> branchId = const Value.absent(),
    Value<String?> supplierId = const Value.absent(),
    Value<String?> supplierName = const Value.absent(),
    String? status,
    String? poNumber,
    Value<String?> notes = const Value.absent(),
    Value<DateTime?> expectedDelivery = const Value.absent(),
    double? totalAmount,
    Value<String?> createdById = const Value.absent(),
    Value<String?> createdByName = const Value.absent(),
    Value<DateTime?> submittedAt = const Value.absent(),
    Value<DateTime?> approvedAt = const Value.absent(),
    Value<String?> approvedById = const Value.absent(),
    Value<String?> approvedByName = const Value.absent(),
    bool? isDeleted,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? syncStatus,
    Value<DateTime?> lastSyncAttempt = const Value.absent(),
    Value<String?> syncError = const Value.absent(),
    DateTime? createdAt,
    DateTime? localUpdatedAt,
  }) => PurchaseOrderRow(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    branchId: branchId.present ? branchId.value : this.branchId,
    supplierId: supplierId.present ? supplierId.value : this.supplierId,
    supplierName: supplierName.present ? supplierName.value : this.supplierName,
    status: status ?? this.status,
    poNumber: poNumber ?? this.poNumber,
    notes: notes.present ? notes.value : this.notes,
    expectedDelivery: expectedDelivery.present
        ? expectedDelivery.value
        : this.expectedDelivery,
    totalAmount: totalAmount ?? this.totalAmount,
    createdById: createdById.present ? createdById.value : this.createdById,
    createdByName: createdByName.present
        ? createdByName.value
        : this.createdByName,
    submittedAt: submittedAt.present ? submittedAt.value : this.submittedAt,
    approvedAt: approvedAt.present ? approvedAt.value : this.approvedAt,
    approvedById: approvedById.present ? approvedById.value : this.approvedById,
    approvedByName: approvedByName.present
        ? approvedByName.value
        : this.approvedByName,
    isDeleted: isDeleted ?? this.isDeleted,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncAttempt: lastSyncAttempt.present
        ? lastSyncAttempt.value
        : this.lastSyncAttempt,
    syncError: syncError.present ? syncError.value : this.syncError,
    createdAt: createdAt ?? this.createdAt,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
  );
  PurchaseOrderRow copyWithCompanion(PurchaseOrdersTableCompanion data) {
    return PurchaseOrderRow(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      supplierId: data.supplierId.present
          ? data.supplierId.value
          : this.supplierId,
      supplierName: data.supplierName.present
          ? data.supplierName.value
          : this.supplierName,
      status: data.status.present ? data.status.value : this.status,
      poNumber: data.poNumber.present ? data.poNumber.value : this.poNumber,
      notes: data.notes.present ? data.notes.value : this.notes,
      expectedDelivery: data.expectedDelivery.present
          ? data.expectedDelivery.value
          : this.expectedDelivery,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      createdById: data.createdById.present
          ? data.createdById.value
          : this.createdById,
      createdByName: data.createdByName.present
          ? data.createdByName.value
          : this.createdByName,
      submittedAt: data.submittedAt.present
          ? data.submittedAt.value
          : this.submittedAt,
      approvedAt: data.approvedAt.present
          ? data.approvedAt.value
          : this.approvedAt,
      approvedById: data.approvedById.present
          ? data.approvedById.value
          : this.approvedById,
      approvedByName: data.approvedByName.present
          ? data.approvedByName.value
          : this.approvedByName,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastSyncAttempt: data.lastSyncAttempt.present
          ? data.lastSyncAttempt.value
          : this.lastSyncAttempt,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseOrderRow(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('branchId: $branchId, ')
          ..write('supplierId: $supplierId, ')
          ..write('supplierName: $supplierName, ')
          ..write('status: $status, ')
          ..write('poNumber: $poNumber, ')
          ..write('notes: $notes, ')
          ..write('expectedDelivery: $expectedDelivery, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('createdById: $createdById, ')
          ..write('createdByName: $createdByName, ')
          ..write('submittedAt: $submittedAt, ')
          ..write('approvedAt: $approvedAt, ')
          ..write('approvedById: $approvedById, ')
          ..write('approvedByName: $approvedByName, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError, ')
          ..write('createdAt: $createdAt, ')
          ..write('localUpdatedAt: $localUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    businessId,
    branchId,
    supplierId,
    supplierName,
    status,
    poNumber,
    notes,
    expectedDelivery,
    totalAmount,
    createdById,
    createdByName,
    submittedAt,
    approvedAt,
    approvedById,
    approvedByName,
    isDeleted,
    deletedAt,
    syncStatus,
    lastSyncAttempt,
    syncError,
    createdAt,
    localUpdatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PurchaseOrderRow &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.branchId == this.branchId &&
          other.supplierId == this.supplierId &&
          other.supplierName == this.supplierName &&
          other.status == this.status &&
          other.poNumber == this.poNumber &&
          other.notes == this.notes &&
          other.expectedDelivery == this.expectedDelivery &&
          other.totalAmount == this.totalAmount &&
          other.createdById == this.createdById &&
          other.createdByName == this.createdByName &&
          other.submittedAt == this.submittedAt &&
          other.approvedAt == this.approvedAt &&
          other.approvedById == this.approvedById &&
          other.approvedByName == this.approvedByName &&
          other.isDeleted == this.isDeleted &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncAttempt == this.lastSyncAttempt &&
          other.syncError == this.syncError &&
          other.createdAt == this.createdAt &&
          other.localUpdatedAt == this.localUpdatedAt);
}

class PurchaseOrdersTableCompanion extends UpdateCompanion<PurchaseOrderRow> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String?> branchId;
  final Value<String?> supplierId;
  final Value<String?> supplierName;
  final Value<String> status;
  final Value<String> poNumber;
  final Value<String?> notes;
  final Value<DateTime?> expectedDelivery;
  final Value<double> totalAmount;
  final Value<String?> createdById;
  final Value<String?> createdByName;
  final Value<DateTime?> submittedAt;
  final Value<DateTime?> approvedAt;
  final Value<String?> approvedById;
  final Value<String?> approvedByName;
  final Value<bool> isDeleted;
  final Value<DateTime?> deletedAt;
  final Value<int> syncStatus;
  final Value<DateTime?> lastSyncAttempt;
  final Value<String?> syncError;
  final Value<DateTime> createdAt;
  final Value<DateTime> localUpdatedAt;
  final Value<int> rowid;
  const PurchaseOrdersTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.supplierId = const Value.absent(),
    this.supplierName = const Value.absent(),
    this.status = const Value.absent(),
    this.poNumber = const Value.absent(),
    this.notes = const Value.absent(),
    this.expectedDelivery = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.createdById = const Value.absent(),
    this.createdByName = const Value.absent(),
    this.submittedAt = const Value.absent(),
    this.approvedAt = const Value.absent(),
    this.approvedById = const Value.absent(),
    this.approvedByName = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PurchaseOrdersTableCompanion.insert({
    required String id,
    required String businessId,
    this.branchId = const Value.absent(),
    this.supplierId = const Value.absent(),
    this.supplierName = const Value.absent(),
    this.status = const Value.absent(),
    required String poNumber,
    this.notes = const Value.absent(),
    this.expectedDelivery = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.createdById = const Value.absent(),
    this.createdByName = const Value.absent(),
    this.submittedAt = const Value.absent(),
    this.approvedAt = const Value.absent(),
    this.approvedById = const Value.absent(),
    this.approvedByName = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       poNumber = Value(poNumber);
  static Insertable<PurchaseOrderRow> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? branchId,
    Expression<String>? supplierId,
    Expression<String>? supplierName,
    Expression<String>? status,
    Expression<String>? poNumber,
    Expression<String>? notes,
    Expression<DateTime>? expectedDelivery,
    Expression<double>? totalAmount,
    Expression<String>? createdById,
    Expression<String>? createdByName,
    Expression<DateTime>? submittedAt,
    Expression<DateTime>? approvedAt,
    Expression<String>? approvedById,
    Expression<String>? approvedByName,
    Expression<bool>? isDeleted,
    Expression<DateTime>? deletedAt,
    Expression<int>? syncStatus,
    Expression<DateTime>? lastSyncAttempt,
    Expression<String>? syncError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? localUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (branchId != null) 'branch_id': branchId,
      if (supplierId != null) 'supplier_id': supplierId,
      if (supplierName != null) 'supplier_name': supplierName,
      if (status != null) 'status': status,
      if (poNumber != null) 'po_number': poNumber,
      if (notes != null) 'notes': notes,
      if (expectedDelivery != null) 'expected_delivery': expectedDelivery,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (createdById != null) 'created_by_id': createdById,
      if (createdByName != null) 'created_by_name': createdByName,
      if (submittedAt != null) 'submitted_at': submittedAt,
      if (approvedAt != null) 'approved_at': approvedAt,
      if (approvedById != null) 'approved_by_id': approvedById,
      if (approvedByName != null) 'approved_by_name': approvedByName,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncAttempt != null) 'last_sync_attempt': lastSyncAttempt,
      if (syncError != null) 'sync_error': syncError,
      if (createdAt != null) 'created_at': createdAt,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PurchaseOrdersTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String?>? branchId,
    Value<String?>? supplierId,
    Value<String?>? supplierName,
    Value<String>? status,
    Value<String>? poNumber,
    Value<String?>? notes,
    Value<DateTime?>? expectedDelivery,
    Value<double>? totalAmount,
    Value<String?>? createdById,
    Value<String?>? createdByName,
    Value<DateTime?>? submittedAt,
    Value<DateTime?>? approvedAt,
    Value<String?>? approvedById,
    Value<String?>? approvedByName,
    Value<bool>? isDeleted,
    Value<DateTime?>? deletedAt,
    Value<int>? syncStatus,
    Value<DateTime?>? lastSyncAttempt,
    Value<String?>? syncError,
    Value<DateTime>? createdAt,
    Value<DateTime>? localUpdatedAt,
    Value<int>? rowid,
  }) {
    return PurchaseOrdersTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      branchId: branchId ?? this.branchId,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      status: status ?? this.status,
      poNumber: poNumber ?? this.poNumber,
      notes: notes ?? this.notes,
      expectedDelivery: expectedDelivery ?? this.expectedDelivery,
      totalAmount: totalAmount ?? this.totalAmount,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
      submittedAt: submittedAt ?? this.submittedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedById: approvedById ?? this.approvedById,
      approvedByName: approvedByName ?? this.approvedByName,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      syncError: syncError ?? this.syncError,
      createdAt: createdAt ?? this.createdAt,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (supplierId.present) {
      map['supplier_id'] = Variable<String>(supplierId.value);
    }
    if (supplierName.present) {
      map['supplier_name'] = Variable<String>(supplierName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (poNumber.present) {
      map['po_number'] = Variable<String>(poNumber.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (expectedDelivery.present) {
      map['expected_delivery'] = Variable<DateTime>(expectedDelivery.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (createdById.present) {
      map['created_by_id'] = Variable<String>(createdById.value);
    }
    if (createdByName.present) {
      map['created_by_name'] = Variable<String>(createdByName.value);
    }
    if (submittedAt.present) {
      map['submitted_at'] = Variable<DateTime>(submittedAt.value);
    }
    if (approvedAt.present) {
      map['approved_at'] = Variable<DateTime>(approvedAt.value);
    }
    if (approvedById.present) {
      map['approved_by_id'] = Variable<String>(approvedById.value);
    }
    if (approvedByName.present) {
      map['approved_by_name'] = Variable<String>(approvedByName.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (lastSyncAttempt.present) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseOrdersTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('branchId: $branchId, ')
          ..write('supplierId: $supplierId, ')
          ..write('supplierName: $supplierName, ')
          ..write('status: $status, ')
          ..write('poNumber: $poNumber, ')
          ..write('notes: $notes, ')
          ..write('expectedDelivery: $expectedDelivery, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('createdById: $createdById, ')
          ..write('createdByName: $createdByName, ')
          ..write('submittedAt: $submittedAt, ')
          ..write('approvedAt: $approvedAt, ')
          ..write('approvedById: $approvedById, ')
          ..write('approvedByName: $approvedByName, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError, ')
          ..write('createdAt: $createdAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PurchaseOrderLinesTableTable extends PurchaseOrderLinesTable
    with TableInfo<$PurchaseOrderLinesTableTable, PurchaseOrderLineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PurchaseOrderLinesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purchaseOrderIdMeta = const VerificationMeta(
    'purchaseOrderId',
  );
  @override
  late final GeneratedColumn<String> purchaseOrderId = GeneratedColumn<String>(
    'purchase_order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variantIdMeta = const VerificationMeta(
    'variantId',
  );
  @override
  late final GeneratedColumn<String> variantId = GeneratedColumn<String>(
    'variant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variantNameMeta = const VerificationMeta(
    'variantName',
  );
  @override
  late final GeneratedColumn<String> variantName = GeneratedColumn<String>(
    'variant_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityOrderedMeta = const VerificationMeta(
    'quantityOrdered',
  );
  @override
  late final GeneratedColumn<double> quantityOrdered = GeneratedColumn<double>(
    'quantity_ordered',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _quantityReceivedMeta = const VerificationMeta(
    'quantityReceived',
  );
  @override
  late final GeneratedColumn<double> quantityReceived = GeneratedColumn<double>(
    'quantity_received',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _unitCostMeta = const VerificationMeta(
    'unitCost',
  );
  @override
  late final GeneratedColumn<double> unitCost = GeneratedColumn<double>(
    'unit_cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    purchaseOrderId,
    businessId,
    productId,
    variantId,
    productName,
    variantName,
    sku,
    quantityOrdered,
    quantityReceived,
    unitCost,
    isDeleted,
    syncStatus,
    createdAt,
    localUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchase_order_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<PurchaseOrderLineRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('purchase_order_id')) {
      context.handle(
        _purchaseOrderIdMeta,
        purchaseOrderId.isAcceptableOrUnknown(
          data['purchase_order_id']!,
          _purchaseOrderIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purchaseOrderIdMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('variant_id')) {
      context.handle(
        _variantIdMeta,
        variantId.isAcceptableOrUnknown(data['variant_id']!, _variantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_variantIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('variant_name')) {
      context.handle(
        _variantNameMeta,
        variantName.isAcceptableOrUnknown(
          data['variant_name']!,
          _variantNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_variantNameMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    }
    if (data.containsKey('quantity_ordered')) {
      context.handle(
        _quantityOrderedMeta,
        quantityOrdered.isAcceptableOrUnknown(
          data['quantity_ordered']!,
          _quantityOrderedMeta,
        ),
      );
    }
    if (data.containsKey('quantity_received')) {
      context.handle(
        _quantityReceivedMeta,
        quantityReceived.isAcceptableOrUnknown(
          data['quantity_received']!,
          _quantityReceivedMeta,
        ),
      );
    }
    if (data.containsKey('unit_cost')) {
      context.handle(
        _unitCostMeta,
        unitCost.isAcceptableOrUnknown(data['unit_cost']!, _unitCostMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PurchaseOrderLineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PurchaseOrderLineRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      purchaseOrderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_order_id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      variantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_id'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      variantName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_name'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      ),
      quantityOrdered: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity_ordered'],
      )!,
      quantityReceived: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity_received'],
      )!,
      unitCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_cost'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
    );
  }

  @override
  $PurchaseOrderLinesTableTable createAlias(String alias) {
    return $PurchaseOrderLinesTableTable(attachedDatabase, alias);
  }
}

class PurchaseOrderLineRow extends DataClass
    implements Insertable<PurchaseOrderLineRow> {
  final String id;
  final String purchaseOrderId;
  final String businessId;
  final String productId;
  final String variantId;
  final String productName;
  final String variantName;
  final String? sku;
  final double quantityOrdered;
  final double quantityReceived;
  final double unitCost;
  final bool isDeleted;
  final int syncStatus;
  final DateTime createdAt;
  final DateTime localUpdatedAt;
  const PurchaseOrderLineRow({
    required this.id,
    required this.purchaseOrderId,
    required this.businessId,
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.variantName,
    this.sku,
    required this.quantityOrdered,
    required this.quantityReceived,
    required this.unitCost,
    required this.isDeleted,
    required this.syncStatus,
    required this.createdAt,
    required this.localUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['purchase_order_id'] = Variable<String>(purchaseOrderId);
    map['business_id'] = Variable<String>(businessId);
    map['product_id'] = Variable<String>(productId);
    map['variant_id'] = Variable<String>(variantId);
    map['product_name'] = Variable<String>(productName);
    map['variant_name'] = Variable<String>(variantName);
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    map['quantity_ordered'] = Variable<double>(quantityOrdered);
    map['quantity_received'] = Variable<double>(quantityReceived);
    map['unit_cost'] = Variable<double>(unitCost);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['sync_status'] = Variable<int>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    return map;
  }

  PurchaseOrderLinesTableCompanion toCompanion(bool nullToAbsent) {
    return PurchaseOrderLinesTableCompanion(
      id: Value(id),
      purchaseOrderId: Value(purchaseOrderId),
      businessId: Value(businessId),
      productId: Value(productId),
      variantId: Value(variantId),
      productName: Value(productName),
      variantName: Value(variantName),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      quantityOrdered: Value(quantityOrdered),
      quantityReceived: Value(quantityReceived),
      unitCost: Value(unitCost),
      isDeleted: Value(isDeleted),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      localUpdatedAt: Value(localUpdatedAt),
    );
  }

  factory PurchaseOrderLineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PurchaseOrderLineRow(
      id: serializer.fromJson<String>(json['id']),
      purchaseOrderId: serializer.fromJson<String>(json['purchaseOrderId']),
      businessId: serializer.fromJson<String>(json['businessId']),
      productId: serializer.fromJson<String>(json['productId']),
      variantId: serializer.fromJson<String>(json['variantId']),
      productName: serializer.fromJson<String>(json['productName']),
      variantName: serializer.fromJson<String>(json['variantName']),
      sku: serializer.fromJson<String?>(json['sku']),
      quantityOrdered: serializer.fromJson<double>(json['quantityOrdered']),
      quantityReceived: serializer.fromJson<double>(json['quantityReceived']),
      unitCost: serializer.fromJson<double>(json['unitCost']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'purchaseOrderId': serializer.toJson<String>(purchaseOrderId),
      'businessId': serializer.toJson<String>(businessId),
      'productId': serializer.toJson<String>(productId),
      'variantId': serializer.toJson<String>(variantId),
      'productName': serializer.toJson<String>(productName),
      'variantName': serializer.toJson<String>(variantName),
      'sku': serializer.toJson<String?>(sku),
      'quantityOrdered': serializer.toJson<double>(quantityOrdered),
      'quantityReceived': serializer.toJson<double>(quantityReceived),
      'unitCost': serializer.toJson<double>(unitCost),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
    };
  }

  PurchaseOrderLineRow copyWith({
    String? id,
    String? purchaseOrderId,
    String? businessId,
    String? productId,
    String? variantId,
    String? productName,
    String? variantName,
    Value<String?> sku = const Value.absent(),
    double? quantityOrdered,
    double? quantityReceived,
    double? unitCost,
    bool? isDeleted,
    int? syncStatus,
    DateTime? createdAt,
    DateTime? localUpdatedAt,
  }) => PurchaseOrderLineRow(
    id: id ?? this.id,
    purchaseOrderId: purchaseOrderId ?? this.purchaseOrderId,
    businessId: businessId ?? this.businessId,
    productId: productId ?? this.productId,
    variantId: variantId ?? this.variantId,
    productName: productName ?? this.productName,
    variantName: variantName ?? this.variantName,
    sku: sku.present ? sku.value : this.sku,
    quantityOrdered: quantityOrdered ?? this.quantityOrdered,
    quantityReceived: quantityReceived ?? this.quantityReceived,
    unitCost: unitCost ?? this.unitCost,
    isDeleted: isDeleted ?? this.isDeleted,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
  );
  PurchaseOrderLineRow copyWithCompanion(
    PurchaseOrderLinesTableCompanion data,
  ) {
    return PurchaseOrderLineRow(
      id: data.id.present ? data.id.value : this.id,
      purchaseOrderId: data.purchaseOrderId.present
          ? data.purchaseOrderId.value
          : this.purchaseOrderId,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      productId: data.productId.present ? data.productId.value : this.productId,
      variantId: data.variantId.present ? data.variantId.value : this.variantId,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      variantName: data.variantName.present
          ? data.variantName.value
          : this.variantName,
      sku: data.sku.present ? data.sku.value : this.sku,
      quantityOrdered: data.quantityOrdered.present
          ? data.quantityOrdered.value
          : this.quantityOrdered,
      quantityReceived: data.quantityReceived.present
          ? data.quantityReceived.value
          : this.quantityReceived,
      unitCost: data.unitCost.present ? data.unitCost.value : this.unitCost,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseOrderLineRow(')
          ..write('id: $id, ')
          ..write('purchaseOrderId: $purchaseOrderId, ')
          ..write('businessId: $businessId, ')
          ..write('productId: $productId, ')
          ..write('variantId: $variantId, ')
          ..write('productName: $productName, ')
          ..write('variantName: $variantName, ')
          ..write('sku: $sku, ')
          ..write('quantityOrdered: $quantityOrdered, ')
          ..write('quantityReceived: $quantityReceived, ')
          ..write('unitCost: $unitCost, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('localUpdatedAt: $localUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    purchaseOrderId,
    businessId,
    productId,
    variantId,
    productName,
    variantName,
    sku,
    quantityOrdered,
    quantityReceived,
    unitCost,
    isDeleted,
    syncStatus,
    createdAt,
    localUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PurchaseOrderLineRow &&
          other.id == this.id &&
          other.purchaseOrderId == this.purchaseOrderId &&
          other.businessId == this.businessId &&
          other.productId == this.productId &&
          other.variantId == this.variantId &&
          other.productName == this.productName &&
          other.variantName == this.variantName &&
          other.sku == this.sku &&
          other.quantityOrdered == this.quantityOrdered &&
          other.quantityReceived == this.quantityReceived &&
          other.unitCost == this.unitCost &&
          other.isDeleted == this.isDeleted &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.localUpdatedAt == this.localUpdatedAt);
}

class PurchaseOrderLinesTableCompanion
    extends UpdateCompanion<PurchaseOrderLineRow> {
  final Value<String> id;
  final Value<String> purchaseOrderId;
  final Value<String> businessId;
  final Value<String> productId;
  final Value<String> variantId;
  final Value<String> productName;
  final Value<String> variantName;
  final Value<String?> sku;
  final Value<double> quantityOrdered;
  final Value<double> quantityReceived;
  final Value<double> unitCost;
  final Value<bool> isDeleted;
  final Value<int> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> localUpdatedAt;
  final Value<int> rowid;
  const PurchaseOrderLinesTableCompanion({
    this.id = const Value.absent(),
    this.purchaseOrderId = const Value.absent(),
    this.businessId = const Value.absent(),
    this.productId = const Value.absent(),
    this.variantId = const Value.absent(),
    this.productName = const Value.absent(),
    this.variantName = const Value.absent(),
    this.sku = const Value.absent(),
    this.quantityOrdered = const Value.absent(),
    this.quantityReceived = const Value.absent(),
    this.unitCost = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PurchaseOrderLinesTableCompanion.insert({
    required String id,
    required String purchaseOrderId,
    required String businessId,
    required String productId,
    required String variantId,
    required String productName,
    required String variantName,
    this.sku = const Value.absent(),
    this.quantityOrdered = const Value.absent(),
    this.quantityReceived = const Value.absent(),
    this.unitCost = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       purchaseOrderId = Value(purchaseOrderId),
       businessId = Value(businessId),
       productId = Value(productId),
       variantId = Value(variantId),
       productName = Value(productName),
       variantName = Value(variantName);
  static Insertable<PurchaseOrderLineRow> custom({
    Expression<String>? id,
    Expression<String>? purchaseOrderId,
    Expression<String>? businessId,
    Expression<String>? productId,
    Expression<String>? variantId,
    Expression<String>? productName,
    Expression<String>? variantName,
    Expression<String>? sku,
    Expression<double>? quantityOrdered,
    Expression<double>? quantityReceived,
    Expression<double>? unitCost,
    Expression<bool>? isDeleted,
    Expression<int>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? localUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (purchaseOrderId != null) 'purchase_order_id': purchaseOrderId,
      if (businessId != null) 'business_id': businessId,
      if (productId != null) 'product_id': productId,
      if (variantId != null) 'variant_id': variantId,
      if (productName != null) 'product_name': productName,
      if (variantName != null) 'variant_name': variantName,
      if (sku != null) 'sku': sku,
      if (quantityOrdered != null) 'quantity_ordered': quantityOrdered,
      if (quantityReceived != null) 'quantity_received': quantityReceived,
      if (unitCost != null) 'unit_cost': unitCost,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PurchaseOrderLinesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? purchaseOrderId,
    Value<String>? businessId,
    Value<String>? productId,
    Value<String>? variantId,
    Value<String>? productName,
    Value<String>? variantName,
    Value<String?>? sku,
    Value<double>? quantityOrdered,
    Value<double>? quantityReceived,
    Value<double>? unitCost,
    Value<bool>? isDeleted,
    Value<int>? syncStatus,
    Value<DateTime>? createdAt,
    Value<DateTime>? localUpdatedAt,
    Value<int>? rowid,
  }) {
    return PurchaseOrderLinesTableCompanion(
      id: id ?? this.id,
      purchaseOrderId: purchaseOrderId ?? this.purchaseOrderId,
      businessId: businessId ?? this.businessId,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      productName: productName ?? this.productName,
      variantName: variantName ?? this.variantName,
      sku: sku ?? this.sku,
      quantityOrdered: quantityOrdered ?? this.quantityOrdered,
      quantityReceived: quantityReceived ?? this.quantityReceived,
      unitCost: unitCost ?? this.unitCost,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (purchaseOrderId.present) {
      map['purchase_order_id'] = Variable<String>(purchaseOrderId.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (variantId.present) {
      map['variant_id'] = Variable<String>(variantId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (variantName.present) {
      map['variant_name'] = Variable<String>(variantName.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (quantityOrdered.present) {
      map['quantity_ordered'] = Variable<double>(quantityOrdered.value);
    }
    if (quantityReceived.present) {
      map['quantity_received'] = Variable<double>(quantityReceived.value);
    }
    if (unitCost.present) {
      map['unit_cost'] = Variable<double>(unitCost.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseOrderLinesTableCompanion(')
          ..write('id: $id, ')
          ..write('purchaseOrderId: $purchaseOrderId, ')
          ..write('businessId: $businessId, ')
          ..write('productId: $productId, ')
          ..write('variantId: $variantId, ')
          ..write('productName: $productName, ')
          ..write('variantName: $variantName, ')
          ..write('sku: $sku, ')
          ..write('quantityOrdered: $quantityOrdered, ')
          ..write('quantityReceived: $quantityReceived, ')
          ..write('unitCost: $unitCost, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipeLinesTableTable extends RecipeLinesTable
    with TableInfo<$RecipeLinesTableTable, RecipeLineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeLinesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productVariantIdMeta = const VerificationMeta(
    'productVariantId',
  );
  @override
  late final GeneratedColumn<String> productVariantId = GeneratedColumn<String>(
    'product_variant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ingredientVariantIdMeta =
      const VerificationMeta('ingredientVariantId');
  @override
  late final GeneratedColumn<String> ingredientVariantId =
      GeneratedColumn<String>(
        'ingredient_variant_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _ingredientNameMeta = const VerificationMeta(
    'ingredientName',
  );
  @override
  late final GeneratedColumn<String> ingredientName = GeneratedColumn<String>(
    'ingredient_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncAttemptMeta = const VerificationMeta(
    'lastSyncAttempt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAttempt =
      GeneratedColumn<DateTime>(
        'last_sync_attempt',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    productVariantId,
    ingredientVariantId,
    ingredientName,
    quantity,
    unit,
    isDeleted,
    deletedAt,
    syncStatus,
    lastSyncAttempt,
    syncError,
    createdAt,
    localUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeLineRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('product_variant_id')) {
      context.handle(
        _productVariantIdMeta,
        productVariantId.isAcceptableOrUnknown(
          data['product_variant_id']!,
          _productVariantIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productVariantIdMeta);
    }
    if (data.containsKey('ingredient_variant_id')) {
      context.handle(
        _ingredientVariantIdMeta,
        ingredientVariantId.isAcceptableOrUnknown(
          data['ingredient_variant_id']!,
          _ingredientVariantIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ingredientVariantIdMeta);
    }
    if (data.containsKey('ingredient_name')) {
      context.handle(
        _ingredientNameMeta,
        ingredientName.isAcceptableOrUnknown(
          data['ingredient_name']!,
          _ingredientNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ingredientNameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('last_sync_attempt')) {
      context.handle(
        _lastSyncAttemptMeta,
        lastSyncAttempt.isAcceptableOrUnknown(
          data['last_sync_attempt']!,
          _lastSyncAttemptMeta,
        ),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecipeLineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeLineRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      productVariantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_variant_id'],
      )!,
      ingredientVariantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ingredient_variant_id'],
      )!,
      ingredientName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ingredient_name'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      lastSyncAttempt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_attempt'],
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
    );
  }

  @override
  $RecipeLinesTableTable createAlias(String alias) {
    return $RecipeLinesTableTable(attachedDatabase, alias);
  }
}

class RecipeLineRow extends DataClass implements Insertable<RecipeLineRow> {
  final String id;
  final String businessId;

  /// The sellable variant that owns this recipe line.
  final String productVariantId;

  /// The consumed ingredient's variant (products.type='ingredient').
  final String ingredientVariantId;
  final String ingredientName;

  /// Amount consumed per 1 unit sold, in the ingredient's own stock unit.
  final double quantity;

  /// Unit of measure, denormalized from the ingredient (g, kg, ml, L, pcs).
  final String? unit;
  final bool isDeleted;
  final DateTime? deletedAt;

  /// 0=pendingUpload, 1=pendingUpdate, 2=pendingDelete, 3=synced, 4=failed
  final int syncStatus;
  final DateTime? lastSyncAttempt;
  final String? syncError;
  final DateTime createdAt;
  final DateTime localUpdatedAt;
  const RecipeLineRow({
    required this.id,
    required this.businessId,
    required this.productVariantId,
    required this.ingredientVariantId,
    required this.ingredientName,
    required this.quantity,
    this.unit,
    required this.isDeleted,
    this.deletedAt,
    required this.syncStatus,
    this.lastSyncAttempt,
    this.syncError,
    required this.createdAt,
    required this.localUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['product_variant_id'] = Variable<String>(productVariantId);
    map['ingredient_variant_id'] = Variable<String>(ingredientVariantId);
    map['ingredient_name'] = Variable<String>(ingredientName);
    map['quantity'] = Variable<double>(quantity);
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || lastSyncAttempt != null) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt);
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    return map;
  }

  RecipeLinesTableCompanion toCompanion(bool nullToAbsent) {
    return RecipeLinesTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      productVariantId: Value(productVariantId),
      ingredientVariantId: Value(ingredientVariantId),
      ingredientName: Value(ingredientName),
      quantity: Value(quantity),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      isDeleted: Value(isDeleted),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
      lastSyncAttempt: lastSyncAttempt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAttempt),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      createdAt: Value(createdAt),
      localUpdatedAt: Value(localUpdatedAt),
    );
  }

  factory RecipeLineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeLineRow(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      productVariantId: serializer.fromJson<String>(json['productVariantId']),
      ingredientVariantId: serializer.fromJson<String>(
        json['ingredientVariantId'],
      ),
      ingredientName: serializer.fromJson<String>(json['ingredientName']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unit: serializer.fromJson<String?>(json['unit']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      lastSyncAttempt: serializer.fromJson<DateTime?>(json['lastSyncAttempt']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'productVariantId': serializer.toJson<String>(productVariantId),
      'ingredientVariantId': serializer.toJson<String>(ingredientVariantId),
      'ingredientName': serializer.toJson<String>(ingredientName),
      'quantity': serializer.toJson<double>(quantity),
      'unit': serializer.toJson<String?>(unit),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'lastSyncAttempt': serializer.toJson<DateTime?>(lastSyncAttempt),
      'syncError': serializer.toJson<String?>(syncError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
    };
  }

  RecipeLineRow copyWith({
    String? id,
    String? businessId,
    String? productVariantId,
    String? ingredientVariantId,
    String? ingredientName,
    double? quantity,
    Value<String?> unit = const Value.absent(),
    bool? isDeleted,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? syncStatus,
    Value<DateTime?> lastSyncAttempt = const Value.absent(),
    Value<String?> syncError = const Value.absent(),
    DateTime? createdAt,
    DateTime? localUpdatedAt,
  }) => RecipeLineRow(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    productVariantId: productVariantId ?? this.productVariantId,
    ingredientVariantId: ingredientVariantId ?? this.ingredientVariantId,
    ingredientName: ingredientName ?? this.ingredientName,
    quantity: quantity ?? this.quantity,
    unit: unit.present ? unit.value : this.unit,
    isDeleted: isDeleted ?? this.isDeleted,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncAttempt: lastSyncAttempt.present
        ? lastSyncAttempt.value
        : this.lastSyncAttempt,
    syncError: syncError.present ? syncError.value : this.syncError,
    createdAt: createdAt ?? this.createdAt,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
  );
  RecipeLineRow copyWithCompanion(RecipeLinesTableCompanion data) {
    return RecipeLineRow(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      productVariantId: data.productVariantId.present
          ? data.productVariantId.value
          : this.productVariantId,
      ingredientVariantId: data.ingredientVariantId.present
          ? data.ingredientVariantId.value
          : this.ingredientVariantId,
      ingredientName: data.ingredientName.present
          ? data.ingredientName.value
          : this.ingredientName,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lastSyncAttempt: data.lastSyncAttempt.present
          ? data.lastSyncAttempt.value
          : this.lastSyncAttempt,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeLineRow(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('productVariantId: $productVariantId, ')
          ..write('ingredientVariantId: $ingredientVariantId, ')
          ..write('ingredientName: $ingredientName, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError, ')
          ..write('createdAt: $createdAt, ')
          ..write('localUpdatedAt: $localUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    productVariantId,
    ingredientVariantId,
    ingredientName,
    quantity,
    unit,
    isDeleted,
    deletedAt,
    syncStatus,
    lastSyncAttempt,
    syncError,
    createdAt,
    localUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeLineRow &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.productVariantId == this.productVariantId &&
          other.ingredientVariantId == this.ingredientVariantId &&
          other.ingredientName == this.ingredientName &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.isDeleted == this.isDeleted &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncAttempt == this.lastSyncAttempt &&
          other.syncError == this.syncError &&
          other.createdAt == this.createdAt &&
          other.localUpdatedAt == this.localUpdatedAt);
}

class RecipeLinesTableCompanion extends UpdateCompanion<RecipeLineRow> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> productVariantId;
  final Value<String> ingredientVariantId;
  final Value<String> ingredientName;
  final Value<double> quantity;
  final Value<String?> unit;
  final Value<bool> isDeleted;
  final Value<DateTime?> deletedAt;
  final Value<int> syncStatus;
  final Value<DateTime?> lastSyncAttempt;
  final Value<String?> syncError;
  final Value<DateTime> createdAt;
  final Value<DateTime> localUpdatedAt;
  final Value<int> rowid;
  const RecipeLinesTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.productVariantId = const Value.absent(),
    this.ingredientVariantId = const Value.absent(),
    this.ingredientName = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipeLinesTableCompanion.insert({
    required String id,
    required String businessId,
    required String productVariantId,
    required String ingredientVariantId,
    required String ingredientName,
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       productVariantId = Value(productVariantId),
       ingredientVariantId = Value(ingredientVariantId),
       ingredientName = Value(ingredientName);
  static Insertable<RecipeLineRow> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? productVariantId,
    Expression<String>? ingredientVariantId,
    Expression<String>? ingredientName,
    Expression<double>? quantity,
    Expression<String>? unit,
    Expression<bool>? isDeleted,
    Expression<DateTime>? deletedAt,
    Expression<int>? syncStatus,
    Expression<DateTime>? lastSyncAttempt,
    Expression<String>? syncError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? localUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (productVariantId != null) 'product_variant_id': productVariantId,
      if (ingredientVariantId != null)
        'ingredient_variant_id': ingredientVariantId,
      if (ingredientName != null) 'ingredient_name': ingredientName,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lastSyncAttempt != null) 'last_sync_attempt': lastSyncAttempt,
      if (syncError != null) 'sync_error': syncError,
      if (createdAt != null) 'created_at': createdAt,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipeLinesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? productVariantId,
    Value<String>? ingredientVariantId,
    Value<String>? ingredientName,
    Value<double>? quantity,
    Value<String?>? unit,
    Value<bool>? isDeleted,
    Value<DateTime?>? deletedAt,
    Value<int>? syncStatus,
    Value<DateTime?>? lastSyncAttempt,
    Value<String?>? syncError,
    Value<DateTime>? createdAt,
    Value<DateTime>? localUpdatedAt,
    Value<int>? rowid,
  }) {
    return RecipeLinesTableCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      productVariantId: productVariantId ?? this.productVariantId,
      ingredientVariantId: ingredientVariantId ?? this.ingredientVariantId,
      ingredientName: ingredientName ?? this.ingredientName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      syncError: syncError ?? this.syncError,
      createdAt: createdAt ?? this.createdAt,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (productVariantId.present) {
      map['product_variant_id'] = Variable<String>(productVariantId.value);
    }
    if (ingredientVariantId.present) {
      map['ingredient_variant_id'] = Variable<String>(
        ingredientVariantId.value,
      );
    }
    if (ingredientName.present) {
      map['ingredient_name'] = Variable<String>(ingredientName.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (lastSyncAttempt.present) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeLinesTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('productVariantId: $productVariantId, ')
          ..write('ingredientVariantId: $ingredientVariantId, ')
          ..write('ingredientName: $ingredientName, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('syncError: $syncError, ')
          ..write('createdAt: $createdAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AuthContextTableTable authContextTable = $AuthContextTableTable(
    this,
  );
  late final $BusinessTemplatesTableTable businessTemplatesTable =
      $BusinessTemplatesTableTable(this);
  late final $BusinessesTableTable businessesTable = $BusinessesTableTable(
    this,
  );
  late final $BranchesTableTable branchesTable = $BranchesTableTable(this);
  late final $CategoriesTableTable categoriesTable = $CategoriesTableTable(
    this,
  );
  late final $ExpensesTableTable expensesTable = $ExpensesTableTable(this);
  late final $ProductsTableTable productsTable = $ProductsTableTable(this);
  late final $ProductVariantsTableTable productVariantsTable =
      $ProductVariantsTableTable(this);
  late final $TransactionsTableTable transactionsTable =
      $TransactionsTableTable(this);
  late final $TransactionItemsTableTable transactionItemsTable =
      $TransactionItemsTableTable(this);
  late final $DraftSalesTableTable draftSalesTable = $DraftSalesTableTable(
    this,
  );
  late final $DraftSaleItemsTableTable draftSaleItemsTable =
      $DraftSaleItemsTableTable(this);
  late final $InventoryLevelsTableTable inventoryLevelsTable =
      $InventoryLevelsTableTable(this);
  late final $StockLedgerTableTable stockLedgerTable = $StockLedgerTableTable(
    this,
  );
  late final $ReceiptSettingsTableTable receiptSettingsTable =
      $ReceiptSettingsTableTable(this);
  late final $AuditLogsTableTable auditLogsTable = $AuditLogsTableTable(this);
  late final $EmployeesTableTable employeesTable = $EmployeesTableTable(this);
  late final $EmployeePermissionsTableTable employeePermissionsTable =
      $EmployeePermissionsTableTable(this);
  late final $BusinessModulesTableTable businessModulesTable =
      $BusinessModulesTableTable(this);
  late final $SuppliersTableTable suppliersTable = $SuppliersTableTable(this);
  late final $PurchaseOrdersTableTable purchaseOrdersTable =
      $PurchaseOrdersTableTable(this);
  late final $PurchaseOrderLinesTableTable purchaseOrderLinesTable =
      $PurchaseOrderLinesTableTable(this);
  late final $RecipeLinesTableTable recipeLinesTable = $RecipeLinesTableTable(
    this,
  );
  late final AuthContextDao authContextDao = AuthContextDao(
    this as AppDatabase,
  );
  late final BusinessTemplatesDao businessTemplatesDao = BusinessTemplatesDao(
    this as AppDatabase,
  );
  late final BusinessesDao businessesDao = BusinessesDao(this as AppDatabase);
  late final BranchesDao branchesDao = BranchesDao(this as AppDatabase);
  late final CategoriesDao categoriesDao = CategoriesDao(this as AppDatabase);
  late final ExpensesDao expensesDao = ExpensesDao(this as AppDatabase);
  late final ProductsDao productsDao = ProductsDao(this as AppDatabase);
  late final ProductVariantsDao productVariantsDao = ProductVariantsDao(
    this as AppDatabase,
  );
  late final TransactionsDao transactionsDao = TransactionsDao(
    this as AppDatabase,
  );
  late final DraftSalesDao draftSalesDao = DraftSalesDao(this as AppDatabase);
  late final InventoryLevelsDao inventoryLevelsDao = InventoryLevelsDao(
    this as AppDatabase,
  );
  late final StockLedgerDao stockLedgerDao = StockLedgerDao(
    this as AppDatabase,
  );
  late final ReceiptSettingsDao receiptSettingsDao = ReceiptSettingsDao(
    this as AppDatabase,
  );
  late final AuditLogsDao auditLogsDao = AuditLogsDao(this as AppDatabase);
  late final EmployeesDao employeesDao = EmployeesDao(this as AppDatabase);
  late final EmployeePermissionsDao employeePermissionsDao =
      EmployeePermissionsDao(this as AppDatabase);
  late final BusinessModulesDao businessModulesDao = BusinessModulesDao(
    this as AppDatabase,
  );
  late final SuppliersDao suppliersDao = SuppliersDao(this as AppDatabase);
  late final PurchaseOrdersDao purchaseOrdersDao = PurchaseOrdersDao(
    this as AppDatabase,
  );
  late final PurchaseOrderLinesDao purchaseOrderLinesDao =
      PurchaseOrderLinesDao(this as AppDatabase);
  late final RecipeLinesDao recipeLinesDao = RecipeLinesDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    authContextTable,
    businessTemplatesTable,
    businessesTable,
    branchesTable,
    categoriesTable,
    expensesTable,
    productsTable,
    productVariantsTable,
    transactionsTable,
    transactionItemsTable,
    draftSalesTable,
    draftSaleItemsTable,
    inventoryLevelsTable,
    stockLedgerTable,
    receiptSettingsTable,
    auditLogsTable,
    employeesTable,
    employeePermissionsTable,
    businessModulesTable,
    suppliersTable,
    purchaseOrdersTable,
    purchaseOrderLinesTable,
    recipeLinesTable,
  ];
}

typedef $$AuthContextTableTableCreateCompanionBuilder =
    AuthContextTableCompanion Function({
      required String userId,
      Value<String?> email,
      Value<String?> fullName,
      Value<String?> avatarUrl,
      Value<String?> businessId,
      Value<String?> roleId,
      Value<String?> roleName,
      Value<String?> businessName,
      Value<String?> branchId,
      Value<String?> branchName,
      Value<String?> businessTemplateId,
      Value<String?> businessTemplateName,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });
typedef $$AuthContextTableTableUpdateCompanionBuilder =
    AuthContextTableCompanion Function({
      Value<String> userId,
      Value<String?> email,
      Value<String?> fullName,
      Value<String?> avatarUrl,
      Value<String?> businessId,
      Value<String?> roleId,
      Value<String?> roleName,
      Value<String?> businessName,
      Value<String?> branchId,
      Value<String?> branchName,
      Value<String?> businessTemplateId,
      Value<String?> businessTemplateName,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });

class $$AuthContextTableTableFilterComposer
    extends Composer<_$AppDatabase, $AuthContextTableTable> {
  $$AuthContextTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roleId => $composableBuilder(
    column: $table.roleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roleName => $composableBuilder(
    column: $table.roleName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchName => $composableBuilder(
    column: $table.branchName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessTemplateId => $composableBuilder(
    column: $table.businessTemplateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessTemplateName => $composableBuilder(
    column: $table.businessTemplateName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuthContextTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AuthContextTableTable> {
  $$AuthContextTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roleId => $composableBuilder(
    column: $table.roleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roleName => $composableBuilder(
    column: $table.roleName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchName => $composableBuilder(
    column: $table.branchName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessTemplateId => $composableBuilder(
    column: $table.businessTemplateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessTemplateName => $composableBuilder(
    column: $table.businessTemplateName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuthContextTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuthContextTableTable> {
  $$AuthContextTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get roleId =>
      $composableBuilder(column: $table.roleId, builder: (column) => column);

  GeneratedColumn<String> get roleName =>
      $composableBuilder(column: $table.roleName, builder: (column) => column);

  GeneratedColumn<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get branchName => $composableBuilder(
    column: $table.branchName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessTemplateId => $composableBuilder(
    column: $table.businessTemplateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessTemplateName => $composableBuilder(
    column: $table.businessTemplateName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );
}

class $$AuthContextTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuthContextTableTable,
          AuthContextTableData,
          $$AuthContextTableTableFilterComposer,
          $$AuthContextTableTableOrderingComposer,
          $$AuthContextTableTableAnnotationComposer,
          $$AuthContextTableTableCreateCompanionBuilder,
          $$AuthContextTableTableUpdateCompanionBuilder,
          (
            AuthContextTableData,
            BaseReferences<
              _$AppDatabase,
              $AuthContextTableTable,
              AuthContextTableData
            >,
          ),
          AuthContextTableData,
          PrefetchHooks Function()
        > {
  $$AuthContextTableTableTableManager(
    _$AppDatabase db,
    $AuthContextTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuthContextTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuthContextTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuthContextTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> fullName = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> businessId = const Value.absent(),
                Value<String?> roleId = const Value.absent(),
                Value<String?> roleName = const Value.absent(),
                Value<String?> businessName = const Value.absent(),
                Value<String?> branchId = const Value.absent(),
                Value<String?> branchName = const Value.absent(),
                Value<String?> businessTemplateId = const Value.absent(),
                Value<String?> businessTemplateName = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuthContextTableCompanion(
                userId: userId,
                email: email,
                fullName: fullName,
                avatarUrl: avatarUrl,
                businessId: businessId,
                roleId: roleId,
                roleName: roleName,
                businessName: businessName,
                branchId: branchId,
                branchName: branchName,
                businessTemplateId: businessTemplateId,
                businessTemplateName: businessTemplateName,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                Value<String?> email = const Value.absent(),
                Value<String?> fullName = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> businessId = const Value.absent(),
                Value<String?> roleId = const Value.absent(),
                Value<String?> roleName = const Value.absent(),
                Value<String?> businessName = const Value.absent(),
                Value<String?> branchId = const Value.absent(),
                Value<String?> branchName = const Value.absent(),
                Value<String?> businessTemplateId = const Value.absent(),
                Value<String?> businessTemplateName = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuthContextTableCompanion.insert(
                userId: userId,
                email: email,
                fullName: fullName,
                avatarUrl: avatarUrl,
                businessId: businessId,
                roleId: roleId,
                roleName: roleName,
                businessName: businessName,
                branchId: branchId,
                branchName: branchName,
                businessTemplateId: businessTemplateId,
                businessTemplateName: businessTemplateName,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuthContextTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuthContextTableTable,
      AuthContextTableData,
      $$AuthContextTableTableFilterComposer,
      $$AuthContextTableTableOrderingComposer,
      $$AuthContextTableTableAnnotationComposer,
      $$AuthContextTableTableCreateCompanionBuilder,
      $$AuthContextTableTableUpdateCompanionBuilder,
      (
        AuthContextTableData,
        BaseReferences<
          _$AppDatabase,
          $AuthContextTableTable,
          AuthContextTableData
        >,
      ),
      AuthContextTableData,
      PrefetchHooks Function()
    >;
typedef $$BusinessTemplatesTableTableCreateCompanionBuilder =
    BusinessTemplatesTableCompanion Function({
      required String id,
      Value<String> code,
      required String name,
      Value<int> version,
      Value<bool> isActive,
      Value<DateTime?> createdAt,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });
typedef $$BusinessTemplatesTableTableUpdateCompanionBuilder =
    BusinessTemplatesTableCompanion Function({
      Value<String> id,
      Value<String> code,
      Value<String> name,
      Value<int> version,
      Value<bool> isActive,
      Value<DateTime?> createdAt,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });

class $$BusinessTemplatesTableTableFilterComposer
    extends Composer<_$AppDatabase, $BusinessTemplatesTableTable> {
  $$BusinessTemplatesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BusinessTemplatesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $BusinessTemplatesTableTable> {
  $$BusinessTemplatesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BusinessTemplatesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $BusinessTemplatesTableTable> {
  $$BusinessTemplatesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );
}

class $$BusinessTemplatesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BusinessTemplatesTableTable,
          BusinessTemplatesTableData,
          $$BusinessTemplatesTableTableFilterComposer,
          $$BusinessTemplatesTableTableOrderingComposer,
          $$BusinessTemplatesTableTableAnnotationComposer,
          $$BusinessTemplatesTableTableCreateCompanionBuilder,
          $$BusinessTemplatesTableTableUpdateCompanionBuilder,
          (
            BusinessTemplatesTableData,
            BaseReferences<
              _$AppDatabase,
              $BusinessTemplatesTableTable,
              BusinessTemplatesTableData
            >,
          ),
          BusinessTemplatesTableData,
          PrefetchHooks Function()
        > {
  $$BusinessTemplatesTableTableTableManager(
    _$AppDatabase db,
    $BusinessTemplatesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BusinessTemplatesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$BusinessTemplatesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$BusinessTemplatesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BusinessTemplatesTableCompanion(
                id: id,
                code: code,
                name: name,
                version: version,
                isActive: isActive,
                createdAt: createdAt,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> code = const Value.absent(),
                required String name,
                Value<int> version = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BusinessTemplatesTableCompanion.insert(
                id: id,
                code: code,
                name: name,
                version: version,
                isActive: isActive,
                createdAt: createdAt,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BusinessTemplatesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BusinessTemplatesTableTable,
      BusinessTemplatesTableData,
      $$BusinessTemplatesTableTableFilterComposer,
      $$BusinessTemplatesTableTableOrderingComposer,
      $$BusinessTemplatesTableTableAnnotationComposer,
      $$BusinessTemplatesTableTableCreateCompanionBuilder,
      $$BusinessTemplatesTableTableUpdateCompanionBuilder,
      (
        BusinessTemplatesTableData,
        BaseReferences<
          _$AppDatabase,
          $BusinessTemplatesTableTable,
          BusinessTemplatesTableData
        >,
      ),
      BusinessTemplatesTableData,
      PrefetchHooks Function()
    >;
typedef $$BusinessesTableTableCreateCompanionBuilder =
    BusinessesTableCompanion Function({
      required String id,
      required String name,
      required String ownerId,
      required String templateId,
      required DateTime createdAt,
      Value<bool> isActive,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });
typedef $$BusinessesTableTableUpdateCompanionBuilder =
    BusinessesTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> ownerId,
      Value<String> templateId,
      Value<DateTime> createdAt,
      Value<bool> isActive,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });

class $$BusinessesTableTableFilterComposer
    extends Composer<_$AppDatabase, $BusinessesTableTable> {
  $$BusinessesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BusinessesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $BusinessesTableTable> {
  $$BusinessesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BusinessesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $BusinessesTableTable> {
  $$BusinessesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );
}

class $$BusinessesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BusinessesTableTable,
          BusinessesTableData,
          $$BusinessesTableTableFilterComposer,
          $$BusinessesTableTableOrderingComposer,
          $$BusinessesTableTableAnnotationComposer,
          $$BusinessesTableTableCreateCompanionBuilder,
          $$BusinessesTableTableUpdateCompanionBuilder,
          (
            BusinessesTableData,
            BaseReferences<
              _$AppDatabase,
              $BusinessesTableTable,
              BusinessesTableData
            >,
          ),
          BusinessesTableData,
          PrefetchHooks Function()
        > {
  $$BusinessesTableTableTableManager(
    _$AppDatabase db,
    $BusinessesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BusinessesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BusinessesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BusinessesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BusinessesTableCompanion(
                id: id,
                name: name,
                ownerId: ownerId,
                templateId: templateId,
                createdAt: createdAt,
                isActive: isActive,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String ownerId,
                required String templateId,
                required DateTime createdAt,
                Value<bool> isActive = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BusinessesTableCompanion.insert(
                id: id,
                name: name,
                ownerId: ownerId,
                templateId: templateId,
                createdAt: createdAt,
                isActive: isActive,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BusinessesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BusinessesTableTable,
      BusinessesTableData,
      $$BusinessesTableTableFilterComposer,
      $$BusinessesTableTableOrderingComposer,
      $$BusinessesTableTableAnnotationComposer,
      $$BusinessesTableTableCreateCompanionBuilder,
      $$BusinessesTableTableUpdateCompanionBuilder,
      (
        BusinessesTableData,
        BaseReferences<
          _$AppDatabase,
          $BusinessesTableTable,
          BusinessesTableData
        >,
      ),
      BusinessesTableData,
      PrefetchHooks Function()
    >;
typedef $$BranchesTableTableCreateCompanionBuilder =
    BranchesTableCompanion Function({
      required String id,
      required String businessId,
      required String name,
      Value<String?> location,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });
typedef $$BranchesTableTableUpdateCompanionBuilder =
    BranchesTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> name,
      Value<String?> location,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });

class $$BranchesTableTableFilterComposer
    extends Composer<_$AppDatabase, $BranchesTableTable> {
  $$BranchesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BranchesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $BranchesTableTable> {
  $$BranchesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BranchesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $BranchesTableTable> {
  $$BranchesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );
}

class $$BranchesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BranchesTableTable,
          BranchesTableData,
          $$BranchesTableTableFilterComposer,
          $$BranchesTableTableOrderingComposer,
          $$BranchesTableTableAnnotationComposer,
          $$BranchesTableTableCreateCompanionBuilder,
          $$BranchesTableTableUpdateCompanionBuilder,
          (
            BranchesTableData,
            BaseReferences<
              _$AppDatabase,
              $BranchesTableTable,
              BranchesTableData
            >,
          ),
          BranchesTableData,
          PrefetchHooks Function()
        > {
  $$BranchesTableTableTableManager(_$AppDatabase db, $BranchesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BranchesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BranchesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BranchesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BranchesTableCompanion(
                id: id,
                businessId: businessId,
                name: name,
                location: location,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String name,
                Value<String?> location = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BranchesTableCompanion.insert(
                id: id,
                businessId: businessId,
                name: name,
                location: location,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BranchesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BranchesTableTable,
      BranchesTableData,
      $$BranchesTableTableFilterComposer,
      $$BranchesTableTableOrderingComposer,
      $$BranchesTableTableAnnotationComposer,
      $$BranchesTableTableCreateCompanionBuilder,
      $$BranchesTableTableUpdateCompanionBuilder,
      (
        BranchesTableData,
        BaseReferences<_$AppDatabase, $BranchesTableTable, BranchesTableData>,
      ),
      BranchesTableData,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableTableCreateCompanionBuilder =
    CategoriesTableCompanion Function({
      required String id,
      required String businessId,
      required String name,
      Value<int> sortOrder,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });
typedef $$CategoriesTableTableUpdateCompanionBuilder =
    CategoriesTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> name,
      Value<int> sortOrder,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });

class $$CategoriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTableTable> {
  $$CategoriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTableTable> {
  $$CategoriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTableTable> {
  $$CategoriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );
}

class $$CategoriesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTableTable,
          CategoriesTableData,
          $$CategoriesTableTableFilterComposer,
          $$CategoriesTableTableOrderingComposer,
          $$CategoriesTableTableAnnotationComposer,
          $$CategoriesTableTableCreateCompanionBuilder,
          $$CategoriesTableTableUpdateCompanionBuilder,
          (
            CategoriesTableData,
            BaseReferences<
              _$AppDatabase,
              $CategoriesTableTable,
              CategoriesTableData
            >,
          ),
          CategoriesTableData,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableTableManager(
    _$AppDatabase db,
    $CategoriesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesTableCompanion(
                id: id,
                businessId: businessId,
                name: name,
                sortOrder: sortOrder,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String name,
                Value<int> sortOrder = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesTableCompanion.insert(
                id: id,
                businessId: businessId,
                name: name,
                sortOrder: sortOrder,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTableTable,
      CategoriesTableData,
      $$CategoriesTableTableFilterComposer,
      $$CategoriesTableTableOrderingComposer,
      $$CategoriesTableTableAnnotationComposer,
      $$CategoriesTableTableCreateCompanionBuilder,
      $$CategoriesTableTableUpdateCompanionBuilder,
      (
        CategoriesTableData,
        BaseReferences<
          _$AppDatabase,
          $CategoriesTableTable,
          CategoriesTableData
        >,
      ),
      CategoriesTableData,
      PrefetchHooks Function()
    >;
typedef $$ExpensesTableTableCreateCompanionBuilder =
    ExpensesTableCompanion Function({
      required String id,
      required String businessId,
      Value<String?> branchId,
      Value<String?> branchName,
      required String category,
      required String vendor,
      required double amount,
      Value<String> status,
      required String submittedById,
      required String submittedByName,
      Value<String?> approvedById,
      Value<String?> approvedByName,
      Value<String?> note,
      required DateTime expenseDate,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<int> rowid,
    });
typedef $$ExpensesTableTableUpdateCompanionBuilder =
    ExpensesTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String?> branchId,
      Value<String?> branchName,
      Value<String> category,
      Value<String> vendor,
      Value<double> amount,
      Value<String> status,
      Value<String> submittedById,
      Value<String> submittedByName,
      Value<String?> approvedById,
      Value<String?> approvedByName,
      Value<String?> note,
      Value<DateTime> expenseDate,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<int> rowid,
    });

class $$ExpensesTableTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTableTable> {
  $$ExpensesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchName => $composableBuilder(
    column: $table.branchName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vendor => $composableBuilder(
    column: $table.vendor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get submittedById => $composableBuilder(
    column: $table.submittedById,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get submittedByName => $composableBuilder(
    column: $table.submittedByName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get approvedById => $composableBuilder(
    column: $table.approvedById,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get approvedByName => $composableBuilder(
    column: $table.approvedByName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expenseDate => $composableBuilder(
    column: $table.expenseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExpensesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTableTable> {
  $$ExpensesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchName => $composableBuilder(
    column: $table.branchName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vendor => $composableBuilder(
    column: $table.vendor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get submittedById => $composableBuilder(
    column: $table.submittedById,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get submittedByName => $composableBuilder(
    column: $table.submittedByName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get approvedById => $composableBuilder(
    column: $table.approvedById,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get approvedByName => $composableBuilder(
    column: $table.approvedByName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expenseDate => $composableBuilder(
    column: $table.expenseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExpensesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTableTable> {
  $$ExpensesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get branchName => $composableBuilder(
    column: $table.branchName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get vendor =>
      $composableBuilder(column: $table.vendor, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get submittedById => $composableBuilder(
    column: $table.submittedById,
    builder: (column) => column,
  );

  GeneratedColumn<String> get submittedByName => $composableBuilder(
    column: $table.submittedByName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get approvedById => $composableBuilder(
    column: $table.approvedById,
    builder: (column) => column,
  );

  GeneratedColumn<String> get approvedByName => $composableBuilder(
    column: $table.approvedByName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get expenseDate => $composableBuilder(
    column: $table.expenseDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);
}

class $$ExpensesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpensesTableTable,
          ExpenseRow,
          $$ExpensesTableTableFilterComposer,
          $$ExpensesTableTableOrderingComposer,
          $$ExpensesTableTableAnnotationComposer,
          $$ExpensesTableTableCreateCompanionBuilder,
          $$ExpensesTableTableUpdateCompanionBuilder,
          (
            ExpenseRow,
            BaseReferences<_$AppDatabase, $ExpensesTableTable, ExpenseRow>,
          ),
          ExpenseRow,
          PrefetchHooks Function()
        > {
  $$ExpensesTableTableTableManager(_$AppDatabase db, $ExpensesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String?> branchId = const Value.absent(),
                Value<String?> branchName = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> vendor = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> submittedById = const Value.absent(),
                Value<String> submittedByName = const Value.absent(),
                Value<String?> approvedById = const Value.absent(),
                Value<String?> approvedByName = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> expenseDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesTableCompanion(
                id: id,
                businessId: businessId,
                branchId: branchId,
                branchName: branchName,
                category: category,
                vendor: vendor,
                amount: amount,
                status: status,
                submittedById: submittedById,
                submittedByName: submittedByName,
                approvedById: approvedById,
                approvedByName: approvedByName,
                note: note,
                expenseDate: expenseDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                Value<String?> branchId = const Value.absent(),
                Value<String?> branchName = const Value.absent(),
                required String category,
                required String vendor,
                required double amount,
                Value<String> status = const Value.absent(),
                required String submittedById,
                required String submittedByName,
                Value<String?> approvedById = const Value.absent(),
                Value<String?> approvedByName = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime expenseDate,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesTableCompanion.insert(
                id: id,
                businessId: businessId,
                branchId: branchId,
                branchName: branchName,
                category: category,
                vendor: vendor,
                amount: amount,
                status: status,
                submittedById: submittedById,
                submittedByName: submittedByName,
                approvedById: approvedById,
                approvedByName: approvedByName,
                note: note,
                expenseDate: expenseDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExpensesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpensesTableTable,
      ExpenseRow,
      $$ExpensesTableTableFilterComposer,
      $$ExpensesTableTableOrderingComposer,
      $$ExpensesTableTableAnnotationComposer,
      $$ExpensesTableTableCreateCompanionBuilder,
      $$ExpensesTableTableUpdateCompanionBuilder,
      (
        ExpenseRow,
        BaseReferences<_$AppDatabase, $ExpensesTableTable, ExpenseRow>,
      ),
      ExpenseRow,
      PrefetchHooks Function()
    >;
typedef $$ProductsTableTableCreateCompanionBuilder =
    ProductsTableCompanion Function({
      required String id,
      required String businessId,
      Value<String?> categoryId,
      required String name,
      Value<String?> sku,
      Value<String?> barcode,
      Value<String> type,
      Value<String> trackingMethod,
      Value<double?> tax,
      Value<String> sellBy,
      Value<bool> hasVariants,
      Value<String?> imagePath,
      Value<bool> isActive,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });
typedef $$ProductsTableTableUpdateCompanionBuilder =
    ProductsTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String?> categoryId,
      Value<String> name,
      Value<String?> sku,
      Value<String?> barcode,
      Value<String> type,
      Value<String> trackingMethod,
      Value<double?> tax,
      Value<String> sellBy,
      Value<bool> hasVariants,
      Value<String?> imagePath,
      Value<bool> isActive,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });

class $$ProductsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackingMethod => $composableBuilder(
    column: $table.trackingMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get tax => $composableBuilder(
    column: $table.tax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sellBy => $composableBuilder(
    column: $table.sellBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasVariants => $composableBuilder(
    column: $table.hasVariants,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackingMethod => $composableBuilder(
    column: $table.trackingMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get tax => $composableBuilder(
    column: $table.tax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sellBy => $composableBuilder(
    column: $table.sellBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasVariants => $composableBuilder(
    column: $table.hasVariants,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTableTable> {
  $$ProductsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get trackingMethod => $composableBuilder(
    column: $table.trackingMethod,
    builder: (column) => column,
  );

  GeneratedColumn<double> get tax =>
      $composableBuilder(column: $table.tax, builder: (column) => column);

  GeneratedColumn<String> get sellBy =>
      $composableBuilder(column: $table.sellBy, builder: (column) => column);

  GeneratedColumn<bool> get hasVariants => $composableBuilder(
    column: $table.hasVariants,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );
}

class $$ProductsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTableTable,
          ProductsTableData,
          $$ProductsTableTableFilterComposer,
          $$ProductsTableTableOrderingComposer,
          $$ProductsTableTableAnnotationComposer,
          $$ProductsTableTableCreateCompanionBuilder,
          $$ProductsTableTableUpdateCompanionBuilder,
          (
            ProductsTableData,
            BaseReferences<
              _$AppDatabase,
              $ProductsTableTable,
              ProductsTableData
            >,
          ),
          ProductsTableData,
          PrefetchHooks Function()
        > {
  $$ProductsTableTableTableManager(_$AppDatabase db, $ProductsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> trackingMethod = const Value.absent(),
                Value<double?> tax = const Value.absent(),
                Value<String> sellBy = const Value.absent(),
                Value<bool> hasVariants = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsTableCompanion(
                id: id,
                businessId: businessId,
                categoryId: categoryId,
                name: name,
                sku: sku,
                barcode: barcode,
                type: type,
                trackingMethod: trackingMethod,
                tax: tax,
                sellBy: sellBy,
                hasVariants: hasVariants,
                imagePath: imagePath,
                isActive: isActive,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                Value<String?> categoryId = const Value.absent(),
                required String name,
                Value<String?> sku = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> trackingMethod = const Value.absent(),
                Value<double?> tax = const Value.absent(),
                Value<String> sellBy = const Value.absent(),
                Value<bool> hasVariants = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsTableCompanion.insert(
                id: id,
                businessId: businessId,
                categoryId: categoryId,
                name: name,
                sku: sku,
                barcode: barcode,
                type: type,
                trackingMethod: trackingMethod,
                tax: tax,
                sellBy: sellBy,
                hasVariants: hasVariants,
                imagePath: imagePath,
                isActive: isActive,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTableTable,
      ProductsTableData,
      $$ProductsTableTableFilterComposer,
      $$ProductsTableTableOrderingComposer,
      $$ProductsTableTableAnnotationComposer,
      $$ProductsTableTableCreateCompanionBuilder,
      $$ProductsTableTableUpdateCompanionBuilder,
      (
        ProductsTableData,
        BaseReferences<_$AppDatabase, $ProductsTableTable, ProductsTableData>,
      ),
      ProductsTableData,
      PrefetchHooks Function()
    >;
typedef $$ProductVariantsTableTableCreateCompanionBuilder =
    ProductVariantsTableCompanion Function({
      required String id,
      required String productId,
      required String businessId,
      required String name,
      Value<double> price,
      Value<double?> costPrice,
      Value<double?> retailPrice,
      Value<int> stock,
      Value<String?> sku,
      Value<String?> barcode,
      Value<String?> unit,
      Value<double?> stockDecimal,
      Value<int?> lowStockAlert,
      Value<bool> trackStock,
      Value<bool> trackExpiry,
      Value<DateTime?> expiryDate,
      Value<bool> isActive,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });
typedef $$ProductVariantsTableTableUpdateCompanionBuilder =
    ProductVariantsTableCompanion Function({
      Value<String> id,
      Value<String> productId,
      Value<String> businessId,
      Value<String> name,
      Value<double> price,
      Value<double?> costPrice,
      Value<double?> retailPrice,
      Value<int> stock,
      Value<String?> sku,
      Value<String?> barcode,
      Value<String?> unit,
      Value<double?> stockDecimal,
      Value<int?> lowStockAlert,
      Value<bool> trackStock,
      Value<bool> trackExpiry,
      Value<DateTime?> expiryDate,
      Value<bool> isActive,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });

class $$ProductVariantsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProductVariantsTableTable> {
  $$ProductVariantsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get retailPrice => $composableBuilder(
    column: $table.retailPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stock => $composableBuilder(
    column: $table.stock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stockDecimal => $composableBuilder(
    column: $table.stockDecimal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lowStockAlert => $composableBuilder(
    column: $table.lowStockAlert,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get trackStock => $composableBuilder(
    column: $table.trackStock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get trackExpiry => $composableBuilder(
    column: $table.trackExpiry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductVariantsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductVariantsTableTable> {
  $$ProductVariantsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get retailPrice => $composableBuilder(
    column: $table.retailPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stock => $composableBuilder(
    column: $table.stock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stockDecimal => $composableBuilder(
    column: $table.stockDecimal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lowStockAlert => $composableBuilder(
    column: $table.lowStockAlert,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get trackStock => $composableBuilder(
    column: $table.trackStock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get trackExpiry => $composableBuilder(
    column: $table.trackExpiry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductVariantsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductVariantsTableTable> {
  $$ProductVariantsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<double> get costPrice =>
      $composableBuilder(column: $table.costPrice, builder: (column) => column);

  GeneratedColumn<double> get retailPrice => $composableBuilder(
    column: $table.retailPrice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stock =>
      $composableBuilder(column: $table.stock, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get stockDecimal => $composableBuilder(
    column: $table.stockDecimal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lowStockAlert => $composableBuilder(
    column: $table.lowStockAlert,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get trackStock => $composableBuilder(
    column: $table.trackStock,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get trackExpiry => $composableBuilder(
    column: $table.trackExpiry,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );
}

class $$ProductVariantsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductVariantsTableTable,
          ProductVariantsTableData,
          $$ProductVariantsTableTableFilterComposer,
          $$ProductVariantsTableTableOrderingComposer,
          $$ProductVariantsTableTableAnnotationComposer,
          $$ProductVariantsTableTableCreateCompanionBuilder,
          $$ProductVariantsTableTableUpdateCompanionBuilder,
          (
            ProductVariantsTableData,
            BaseReferences<
              _$AppDatabase,
              $ProductVariantsTableTable,
              ProductVariantsTableData
            >,
          ),
          ProductVariantsTableData,
          PrefetchHooks Function()
        > {
  $$ProductVariantsTableTableTableManager(
    _$AppDatabase db,
    $ProductVariantsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductVariantsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductVariantsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ProductVariantsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<double?> costPrice = const Value.absent(),
                Value<double?> retailPrice = const Value.absent(),
                Value<int> stock = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<double?> stockDecimal = const Value.absent(),
                Value<int?> lowStockAlert = const Value.absent(),
                Value<bool> trackStock = const Value.absent(),
                Value<bool> trackExpiry = const Value.absent(),
                Value<DateTime?> expiryDate = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductVariantsTableCompanion(
                id: id,
                productId: productId,
                businessId: businessId,
                name: name,
                price: price,
                costPrice: costPrice,
                retailPrice: retailPrice,
                stock: stock,
                sku: sku,
                barcode: barcode,
                unit: unit,
                stockDecimal: stockDecimal,
                lowStockAlert: lowStockAlert,
                trackStock: trackStock,
                trackExpiry: trackExpiry,
                expiryDate: expiryDate,
                isActive: isActive,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String productId,
                required String businessId,
                required String name,
                Value<double> price = const Value.absent(),
                Value<double?> costPrice = const Value.absent(),
                Value<double?> retailPrice = const Value.absent(),
                Value<int> stock = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<double?> stockDecimal = const Value.absent(),
                Value<int?> lowStockAlert = const Value.absent(),
                Value<bool> trackStock = const Value.absent(),
                Value<bool> trackExpiry = const Value.absent(),
                Value<DateTime?> expiryDate = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductVariantsTableCompanion.insert(
                id: id,
                productId: productId,
                businessId: businessId,
                name: name,
                price: price,
                costPrice: costPrice,
                retailPrice: retailPrice,
                stock: stock,
                sku: sku,
                barcode: barcode,
                unit: unit,
                stockDecimal: stockDecimal,
                lowStockAlert: lowStockAlert,
                trackStock: trackStock,
                trackExpiry: trackExpiry,
                expiryDate: expiryDate,
                isActive: isActive,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductVariantsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductVariantsTableTable,
      ProductVariantsTableData,
      $$ProductVariantsTableTableFilterComposer,
      $$ProductVariantsTableTableOrderingComposer,
      $$ProductVariantsTableTableAnnotationComposer,
      $$ProductVariantsTableTableCreateCompanionBuilder,
      $$ProductVariantsTableTableUpdateCompanionBuilder,
      (
        ProductVariantsTableData,
        BaseReferences<
          _$AppDatabase,
          $ProductVariantsTableTable,
          ProductVariantsTableData
        >,
      ),
      ProductVariantsTableData,
      PrefetchHooks Function()
    >;
typedef $$TransactionsTableTableCreateCompanionBuilder =
    TransactionsTableCompanion Function({
      required String id,
      Value<String?> businessId,
      Value<String?> branchId,
      required String cashierId,
      Value<String?> shiftId,
      required double totalAmount,
      Value<double> discountAmount,
      required double taxAmount,
      Value<String> status,
      Value<String?> transactionHash,
      Value<DateTime> createdAt,
      Value<String?> customerName,
      Value<String> paymentMethod,
      required double subtotal,
      Value<double?> amountReceived,
      Value<double?> changeDue,
      required int itemCount,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<int> rowid,
    });
typedef $$TransactionsTableTableUpdateCompanionBuilder =
    TransactionsTableCompanion Function({
      Value<String> id,
      Value<String?> businessId,
      Value<String?> branchId,
      Value<String> cashierId,
      Value<String?> shiftId,
      Value<double> totalAmount,
      Value<double> discountAmount,
      Value<double> taxAmount,
      Value<String> status,
      Value<String?> transactionHash,
      Value<DateTime> createdAt,
      Value<String?> customerName,
      Value<String> paymentMethod,
      Value<double> subtotal,
      Value<double?> amountReceived,
      Value<double?> changeDue,
      Value<int> itemCount,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<int> rowid,
    });

class $$TransactionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTableTable> {
  $$TransactionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashierId => $composableBuilder(
    column: $table.cashierId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shiftId => $composableBuilder(
    column: $table.shiftId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get taxAmount => $composableBuilder(
    column: $table.taxAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionHash => $composableBuilder(
    column: $table.transactionHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amountReceived => $composableBuilder(
    column: $table.amountReceived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get changeDue => $composableBuilder(
    column: $table.changeDue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTableTable> {
  $$TransactionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashierId => $composableBuilder(
    column: $table.cashierId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shiftId => $composableBuilder(
    column: $table.shiftId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get taxAmount => $composableBuilder(
    column: $table.taxAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionHash => $composableBuilder(
    column: $table.transactionHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amountReceived => $composableBuilder(
    column: $table.amountReceived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get changeDue => $composableBuilder(
    column: $table.changeDue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTableTable> {
  $$TransactionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get cashierId =>
      $composableBuilder(column: $table.cashierId, builder: (column) => column);

  GeneratedColumn<String> get shiftId =>
      $composableBuilder(column: $table.shiftId, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get taxAmount =>
      $composableBuilder(column: $table.taxAmount, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get transactionHash => $composableBuilder(
    column: $table.transactionHash,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<double> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<double> get amountReceived => $composableBuilder(
    column: $table.amountReceived,
    builder: (column) => column,
  );

  GeneratedColumn<double> get changeDue =>
      $composableBuilder(column: $table.changeDue, builder: (column) => column);

  GeneratedColumn<int> get itemCount =>
      $composableBuilder(column: $table.itemCount, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);
}

class $$TransactionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTableTable,
          TransactionsTableData,
          $$TransactionsTableTableFilterComposer,
          $$TransactionsTableTableOrderingComposer,
          $$TransactionsTableTableAnnotationComposer,
          $$TransactionsTableTableCreateCompanionBuilder,
          $$TransactionsTableTableUpdateCompanionBuilder,
          (
            TransactionsTableData,
            BaseReferences<
              _$AppDatabase,
              $TransactionsTableTable,
              TransactionsTableData
            >,
          ),
          TransactionsTableData,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableTableManager(
    _$AppDatabase db,
    $TransactionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> businessId = const Value.absent(),
                Value<String?> branchId = const Value.absent(),
                Value<String> cashierId = const Value.absent(),
                Value<String?> shiftId = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<double> discountAmount = const Value.absent(),
                Value<double> taxAmount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> transactionHash = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> customerName = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<double> subtotal = const Value.absent(),
                Value<double?> amountReceived = const Value.absent(),
                Value<double?> changeDue = const Value.absent(),
                Value<int> itemCount = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsTableCompanion(
                id: id,
                businessId: businessId,
                branchId: branchId,
                cashierId: cashierId,
                shiftId: shiftId,
                totalAmount: totalAmount,
                discountAmount: discountAmount,
                taxAmount: taxAmount,
                status: status,
                transactionHash: transactionHash,
                createdAt: createdAt,
                customerName: customerName,
                paymentMethod: paymentMethod,
                subtotal: subtotal,
                amountReceived: amountReceived,
                changeDue: changeDue,
                itemCount: itemCount,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> businessId = const Value.absent(),
                Value<String?> branchId = const Value.absent(),
                required String cashierId,
                Value<String?> shiftId = const Value.absent(),
                required double totalAmount,
                Value<double> discountAmount = const Value.absent(),
                required double taxAmount,
                Value<String> status = const Value.absent(),
                Value<String?> transactionHash = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> customerName = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                required double subtotal,
                Value<double?> amountReceived = const Value.absent(),
                Value<double?> changeDue = const Value.absent(),
                required int itemCount,
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsTableCompanion.insert(
                id: id,
                businessId: businessId,
                branchId: branchId,
                cashierId: cashierId,
                shiftId: shiftId,
                totalAmount: totalAmount,
                discountAmount: discountAmount,
                taxAmount: taxAmount,
                status: status,
                transactionHash: transactionHash,
                createdAt: createdAt,
                customerName: customerName,
                paymentMethod: paymentMethod,
                subtotal: subtotal,
                amountReceived: amountReceived,
                changeDue: changeDue,
                itemCount: itemCount,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTableTable,
      TransactionsTableData,
      $$TransactionsTableTableFilterComposer,
      $$TransactionsTableTableOrderingComposer,
      $$TransactionsTableTableAnnotationComposer,
      $$TransactionsTableTableCreateCompanionBuilder,
      $$TransactionsTableTableUpdateCompanionBuilder,
      (
        TransactionsTableData,
        BaseReferences<
          _$AppDatabase,
          $TransactionsTableTable,
          TransactionsTableData
        >,
      ),
      TransactionsTableData,
      PrefetchHooks Function()
    >;
typedef $$TransactionItemsTableTableCreateCompanionBuilder =
    TransactionItemsTableCompanion Function({
      required String id,
      required String transactionId,
      required String variantId,
      required String productName,
      required String variantName,
      required double unitPrice,
      Value<double?> taxRate,
      required double qty,
      required double lineTotal,
      required double lineTax,
      Value<int> rowid,
    });
typedef $$TransactionItemsTableTableUpdateCompanionBuilder =
    TransactionItemsTableCompanion Function({
      Value<String> id,
      Value<String> transactionId,
      Value<String> variantId,
      Value<String> productName,
      Value<String> variantName,
      Value<double> unitPrice,
      Value<double?> taxRate,
      Value<double> qty,
      Value<double> lineTotal,
      Value<double> lineTax,
      Value<int> rowid,
    });

class $$TransactionItemsTableTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionItemsTableTable> {
  $$TransactionItemsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get taxRate => $composableBuilder(
    column: $table.taxRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lineTotal => $composableBuilder(
    column: $table.lineTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lineTax => $composableBuilder(
    column: $table.lineTax,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionItemsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionItemsTableTable> {
  $$TransactionItemsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get taxRate => $composableBuilder(
    column: $table.taxRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lineTotal => $composableBuilder(
    column: $table.lineTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lineTax => $composableBuilder(
    column: $table.lineTax,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionItemsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionItemsTableTable> {
  $$TransactionItemsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get variantId =>
      $composableBuilder(column: $table.variantId, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<double> get taxRate =>
      $composableBuilder(column: $table.taxRate, builder: (column) => column);

  GeneratedColumn<double> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<double> get lineTotal =>
      $composableBuilder(column: $table.lineTotal, builder: (column) => column);

  GeneratedColumn<double> get lineTax =>
      $composableBuilder(column: $table.lineTax, builder: (column) => column);
}

class $$TransactionItemsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionItemsTableTable,
          TransactionItemsTableData,
          $$TransactionItemsTableTableFilterComposer,
          $$TransactionItemsTableTableOrderingComposer,
          $$TransactionItemsTableTableAnnotationComposer,
          $$TransactionItemsTableTableCreateCompanionBuilder,
          $$TransactionItemsTableTableUpdateCompanionBuilder,
          (
            TransactionItemsTableData,
            BaseReferences<
              _$AppDatabase,
              $TransactionItemsTableTable,
              TransactionItemsTableData
            >,
          ),
          TransactionItemsTableData,
          PrefetchHooks Function()
        > {
  $$TransactionItemsTableTableTableManager(
    _$AppDatabase db,
    $TransactionItemsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionItemsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TransactionItemsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TransactionItemsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> transactionId = const Value.absent(),
                Value<String> variantId = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String> variantName = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
                Value<double?> taxRate = const Value.absent(),
                Value<double> qty = const Value.absent(),
                Value<double> lineTotal = const Value.absent(),
                Value<double> lineTax = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionItemsTableCompanion(
                id: id,
                transactionId: transactionId,
                variantId: variantId,
                productName: productName,
                variantName: variantName,
                unitPrice: unitPrice,
                taxRate: taxRate,
                qty: qty,
                lineTotal: lineTotal,
                lineTax: lineTax,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String transactionId,
                required String variantId,
                required String productName,
                required String variantName,
                required double unitPrice,
                Value<double?> taxRate = const Value.absent(),
                required double qty,
                required double lineTotal,
                required double lineTax,
                Value<int> rowid = const Value.absent(),
              }) => TransactionItemsTableCompanion.insert(
                id: id,
                transactionId: transactionId,
                variantId: variantId,
                productName: productName,
                variantName: variantName,
                unitPrice: unitPrice,
                taxRate: taxRate,
                qty: qty,
                lineTotal: lineTotal,
                lineTax: lineTax,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionItemsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionItemsTableTable,
      TransactionItemsTableData,
      $$TransactionItemsTableTableFilterComposer,
      $$TransactionItemsTableTableOrderingComposer,
      $$TransactionItemsTableTableAnnotationComposer,
      $$TransactionItemsTableTableCreateCompanionBuilder,
      $$TransactionItemsTableTableUpdateCompanionBuilder,
      (
        TransactionItemsTableData,
        BaseReferences<
          _$AppDatabase,
          $TransactionItemsTableTable,
          TransactionItemsTableData
        >,
      ),
      TransactionItemsTableData,
      PrefetchHooks Function()
    >;
typedef $$DraftSalesTableTableCreateCompanionBuilder =
    DraftSalesTableCompanion Function({
      required String id,
      Value<String?> businessId,
      Value<String?> branchId,
      required String cashierId,
      Value<String?> label,
      Value<String?> customerName,
      required double subtotal,
      required double taxAmount,
      Value<double> discountAmount,
      required double totalAmount,
      required int itemCount,
      Value<String?> discountType,
      Value<double?> discountValue,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<int> rowid,
    });
typedef $$DraftSalesTableTableUpdateCompanionBuilder =
    DraftSalesTableCompanion Function({
      Value<String> id,
      Value<String?> businessId,
      Value<String?> branchId,
      Value<String> cashierId,
      Value<String?> label,
      Value<String?> customerName,
      Value<double> subtotal,
      Value<double> taxAmount,
      Value<double> discountAmount,
      Value<double> totalAmount,
      Value<int> itemCount,
      Value<String?> discountType,
      Value<double?> discountValue,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<int> rowid,
    });

class $$DraftSalesTableTableFilterComposer
    extends Composer<_$AppDatabase, $DraftSalesTableTable> {
  $$DraftSalesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashierId => $composableBuilder(
    column: $table.cashierId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get taxAmount => $composableBuilder(
    column: $table.taxAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discountType => $composableBuilder(
    column: $table.discountType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DraftSalesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DraftSalesTableTable> {
  $$DraftSalesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashierId => $composableBuilder(
    column: $table.cashierId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get taxAmount => $composableBuilder(
    column: $table.taxAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discountType => $composableBuilder(
    column: $table.discountType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DraftSalesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DraftSalesTableTable> {
  $$DraftSalesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get cashierId =>
      $composableBuilder(column: $table.cashierId, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<double> get taxAmount =>
      $composableBuilder(column: $table.taxAmount, builder: (column) => column);

  GeneratedColumn<double> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get itemCount =>
      $composableBuilder(column: $table.itemCount, builder: (column) => column);

  GeneratedColumn<String> get discountType => $composableBuilder(
    column: $table.discountType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);
}

class $$DraftSalesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DraftSalesTableTable,
          DraftSalesTableData,
          $$DraftSalesTableTableFilterComposer,
          $$DraftSalesTableTableOrderingComposer,
          $$DraftSalesTableTableAnnotationComposer,
          $$DraftSalesTableTableCreateCompanionBuilder,
          $$DraftSalesTableTableUpdateCompanionBuilder,
          (
            DraftSalesTableData,
            BaseReferences<
              _$AppDatabase,
              $DraftSalesTableTable,
              DraftSalesTableData
            >,
          ),
          DraftSalesTableData,
          PrefetchHooks Function()
        > {
  $$DraftSalesTableTableTableManager(
    _$AppDatabase db,
    $DraftSalesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DraftSalesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DraftSalesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DraftSalesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> businessId = const Value.absent(),
                Value<String?> branchId = const Value.absent(),
                Value<String> cashierId = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String?> customerName = const Value.absent(),
                Value<double> subtotal = const Value.absent(),
                Value<double> taxAmount = const Value.absent(),
                Value<double> discountAmount = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<int> itemCount = const Value.absent(),
                Value<String?> discountType = const Value.absent(),
                Value<double?> discountValue = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DraftSalesTableCompanion(
                id: id,
                businessId: businessId,
                branchId: branchId,
                cashierId: cashierId,
                label: label,
                customerName: customerName,
                subtotal: subtotal,
                taxAmount: taxAmount,
                discountAmount: discountAmount,
                totalAmount: totalAmount,
                itemCount: itemCount,
                discountType: discountType,
                discountValue: discountValue,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> businessId = const Value.absent(),
                Value<String?> branchId = const Value.absent(),
                required String cashierId,
                Value<String?> label = const Value.absent(),
                Value<String?> customerName = const Value.absent(),
                required double subtotal,
                required double taxAmount,
                Value<double> discountAmount = const Value.absent(),
                required double totalAmount,
                required int itemCount,
                Value<String?> discountType = const Value.absent(),
                Value<double?> discountValue = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DraftSalesTableCompanion.insert(
                id: id,
                businessId: businessId,
                branchId: branchId,
                cashierId: cashierId,
                label: label,
                customerName: customerName,
                subtotal: subtotal,
                taxAmount: taxAmount,
                discountAmount: discountAmount,
                totalAmount: totalAmount,
                itemCount: itemCount,
                discountType: discountType,
                discountValue: discountValue,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DraftSalesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DraftSalesTableTable,
      DraftSalesTableData,
      $$DraftSalesTableTableFilterComposer,
      $$DraftSalesTableTableOrderingComposer,
      $$DraftSalesTableTableAnnotationComposer,
      $$DraftSalesTableTableCreateCompanionBuilder,
      $$DraftSalesTableTableUpdateCompanionBuilder,
      (
        DraftSalesTableData,
        BaseReferences<
          _$AppDatabase,
          $DraftSalesTableTable,
          DraftSalesTableData
        >,
      ),
      DraftSalesTableData,
      PrefetchHooks Function()
    >;
typedef $$DraftSaleItemsTableTableCreateCompanionBuilder =
    DraftSaleItemsTableCompanion Function({
      required String id,
      required String draftId,
      required String variantId,
      required String productName,
      required String variantName,
      required double unitPrice,
      Value<double?> taxRate,
      required double qty,
      required double lineTotal,
      required double lineTax,
      Value<int> rowid,
    });
typedef $$DraftSaleItemsTableTableUpdateCompanionBuilder =
    DraftSaleItemsTableCompanion Function({
      Value<String> id,
      Value<String> draftId,
      Value<String> variantId,
      Value<String> productName,
      Value<String> variantName,
      Value<double> unitPrice,
      Value<double?> taxRate,
      Value<double> qty,
      Value<double> lineTotal,
      Value<double> lineTax,
      Value<int> rowid,
    });

class $$DraftSaleItemsTableTableFilterComposer
    extends Composer<_$AppDatabase, $DraftSaleItemsTableTable> {
  $$DraftSaleItemsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get draftId => $composableBuilder(
    column: $table.draftId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get taxRate => $composableBuilder(
    column: $table.taxRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lineTotal => $composableBuilder(
    column: $table.lineTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lineTax => $composableBuilder(
    column: $table.lineTax,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DraftSaleItemsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DraftSaleItemsTableTable> {
  $$DraftSaleItemsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get draftId => $composableBuilder(
    column: $table.draftId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get taxRate => $composableBuilder(
    column: $table.taxRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lineTotal => $composableBuilder(
    column: $table.lineTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lineTax => $composableBuilder(
    column: $table.lineTax,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DraftSaleItemsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DraftSaleItemsTableTable> {
  $$DraftSaleItemsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get draftId =>
      $composableBuilder(column: $table.draftId, builder: (column) => column);

  GeneratedColumn<String> get variantId =>
      $composableBuilder(column: $table.variantId, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<double> get taxRate =>
      $composableBuilder(column: $table.taxRate, builder: (column) => column);

  GeneratedColumn<double> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<double> get lineTotal =>
      $composableBuilder(column: $table.lineTotal, builder: (column) => column);

  GeneratedColumn<double> get lineTax =>
      $composableBuilder(column: $table.lineTax, builder: (column) => column);
}

class $$DraftSaleItemsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DraftSaleItemsTableTable,
          DraftSaleItemsTableData,
          $$DraftSaleItemsTableTableFilterComposer,
          $$DraftSaleItemsTableTableOrderingComposer,
          $$DraftSaleItemsTableTableAnnotationComposer,
          $$DraftSaleItemsTableTableCreateCompanionBuilder,
          $$DraftSaleItemsTableTableUpdateCompanionBuilder,
          (
            DraftSaleItemsTableData,
            BaseReferences<
              _$AppDatabase,
              $DraftSaleItemsTableTable,
              DraftSaleItemsTableData
            >,
          ),
          DraftSaleItemsTableData,
          PrefetchHooks Function()
        > {
  $$DraftSaleItemsTableTableTableManager(
    _$AppDatabase db,
    $DraftSaleItemsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DraftSaleItemsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DraftSaleItemsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DraftSaleItemsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> draftId = const Value.absent(),
                Value<String> variantId = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String> variantName = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
                Value<double?> taxRate = const Value.absent(),
                Value<double> qty = const Value.absent(),
                Value<double> lineTotal = const Value.absent(),
                Value<double> lineTax = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DraftSaleItemsTableCompanion(
                id: id,
                draftId: draftId,
                variantId: variantId,
                productName: productName,
                variantName: variantName,
                unitPrice: unitPrice,
                taxRate: taxRate,
                qty: qty,
                lineTotal: lineTotal,
                lineTax: lineTax,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String draftId,
                required String variantId,
                required String productName,
                required String variantName,
                required double unitPrice,
                Value<double?> taxRate = const Value.absent(),
                required double qty,
                required double lineTotal,
                required double lineTax,
                Value<int> rowid = const Value.absent(),
              }) => DraftSaleItemsTableCompanion.insert(
                id: id,
                draftId: draftId,
                variantId: variantId,
                productName: productName,
                variantName: variantName,
                unitPrice: unitPrice,
                taxRate: taxRate,
                qty: qty,
                lineTotal: lineTotal,
                lineTax: lineTax,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DraftSaleItemsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DraftSaleItemsTableTable,
      DraftSaleItemsTableData,
      $$DraftSaleItemsTableTableFilterComposer,
      $$DraftSaleItemsTableTableOrderingComposer,
      $$DraftSaleItemsTableTableAnnotationComposer,
      $$DraftSaleItemsTableTableCreateCompanionBuilder,
      $$DraftSaleItemsTableTableUpdateCompanionBuilder,
      (
        DraftSaleItemsTableData,
        BaseReferences<
          _$AppDatabase,
          $DraftSaleItemsTableTable,
          DraftSaleItemsTableData
        >,
      ),
      DraftSaleItemsTableData,
      PrefetchHooks Function()
    >;
typedef $$InventoryLevelsTableTableCreateCompanionBuilder =
    InventoryLevelsTableCompanion Function({
      required String id,
      required String variantId,
      required String branchId,
      required String businessId,
      Value<int> quantity,
      Value<double?> quantityDecimal,
      Value<int?> lowStockAlertOverride,
      Value<int> syncStatus,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });
typedef $$InventoryLevelsTableTableUpdateCompanionBuilder =
    InventoryLevelsTableCompanion Function({
      Value<String> id,
      Value<String> variantId,
      Value<String> branchId,
      Value<String> businessId,
      Value<int> quantity,
      Value<double?> quantityDecimal,
      Value<int?> lowStockAlertOverride,
      Value<int> syncStatus,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });

class $$InventoryLevelsTableTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryLevelsTableTable> {
  $$InventoryLevelsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantityDecimal => $composableBuilder(
    column: $table.quantityDecimal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lowStockAlertOverride => $composableBuilder(
    column: $table.lowStockAlertOverride,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InventoryLevelsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryLevelsTableTable> {
  $$InventoryLevelsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantityDecimal => $composableBuilder(
    column: $table.quantityDecimal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lowStockAlertOverride => $composableBuilder(
    column: $table.lowStockAlertOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InventoryLevelsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryLevelsTableTable> {
  $$InventoryLevelsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get variantId =>
      $composableBuilder(column: $table.variantId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get quantityDecimal => $composableBuilder(
    column: $table.quantityDecimal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lowStockAlertOverride => $composableBuilder(
    column: $table.lowStockAlertOverride,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );
}

class $$InventoryLevelsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InventoryLevelsTableTable,
          InventoryLevelsTableData,
          $$InventoryLevelsTableTableFilterComposer,
          $$InventoryLevelsTableTableOrderingComposer,
          $$InventoryLevelsTableTableAnnotationComposer,
          $$InventoryLevelsTableTableCreateCompanionBuilder,
          $$InventoryLevelsTableTableUpdateCompanionBuilder,
          (
            InventoryLevelsTableData,
            BaseReferences<
              _$AppDatabase,
              $InventoryLevelsTableTable,
              InventoryLevelsTableData
            >,
          ),
          InventoryLevelsTableData,
          PrefetchHooks Function()
        > {
  $$InventoryLevelsTableTableTableManager(
    _$AppDatabase db,
    $InventoryLevelsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryLevelsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryLevelsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InventoryLevelsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> variantId = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<double?> quantityDecimal = const Value.absent(),
                Value<int?> lowStockAlertOverride = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoryLevelsTableCompanion(
                id: id,
                variantId: variantId,
                branchId: branchId,
                businessId: businessId,
                quantity: quantity,
                quantityDecimal: quantityDecimal,
                lowStockAlertOverride: lowStockAlertOverride,
                syncStatus: syncStatus,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String variantId,
                required String branchId,
                required String businessId,
                Value<int> quantity = const Value.absent(),
                Value<double?> quantityDecimal = const Value.absent(),
                Value<int?> lowStockAlertOverride = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoryLevelsTableCompanion.insert(
                id: id,
                variantId: variantId,
                branchId: branchId,
                businessId: businessId,
                quantity: quantity,
                quantityDecimal: quantityDecimal,
                lowStockAlertOverride: lowStockAlertOverride,
                syncStatus: syncStatus,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InventoryLevelsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InventoryLevelsTableTable,
      InventoryLevelsTableData,
      $$InventoryLevelsTableTableFilterComposer,
      $$InventoryLevelsTableTableOrderingComposer,
      $$InventoryLevelsTableTableAnnotationComposer,
      $$InventoryLevelsTableTableCreateCompanionBuilder,
      $$InventoryLevelsTableTableUpdateCompanionBuilder,
      (
        InventoryLevelsTableData,
        BaseReferences<
          _$AppDatabase,
          $InventoryLevelsTableTable,
          InventoryLevelsTableData
        >,
      ),
      InventoryLevelsTableData,
      PrefetchHooks Function()
    >;
typedef $$StockLedgerTableTableCreateCompanionBuilder =
    StockLedgerTableCompanion Function({
      required String id,
      required String variantId,
      required String productId,
      required String branchId,
      required String businessId,
      required String changeType,
      required double quantity,
      Value<double?> quantityBefore,
      Value<double?> quantityAfter,
      required String reason,
      Value<String?> note,
      Value<String?> sourceType,
      Value<String?> sourceId,
      Value<DateTime> createdAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });
typedef $$StockLedgerTableTableUpdateCompanionBuilder =
    StockLedgerTableCompanion Function({
      Value<String> id,
      Value<String> variantId,
      Value<String> productId,
      Value<String> branchId,
      Value<String> businessId,
      Value<String> changeType,
      Value<double> quantity,
      Value<double?> quantityBefore,
      Value<double?> quantityAfter,
      Value<String> reason,
      Value<String?> note,
      Value<String?> sourceType,
      Value<String?> sourceId,
      Value<DateTime> createdAt,
      Value<int> syncStatus,
      Value<int> rowid,
    });

class $$StockLedgerTableTableFilterComposer
    extends Composer<_$AppDatabase, $StockLedgerTableTable> {
  $$StockLedgerTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get changeType => $composableBuilder(
    column: $table.changeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantityBefore => $composableBuilder(
    column: $table.quantityBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantityAfter => $composableBuilder(
    column: $table.quantityAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StockLedgerTableTableOrderingComposer
    extends Composer<_$AppDatabase, $StockLedgerTableTable> {
  $$StockLedgerTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get changeType => $composableBuilder(
    column: $table.changeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantityBefore => $composableBuilder(
    column: $table.quantityBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantityAfter => $composableBuilder(
    column: $table.quantityAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StockLedgerTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockLedgerTableTable> {
  $$StockLedgerTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get variantId =>
      $composableBuilder(column: $table.variantId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get changeType => $composableBuilder(
    column: $table.changeType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get quantityBefore => $composableBuilder(
    column: $table.quantityBefore,
    builder: (column) => column,
  );

  GeneratedColumn<double> get quantityAfter => $composableBuilder(
    column: $table.quantityAfter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$StockLedgerTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StockLedgerTableTable,
          StockLedgerTableData,
          $$StockLedgerTableTableFilterComposer,
          $$StockLedgerTableTableOrderingComposer,
          $$StockLedgerTableTableAnnotationComposer,
          $$StockLedgerTableTableCreateCompanionBuilder,
          $$StockLedgerTableTableUpdateCompanionBuilder,
          (
            StockLedgerTableData,
            BaseReferences<
              _$AppDatabase,
              $StockLedgerTableTable,
              StockLedgerTableData
            >,
          ),
          StockLedgerTableData,
          PrefetchHooks Function()
        > {
  $$StockLedgerTableTableTableManager(
    _$AppDatabase db,
    $StockLedgerTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockLedgerTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockLedgerTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockLedgerTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> variantId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> changeType = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<double?> quantityBefore = const Value.absent(),
                Value<double?> quantityAfter = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> sourceType = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockLedgerTableCompanion(
                id: id,
                variantId: variantId,
                productId: productId,
                branchId: branchId,
                businessId: businessId,
                changeType: changeType,
                quantity: quantity,
                quantityBefore: quantityBefore,
                quantityAfter: quantityAfter,
                reason: reason,
                note: note,
                sourceType: sourceType,
                sourceId: sourceId,
                createdAt: createdAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String variantId,
                required String productId,
                required String branchId,
                required String businessId,
                required String changeType,
                required double quantity,
                Value<double?> quantityBefore = const Value.absent(),
                Value<double?> quantityAfter = const Value.absent(),
                required String reason,
                Value<String?> note = const Value.absent(),
                Value<String?> sourceType = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockLedgerTableCompanion.insert(
                id: id,
                variantId: variantId,
                productId: productId,
                branchId: branchId,
                businessId: businessId,
                changeType: changeType,
                quantity: quantity,
                quantityBefore: quantityBefore,
                quantityAfter: quantityAfter,
                reason: reason,
                note: note,
                sourceType: sourceType,
                sourceId: sourceId,
                createdAt: createdAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StockLedgerTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StockLedgerTableTable,
      StockLedgerTableData,
      $$StockLedgerTableTableFilterComposer,
      $$StockLedgerTableTableOrderingComposer,
      $$StockLedgerTableTableAnnotationComposer,
      $$StockLedgerTableTableCreateCompanionBuilder,
      $$StockLedgerTableTableUpdateCompanionBuilder,
      (
        StockLedgerTableData,
        BaseReferences<
          _$AppDatabase,
          $StockLedgerTableTable,
          StockLedgerTableData
        >,
      ),
      StockLedgerTableData,
      PrefetchHooks Function()
    >;
typedef $$ReceiptSettingsTableTableCreateCompanionBuilder =
    ReceiptSettingsTableCompanion Function({
      required String id,
      required String businessId,
      Value<String> businessName,
      Value<String> storeName,
      Value<String> ownerName,
      Value<String> address,
      Value<String> contactNumber,
      Value<String> email,
      Value<String> website,
      Value<String> tinNumber,
      Value<String> permitNumber,
      Value<String> headerText,
      Value<String> footerText,
      Value<String> returnPolicy,
      Value<String> customNotes,
      Value<bool> showLogo,
      Value<String> logoLocalPath,
      Value<String> logoUrl,
      Value<bool> showQrCode,
      Value<bool> showTaxBreakdown,
      Value<bool> showCashierName,
      Value<bool> showCustomerName,
      Value<bool> showDateTime,
      Value<bool> showOrderId,
      Value<String> paperSize,
      Value<String> fontSize,
      Value<String> textAlignment,
      Value<bool> autoPrintAfterCheckout,
      Value<bool> printDuplicateCopy,
      Value<bool> thermalPrinterEnabled,
      Value<String> currencySymbol,
      Value<double> taxPercentage,
      Value<double> serviceChargePercentage,
      Value<bool> vatInclusive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });
typedef $$ReceiptSettingsTableTableUpdateCompanionBuilder =
    ReceiptSettingsTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> businessName,
      Value<String> storeName,
      Value<String> ownerName,
      Value<String> address,
      Value<String> contactNumber,
      Value<String> email,
      Value<String> website,
      Value<String> tinNumber,
      Value<String> permitNumber,
      Value<String> headerText,
      Value<String> footerText,
      Value<String> returnPolicy,
      Value<String> customNotes,
      Value<bool> showLogo,
      Value<String> logoLocalPath,
      Value<String> logoUrl,
      Value<bool> showQrCode,
      Value<bool> showTaxBreakdown,
      Value<bool> showCashierName,
      Value<bool> showCustomerName,
      Value<bool> showDateTime,
      Value<bool> showOrderId,
      Value<String> paperSize,
      Value<String> fontSize,
      Value<String> textAlignment,
      Value<bool> autoPrintAfterCheckout,
      Value<bool> printDuplicateCopy,
      Value<bool> thermalPrinterEnabled,
      Value<String> currencySymbol,
      Value<double> taxPercentage,
      Value<double> serviceChargePercentage,
      Value<bool> vatInclusive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });

class $$ReceiptSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ReceiptSettingsTableTable> {
  $$ReceiptSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeName => $composableBuilder(
    column: $table.storeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerName => $composableBuilder(
    column: $table.ownerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactNumber => $composableBuilder(
    column: $table.contactNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get website => $composableBuilder(
    column: $table.website,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tinNumber => $composableBuilder(
    column: $table.tinNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get permitNumber => $composableBuilder(
    column: $table.permitNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get headerText => $composableBuilder(
    column: $table.headerText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get footerText => $composableBuilder(
    column: $table.footerText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get returnPolicy => $composableBuilder(
    column: $table.returnPolicy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customNotes => $composableBuilder(
    column: $table.customNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showLogo => $composableBuilder(
    column: $table.showLogo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logoLocalPath => $composableBuilder(
    column: $table.logoLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logoUrl => $composableBuilder(
    column: $table.logoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showQrCode => $composableBuilder(
    column: $table.showQrCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showTaxBreakdown => $composableBuilder(
    column: $table.showTaxBreakdown,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showCashierName => $composableBuilder(
    column: $table.showCashierName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showCustomerName => $composableBuilder(
    column: $table.showCustomerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showDateTime => $composableBuilder(
    column: $table.showDateTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showOrderId => $composableBuilder(
    column: $table.showOrderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paperSize => $composableBuilder(
    column: $table.paperSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fontSize => $composableBuilder(
    column: $table.fontSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textAlignment => $composableBuilder(
    column: $table.textAlignment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoPrintAfterCheckout => $composableBuilder(
    column: $table.autoPrintAfterCheckout,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get printDuplicateCopy => $composableBuilder(
    column: $table.printDuplicateCopy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get thermalPrinterEnabled => $composableBuilder(
    column: $table.thermalPrinterEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencySymbol => $composableBuilder(
    column: $table.currencySymbol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get taxPercentage => $composableBuilder(
    column: $table.taxPercentage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get serviceChargePercentage => $composableBuilder(
    column: $table.serviceChargePercentage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get vatInclusive => $composableBuilder(
    column: $table.vatInclusive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReceiptSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ReceiptSettingsTableTable> {
  $$ReceiptSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeName => $composableBuilder(
    column: $table.storeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerName => $composableBuilder(
    column: $table.ownerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactNumber => $composableBuilder(
    column: $table.contactNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get website => $composableBuilder(
    column: $table.website,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tinNumber => $composableBuilder(
    column: $table.tinNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get permitNumber => $composableBuilder(
    column: $table.permitNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get headerText => $composableBuilder(
    column: $table.headerText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get footerText => $composableBuilder(
    column: $table.footerText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get returnPolicy => $composableBuilder(
    column: $table.returnPolicy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customNotes => $composableBuilder(
    column: $table.customNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showLogo => $composableBuilder(
    column: $table.showLogo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logoLocalPath => $composableBuilder(
    column: $table.logoLocalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logoUrl => $composableBuilder(
    column: $table.logoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showQrCode => $composableBuilder(
    column: $table.showQrCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showTaxBreakdown => $composableBuilder(
    column: $table.showTaxBreakdown,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showCashierName => $composableBuilder(
    column: $table.showCashierName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showCustomerName => $composableBuilder(
    column: $table.showCustomerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showDateTime => $composableBuilder(
    column: $table.showDateTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showOrderId => $composableBuilder(
    column: $table.showOrderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paperSize => $composableBuilder(
    column: $table.paperSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fontSize => $composableBuilder(
    column: $table.fontSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textAlignment => $composableBuilder(
    column: $table.textAlignment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoPrintAfterCheckout => $composableBuilder(
    column: $table.autoPrintAfterCheckout,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get printDuplicateCopy => $composableBuilder(
    column: $table.printDuplicateCopy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get thermalPrinterEnabled => $composableBuilder(
    column: $table.thermalPrinterEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencySymbol => $composableBuilder(
    column: $table.currencySymbol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get taxPercentage => $composableBuilder(
    column: $table.taxPercentage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get serviceChargePercentage => $composableBuilder(
    column: $table.serviceChargePercentage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get vatInclusive => $composableBuilder(
    column: $table.vatInclusive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReceiptSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReceiptSettingsTableTable> {
  $$ReceiptSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get storeName =>
      $composableBuilder(column: $table.storeName, builder: (column) => column);

  GeneratedColumn<String> get ownerName =>
      $composableBuilder(column: $table.ownerName, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get contactNumber => $composableBuilder(
    column: $table.contactNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get website =>
      $composableBuilder(column: $table.website, builder: (column) => column);

  GeneratedColumn<String> get tinNumber =>
      $composableBuilder(column: $table.tinNumber, builder: (column) => column);

  GeneratedColumn<String> get permitNumber => $composableBuilder(
    column: $table.permitNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get headerText => $composableBuilder(
    column: $table.headerText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get footerText => $composableBuilder(
    column: $table.footerText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get returnPolicy => $composableBuilder(
    column: $table.returnPolicy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customNotes => $composableBuilder(
    column: $table.customNotes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showLogo =>
      $composableBuilder(column: $table.showLogo, builder: (column) => column);

  GeneratedColumn<String> get logoLocalPath => $composableBuilder(
    column: $table.logoLocalPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get logoUrl =>
      $composableBuilder(column: $table.logoUrl, builder: (column) => column);

  GeneratedColumn<bool> get showQrCode => $composableBuilder(
    column: $table.showQrCode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showTaxBreakdown => $composableBuilder(
    column: $table.showTaxBreakdown,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showCashierName => $composableBuilder(
    column: $table.showCashierName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showCustomerName => $composableBuilder(
    column: $table.showCustomerName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showDateTime => $composableBuilder(
    column: $table.showDateTime,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showOrderId => $composableBuilder(
    column: $table.showOrderId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paperSize =>
      $composableBuilder(column: $table.paperSize, builder: (column) => column);

  GeneratedColumn<String> get fontSize =>
      $composableBuilder(column: $table.fontSize, builder: (column) => column);

  GeneratedColumn<String> get textAlignment => $composableBuilder(
    column: $table.textAlignment,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoPrintAfterCheckout => $composableBuilder(
    column: $table.autoPrintAfterCheckout,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get printDuplicateCopy => $composableBuilder(
    column: $table.printDuplicateCopy,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get thermalPrinterEnabled => $composableBuilder(
    column: $table.thermalPrinterEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencySymbol => $composableBuilder(
    column: $table.currencySymbol,
    builder: (column) => column,
  );

  GeneratedColumn<double> get taxPercentage => $composableBuilder(
    column: $table.taxPercentage,
    builder: (column) => column,
  );

  GeneratedColumn<double> get serviceChargePercentage => $composableBuilder(
    column: $table.serviceChargePercentage,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get vatInclusive => $composableBuilder(
    column: $table.vatInclusive,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );
}

class $$ReceiptSettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReceiptSettingsTableTable,
          ReceiptSettingsRow,
          $$ReceiptSettingsTableTableFilterComposer,
          $$ReceiptSettingsTableTableOrderingComposer,
          $$ReceiptSettingsTableTableAnnotationComposer,
          $$ReceiptSettingsTableTableCreateCompanionBuilder,
          $$ReceiptSettingsTableTableUpdateCompanionBuilder,
          (
            ReceiptSettingsRow,
            BaseReferences<
              _$AppDatabase,
              $ReceiptSettingsTableTable,
              ReceiptSettingsRow
            >,
          ),
          ReceiptSettingsRow,
          PrefetchHooks Function()
        > {
  $$ReceiptSettingsTableTableTableManager(
    _$AppDatabase db,
    $ReceiptSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptSettingsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ReceiptSettingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> businessName = const Value.absent(),
                Value<String> storeName = const Value.absent(),
                Value<String> ownerName = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String> contactNumber = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> website = const Value.absent(),
                Value<String> tinNumber = const Value.absent(),
                Value<String> permitNumber = const Value.absent(),
                Value<String> headerText = const Value.absent(),
                Value<String> footerText = const Value.absent(),
                Value<String> returnPolicy = const Value.absent(),
                Value<String> customNotes = const Value.absent(),
                Value<bool> showLogo = const Value.absent(),
                Value<String> logoLocalPath = const Value.absent(),
                Value<String> logoUrl = const Value.absent(),
                Value<bool> showQrCode = const Value.absent(),
                Value<bool> showTaxBreakdown = const Value.absent(),
                Value<bool> showCashierName = const Value.absent(),
                Value<bool> showCustomerName = const Value.absent(),
                Value<bool> showDateTime = const Value.absent(),
                Value<bool> showOrderId = const Value.absent(),
                Value<String> paperSize = const Value.absent(),
                Value<String> fontSize = const Value.absent(),
                Value<String> textAlignment = const Value.absent(),
                Value<bool> autoPrintAfterCheckout = const Value.absent(),
                Value<bool> printDuplicateCopy = const Value.absent(),
                Value<bool> thermalPrinterEnabled = const Value.absent(),
                Value<String> currencySymbol = const Value.absent(),
                Value<double> taxPercentage = const Value.absent(),
                Value<double> serviceChargePercentage = const Value.absent(),
                Value<bool> vatInclusive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReceiptSettingsTableCompanion(
                id: id,
                businessId: businessId,
                businessName: businessName,
                storeName: storeName,
                ownerName: ownerName,
                address: address,
                contactNumber: contactNumber,
                email: email,
                website: website,
                tinNumber: tinNumber,
                permitNumber: permitNumber,
                headerText: headerText,
                footerText: footerText,
                returnPolicy: returnPolicy,
                customNotes: customNotes,
                showLogo: showLogo,
                logoLocalPath: logoLocalPath,
                logoUrl: logoUrl,
                showQrCode: showQrCode,
                showTaxBreakdown: showTaxBreakdown,
                showCashierName: showCashierName,
                showCustomerName: showCustomerName,
                showDateTime: showDateTime,
                showOrderId: showOrderId,
                paperSize: paperSize,
                fontSize: fontSize,
                textAlignment: textAlignment,
                autoPrintAfterCheckout: autoPrintAfterCheckout,
                printDuplicateCopy: printDuplicateCopy,
                thermalPrinterEnabled: thermalPrinterEnabled,
                currencySymbol: currencySymbol,
                taxPercentage: taxPercentage,
                serviceChargePercentage: serviceChargePercentage,
                vatInclusive: vatInclusive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                Value<String> businessName = const Value.absent(),
                Value<String> storeName = const Value.absent(),
                Value<String> ownerName = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String> contactNumber = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> website = const Value.absent(),
                Value<String> tinNumber = const Value.absent(),
                Value<String> permitNumber = const Value.absent(),
                Value<String> headerText = const Value.absent(),
                Value<String> footerText = const Value.absent(),
                Value<String> returnPolicy = const Value.absent(),
                Value<String> customNotes = const Value.absent(),
                Value<bool> showLogo = const Value.absent(),
                Value<String> logoLocalPath = const Value.absent(),
                Value<String> logoUrl = const Value.absent(),
                Value<bool> showQrCode = const Value.absent(),
                Value<bool> showTaxBreakdown = const Value.absent(),
                Value<bool> showCashierName = const Value.absent(),
                Value<bool> showCustomerName = const Value.absent(),
                Value<bool> showDateTime = const Value.absent(),
                Value<bool> showOrderId = const Value.absent(),
                Value<String> paperSize = const Value.absent(),
                Value<String> fontSize = const Value.absent(),
                Value<String> textAlignment = const Value.absent(),
                Value<bool> autoPrintAfterCheckout = const Value.absent(),
                Value<bool> printDuplicateCopy = const Value.absent(),
                Value<bool> thermalPrinterEnabled = const Value.absent(),
                Value<String> currencySymbol = const Value.absent(),
                Value<double> taxPercentage = const Value.absent(),
                Value<double> serviceChargePercentage = const Value.absent(),
                Value<bool> vatInclusive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReceiptSettingsTableCompanion.insert(
                id: id,
                businessId: businessId,
                businessName: businessName,
                storeName: storeName,
                ownerName: ownerName,
                address: address,
                contactNumber: contactNumber,
                email: email,
                website: website,
                tinNumber: tinNumber,
                permitNumber: permitNumber,
                headerText: headerText,
                footerText: footerText,
                returnPolicy: returnPolicy,
                customNotes: customNotes,
                showLogo: showLogo,
                logoLocalPath: logoLocalPath,
                logoUrl: logoUrl,
                showQrCode: showQrCode,
                showTaxBreakdown: showTaxBreakdown,
                showCashierName: showCashierName,
                showCustomerName: showCustomerName,
                showDateTime: showDateTime,
                showOrderId: showOrderId,
                paperSize: paperSize,
                fontSize: fontSize,
                textAlignment: textAlignment,
                autoPrintAfterCheckout: autoPrintAfterCheckout,
                printDuplicateCopy: printDuplicateCopy,
                thermalPrinterEnabled: thermalPrinterEnabled,
                currencySymbol: currencySymbol,
                taxPercentage: taxPercentage,
                serviceChargePercentage: serviceChargePercentage,
                vatInclusive: vatInclusive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReceiptSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReceiptSettingsTableTable,
      ReceiptSettingsRow,
      $$ReceiptSettingsTableTableFilterComposer,
      $$ReceiptSettingsTableTableOrderingComposer,
      $$ReceiptSettingsTableTableAnnotationComposer,
      $$ReceiptSettingsTableTableCreateCompanionBuilder,
      $$ReceiptSettingsTableTableUpdateCompanionBuilder,
      (
        ReceiptSettingsRow,
        BaseReferences<
          _$AppDatabase,
          $ReceiptSettingsTableTable,
          ReceiptSettingsRow
        >,
      ),
      ReceiptSettingsRow,
      PrefetchHooks Function()
    >;
typedef $$AuditLogsTableTableCreateCompanionBuilder =
    AuditLogsTableCompanion Function({
      required String id,
      required String businessId,
      required String branchId,
      required String userId,
      required String actionType,
      required String entityType,
      Value<String?> entityId,
      required String description,
      Value<String> metadata,
      Value<String> deviceId,
      Value<DateTime> createdAt,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<int> rowid,
    });
typedef $$AuditLogsTableTableUpdateCompanionBuilder =
    AuditLogsTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> branchId,
      Value<String> userId,
      Value<String> actionType,
      Value<String> entityType,
      Value<String?> entityId,
      Value<String> description,
      Value<String> metadata,
      Value<String> deviceId,
      Value<DateTime> createdAt,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<int> rowid,
    });

class $$AuditLogsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AuditLogsTableTable> {
  $$AuditLogsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditLogsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditLogsTableTable> {
  $$AuditLogsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditLogsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditLogsTableTable> {
  $$AuditLogsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);
}

class $$AuditLogsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuditLogsTableTable,
          AuditLogRow,
          $$AuditLogsTableTableFilterComposer,
          $$AuditLogsTableTableOrderingComposer,
          $$AuditLogsTableTableAnnotationComposer,
          $$AuditLogsTableTableCreateCompanionBuilder,
          $$AuditLogsTableTableUpdateCompanionBuilder,
          (
            AuditLogRow,
            BaseReferences<_$AppDatabase, $AuditLogsTableTable, AuditLogRow>,
          ),
          AuditLogRow,
          PrefetchHooks Function()
        > {
  $$AuditLogsTableTableTableManager(
    _$AppDatabase db,
    $AuditLogsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditLogsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditLogsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditLogsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> actionType = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String?> entityId = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> metadata = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditLogsTableCompanion(
                id: id,
                businessId: businessId,
                branchId: branchId,
                userId: userId,
                actionType: actionType,
                entityType: entityType,
                entityId: entityId,
                description: description,
                metadata: metadata,
                deviceId: deviceId,
                createdAt: createdAt,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String branchId,
                required String userId,
                required String actionType,
                required String entityType,
                Value<String?> entityId = const Value.absent(),
                required String description,
                Value<String> metadata = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditLogsTableCompanion.insert(
                id: id,
                businessId: businessId,
                branchId: branchId,
                userId: userId,
                actionType: actionType,
                entityType: entityType,
                entityId: entityId,
                description: description,
                metadata: metadata,
                deviceId: deviceId,
                createdAt: createdAt,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuditLogsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuditLogsTableTable,
      AuditLogRow,
      $$AuditLogsTableTableFilterComposer,
      $$AuditLogsTableTableOrderingComposer,
      $$AuditLogsTableTableAnnotationComposer,
      $$AuditLogsTableTableCreateCompanionBuilder,
      $$AuditLogsTableTableUpdateCompanionBuilder,
      (
        AuditLogRow,
        BaseReferences<_$AppDatabase, $AuditLogsTableTable, AuditLogRow>,
      ),
      AuditLogRow,
      PrefetchHooks Function()
    >;
typedef $$EmployeesTableTableCreateCompanionBuilder =
    EmployeesTableCompanion Function({
      required String id,
      required String businessId,
      Value<String?> userId,
      Value<String?> authUserId,
      Value<String?> email,
      Value<String?> fullName,
      Value<String?> roleId,
      Value<String?> roleName,
      Value<String?> branchId,
      Value<bool> isActive,
      Value<DateTime?> createdAt,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<int> rowid,
    });
typedef $$EmployeesTableTableUpdateCompanionBuilder =
    EmployeesTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String?> userId,
      Value<String?> authUserId,
      Value<String?> email,
      Value<String?> fullName,
      Value<String?> roleId,
      Value<String?> roleName,
      Value<String?> branchId,
      Value<bool> isActive,
      Value<DateTime?> createdAt,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<int> rowid,
    });

class $$EmployeesTableTableFilterComposer
    extends Composer<_$AppDatabase, $EmployeesTableTable> {
  $$EmployeesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authUserId => $composableBuilder(
    column: $table.authUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roleId => $composableBuilder(
    column: $table.roleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roleName => $composableBuilder(
    column: $table.roleName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EmployeesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $EmployeesTableTable> {
  $$EmployeesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authUserId => $composableBuilder(
    column: $table.authUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roleId => $composableBuilder(
    column: $table.roleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roleName => $composableBuilder(
    column: $table.roleName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EmployeesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmployeesTableTable> {
  $$EmployeesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get authUserId => $composableBuilder(
    column: $table.authUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get roleId =>
      $composableBuilder(column: $table.roleId, builder: (column) => column);

  GeneratedColumn<String> get roleName =>
      $composableBuilder(column: $table.roleName, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);
}

class $$EmployeesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EmployeesTableTable,
          EmployeeRow,
          $$EmployeesTableTableFilterComposer,
          $$EmployeesTableTableOrderingComposer,
          $$EmployeesTableTableAnnotationComposer,
          $$EmployeesTableTableCreateCompanionBuilder,
          $$EmployeesTableTableUpdateCompanionBuilder,
          (
            EmployeeRow,
            BaseReferences<_$AppDatabase, $EmployeesTableTable, EmployeeRow>,
          ),
          EmployeeRow,
          PrefetchHooks Function()
        > {
  $$EmployeesTableTableTableManager(
    _$AppDatabase db,
    $EmployeesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmployeesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmployeesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmployeesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> authUserId = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> fullName = const Value.absent(),
                Value<String?> roleId = const Value.absent(),
                Value<String?> roleName = const Value.absent(),
                Value<String?> branchId = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EmployeesTableCompanion(
                id: id,
                businessId: businessId,
                userId: userId,
                authUserId: authUserId,
                email: email,
                fullName: fullName,
                roleId: roleId,
                roleName: roleName,
                branchId: branchId,
                isActive: isActive,
                createdAt: createdAt,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                Value<String?> userId = const Value.absent(),
                Value<String?> authUserId = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> fullName = const Value.absent(),
                Value<String?> roleId = const Value.absent(),
                Value<String?> roleName = const Value.absent(),
                Value<String?> branchId = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EmployeesTableCompanion.insert(
                id: id,
                businessId: businessId,
                userId: userId,
                authUserId: authUserId,
                email: email,
                fullName: fullName,
                roleId: roleId,
                roleName: roleName,
                branchId: branchId,
                isActive: isActive,
                createdAt: createdAt,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EmployeesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EmployeesTableTable,
      EmployeeRow,
      $$EmployeesTableTableFilterComposer,
      $$EmployeesTableTableOrderingComposer,
      $$EmployeesTableTableAnnotationComposer,
      $$EmployeesTableTableCreateCompanionBuilder,
      $$EmployeesTableTableUpdateCompanionBuilder,
      (
        EmployeeRow,
        BaseReferences<_$AppDatabase, $EmployeesTableTable, EmployeeRow>,
      ),
      EmployeeRow,
      PrefetchHooks Function()
    >;
typedef $$EmployeePermissionsTableTableCreateCompanionBuilder =
    EmployeePermissionsTableCompanion Function({
      required String authUserId,
      Value<String?> employeeId,
      Value<String> permissionsJson,
      Value<DateTime?> syncedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$EmployeePermissionsTableTableUpdateCompanionBuilder =
    EmployeePermissionsTableCompanion Function({
      Value<String> authUserId,
      Value<String?> employeeId,
      Value<String> permissionsJson,
      Value<DateTime?> syncedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$EmployeePermissionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $EmployeePermissionsTableTable> {
  $$EmployeePermissionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get authUserId => $composableBuilder(
    column: $table.authUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get permissionsJson => $composableBuilder(
    column: $table.permissionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EmployeePermissionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $EmployeePermissionsTableTable> {
  $$EmployeePermissionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get authUserId => $composableBuilder(
    column: $table.authUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get permissionsJson => $composableBuilder(
    column: $table.permissionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EmployeePermissionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmployeePermissionsTableTable> {
  $$EmployeePermissionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get authUserId => $composableBuilder(
    column: $table.authUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get permissionsJson => $composableBuilder(
    column: $table.permissionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$EmployeePermissionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EmployeePermissionsTableTable,
          EmployeePermissionsRow,
          $$EmployeePermissionsTableTableFilterComposer,
          $$EmployeePermissionsTableTableOrderingComposer,
          $$EmployeePermissionsTableTableAnnotationComposer,
          $$EmployeePermissionsTableTableCreateCompanionBuilder,
          $$EmployeePermissionsTableTableUpdateCompanionBuilder,
          (
            EmployeePermissionsRow,
            BaseReferences<
              _$AppDatabase,
              $EmployeePermissionsTableTable,
              EmployeePermissionsRow
            >,
          ),
          EmployeePermissionsRow,
          PrefetchHooks Function()
        > {
  $$EmployeePermissionsTableTableTableManager(
    _$AppDatabase db,
    $EmployeePermissionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmployeePermissionsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$EmployeePermissionsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EmployeePermissionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> authUserId = const Value.absent(),
                Value<String?> employeeId = const Value.absent(),
                Value<String> permissionsJson = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EmployeePermissionsTableCompanion(
                authUserId: authUserId,
                employeeId: employeeId,
                permissionsJson: permissionsJson,
                syncedAt: syncedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String authUserId,
                Value<String?> employeeId = const Value.absent(),
                Value<String> permissionsJson = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EmployeePermissionsTableCompanion.insert(
                authUserId: authUserId,
                employeeId: employeeId,
                permissionsJson: permissionsJson,
                syncedAt: syncedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EmployeePermissionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EmployeePermissionsTableTable,
      EmployeePermissionsRow,
      $$EmployeePermissionsTableTableFilterComposer,
      $$EmployeePermissionsTableTableOrderingComposer,
      $$EmployeePermissionsTableTableAnnotationComposer,
      $$EmployeePermissionsTableTableCreateCompanionBuilder,
      $$EmployeePermissionsTableTableUpdateCompanionBuilder,
      (
        EmployeePermissionsRow,
        BaseReferences<
          _$AppDatabase,
          $EmployeePermissionsTableTable,
          EmployeePermissionsRow
        >,
      ),
      EmployeePermissionsRow,
      PrefetchHooks Function()
    >;
typedef $$BusinessModulesTableTableCreateCompanionBuilder =
    BusinessModulesTableCompanion Function({
      required String businessId,
      required String moduleCode,
      Value<bool> enabled,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });
typedef $$BusinessModulesTableTableUpdateCompanionBuilder =
    BusinessModulesTableCompanion Function({
      Value<String> businessId,
      Value<String> moduleCode,
      Value<bool> enabled,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$BusinessModulesTableTableFilterComposer
    extends Composer<_$AppDatabase, $BusinessModulesTableTable> {
  $$BusinessModulesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get moduleCode => $composableBuilder(
    column: $table.moduleCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BusinessModulesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $BusinessModulesTableTable> {
  $$BusinessModulesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get moduleCode => $composableBuilder(
    column: $table.moduleCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BusinessModulesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $BusinessModulesTableTable> {
  $$BusinessModulesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get moduleCode => $composableBuilder(
    column: $table.moduleCode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$BusinessModulesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BusinessModulesTableTable,
          BusinessModuleRow,
          $$BusinessModulesTableTableFilterComposer,
          $$BusinessModulesTableTableOrderingComposer,
          $$BusinessModulesTableTableAnnotationComposer,
          $$BusinessModulesTableTableCreateCompanionBuilder,
          $$BusinessModulesTableTableUpdateCompanionBuilder,
          (
            BusinessModuleRow,
            BaseReferences<
              _$AppDatabase,
              $BusinessModulesTableTable,
              BusinessModuleRow
            >,
          ),
          BusinessModuleRow,
          PrefetchHooks Function()
        > {
  $$BusinessModulesTableTableTableManager(
    _$AppDatabase db,
    $BusinessModulesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BusinessModulesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BusinessModulesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$BusinessModulesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> businessId = const Value.absent(),
                Value<String> moduleCode = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BusinessModulesTableCompanion(
                businessId: businessId,
                moduleCode: moduleCode,
                enabled: enabled,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String businessId,
                required String moduleCode,
                Value<bool> enabled = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BusinessModulesTableCompanion.insert(
                businessId: businessId,
                moduleCode: moduleCode,
                enabled: enabled,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BusinessModulesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BusinessModulesTableTable,
      BusinessModuleRow,
      $$BusinessModulesTableTableFilterComposer,
      $$BusinessModulesTableTableOrderingComposer,
      $$BusinessModulesTableTableAnnotationComposer,
      $$BusinessModulesTableTableCreateCompanionBuilder,
      $$BusinessModulesTableTableUpdateCompanionBuilder,
      (
        BusinessModuleRow,
        BaseReferences<
          _$AppDatabase,
          $BusinessModulesTableTable,
          BusinessModuleRow
        >,
      ),
      BusinessModuleRow,
      PrefetchHooks Function()
    >;
typedef $$SuppliersTableTableCreateCompanionBuilder =
    SuppliersTableCompanion Function({
      required String id,
      required String businessId,
      required String name,
      Value<String?> contactName,
      Value<String?> phone,
      Value<String?> email,
      Value<String?> address,
      Value<String?> taxId,
      Value<String?> notes,
      Value<bool> isActive,
      Value<bool> isDeleted,
      Value<DateTime?> deletedAt,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<DateTime> createdAt,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });
typedef $$SuppliersTableTableUpdateCompanionBuilder =
    SuppliersTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> name,
      Value<String?> contactName,
      Value<String?> phone,
      Value<String?> email,
      Value<String?> address,
      Value<String?> taxId,
      Value<String?> notes,
      Value<bool> isActive,
      Value<bool> isDeleted,
      Value<DateTime?> deletedAt,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<DateTime> createdAt,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });

class $$SuppliersTableTableFilterComposer
    extends Composer<_$AppDatabase, $SuppliersTableTable> {
  $$SuppliersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactName => $composableBuilder(
    column: $table.contactName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxId => $composableBuilder(
    column: $table.taxId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SuppliersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SuppliersTableTable> {
  $$SuppliersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactName => $composableBuilder(
    column: $table.contactName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxId => $composableBuilder(
    column: $table.taxId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SuppliersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SuppliersTableTable> {
  $$SuppliersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get contactName => $composableBuilder(
    column: $table.contactName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get taxId =>
      $composableBuilder(column: $table.taxId, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );
}

class $$SuppliersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SuppliersTableTable,
          SupplierRow,
          $$SuppliersTableTableFilterComposer,
          $$SuppliersTableTableOrderingComposer,
          $$SuppliersTableTableAnnotationComposer,
          $$SuppliersTableTableCreateCompanionBuilder,
          $$SuppliersTableTableUpdateCompanionBuilder,
          (
            SupplierRow,
            BaseReferences<_$AppDatabase, $SuppliersTableTable, SupplierRow>,
          ),
          SupplierRow,
          PrefetchHooks Function()
        > {
  $$SuppliersTableTableTableManager(
    _$AppDatabase db,
    $SuppliersTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SuppliersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SuppliersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SuppliersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> contactName = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> taxId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SuppliersTableCompanion(
                id: id,
                businessId: businessId,
                name: name,
                contactName: contactName,
                phone: phone,
                email: email,
                address: address,
                taxId: taxId,
                notes: notes,
                isActive: isActive,
                isDeleted: isDeleted,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                createdAt: createdAt,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String name,
                Value<String?> contactName = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> taxId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SuppliersTableCompanion.insert(
                id: id,
                businessId: businessId,
                name: name,
                contactName: contactName,
                phone: phone,
                email: email,
                address: address,
                taxId: taxId,
                notes: notes,
                isActive: isActive,
                isDeleted: isDeleted,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                createdAt: createdAt,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SuppliersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SuppliersTableTable,
      SupplierRow,
      $$SuppliersTableTableFilterComposer,
      $$SuppliersTableTableOrderingComposer,
      $$SuppliersTableTableAnnotationComposer,
      $$SuppliersTableTableCreateCompanionBuilder,
      $$SuppliersTableTableUpdateCompanionBuilder,
      (
        SupplierRow,
        BaseReferences<_$AppDatabase, $SuppliersTableTable, SupplierRow>,
      ),
      SupplierRow,
      PrefetchHooks Function()
    >;
typedef $$PurchaseOrdersTableTableCreateCompanionBuilder =
    PurchaseOrdersTableCompanion Function({
      required String id,
      required String businessId,
      Value<String?> branchId,
      Value<String?> supplierId,
      Value<String?> supplierName,
      Value<String> status,
      required String poNumber,
      Value<String?> notes,
      Value<DateTime?> expectedDelivery,
      Value<double> totalAmount,
      Value<String?> createdById,
      Value<String?> createdByName,
      Value<DateTime?> submittedAt,
      Value<DateTime?> approvedAt,
      Value<String?> approvedById,
      Value<String?> approvedByName,
      Value<bool> isDeleted,
      Value<DateTime?> deletedAt,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<DateTime> createdAt,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });
typedef $$PurchaseOrdersTableTableUpdateCompanionBuilder =
    PurchaseOrdersTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String?> branchId,
      Value<String?> supplierId,
      Value<String?> supplierName,
      Value<String> status,
      Value<String> poNumber,
      Value<String?> notes,
      Value<DateTime?> expectedDelivery,
      Value<double> totalAmount,
      Value<String?> createdById,
      Value<String?> createdByName,
      Value<DateTime?> submittedAt,
      Value<DateTime?> approvedAt,
      Value<String?> approvedById,
      Value<String?> approvedByName,
      Value<bool> isDeleted,
      Value<DateTime?> deletedAt,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<DateTime> createdAt,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });

class $$PurchaseOrdersTableTableFilterComposer
    extends Composer<_$AppDatabase, $PurchaseOrdersTableTable> {
  $$PurchaseOrdersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supplierId => $composableBuilder(
    column: $table.supplierId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supplierName => $composableBuilder(
    column: $table.supplierName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get poNumber => $composableBuilder(
    column: $table.poNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expectedDelivery => $composableBuilder(
    column: $table.expectedDelivery,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdById => $composableBuilder(
    column: $table.createdById,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdByName => $composableBuilder(
    column: $table.createdByName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get approvedAt => $composableBuilder(
    column: $table.approvedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get approvedById => $composableBuilder(
    column: $table.approvedById,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get approvedByName => $composableBuilder(
    column: $table.approvedByName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PurchaseOrdersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PurchaseOrdersTableTable> {
  $$PurchaseOrdersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supplierId => $composableBuilder(
    column: $table.supplierId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supplierName => $composableBuilder(
    column: $table.supplierName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get poNumber => $composableBuilder(
    column: $table.poNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expectedDelivery => $composableBuilder(
    column: $table.expectedDelivery,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdById => $composableBuilder(
    column: $table.createdById,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdByName => $composableBuilder(
    column: $table.createdByName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get approvedAt => $composableBuilder(
    column: $table.approvedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get approvedById => $composableBuilder(
    column: $table.approvedById,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get approvedByName => $composableBuilder(
    column: $table.approvedByName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PurchaseOrdersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PurchaseOrdersTableTable> {
  $$PurchaseOrdersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get supplierId => $composableBuilder(
    column: $table.supplierId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get supplierName => $composableBuilder(
    column: $table.supplierName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get poNumber =>
      $composableBuilder(column: $table.poNumber, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get expectedDelivery => $composableBuilder(
    column: $table.expectedDelivery,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdById => $composableBuilder(
    column: $table.createdById,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdByName => $composableBuilder(
    column: $table.createdByName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get approvedAt => $composableBuilder(
    column: $table.approvedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get approvedById => $composableBuilder(
    column: $table.approvedById,
    builder: (column) => column,
  );

  GeneratedColumn<String> get approvedByName => $composableBuilder(
    column: $table.approvedByName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );
}

class $$PurchaseOrdersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PurchaseOrdersTableTable,
          PurchaseOrderRow,
          $$PurchaseOrdersTableTableFilterComposer,
          $$PurchaseOrdersTableTableOrderingComposer,
          $$PurchaseOrdersTableTableAnnotationComposer,
          $$PurchaseOrdersTableTableCreateCompanionBuilder,
          $$PurchaseOrdersTableTableUpdateCompanionBuilder,
          (
            PurchaseOrderRow,
            BaseReferences<
              _$AppDatabase,
              $PurchaseOrdersTableTable,
              PurchaseOrderRow
            >,
          ),
          PurchaseOrderRow,
          PrefetchHooks Function()
        > {
  $$PurchaseOrdersTableTableTableManager(
    _$AppDatabase db,
    $PurchaseOrdersTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PurchaseOrdersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PurchaseOrdersTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PurchaseOrdersTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String?> branchId = const Value.absent(),
                Value<String?> supplierId = const Value.absent(),
                Value<String?> supplierName = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> poNumber = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime?> expectedDelivery = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<String?> createdById = const Value.absent(),
                Value<String?> createdByName = const Value.absent(),
                Value<DateTime?> submittedAt = const Value.absent(),
                Value<DateTime?> approvedAt = const Value.absent(),
                Value<String?> approvedById = const Value.absent(),
                Value<String?> approvedByName = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PurchaseOrdersTableCompanion(
                id: id,
                businessId: businessId,
                branchId: branchId,
                supplierId: supplierId,
                supplierName: supplierName,
                status: status,
                poNumber: poNumber,
                notes: notes,
                expectedDelivery: expectedDelivery,
                totalAmount: totalAmount,
                createdById: createdById,
                createdByName: createdByName,
                submittedAt: submittedAt,
                approvedAt: approvedAt,
                approvedById: approvedById,
                approvedByName: approvedByName,
                isDeleted: isDeleted,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                createdAt: createdAt,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                Value<String?> branchId = const Value.absent(),
                Value<String?> supplierId = const Value.absent(),
                Value<String?> supplierName = const Value.absent(),
                Value<String> status = const Value.absent(),
                required String poNumber,
                Value<String?> notes = const Value.absent(),
                Value<DateTime?> expectedDelivery = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<String?> createdById = const Value.absent(),
                Value<String?> createdByName = const Value.absent(),
                Value<DateTime?> submittedAt = const Value.absent(),
                Value<DateTime?> approvedAt = const Value.absent(),
                Value<String?> approvedById = const Value.absent(),
                Value<String?> approvedByName = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PurchaseOrdersTableCompanion.insert(
                id: id,
                businessId: businessId,
                branchId: branchId,
                supplierId: supplierId,
                supplierName: supplierName,
                status: status,
                poNumber: poNumber,
                notes: notes,
                expectedDelivery: expectedDelivery,
                totalAmount: totalAmount,
                createdById: createdById,
                createdByName: createdByName,
                submittedAt: submittedAt,
                approvedAt: approvedAt,
                approvedById: approvedById,
                approvedByName: approvedByName,
                isDeleted: isDeleted,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                createdAt: createdAt,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PurchaseOrdersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PurchaseOrdersTableTable,
      PurchaseOrderRow,
      $$PurchaseOrdersTableTableFilterComposer,
      $$PurchaseOrdersTableTableOrderingComposer,
      $$PurchaseOrdersTableTableAnnotationComposer,
      $$PurchaseOrdersTableTableCreateCompanionBuilder,
      $$PurchaseOrdersTableTableUpdateCompanionBuilder,
      (
        PurchaseOrderRow,
        BaseReferences<
          _$AppDatabase,
          $PurchaseOrdersTableTable,
          PurchaseOrderRow
        >,
      ),
      PurchaseOrderRow,
      PrefetchHooks Function()
    >;
typedef $$PurchaseOrderLinesTableTableCreateCompanionBuilder =
    PurchaseOrderLinesTableCompanion Function({
      required String id,
      required String purchaseOrderId,
      required String businessId,
      required String productId,
      required String variantId,
      required String productName,
      required String variantName,
      Value<String?> sku,
      Value<double> quantityOrdered,
      Value<double> quantityReceived,
      Value<double> unitCost,
      Value<bool> isDeleted,
      Value<int> syncStatus,
      Value<DateTime> createdAt,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });
typedef $$PurchaseOrderLinesTableTableUpdateCompanionBuilder =
    PurchaseOrderLinesTableCompanion Function({
      Value<String> id,
      Value<String> purchaseOrderId,
      Value<String> businessId,
      Value<String> productId,
      Value<String> variantId,
      Value<String> productName,
      Value<String> variantName,
      Value<String?> sku,
      Value<double> quantityOrdered,
      Value<double> quantityReceived,
      Value<double> unitCost,
      Value<bool> isDeleted,
      Value<int> syncStatus,
      Value<DateTime> createdAt,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });

class $$PurchaseOrderLinesTableTableFilterComposer
    extends Composer<_$AppDatabase, $PurchaseOrderLinesTableTable> {
  $$PurchaseOrderLinesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purchaseOrderId => $composableBuilder(
    column: $table.purchaseOrderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantityOrdered => $composableBuilder(
    column: $table.quantityOrdered,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantityReceived => $composableBuilder(
    column: $table.quantityReceived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitCost => $composableBuilder(
    column: $table.unitCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PurchaseOrderLinesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PurchaseOrderLinesTableTable> {
  $$PurchaseOrderLinesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purchaseOrderId => $composableBuilder(
    column: $table.purchaseOrderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantityOrdered => $composableBuilder(
    column: $table.quantityOrdered,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantityReceived => $composableBuilder(
    column: $table.quantityReceived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitCost => $composableBuilder(
    column: $table.unitCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PurchaseOrderLinesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PurchaseOrderLinesTableTable> {
  $$PurchaseOrderLinesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get purchaseOrderId => $composableBuilder(
    column: $table.purchaseOrderId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get variantId =>
      $composableBuilder(column: $table.variantId, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<double> get quantityOrdered => $composableBuilder(
    column: $table.quantityOrdered,
    builder: (column) => column,
  );

  GeneratedColumn<double> get quantityReceived => $composableBuilder(
    column: $table.quantityReceived,
    builder: (column) => column,
  );

  GeneratedColumn<double> get unitCost =>
      $composableBuilder(column: $table.unitCost, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );
}

class $$PurchaseOrderLinesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PurchaseOrderLinesTableTable,
          PurchaseOrderLineRow,
          $$PurchaseOrderLinesTableTableFilterComposer,
          $$PurchaseOrderLinesTableTableOrderingComposer,
          $$PurchaseOrderLinesTableTableAnnotationComposer,
          $$PurchaseOrderLinesTableTableCreateCompanionBuilder,
          $$PurchaseOrderLinesTableTableUpdateCompanionBuilder,
          (
            PurchaseOrderLineRow,
            BaseReferences<
              _$AppDatabase,
              $PurchaseOrderLinesTableTable,
              PurchaseOrderLineRow
            >,
          ),
          PurchaseOrderLineRow,
          PrefetchHooks Function()
        > {
  $$PurchaseOrderLinesTableTableTableManager(
    _$AppDatabase db,
    $PurchaseOrderLinesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PurchaseOrderLinesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PurchaseOrderLinesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PurchaseOrderLinesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> purchaseOrderId = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> variantId = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String> variantName = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                Value<double> quantityOrdered = const Value.absent(),
                Value<double> quantityReceived = const Value.absent(),
                Value<double> unitCost = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PurchaseOrderLinesTableCompanion(
                id: id,
                purchaseOrderId: purchaseOrderId,
                businessId: businessId,
                productId: productId,
                variantId: variantId,
                productName: productName,
                variantName: variantName,
                sku: sku,
                quantityOrdered: quantityOrdered,
                quantityReceived: quantityReceived,
                unitCost: unitCost,
                isDeleted: isDeleted,
                syncStatus: syncStatus,
                createdAt: createdAt,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String purchaseOrderId,
                required String businessId,
                required String productId,
                required String variantId,
                required String productName,
                required String variantName,
                Value<String?> sku = const Value.absent(),
                Value<double> quantityOrdered = const Value.absent(),
                Value<double> quantityReceived = const Value.absent(),
                Value<double> unitCost = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PurchaseOrderLinesTableCompanion.insert(
                id: id,
                purchaseOrderId: purchaseOrderId,
                businessId: businessId,
                productId: productId,
                variantId: variantId,
                productName: productName,
                variantName: variantName,
                sku: sku,
                quantityOrdered: quantityOrdered,
                quantityReceived: quantityReceived,
                unitCost: unitCost,
                isDeleted: isDeleted,
                syncStatus: syncStatus,
                createdAt: createdAt,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PurchaseOrderLinesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PurchaseOrderLinesTableTable,
      PurchaseOrderLineRow,
      $$PurchaseOrderLinesTableTableFilterComposer,
      $$PurchaseOrderLinesTableTableOrderingComposer,
      $$PurchaseOrderLinesTableTableAnnotationComposer,
      $$PurchaseOrderLinesTableTableCreateCompanionBuilder,
      $$PurchaseOrderLinesTableTableUpdateCompanionBuilder,
      (
        PurchaseOrderLineRow,
        BaseReferences<
          _$AppDatabase,
          $PurchaseOrderLinesTableTable,
          PurchaseOrderLineRow
        >,
      ),
      PurchaseOrderLineRow,
      PrefetchHooks Function()
    >;
typedef $$RecipeLinesTableTableCreateCompanionBuilder =
    RecipeLinesTableCompanion Function({
      required String id,
      required String businessId,
      required String productVariantId,
      required String ingredientVariantId,
      required String ingredientName,
      Value<double> quantity,
      Value<String?> unit,
      Value<bool> isDeleted,
      Value<DateTime?> deletedAt,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<DateTime> createdAt,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });
typedef $$RecipeLinesTableTableUpdateCompanionBuilder =
    RecipeLinesTableCompanion Function({
      Value<String> id,
      Value<String> businessId,
      Value<String> productVariantId,
      Value<String> ingredientVariantId,
      Value<String> ingredientName,
      Value<double> quantity,
      Value<String?> unit,
      Value<bool> isDeleted,
      Value<DateTime?> deletedAt,
      Value<int> syncStatus,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> syncError,
      Value<DateTime> createdAt,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });

class $$RecipeLinesTableTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeLinesTableTable> {
  $$RecipeLinesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productVariantId => $composableBuilder(
    column: $table.productVariantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ingredientVariantId => $composableBuilder(
    column: $table.ingredientVariantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ingredientName => $composableBuilder(
    column: $table.ingredientName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecipeLinesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeLinesTableTable> {
  $$RecipeLinesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productVariantId => $composableBuilder(
    column: $table.productVariantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ingredientVariantId => $composableBuilder(
    column: $table.ingredientVariantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ingredientName => $composableBuilder(
    column: $table.ingredientName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecipeLinesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeLinesTableTable> {
  $$RecipeLinesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productVariantId => $composableBuilder(
    column: $table.productVariantId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ingredientVariantId => $composableBuilder(
    column: $table.ingredientVariantId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ingredientName => $composableBuilder(
    column: $table.ingredientName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );
}

class $$RecipeLinesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipeLinesTableTable,
          RecipeLineRow,
          $$RecipeLinesTableTableFilterComposer,
          $$RecipeLinesTableTableOrderingComposer,
          $$RecipeLinesTableTableAnnotationComposer,
          $$RecipeLinesTableTableCreateCompanionBuilder,
          $$RecipeLinesTableTableUpdateCompanionBuilder,
          (
            RecipeLineRow,
            BaseReferences<
              _$AppDatabase,
              $RecipeLinesTableTable,
              RecipeLineRow
            >,
          ),
          RecipeLineRow,
          PrefetchHooks Function()
        > {
  $$RecipeLinesTableTableTableManager(
    _$AppDatabase db,
    $RecipeLinesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeLinesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeLinesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeLinesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> productVariantId = const Value.absent(),
                Value<String> ingredientVariantId = const Value.absent(),
                Value<String> ingredientName = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipeLinesTableCompanion(
                id: id,
                businessId: businessId,
                productVariantId: productVariantId,
                ingredientVariantId: ingredientVariantId,
                ingredientName: ingredientName,
                quantity: quantity,
                unit: unit,
                isDeleted: isDeleted,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                createdAt: createdAt,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String productVariantId,
                required String ingredientVariantId,
                required String ingredientName,
                Value<double> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipeLinesTableCompanion.insert(
                id: id,
                businessId: businessId,
                productVariantId: productVariantId,
                ingredientVariantId: ingredientVariantId,
                ingredientName: ingredientName,
                quantity: quantity,
                unit: unit,
                isDeleted: isDeleted,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                lastSyncAttempt: lastSyncAttempt,
                syncError: syncError,
                createdAt: createdAt,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecipeLinesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipeLinesTableTable,
      RecipeLineRow,
      $$RecipeLinesTableTableFilterComposer,
      $$RecipeLinesTableTableOrderingComposer,
      $$RecipeLinesTableTableAnnotationComposer,
      $$RecipeLinesTableTableCreateCompanionBuilder,
      $$RecipeLinesTableTableUpdateCompanionBuilder,
      (
        RecipeLineRow,
        BaseReferences<_$AppDatabase, $RecipeLinesTableTable, RecipeLineRow>,
      ),
      RecipeLineRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AuthContextTableTableTableManager get authContextTable =>
      $$AuthContextTableTableTableManager(_db, _db.authContextTable);
  $$BusinessTemplatesTableTableTableManager get businessTemplatesTable =>
      $$BusinessTemplatesTableTableTableManager(
        _db,
        _db.businessTemplatesTable,
      );
  $$BusinessesTableTableTableManager get businessesTable =>
      $$BusinessesTableTableTableManager(_db, _db.businessesTable);
  $$BranchesTableTableTableManager get branchesTable =>
      $$BranchesTableTableTableManager(_db, _db.branchesTable);
  $$CategoriesTableTableTableManager get categoriesTable =>
      $$CategoriesTableTableTableManager(_db, _db.categoriesTable);
  $$ExpensesTableTableTableManager get expensesTable =>
      $$ExpensesTableTableTableManager(_db, _db.expensesTable);
  $$ProductsTableTableTableManager get productsTable =>
      $$ProductsTableTableTableManager(_db, _db.productsTable);
  $$ProductVariantsTableTableTableManager get productVariantsTable =>
      $$ProductVariantsTableTableTableManager(_db, _db.productVariantsTable);
  $$TransactionsTableTableTableManager get transactionsTable =>
      $$TransactionsTableTableTableManager(_db, _db.transactionsTable);
  $$TransactionItemsTableTableTableManager get transactionItemsTable =>
      $$TransactionItemsTableTableTableManager(_db, _db.transactionItemsTable);
  $$DraftSalesTableTableTableManager get draftSalesTable =>
      $$DraftSalesTableTableTableManager(_db, _db.draftSalesTable);
  $$DraftSaleItemsTableTableTableManager get draftSaleItemsTable =>
      $$DraftSaleItemsTableTableTableManager(_db, _db.draftSaleItemsTable);
  $$InventoryLevelsTableTableTableManager get inventoryLevelsTable =>
      $$InventoryLevelsTableTableTableManager(_db, _db.inventoryLevelsTable);
  $$StockLedgerTableTableTableManager get stockLedgerTable =>
      $$StockLedgerTableTableTableManager(_db, _db.stockLedgerTable);
  $$ReceiptSettingsTableTableTableManager get receiptSettingsTable =>
      $$ReceiptSettingsTableTableTableManager(_db, _db.receiptSettingsTable);
  $$AuditLogsTableTableTableManager get auditLogsTable =>
      $$AuditLogsTableTableTableManager(_db, _db.auditLogsTable);
  $$EmployeesTableTableTableManager get employeesTable =>
      $$EmployeesTableTableTableManager(_db, _db.employeesTable);
  $$EmployeePermissionsTableTableTableManager get employeePermissionsTable =>
      $$EmployeePermissionsTableTableTableManager(
        _db,
        _db.employeePermissionsTable,
      );
  $$BusinessModulesTableTableTableManager get businessModulesTable =>
      $$BusinessModulesTableTableTableManager(_db, _db.businessModulesTable);
  $$SuppliersTableTableTableManager get suppliersTable =>
      $$SuppliersTableTableTableManager(_db, _db.suppliersTable);
  $$PurchaseOrdersTableTableTableManager get purchaseOrdersTable =>
      $$PurchaseOrdersTableTableTableManager(_db, _db.purchaseOrdersTable);
  $$PurchaseOrderLinesTableTableTableManager get purchaseOrderLinesTable =>
      $$PurchaseOrderLinesTableTableTableManager(
        _db,
        _db.purchaseOrderLinesTable,
      );
  $$RecipeLinesTableTableTableManager get recipeLinesTable =>
      $$RecipeLinesTableTableTableManager(_db, _db.recipeLinesTable);
}
