import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/database/daos/business_modules_dao.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/core/permissions/data/permission_remote_ds.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';

// ── Module catalogue ────────────────────────────────────────────────────────

class _ModuleInfo {
  final String code;
  final String label;
  final String description;
  final IconData icon;

  const _ModuleInfo({
    required this.code,
    required this.label,
    required this.description,
    required this.icon,
  });
}

const _kModules = <_ModuleInfo>[
  _ModuleInfo(
    code: 'pos',
    label: 'POS Terminal',
    description: 'Point-of-sale checkout and shift management',
    icon: IconlyLight.buy,
  ),
  _ModuleInfo(
    code: 'inventory',
    label: 'Inventory',
    description: 'Stock tracking, adjustments and transfers',
    icon: IconlyLight.bag_2,
  ),
  _ModuleInfo(
    code: 'expenses',
    label: 'Expenses',
    description: 'Expense recording and approval workflow',
    icon: IconlyLight.wallet,
  ),
  _ModuleInfo(
    code: 'employees',
    label: 'Employees',
    description: 'Staff management, roles and permissions',
    icon: IconlyLight.profile,
  ),
  _ModuleInfo(
    code: 'reports',
    label: 'Reports & Analytics',
    description: 'Sales, stock and financial reporting',
    icon: IconlyLight.chart,
  ),
  _ModuleInfo(
    code: 'procurement',
    label: 'Procurement',
    description: 'Suppliers, purchase orders and goods receiving',
    icon: IconlyLight.work,
  ),
  _ModuleInfo(
    code: 'crm',
    label: 'Customers',
    description: 'Customer directory and purchase history',
    icon: IconlyLight.profile,
  ),
  _ModuleInfo(
    code: 'ingredients',
    label: 'Ingredients',
    description: 'Ingredient stock items consumed by recipe-based products',
    icon: IconlyLight.category,
  ),
  _ModuleInfo(
    code: 'recipes',
    label: 'Recipes',
    description: 'Bill-of-materials configuration on recipe-based products',
    icon: IconlyLight.discovery,
  ),
  _ModuleInfo(
    code: 'audit',
    label: 'Audit Logs',
    description: 'Activity tracking and security audit trail',
    icon: IconlyLight.shield_done,
  ),
];

const _kBannerDismissedKey = 'module_settings_banner_dismissed';

// ── Cubit state ─────────────────────────────────────────────────────────────

sealed class ModuleSettingsState {}

class ModuleSettingsLoading extends ModuleSettingsState {}

class ModuleSettingsError extends ModuleSettingsState {
  final String message;
  ModuleSettingsError(this.message);
}

class ModuleSettingsLoaded extends ModuleSettingsState {
  final Map<String, bool> modules;
  final Set<String> saving; // in-flight remote call
  final Set<String> pending; // saved locally, awaiting remote sync
  final bool isOffline; // true when no remote connection could be reached

  ModuleSettingsLoaded({
    required this.modules,
    Set<String>? saving,
    Set<String>? pending,
    this.isOffline = false,
  })  : saving = saving ?? const {},
        pending = pending ?? const {};

  ModuleSettingsLoaded copyWith({
    Map<String, bool>? modules,
    Set<String>? saving,
    Set<String>? pending,
    bool? isOffline,
  }) => ModuleSettingsLoaded(
    modules: modules ?? this.modules,
    saving: saving ?? this.saving,
    pending: pending ?? this.pending,
    isOffline: isOffline ?? this.isOffline,
  );
}

// ── Cubit ────────────────────────────────────────────────────────────────────

// SharedPreferences key for changes saved locally but not yet pushed to remote.
String _pendingKey(String businessId) => 'module_pending_$businessId';

class ModuleSettingsCubit extends Cubit<ModuleSettingsState> {
  final String businessId;
  StreamSubscription<bool>? _connectivitySub;

  ModuleSettingsCubit(this.businessId) : super(ModuleSettingsLoading());

  Future<void> load() async {
    // 1. Render from cache immediately — page is usable offline right away.
    await _emitFromCache();

    // 2. Auto-sync whenever connectivity is restored.
    _connectivitySub = sl<ConnectivityService>().onConnectivityChanged.listen(
      (isConnected) { if (isConnected) _syncWithRemote(); },
    );

    // 3. Attempt to sync right now.
    await _syncWithRemote();
  }

  // Loads local DB + pending set and emits a loaded state.
  Future<void> _emitFromCache() async {
    final cached = await sl<BusinessModulesDao>().getAll(businessId);
    final pendingCodes = await _readPendingCodes();
    if (cached.isNotEmpty || pendingCodes.isNotEmpty) {
      final codeMap = {for (final r in cached) r.moduleCode: r.enabled};
      final modules = {
        for (final m in _kModules) m.code: codeMap[m.code] ?? true,
      };
      emit(ModuleSettingsLoaded(
        modules: modules,
        isOffline: true,
        pending: pendingCodes,
      ));
    }
  }

  // Flushes pending changes then fetches fresh state from remote.
  Future<void> _syncWithRemote() async {
    final pendingCodes = await _readPendingCodes();
    if (pendingCodes.isNotEmpty) {
      await _flushPending(pendingCodes);
    }

    try {
      final raw = await sl<PermissionRemoteDs>().fetchEnabledModules(businessId);
      final modules = {for (final m in _kModules) m.code: raw[m.code] ?? true};
      await sl<BusinessModulesDao>().saveModules(businessId, modules);
      await sl<PermissionService>().syncModules(businessId);
      emit(ModuleSettingsLoaded(modules: modules));
    } catch (e, st) {
      debugPrint('[ModuleSettings] Error in _syncWithRemote: $e\n$st');
      if (state is! ModuleSettingsLoaded) {
        emit(ModuleSettingsError('Failed to load modules. Please try again.'));
      }
    }
  }

  // Pushes each pending module toggle to remote. Removes from pending on success.
  Future<void> _flushPending(Set<String> codes) async {
    final localRows = await sl<BusinessModulesDao>().getAll(businessId);
    final localMap = {for (final r in localRows) r.moduleCode: r.enabled};

    for (final code in codes) {
      final enabled = localMap[code];
      if (enabled == null) {
        await _removePending(code);
        continue;
      }
      try {
        await sl<PermissionRemoteDs>().setModuleEnabled(businessId, code, enabled);
        await _removePending(code);

        final label = _kModules
            .firstWhere(
              (m) => m.code == code,
              orElse: () => _ModuleInfo(
                code: code,
                label: code,
                description: '',
                icon: IconlyLight.category,
              ),
            )
            .label;
        sl<AuditLogService>().log(
          actionType: AuditLogActionType.businessModuleChanged,
          entityType: 'module',
          entityName: label,
          description: '$label module ${enabled ? 'enabled' : 'disabled'}',
          metadata: {'module': code, 'enabled': enabled},
          businessId: businessId,
        );

        final s = state;
        if (s is ModuleSettingsLoaded) {
          emit(s.copyWith(pending: Set<String>.of(s.pending)..remove(code)));
        }
      } catch (e, st) {
        debugPrint('[ModuleSettings] Error flushing pending "$code": $e\n$st');
        // Keep in pending — will retry on next connectivity event.
      }
    }
  }

  Future<void> toggle(String code, bool enabled) async {
    final current = state;
    if (current is! ModuleSettingsLoaded) return;
    if (current.saving.contains(code)) return;

    // Write locally first — the change survives even if remote is unreachable.
    await sl<BusinessModulesDao>().saveModules(businessId, {code: enabled});
    await _addPending(code);

    // Refresh the live module gate from the local cache so the toggle takes
    // effect instantly across the app — online or offline. Without this the
    // gate only updates on remote sync, which never runs while offline.
    await sl<PermissionService>().loadEnabledModules(businessId);

    // Show spinner only — don't add to pending yet. If remote succeeds we
    // never show the offline banner. If remote fails we promote to pending.
    emit(current.copyWith(
      modules: {...current.modules, code: enabled},
      saving: {...current.saving, code},
    ));

    try {
      await sl<PermissionRemoteDs>().setModuleEnabled(businessId, code, enabled);
      await _removePending(code);
      await sl<PermissionService>().syncModules(businessId);

      final label = _kModules
          .firstWhere(
            (m) => m.code == code,
            orElse: () => _ModuleInfo(
              code: code,
              label: code,
              description: '',
              icon: IconlyLight.category,
            ),
          )
          .label;
      sl<AuditLogService>().log(
        actionType: AuditLogActionType.businessModuleChanged,
        entityType: 'module',
        entityName: label,
        description: '$label module ${enabled ? 'enabled' : 'disabled'}',
        metadata: {'module': code, 'enabled': enabled},
        businessId: businessId,
      );

      final s = state;
      if (s is ModuleSettingsLoaded) {
        emit(s.copyWith(pending: Set<String>.of(s.pending)..remove(code)));
      }
    } catch (e, st) {
      debugPrint('[ModuleSettings] Error in toggle "$code" → $enabled: $e\n$st');
      // Remote failed — promote to pending so the offline banner appears.
      final s = state;
      if (s is ModuleSettingsLoaded) {
        emit(s.copyWith(pending: {...s.pending, code}));
      }
    } finally {
      final s = state;
      if (s is ModuleSettingsLoaded) {
        emit(s.copyWith(saving: Set<String>.of(s.saving)..remove(code)));
      }
    }
  }

  // ── SharedPreferences pending-set helpers ────────────────────────────────

  Future<Set<String>> _readPendingCodes() async {
    final list = sl<SharedPreferences>().getStringList(_pendingKey(businessId));
    return list?.toSet() ?? {};
  }

  Future<void> _addPending(String code) async {
    final codes = await _readPendingCodes()..add(code);
    await sl<SharedPreferences>().setStringList(
      _pendingKey(businessId),
      codes.toList(),
    );
  }

  Future<void> _removePending(String code) async {
    final codes = await _readPendingCodes()..remove(code);
    await sl<SharedPreferences>().setStringList(
      _pendingKey(businessId),
      codes.toList(),
    );
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    return super.close();
  }
}

// ── Page ─────────────────────────────────────────────────────────────────────

class ModuleSettingsPage extends StatelessWidget {
  final String businessId;

  const ModuleSettingsPage({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ModuleSettingsCubit(businessId)..load(),
      child: const _ModuleSettingsView(),
    );
  }
}

class _ModuleSettingsView extends StatefulWidget {
  const _ModuleSettingsView();

  @override
  State<_ModuleSettingsView> createState() => _ModuleSettingsViewState();
}

class _ModuleSettingsViewState extends State<_ModuleSettingsView> {
  bool _bannerVisible = false;

  @override
  void initState() {
    super.initState();
    _loadBannerState();
  }

  Future<void> _loadBannerState() async {
    final prefs = sl<SharedPreferences>();
    final dismissed = prefs.getBool(_kBannerDismissedKey) ?? false;
    if (mounted) setState(() => _bannerVisible = !dismissed);
  }

  Future<void> _dismissBanner() async {
    setState(() => _bannerVisible = false);
    await sl<SharedPreferences>().setBool(_kBannerDismissedKey, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppSubPageBar(title: 'Module Management'),
      body: BlocBuilder<ModuleSettingsCubit, ModuleSettingsState>(
        builder: (context, state) {
          if (state is ModuleSettingsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.brand),
            );
          }

          if (state is ModuleSettingsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        IconlyLight.danger,
                        size: 28,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: getOutfitStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () =>
                          context.read<ModuleSettingsCubit>().load(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Retry',
                        style: getOutfitStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final loaded = state as ModuleSettingsLoaded;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              // ── Dismissible info banner ──────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOut,
                child: _bannerVisible
                    ? _InfoBanner(onDismiss: _dismissBanner)
                    : const SizedBox.shrink(),
              ),
              if (_bannerVisible) const SizedBox(height: 16),

              // ── Section header ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'BUSINESS MODULES',
                  style: getOutfitStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              // ── Offline / pending notice ─────────────────────────────────
              if (loaded.isOffline || loaded.pending.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withAlpha(60),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        IconlyLight.danger,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loaded.pending.isNotEmpty
                              ? 'You\'re offline — changes saved locally and will sync when you\'re back online.'
                              : 'Offline — showing cached data.',
                          style: getOutfitStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ── Module cards ─────────────────────────────────────────────
              ...List.generate(_kModules.length, (i) {
                final m = _kModules[i];
                final enabled = loaded.modules[m.code] ?? true;
                final saving = loaded.saving.contains(m.code);
                final pendingSync = loaded.pending.contains(m.code);
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: i < _kModules.length - 1 ? 10 : 0,
                  ),
                  child: _ModuleCard(
                    info: m,
                    enabled: enabled,
                    saving: saving,
                    pendingSync: pendingSync,
                  ),
                );
              }),

              // ── Footer note ──────────────────────────────────────────────
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    IconlyLight.shield_done,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Changes are saved automatically',
                    style: getOutfitStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Dismissible info banner ──────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final VoidCallback onDismiss;

  const _InfoBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.brand.withAlpha(14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brand.withAlpha(35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(IconlyLight.info_circle, size: 18, color: AppColors.brand),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Enable or disable business modules.'
              'Disabled modules are hidden from staff and '
              'access is blocked at the server level.',
              style: getOutfitStyle(
                fontSize: 13,
                color: AppColors.brand,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.brand.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 15,
                color: AppColors.brand,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Module card ──────────────────────────────────────────────────────────────

class _ModuleCard extends StatelessWidget {
  final _ModuleInfo info;
  final bool enabled;
  final bool saving;
  final bool pendingSync;

  const _ModuleCard({
    required this.info,
    required this.enabled,
    required this.saving,
    this.pendingSync = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled ? AppColors.brand.withAlpha(45) : AppColors.borderSoft,
          width: 1.2,
        ),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.brand.withAlpha(18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon container
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: enabled
                    ? AppColors.brand.withAlpha(20)
                    : AppColors.borderSoft.withAlpha(120),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                info.icon,
                size: 20,
                color: enabled ? AppColors.brand : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 14),

            // Label + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.label,
                    style: getOutfitStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: enabled
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    info.description,
                    style: getOutfitStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Toggle / spinner / pending indicator
            if (saving)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.brand,
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (pendingSync)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        size: 16,
                        color: AppColors.warning,
                      ),
                    ),
                  CupertinoSwitch(
                    value: enabled,
                    activeTrackColor: AppColors.brand,
                    onChanged: (v) =>
                        context.read<ModuleSettingsCubit>().toggle(info.code, v),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
