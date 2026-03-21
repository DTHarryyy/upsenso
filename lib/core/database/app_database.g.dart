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
  late final AuthContextDao authContextDao = AuthContextDao(
    this as AppDatabase,
  );
  late final BusinessTemplatesDao businessTemplatesDao = BusinessTemplatesDao(
    this as AppDatabase,
  );
  late final BusinessesDao businessesDao = BusinessesDao(this as AppDatabase);
  late final BranchesDao branchesDao = BranchesDao(this as AppDatabase);
  late final CategoriesDao categoriesDao = CategoriesDao(this as AppDatabase);
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
}
