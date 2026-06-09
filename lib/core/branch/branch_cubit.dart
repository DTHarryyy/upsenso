import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:pos/core/branch/branch_state.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/permissions/data_scope.dart';
import 'package:pos/core/permissions/role_permission_matrix.dart';
import 'package:pos/core/sync/sync_status.dart';
import 'package:pos/features/auth/domain/entities/app_user.dart';
import 'package:pos/features/business/data/datasources/business_remote_ds.dart';
import 'package:pos/features/business/domain/entities/branch.dart';

/// Manages branch selection and filtering based on user role
class BranchCubit extends Cubit<BranchState> {
  static const String allBranchesLabel = 'All Branches';
  static const String _selectedBranchNameKey = 'selected_branch_name';
  static const String _selectedBranchIdKey = 'selected_branch_id';
  static const String _cachedBranchOptionsKey = 'cached_branch_options';
  static const String _cachedCanSwitchKey = 'cached_can_switch_branches';
  static const String _legacySelectedBranchKey = 'selected_branch';

  Map<String, String?> _branchIdsByName = const {};
  String? _lastLoadContextKey;
  String _currentBusinessId = '';

  BranchCubit() : super(BranchState.initial());

  /// Load the last selected branch from local storage, scoped to [businessId].
  Future<_CachedBranchSelection> _getLastSelectedBranch(
    String businessId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nameKey = '${_selectedBranchNameKey}_$businessId';
      final idKey = '${_selectedBranchIdKey}_$businessId';
      // Fall back to legacy (unscoped) key on first migration
      final selectedName =
          prefs.getString(nameKey) ?? prefs.getString(_legacySelectedBranchKey);
      final selectedId = prefs.getString(idKey);
      return _CachedBranchSelection(name: selectedName, id: selectedId);
    } catch (e) {
      debugPrint('[BranchCubit] Error loading cached selection: $e');
      return const _CachedBranchSelection();
    }
  }

  /// Save the selected branch to local storage, scoped to [businessId].
  Future<void> _saveSelectedBranch({
    required String businessId,
    required String branchName,
    required String? branchId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nameKey = '${_selectedBranchNameKey}_$businessId';
      final idKey = '${_selectedBranchIdKey}_$businessId';
      await prefs.setString(nameKey, branchName);
      // Keep legacy key so older app versions still read something sensible
      await prefs.setString(_legacySelectedBranchKey, branchName);

      if (branchId == null || branchId.trim().isEmpty) {
        await prefs.remove(idKey);
      } else {
        await prefs.setString(idKey, branchId);
      }
    } catch (e) {
      debugPrint('[BranchCubit] Error saving selection: $e');
    }
  }

  Future<List<_BranchOption>> _getCachedBranchOptions(String businessId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('${_cachedBranchOptionsKey}_$businessId');
      if (raw == null || raw.isEmpty) {
        return const [];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }

      final options = <_BranchOption>[];
      for (final item in decoded) {
        if (item is! Map) continue;

        final name = item['name']?.toString().trim();
        if (name == null || name.isEmpty) continue;

        final idRaw = item['id']?.toString().trim();
        options.add(
          _BranchOption(
            name: name,
            id: (idRaw == null || idRaw.isEmpty) ? null : idRaw,
          ),
        );
      }

      return options;
    } catch (e) {
      debugPrint('[BranchCubit] Error loading cached options: $e');
      return const [];
    }
  }

  Future<void> _saveCachedBranchOptions(
    String businessId,
    List<_BranchOption> options,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = options
          .map((option) => {'name': option.name, 'id': option.id})
          .toList(growable: false);
      await prefs.setString(
        '${_cachedBranchOptionsKey}_$businessId',
        jsonEncode(payload),
      );
    } catch (e) {
      debugPrint('[BranchCubit] Error saving cached options: $e');
    }
  }

  /// Save whether the user can switch branches, scoped to [businessId].
  Future<void> _saveCachedCanSwitch(String businessId, bool canSwitch) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${_cachedCanSwitchKey}_$businessId', canSwitch);
    } catch (e) {
      debugPrint('[BranchCubit] Error saving canSwitch: $e');
    }
  }

  /// Check if a role is Super Admin
  bool _isSuperAdmin(String? roleName) {
    final normalized = roleName?.trim().toLowerCase() ?? '';
    return normalized == 'super admin' ||
        normalized == 'superadmin' ||
        normalized == 'super_admin';
  }

  /// Determine if user can access all branches.
  /// Offline sessions can have missing roleName, so we also infer from branch linkage.
  bool _canAccessAllBranches(AppUser user) {
    if (_isSuperAdmin(user.roleName)) return true;

    final hasBusiness = user.businessId?.trim().isNotEmpty ?? false;
    final hasAssignedBranch = user.branchId?.trim().isNotEmpty ?? false;
    return hasBusiness && !hasAssignedBranch;
  }

  /// Load branches for the given user based on their role
  Future<void> loadBranchesForUser(AppUser user) async {
    if (state.isLoading) return;

    final loadContextKey =
        '${user.id}|${user.businessId ?? ''}|${user.roleName ?? ''}|${user.branchId ?? ''}|${user.branchName ?? ''}';
    if (_lastLoadContextKey == loadContextKey &&
        state.availableBranches.isNotEmpty) {
      return;
    }
    _lastLoadContextKey = loadContextKey;

    final businessId = user.businessId?.trim() ?? '';
    _currentBusinessId = businessId;
    final cachedSelection = await _getLastSelectedBranch(businessId);
    final cachedOptions = await _getCachedBranchOptions(businessId);
    final canAccessAllBranches = _canAccessAllBranches(user);
    final branchOptions = <_BranchOption>[];

    void addBranchOption({required String? id, required String? name}) {
      final cleanName = name?.trim();
      if (cleanName == null || cleanName.isEmpty) return;

      final cleanId = id?.trim();
      branchOptions.add(
        _BranchOption(
          name: cleanName,
          id: (cleanId == null || cleanId.isEmpty) ? null : cleanId,
        ),
      );
    }

    final fallbackBranch = user.branchName?.trim();
    addBranchOption(id: user.branchId?.trim(), name: fallbackBranch);
    for (final cached in cachedOptions) {
      addBranchOption(id: cached.id, name: cached.name);
    }

    Future<void> applyBranchState({bool persist = true}) async {
      if (branchOptions.isEmpty) {
        addBranchOption(id: null, name: 'Branch');
      }

      final idsByName = _createBranchIdMap(branchOptions);
      final uniqueNames = idsByName.keys.toList();
      uniqueNames.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      final roleLowerKey = RolePermissionMatrix.normalise(user.roleName);
      // Roles that are always scoped to a single assigned branch and must
      // never be allowed to switch — regardless of cache or branchId state.
      final isBranchScopedRole =
          RolePermissionMatrix.dataScopeTypeFor(roleLowerKey) !=
          DataScopeType.allBranches;
      // Can switch only when the role is NOT branch-scoped AND the user has
      // no explicit branch assignment (canAccessAllBranches already encodes
      // the !hasAssignedBranch logic for non-super-admin users).
      // The cached value is intentionally excluded: it must never override
      // the role / branch assignment determined from the live session.
      final canSwitch = !isBranchScopedRole && canAccessAllBranches;
      if (canSwitch && !uniqueNames.contains(allBranchesLabel)) {
        uniqueNames.insert(0, allBranchesLabel);
        idsByName[allBranchesLabel] = null;
      }

      final selected = _resolveSelectedBranch(
        options: uniqueNames,
        current: state.selectedBranch,
        cached: cachedSelection.name,
        fallback: canSwitch ? allBranchesLabel : fallbackBranch,
      );

      final selectedId = selected == allBranchesLabel
          ? null
          : (idsByName[selected] ??
                cachedSelection.id ??
                user.branchId?.trim() ??
                state.selectedBranchId);

      _branchIdsByName = Map.unmodifiable(idsByName);

      emit(
        BranchState(
          selectedBranch: selected,
          selectedBranchId: selectedId,
          availableBranches: uniqueNames,
          canSwitchBranches: canSwitch,
          roleName: user.roleName,
        ),
      );

      if (!persist) return;

      await _saveSelectedBranch(
        businessId: businessId,
        branchName: selected,
        branchId: selectedId,
      );

      final cacheableOptions = idsByName.entries
          .where((entry) => entry.key != allBranchesLabel)
          .map((entry) => _BranchOption(name: entry.key, id: entry.value))
          .toList(growable: false);
      await _saveCachedBranchOptions(businessId, cacheableOptions);
      await _saveCachedCanSwitch(businessId, canSwitch);
    }

    // Always emit cached/fallback branch state immediately for responsive UI.
    await applyBranchState(persist: false);

    if (businessId.isEmpty) {
      await applyBranchState();
      return;
    }

    final remote = sl<BusinessRemoteDs>();
    final branchesDao = sl<BranchesDao>();

    if (canAccessAllBranches) {
      var remoteRows = <Map<String, dynamic>>[];
      try {
        remoteRows = await remote
            .getActiveBranchesByBusiness(businessId)
            .timeout(const Duration(seconds: 2));
      } catch (_) {
        remoteRows = const [];
      }

      if (remoteRows.isNotEmpty) {
        for (final row in remoteRows) {
          addBranchOption(
            id: row['id']?.toString(),
            name: row['name']?.toString(),
          );
        }
      } else {
        try {
          final localRows = await branchesDao.getByBusinessId(businessId);
          for (final row in localRows) {
            addBranchOption(id: row.id, name: row.name);
          }
        } catch (_) {
          // Ignore local fallback errors; cached options will still apply.
        }
      }
    } else {
      final assignedBranchId = user.branchId?.trim();
      if (assignedBranchId != null && assignedBranchId.isNotEmpty) {
        Map<String, dynamic>? remoteRow;
        try {
          remoteRow = await remote
              .getActiveBranchById(assignedBranchId)
              .timeout(const Duration(seconds: 2));
        } catch (_) {
          remoteRow = null;
        }

        if (remoteRow != null) {
          addBranchOption(
            id: remoteRow['id']?.toString() ?? assignedBranchId,
            name: remoteRow['name']?.toString(),
          );
        } else {
          try {
            final local = await branchesDao.getById(assignedBranchId);
            if (local != null) {
              addBranchOption(id: local.id, name: local.name);
            }
          } catch (_) {
            // Ignore local fallback errors; cached options will still apply.
          }
        }
      }
    }

    // Remove the placeholder 'Branch' entry if real branches were fetched
    if (branchOptions.any((o) => o.name != 'Branch')) {
      branchOptions.removeWhere((o) => o.name == 'Branch' && o.id == null);
    }

    await applyBranchState();
  }

  Map<String, String?> _createBranchIdMap(List<_BranchOption> options) {
    final map = <String, String?>{};
    for (final option in options) {
      if (!map.containsKey(option.name)) {
        map[option.name] = option.id;
        continue;
      }

      final existing = map[option.name]?.trim();
      final incoming = option.id?.trim();

      if ((existing == null || existing.isEmpty) &&
          incoming != null &&
          incoming.isNotEmpty) {
        map[option.name] = incoming;
      }
    }
    return map;
  }

  /// Resolve which branch should be selected
  String _resolveSelectedBranch({
    required List<String> options,
    required String? current,
    required String? cached,
    required String? fallback,
  }) {
    if (current != null && options.contains(current)) {
      return current;
    }
    if (cached != null && options.contains(cached)) {
      return cached;
    }
    if (fallback != null && options.contains(fallback)) {
      return fallback;
    }
    return options.isNotEmpty ? options.first : 'Branch';
  }

  /// Select a different branch (only for Super Admin)
  Future<void> selectBranch(String branchName) async {
    if (!state.canSwitchBranches) return;
    if (!state.availableBranches.contains(branchName)) return;

    final selectedId = branchName == allBranchesLabel
        ? null
        : (_branchIdsByName[branchName] ?? state.selectedBranchId);

    emit(
      BranchState(
        selectedBranch: branchName,
        selectedBranchId: selectedId,
        availableBranches: state.availableBranches,
        canSwitchBranches: state.canSwitchBranches,
        roleName: state.roleName,
      ),
    );

    await _saveSelectedBranch(
      businessId: _currentBusinessId,
      branchName: branchName,
      branchId: selectedId,
    );
  }

  /// Get the currently selected branch ID (for filtering)
  /// Returns null for Super Admin when "All Branches" is selected
  String? getSelectedBranchIdForFiltering() {
    if (state.selectedBranch == allBranchesLabel) {
      return null; // No filter, show all
    }
    return state.selectedBranchId;
  }

  /// Add a new branch (Super Admin only)
  Future<String?> addBranch({
    required String businessId,
    required String name,
    String? location,
  }) async {
    if (!state.canSwitchBranches) return null;

    final id = const Uuid().v4();
    final branch = Branch(
      id: id,
      businessId: businessId,
      name: name.trim(),
      location: location?.trim(),
    );

    // Save locally
    final branchesDao = sl<BranchesDao>();
    await branchesDao.insertBranch(branch);

    // Try remote
    try {
      final remote = sl<BusinessRemoteDs>();
      await remote.createBranch(
        id: id,
        businessId: businessId,
        name: branch.name,
        location: branch.location,
      );
      await branchesDao.updateSyncStatus(id: id, status: SyncStatus.synced);
    } catch (e) {
      debugPrint('[BranchCubit] Remote branch creation failed: $e');
    }

    // Update state with the new branch
    final updatedIdsByName = Map<String, String?>.from(_branchIdsByName);
    updatedIdsByName[branch.name] = id;
    _branchIdsByName = Map.unmodifiable(updatedIdsByName);

    final updatedBranches = List<String>.from(state.availableBranches);
    if (!updatedBranches.contains(branch.name)) {
      // Insert before "All Branches" stays first
      final insertIndex = updatedBranches.contains(allBranchesLabel) ? 1 : 0;
      updatedBranches.insert(insertIndex, branch.name);
      updatedBranches.sort((a, b) {
        if (a == allBranchesLabel) return -1;
        if (b == allBranchesLabel) return 1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });
    }

    // Auto-select the new branch
    emit(
      BranchState(
        selectedBranch: branch.name,
        selectedBranchId: id,
        availableBranches: updatedBranches,
        canSwitchBranches: state.canSwitchBranches,
        roleName: state.roleName,
      ),
    );

    await _saveSelectedBranch(
      businessId: businessId,
      branchName: branch.name,
      branchId: id,
    );

    final cacheableOptions = updatedIdsByName.entries
        .where((entry) => entry.key != allBranchesLabel)
        .map((entry) => _BranchOption(name: entry.key, id: entry.value))
        .toList(growable: false);
    await _saveCachedBranchOptions(businessId, cacheableOptions);

    return id;
  }

  /// Returns the branch name for a given [branchId], or `null` if unknown.
  String? branchNameForId(String? branchId) {
    if (branchId == null || branchId.trim().isEmpty) return null;
    for (final entry in _branchIdsByName.entries) {
      if (entry.value == branchId && entry.key != allBranchesLabel) {
        return entry.key;
      }
    }
    return null;
  }

  /// Returns all real branch options that have a known ID (excludes
  /// "All Branches" and any placeholder entries without an ID).
  List<({String name, String id})> getAvailableBranchOptions() {
    return _branchIdsByName.entries
        .where(
          (e) =>
              e.key != allBranchesLabel &&
              e.value != null &&
              e.value!.trim().isNotEmpty,
        )
        .map((e) => (name: e.key, id: e.value!))
        .toList(growable: false);
  }

  /// Reset to initial state
  void reset() {
    _branchIdsByName = const {};
    _lastLoadContextKey = null;
    emit(BranchState.initial());
  }
}

class _BranchOption {
  final String name;
  final String? id;

  const _BranchOption({required this.name, required this.id});
}

class _CachedBranchSelection {
  final String? name;
  final String? id;

  const _CachedBranchSelection({this.name, this.id});
}
