import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/database/daos/business_modules_dao.dart';
import 'package:pos/core/permissions/data/permission_remote_ds.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/widgets/app_section_card.dart';
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
    code: 'suppliers',
    label: 'Supplier Directory',
    description: 'Supplier contacts and purchase records',
    icon: IconlyLight.work,
  ),
  _ModuleInfo(
    code: 'audit',
    label: 'Audit Logs',
    description: 'Activity tracking and security audit trail',
    icon: IconlyLight.document,
  ),
];

// ── Cubit state ────────────────────────────────────────────────────────────

sealed class ModuleSettingsState {}

class ModuleSettingsLoading extends ModuleSettingsState {}

class ModuleSettingsError extends ModuleSettingsState {
  final String message;
  ModuleSettingsError(this.message);
}

class ModuleSettingsLoaded extends ModuleSettingsState {
  final Map<String, bool> modules;
  final Set<String> saving;

  ModuleSettingsLoaded({required this.modules, Set<String>? saving})
      : saving = saving ?? const {};

  ModuleSettingsLoaded copyWith({
    Map<String, bool>? modules,
    Set<String>? saving,
  }) => ModuleSettingsLoaded(
    modules: modules ?? this.modules,
    saving: saving ?? this.saving,
  );
}

// ── Cubit ──────────────────────────────────────────────────────────────────

class ModuleSettingsCubit extends Cubit<ModuleSettingsState> {
  final String businessId;

  ModuleSettingsCubit(this.businessId) : super(ModuleSettingsLoading());

  Future<void> load() async {
    try {
      final raw = await sl<PermissionRemoteDs>().fetchEnabledModules(businessId);
      final modules = {
        for (final m in _kModules) m.code: raw[m.code] ?? true,
      };
      emit(ModuleSettingsLoaded(modules: modules));
    } catch (e, st) {
      debugPrint('[ModuleSettings] load FAILED: $e');
      debugPrint('[ModuleSettings] $st');
      emit(ModuleSettingsError('Failed to load modules. Please try again.'));
    }
  }

  Future<void> toggle(String code, bool enabled) async {
    final current = state;
    if (current is! ModuleSettingsLoaded) return;
    if (current.saving.contains(code)) return;

    // Optimistic update
    emit(current.copyWith(
      modules: {...current.modules, code: enabled},
      saving: {...current.saving, code},
    ));

    try {
      await sl<PermissionRemoteDs>().setModuleEnabled(businessId, code, enabled);
      // Refresh local cache + in-memory state
      await sl<BusinessModulesDao>().saveModules(businessId, {code: enabled});
      await sl<PermissionService>().syncModules(businessId);
    } catch (e, st) {
      debugPrint('[ModuleSettings] toggle "$code" → $enabled FAILED: $e');
      debugPrint('[ModuleSettings] $st');
      // Roll back optimistic update
      final s = state;
      if (s is ModuleSettingsLoaded) {
        emit(s.copyWith(modules: {...s.modules, code: !enabled}));
      }
    } finally {
      final s = state;
      if (s is ModuleSettingsLoaded) {
        final newSaving = Set<String>.of(s.saving)..remove(code);
        emit(s.copyWith(saving: newSaving));
      }
    }
  }
}

// ── Page ───────────────────────────────────────────────────────────────────

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

class _ModuleSettingsView extends StatelessWidget {
  const _ModuleSettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppSubPageBar(title: 'Module Management'),
      body: BlocBuilder<ModuleSettingsCubit, ModuleSettingsState>(
        builder: (context, state) {
          if (state is ModuleSettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ModuleSettingsError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(IconlyLight.danger, size: 40, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    style: getOutfitStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () =>
                        context.read<ModuleSettingsCubit>().load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final loaded = state as ModuleSettingsLoaded;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.brand.withAlpha(12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.brand.withAlpha(40),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      IconlyLight.info_circle,
                      size: 18,
                      color: AppColors.brand,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Disabled modules are hidden from all staff and their '
                        'permissions are blocked at the server level.',
                        style: getOutfitStyle(
                          fontSize: 13,
                          color: AppColors.brand,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppSectionCard(
                title: 'Business Modules',
                icon: IconlyLight.setting,
                children: [
                  for (int i = 0; i < _kModules.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 24,
                        thickness: 1,
                        color: AppColors.borderSoft,
                      ),
                    _ModuleTile(
                      info: _kModules[i],
                      enabled: loaded.modules[_kModules[i].code] ?? true,
                      saving: loaded.saving.contains(_kModules[i].code),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}

// ── Module tile ────────────────────────────────────────────────────────────

class _ModuleTile extends StatelessWidget {
  final _ModuleInfo info;
  final bool enabled;
  final bool saving;

  const _ModuleTile({
    required this.info,
    required this.enabled,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.brand.withAlpha(18)
                : AppColors.borderSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            info.icon,
            size: 18,
            color: enabled ? AppColors.brand : AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 14),
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
        const SizedBox(width: 8),
        saving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Switch(
                value: enabled,
                activeThumbColor: AppColors.brand,
                onChanged: (v) =>
                    context.read<ModuleSettingsCubit>().toggle(info.code, v),
              ),
      ],
    );
  }
}
