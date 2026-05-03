import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum SecureStorageKey {
  cachedBusinessId,
  cachedRoleId,
  cachedRoleName,
  cachedBranchId,
  cachedBranchName,
  cachedBusinessName,
  cachedBusinessTemplateId,
  cachedBusinessTemplateName,
}

class SecureStorageService {
  SecureStorageService() : _store = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final FlutterSecureStorage _store;

  Future<void> write(SecureStorageKey key, String value) =>
      _store.write(key: key.name, value: value);

  Future<String?> read(SecureStorageKey key) =>
      _store.read(key: key.name);

  Future<void> delete(SecureStorageKey key) =>
      _store.delete(key: key.name);

  Future<void> deleteAll() => _store.deleteAll();

  Future<void> writeBusinessContext({
    required String? businessId,
    required String? roleId,
    required String? roleName,
    required String? branchId,
    required String? branchName,
    required String? businessName,
    required String? businessTemplateId,
    required String? businessTemplateName,
  }) async {
    await Future.wait([
      if (businessId != null)
        write(SecureStorageKey.cachedBusinessId, businessId),
      if (roleId != null) write(SecureStorageKey.cachedRoleId, roleId),
      if (roleName != null) write(SecureStorageKey.cachedRoleName, roleName),
      if (branchId != null) write(SecureStorageKey.cachedBranchId, branchId),
      if (branchName != null)
        write(SecureStorageKey.cachedBranchName, branchName),
      if (businessName != null)
        write(SecureStorageKey.cachedBusinessName, businessName),
      if (businessTemplateId != null)
        write(SecureStorageKey.cachedBusinessTemplateId, businessTemplateId),
      if (businessTemplateName != null)
        write(
          SecureStorageKey.cachedBusinessTemplateName,
          businessTemplateName,
        ),
    ]);
  }

  Future<Map<SecureStorageKey, String?>> readBusinessContext() async {
    final results = await Future.wait(
      SecureStorageKey.values.map((key) => read(key)),
    );
    return Map.fromIterables(SecureStorageKey.values, results);
  }
}
