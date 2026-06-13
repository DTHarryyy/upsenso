import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/database/daos/business_modules_dao.dart';
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

// ── Cubit ────────────────────────────────────────────────────────────────────

class ModuleSettingsCubit extends Cubit<ModuleSettingsState> {
  final String businessId;

  ModuleSettingsCubit(this.businessId) : super(ModuleSettingsLoading());

  Future<void> load() async {
    try {
      final raw = await sl<PermissionRemoteDs>().fetchEnabledModules(
        businessId,
      );
      final modules = {for (final m in _kModules) m.code: raw[m.code] ?? true};
      emit(ModuleSettingsLoaded(modules: modules));
    } catch (e) {
      debugPrint('[ModuleSettings] load FAILED: $e');
      emit(ModuleSettingsError('Failed to load modules. Please try again.'));
    }
  }

  Future<void> toggle(String code, bool enabled) async {
    final current = state;
    if (current is! ModuleSettingsLoaded) return;
    if (current.saving.contains(code)) return;

    emit(
      current.copyWith(
        modules: {...current.modules, code: enabled},
        saving: {...current.saving, code},
      ),
    );

    try {
      await sl<PermissionRemoteDs>().setModuleEnabled(
        businessId,
        code,
        enabled,
      );
      await sl<BusinessModulesDao>().saveModules(businessId, {code: enabled});
      await sl<PermissionService>().syncModules(businessId);
    } catch (e) {
      debugPrint('[ModuleSettings] toggle "$code" → $enabled FAILED: $e');
      final s = state;
      if (s is ModuleSettingsLoaded) {
        emit(s.copyWith(modules: {...s.modules, code: !enabled}));
      }
    } finally {
      final s = state;
      if (s is ModuleSettingsLoaded) {
        emit(s.copyWith(saving: Set<String>.of(s.saving)..remove(code)));
      }
    }
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

              // ── Module cards ─────────────────────────────────────────────
              ...List.generate(_kModules.length, (i) {
                final m = _kModules[i];
                final enabled = loaded.modules[m.code] ?? true;
                final saving = loaded.saving.contains(m.code);
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: i < _kModules.length - 1 ? 10 : 0,
                  ),
                  child: _ModuleCard(info: m, enabled: enabled, saving: saving),
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

  const _ModuleCard({
    required this.info,
    required this.enabled,
    required this.saving,
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

            // Toggle / spinner
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
              CupertinoSwitch(
                value: enabled,
                activeTrackColor: AppColors.brand,
                onChanged: (v) =>
                    context.read<ModuleSettingsCubit>().toggle(info.code, v),
              ),
          ],
        ),
      ),
    );
  }
}
