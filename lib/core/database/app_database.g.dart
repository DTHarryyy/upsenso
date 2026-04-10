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

  /// Associated business ID (from database trigger context)
  final String? businessId;

  /// User's role ID in the business
  final String? roleId;

  /// User's role name (e.g., "Super Admin", "Manager")
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultModulesMeta = const VerificationMeta(
    'defaultModules',
  );
  @override
  late final GeneratedColumn<String> defaultModules = GeneratedColumn<String>(
    'default_modules',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultRolesMeta = const VerificationMeta(
    'defaultRoles',
  );
  @override
  late final GeneratedColumn<String> defaultRoles = GeneratedColumn<String>(
    'default_roles',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultPermissionsMeta =
      const VerificationMeta('defaultPermissions');
  @override
  late final GeneratedColumn<String> defaultPermissions =
      GeneratedColumn<String>(
        'default_permissions',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _defaultTaxRateMeta = const VerificationMeta(
    'defaultTaxRate',
  );
  @override
  late final GeneratedColumn<double> defaultTaxRate = GeneratedColumn<double>(
    'default_tax_rate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
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
    name,
    defaultModules,
    defaultRoles,
    defaultPermissions,
    defaultTaxRate,
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
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('default_modules')) {
      context.handle(
        _defaultModulesMeta,
        defaultModules.isAcceptableOrUnknown(
          data['default_modules']!,
          _defaultModulesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_defaultModulesMeta);
    }
    if (data.containsKey('default_roles')) {
      context.handle(
        _defaultRolesMeta,
        defaultRoles.isAcceptableOrUnknown(
          data['default_roles']!,
          _defaultRolesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_defaultRolesMeta);
    }
    if (data.containsKey('default_permissions')) {
      context.handle(
        _defaultPermissionsMeta,
        defaultPermissions.isAcceptableOrUnknown(
          data['default_permissions']!,
          _defaultPermissionsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_defaultPermissionsMeta);
    }
    if (data.containsKey('default_tax_rate')) {
      context.handle(
        _defaultTaxRateMeta,
        defaultTaxRate.isAcceptableOrUnknown(
          data['default_tax_rate']!,
          _defaultTaxRateMeta,
        ),
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
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      defaultModules: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_modules'],
      )!,
      defaultRoles: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_roles'],
      )!,
      defaultPermissions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_permissions'],
      )!,
      defaultTaxRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}default_tax_rate'],
      ),
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
  final String name;
  final String defaultModules;
  final String defaultRoles;
  final String defaultPermissions;
  final double? defaultTaxRate;
  final DateTime? createdAt;
  final DateTime localUpdatedAt;
  const BusinessTemplatesTableData({
    required this.id,
    required this.name,
    required this.defaultModules,
    required this.defaultRoles,
    required this.defaultPermissions,
    this.defaultTaxRate,
    this.createdAt,
    required this.localUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['default_modules'] = Variable<String>(defaultModules);
    map['default_roles'] = Variable<String>(defaultRoles);
    map['default_permissions'] = Variable<String>(defaultPermissions);
    if (!nullToAbsent || defaultTaxRate != null) {
      map['default_tax_rate'] = Variable<double>(defaultTaxRate);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    return map;
  }

  BusinessTemplatesTableCompanion toCompanion(bool nullToAbsent) {
    return BusinessTemplatesTableCompanion(
      id: Value(id),
      name: Value(name),
      defaultModules: Value(defaultModules),
      defaultRoles: Value(defaultRoles),
      defaultPermissions: Value(defaultPermissions),
      defaultTaxRate: defaultTaxRate == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultTaxRate),
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
      name: serializer.fromJson<String>(json['name']),
      defaultModules: serializer.fromJson<String>(json['defaultModules']),
      defaultRoles: serializer.fromJson<String>(json['defaultRoles']),
      defaultPermissions: serializer.fromJson<String>(
        json['defaultPermissions'],
      ),
      defaultTaxRate: serializer.fromJson<double?>(json['defaultTaxRate']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'defaultModules': serializer.toJson<String>(defaultModules),
      'defaultRoles': serializer.toJson<String>(defaultRoles),
      'defaultPermissions': serializer.toJson<String>(defaultPermissions),
      'defaultTaxRate': serializer.toJson<double?>(defaultTaxRate),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
    };
  }

  BusinessTemplatesTableData copyWith({
    String? id,
    String? name,
    String? defaultModules,
    String? defaultRoles,
    String? defaultPermissions,
    Value<double?> defaultTaxRate = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
    DateTime? localUpdatedAt,
  }) => BusinessTemplatesTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    defaultModules: defaultModules ?? this.defaultModules,
    defaultRoles: defaultRoles ?? this.defaultRoles,
    defaultPermissions: defaultPermissions ?? this.defaultPermissions,
    defaultTaxRate: defaultTaxRate.present
        ? defaultTaxRate.value
        : this.defaultTaxRate,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
  );
  BusinessTemplatesTableData copyWithCompanion(
    BusinessTemplatesTableCompanion data,
  ) {
    return BusinessTemplatesTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      defaultModules: data.defaultModules.present
          ? data.defaultModules.value
          : this.defaultModules,
      defaultRoles: data.defaultRoles.present
          ? data.defaultRoles.value
          : this.defaultRoles,
      defaultPermissions: data.defaultPermissions.present
          ? data.defaultPermissions.value
          : this.defaultPermissions,
      defaultTaxRate: data.defaultTaxRate.present
          ? data.defaultTaxRate.value
          : this.defaultTaxRate,
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
          ..write('name: $name, ')
          ..write('defaultModules: $defaultModules, ')
          ..write('defaultRoles: $defaultRoles, ')
          ..write('defaultPermissions: $defaultPermissions, ')
          ..write('defaultTaxRate: $defaultTaxRate, ')
          ..write('createdAt: $createdAt, ')
          ..write('localUpdatedAt: $localUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    defaultModules,
    defaultRoles,
    defaultPermissions,
    defaultTaxRate,
    createdAt,
    localUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BusinessTemplatesTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.defaultModules == this.defaultModules &&
          other.defaultRoles == this.defaultRoles &&
          other.defaultPermissions == this.defaultPermissions &&
          other.defaultTaxRate == this.defaultTaxRate &&
          other.createdAt == this.createdAt &&
          other.localUpdatedAt == this.localUpdatedAt);
}

class BusinessTemplatesTableCompanion
    extends UpdateCompanion<BusinessTemplatesTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> defaultModules;
  final Value<String> defaultRoles;
  final Value<String> defaultPermissions;
  final Value<double?> defaultTaxRate;
  final Value<DateTime?> createdAt;
  final Value<DateTime> localUpdatedAt;
  final Value<int> rowid;
  const BusinessTemplatesTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.defaultModules = const Value.absent(),
    this.defaultRoles = const Value.absent(),
    this.defaultPermissions = const Value.absent(),
    this.defaultTaxRate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BusinessTemplatesTableCompanion.insert({
    required String id,
    required String name,
    required String defaultModules,
    required String defaultRoles,
    required String defaultPermissions,
    this.defaultTaxRate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       defaultModules = Value(defaultModules),
       defaultRoles = Value(defaultRoles),
       defaultPermissions = Value(defaultPermissions);
  static Insertable<BusinessTemplatesTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? defaultModules,
    Expression<String>? defaultRoles,
    Expression<String>? defaultPermissions,
    Expression<double>? defaultTaxRate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? localUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (defaultModules != null) 'default_modules': defaultModules,
      if (defaultRoles != null) 'default_roles': defaultRoles,
      if (defaultPermissions != null) 'default_permissions': defaultPermissions,
      if (defaultTaxRate != null) 'default_tax_rate': defaultTaxRate,
      if (createdAt != null) 'created_at': createdAt,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BusinessTemplatesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? defaultModules,
    Value<String>? defaultRoles,
    Value<String>? defaultPermissions,
    Value<double?>? defaultTaxRate,
    Value<DateTime?>? createdAt,
    Value<DateTime>? localUpdatedAt,
    Value<int>? rowid,
  }) {
    return BusinessTemplatesTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      defaultModules: defaultModules ?? this.defaultModules,
      defaultRoles: defaultRoles ?? this.defaultRoles,
      defaultPermissions: defaultPermissions ?? this.defaultPermissions,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (defaultModules.present) {
      map['default_modules'] = Variable<String>(defaultModules.value);
    }
    if (defaultRoles.present) {
      map['default_roles'] = Variable<String>(defaultRoles.value);
    }
    if (defaultPermissions.present) {
      map['default_permissions'] = Variable<String>(defaultPermissions.value);
    }
    if (defaultTaxRate.present) {
      map['default_tax_rate'] = Variable<double>(defaultTaxRate.value);
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
          ..write('name: $name, ')
          ..write('defaultModules: $defaultModules, ')
          ..write('defaultRoles: $defaultRoles, ')
          ..write('defaultPermissions: $defaultPermissions, ')
          ..write('defaultTaxRate: $defaultTaxRate, ')
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
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
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
    name,
    address,
    phone,
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
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
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
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
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

  /// Branch address (optional, completed later in settings)
  final String? address;

  /// Branch phone number (optional, completed later in settings)
  final String? phone;

  /// Whether branch is active
  final bool isActive;

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
    this.address,
    this.phone,
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
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
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

  BranchesTableCompanion toCompanion(bool nullToAbsent) {
    return BranchesTableCompanion(
      id: Value(id),
      businessId: Value(businessId),
      name: Value(name),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
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

  factory BranchesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BranchesTableData(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String?>(json['address']),
      phone: serializer.fromJson<String?>(json['phone']),
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
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String?>(address),
      'phone': serializer.toJson<String?>(phone),
      'isActive': serializer.toJson<bool>(isActive),
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
    Value<String?> address = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    bool? isActive,
    int? syncStatus,
    Value<DateTime?> lastSyncAttempt = const Value.absent(),
    Value<String?> syncError = const Value.absent(),
    DateTime? localUpdatedAt,
  }) => BranchesTableData(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    name: name ?? this.name,
    address: address.present ? address.value : this.address,
    phone: phone.present ? phone.value : this.phone,
    isActive: isActive ?? this.isActive,
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
      address: data.address.present ? data.address.value : this.address,
      phone: data.phone.present ? data.phone.value : this.phone,
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
    return (StringBuffer('BranchesTableData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('phone: $phone, ')
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
    name,
    address,
    phone,
    isActive,
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
          other.address == this.address &&
          other.phone == this.phone &&
          other.isActive == this.isActive &&
          other.syncStatus == this.syncStatus &&
          other.lastSyncAttempt == this.lastSyncAttempt &&
          other.syncError == this.syncError &&
          other.localUpdatedAt == this.localUpdatedAt);
}

class BranchesTableCompanion extends UpdateCompanion<BranchesTableData> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> name;
  final Value<String?> address;
  final Value<String?> phone;
  final Value<bool> isActive;
  final Value<int> syncStatus;
  final Value<DateTime?> lastSyncAttempt;
  final Value<String?> syncError;
  final Value<DateTime> localUpdatedAt;
  final Value<int> rowid;
  const BranchesTableCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.phone = const Value.absent(),
    this.isActive = const Value.absent(),
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
    this.address = const Value.absent(),
    this.phone = const Value.absent(),
    this.isActive = const Value.absent(),
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
    Expression<String>? address,
    Expression<String>? phone,
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
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (isActive != null) 'is_active': isActive,
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
    Value<String?>? address,
    Value<String?>? phone,
    Value<bool>? isActive,
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
      address: address ?? this.address,
      phone: phone ?? this.phone,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
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
    return (StringBuffer('BranchesTableCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('phone: $phone, ')
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
  int get hashCode => Object.hash(
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
  );
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
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus, ')
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
  late final $ProductsTableTable productsTable = $ProductsTableTable(this);
  late final $ProductVariantsTableTable productVariantsTable =
      $ProductVariantsTableTable(this);
  late final $TransactionsTableTable transactionsTable =
      $TransactionsTableTable(this);
  late final $TransactionItemsTableTable transactionItemsTable =
      $TransactionItemsTableTable(this);
  late final $InventoryLevelsTableTable inventoryLevelsTable =
      $InventoryLevelsTableTable(this);
  late final $StockLedgerTableTable stockLedgerTable = $StockLedgerTableTable(
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
  late final ProductsDao productsDao = ProductsDao(this as AppDatabase);
  late final ProductVariantsDao productVariantsDao = ProductVariantsDao(
    this as AppDatabase,
  );
  late final TransactionsDao transactionsDao = TransactionsDao(
    this as AppDatabase,
  );
  late final InventoryLevelsDao inventoryLevelsDao = InventoryLevelsDao(
    this as AppDatabase,
  );
  late final StockLedgerDao stockLedgerDao = StockLedgerDao(
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
    productsTable,
    productVariantsTable,
    transactionsTable,
    transactionItemsTable,
    inventoryLevelsTable,
    stockLedgerTable,
  ];
}

typedef $$AuthContextTableTableCreateCompanionBuilder =
    AuthContextTableCompanion Function({
      required String userId,
      Value<String?> email,
      Value<String?> fullName,
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
      required String name,
      required String defaultModules,
      required String defaultRoles,
      required String defaultPermissions,
      Value<double?> defaultTaxRate,
      Value<DateTime?> createdAt,
      Value<DateTime> localUpdatedAt,
      Value<int> rowid,
    });
typedef $$BusinessTemplatesTableTableUpdateCompanionBuilder =
    BusinessTemplatesTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> defaultModules,
      Value<String> defaultRoles,
      Value<String> defaultPermissions,
      Value<double?> defaultTaxRate,
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultModules => $composableBuilder(
    column: $table.defaultModules,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultRoles => $composableBuilder(
    column: $table.defaultRoles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultPermissions => $composableBuilder(
    column: $table.defaultPermissions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get defaultTaxRate => $composableBuilder(
    column: $table.defaultTaxRate,
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultModules => $composableBuilder(
    column: $table.defaultModules,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultRoles => $composableBuilder(
    column: $table.defaultRoles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultPermissions => $composableBuilder(
    column: $table.defaultPermissions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get defaultTaxRate => $composableBuilder(
    column: $table.defaultTaxRate,
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

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get defaultModules => $composableBuilder(
    column: $table.defaultModules,
    builder: (column) => column,
  );

  GeneratedColumn<String> get defaultRoles => $composableBuilder(
    column: $table.defaultRoles,
    builder: (column) => column,
  );

  GeneratedColumn<String> get defaultPermissions => $composableBuilder(
    column: $table.defaultPermissions,
    builder: (column) => column,
  );

  GeneratedColumn<double> get defaultTaxRate => $composableBuilder(
    column: $table.defaultTaxRate,
    builder: (column) => column,
  );

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
                Value<String> name = const Value.absent(),
                Value<String> defaultModules = const Value.absent(),
                Value<String> defaultRoles = const Value.absent(),
                Value<String> defaultPermissions = const Value.absent(),
                Value<double?> defaultTaxRate = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BusinessTemplatesTableCompanion(
                id: id,
                name: name,
                defaultModules: defaultModules,
                defaultRoles: defaultRoles,
                defaultPermissions: defaultPermissions,
                defaultTaxRate: defaultTaxRate,
                createdAt: createdAt,
                localUpdatedAt: localUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String defaultModules,
                required String defaultRoles,
                required String defaultPermissions,
                Value<double?> defaultTaxRate = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BusinessTemplatesTableCompanion.insert(
                id: id,
                name: name,
                defaultModules: defaultModules,
                defaultRoles: defaultRoles,
                defaultPermissions: defaultPermissions,
                defaultTaxRate: defaultTaxRate,
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
      Value<String?> address,
      Value<String?> phone,
      Value<bool> isActive,
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
      Value<String?> address,
      Value<String?> phone,
      Value<bool> isActive,
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

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
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

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
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

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

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
                Value<String?> address = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BranchesTableCompanion(
                id: id,
                businessId: businessId,
                name: name,
                address: address,
                phone: phone,
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
                required String name,
                Value<String?> address = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BranchesTableCompanion.insert(
                id: id,
                businessId: businessId,
                name: name,
                address: address,
                phone: phone,
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
typedef $$ProductsTableTableCreateCompanionBuilder =
    ProductsTableCompanion Function({
      required String id,
      required String businessId,
      Value<String?> categoryId,
      required String name,
      Value<String?> sku,
      Value<String?> barcode,
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
  $$ProductsTableTableTableManager get productsTable =>
      $$ProductsTableTableTableManager(_db, _db.productsTable);
  $$ProductVariantsTableTableTableManager get productVariantsTable =>
      $$ProductVariantsTableTableTableManager(_db, _db.productVariantsTable);
  $$TransactionsTableTableTableManager get transactionsTable =>
      $$TransactionsTableTableTableManager(_db, _db.transactionsTable);
  $$TransactionItemsTableTableTableManager get transactionItemsTable =>
      $$TransactionItemsTableTableTableManager(_db, _db.transactionItemsTable);
  $$InventoryLevelsTableTableTableManager get inventoryLevelsTable =>
      $$InventoryLevelsTableTableTableManager(_db, _db.inventoryLevelsTable);
  $$StockLedgerTableTableTableManager get stockLedgerTable =>
      $$StockLedgerTableTableTableManager(_db, _db.stockLedgerTable);
}
