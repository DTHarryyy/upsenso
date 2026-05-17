import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_strings.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/validators.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/ui/status/status_snack.dart';
import 'package:pos/core/ui/status/status_type.dart';

import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/auth/presentation/widgets/auth_layout.dart';
import 'package:pos/features/business/domain/entities/business_template.dart';
import 'package:pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:pos/features/business/presentation/bloc/business_event.dart';
import 'package:pos/features/business/presentation/bloc/business_state.dart';

class BusinessProfileSetup extends StatefulWidget {
  const BusinessProfileSetup({super.key});

  @override
  State<BusinessProfileSetup> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfileSetup> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _branchNameController;
  BusinessTemplate? _selectedTemplate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _branchNameController = TextEditingController();
    context.read<BusinessBloc>().add(LoadBusinessTemplates());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _branchNameController.dispose();
    super.dispose();
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  Future<void> _navigateToHomeWhenBusinessContextReady() async {
    if (!mounted) return;
    final authBloc = context.read<AuthBloc>();

    try {
      // Wait for AuthBloc to reflect the new business — the remote fetch
      // triggered by AuthStarted usually completes within 1-2 s.
      await authBloc.stream
          .firstWhere(
            (s) =>
                s is AuthAuthenticated &&
                _hasText(s.user.businessId),
          )
          .timeout(const Duration(seconds: 6));
    } catch (_) {
      // Timed out — navigate anyway; router will settle once context arrives.
    }

    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  void _onSubmit() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    if (_selectedTemplate == null) {
      StatusSnack.show(
        context,
        type: StatusType.warning,
        title: 'Select template',
        message: 'Please select a business type to continue.',
      );
      return;
    }

    context.read<BusinessBloc>().add(
      CreateBusinessRequested(
        name: _nameController.text.trim(),
        templateId: _selectedTemplate!.id,
        branchName: _branchNameController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BusinessBloc, BusinessState>(
      listenWhen: (prev, curr) => curr is! BusinessLoading,
      listener: (context, state) {
        if (state is BusinessCreated) {
          context.read<AuthBloc>().add(AuthStarted());
          StatusSnack.show(
            context,
            type: StatusType.success,
            title: 'Business created',
            message: 'Your business profile is ready!',
          );
          _navigateToHomeWhenBusinessContextReady();
          return;
        }
        if (state is BusinessError) {
          StatusSnack.show(
            context,
            type: StatusType.error,
            title: 'Error',
            message: state.message,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is BusinessLoading;
        final templates = state is BusinessTemplatesLoaded
            ? state.templates
            : <BusinessTemplate>[];

        return AuthLayout(
          leftPanel: const _BusinessSetupPanel(),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon badge
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    IconlyLight.work,
                    size: 26,
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(height: 24),

                // Heading
                Text(
                  'Set up your business',
                  style: AppTextStyles.headline(context).copyWith(
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your business profile to unlock your full dashboard.',
                  style: AppTextStyles.subtitle(context).copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 32),

                // Business name
                _FieldLabel(label: 'Business name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Dela Cruz Store',
                    prefixIcon: Icon(IconlyLight.work),
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      Validators.required(v, fieldName: 'Business name'),
                ),
                const SizedBox(height: 24),

                // Branch name
                _FieldLabel(label: 'First branch name'),
                const SizedBox(height: 4),
                Text(
                  'Name for your main location',
                  style: AppTextStyles.caption(context).copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _branchNameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Main Branch, Downtown',
                    prefixIcon: Icon(IconlyBold.work),
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      Validators.required(v, fieldName: 'Branch name'),
                ),
                const SizedBox(height: 24),

                // Business type dropdown
                _FieldLabel(label: 'Business type'),
                const SizedBox(height: 4),
                Text(
                  'Customizes your POS modules and default settings',
                  style: AppTextStyles.caption(context).copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<BusinessTemplate>(
                  initialValue: _selectedTemplate,
                  decoration: const InputDecoration(
                    hintText: 'Select a business type',
                    prefixIcon: Icon(IconlyLight.category),
                  ),
                  isExpanded: true,
                  items: templates.map((t) {
                    return DropdownMenuItem<BusinessTemplate>(
                      value: t,
                      child: Text(t.name),
                    );
                  }).toList(),
                  onChanged: (t) {
                    setState(() => _selectedTemplate = t);
                    if (t != null) {
                      context.read<BusinessBloc>().add(SelectTemplate(t));
                    }
                  },
                  validator: (v) =>
                      v == null ? 'Please select a business type' : null,
                ),

                // Template details
                if (_selectedTemplate != null) ...[
                  const SizedBox(height: 16),
                  _TemplateDetailsCard(template: _selectedTemplate!),
                ],

                const SizedBox(height: 32),

                // Submit
                FilledButton(
                  onPressed: isLoading ? null : _onSubmit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create business'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.subtitle(context).copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _TemplateDetailsCard extends StatelessWidget {
  final BusinessTemplate template;
  const _TemplateDetailsCard({required this.template});

  @override
  Widget build(BuildContext context) {
    final modules = template.defaultModules.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toList();
    final roles = template.defaultRoles.map((r) => r['name'] as String).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                IconlyLight.info_circle,
                size: 16,
                color: AppColors.brand,
              ),
              const SizedBox(width: 6),
              Text(
                'Template details',
                style: AppTextStyles.caption(context).copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _DetailRow(
            icon: IconlyLight.category,
            label: 'Modules',
            value: modules.join(', '),
          ),
          _DetailRow(
            icon: IconlyLight.user,
            label: 'Roles',
            value: roles.join(', '),
          ),
          if (template.defaultTaxRate != null)
            _DetailRow(
              icon: Icons.percent_rounded,
              label: 'Default tax',
              value: '${template.defaultTaxRate}%',
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: AppTextStyles.caption(context).copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: AppTextStyles.caption(context).copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Business setup left panel ──────────────────────────────────────────────

class _BusinessSetupPanel extends StatelessWidget {
  const _BusinessSetupPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D4ED8), Color(0xFF557FF4), Color(0xFF7C9FF8)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthWordmark(),

              const Spacer(),

              // Headline
              const Text(
                'Almost there!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Set up your business profile to unlock your full POS dashboard and start selling.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.80),
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),

              // Setup steps
              const _SetupStep(
                number: '1',
                label: 'Create your account',
                done: true,
              ),
              const SizedBox(height: 12),
              const _SetupStep(
                number: '2',
                label: 'Verify your email',
                done: true,
              ),
              const SizedBox(height: 12),
              const _SetupStep(
                number: '3',
                label: 'Set up your business',
                done: false,
              ),

              const Spacer(),

              Text(
                '© 2025 ${AppStrings.appName}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  final String number;
  final String label;
  final bool done;

  const _SetupStep({
    required this.number,
    required this.label,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: done
                ? Colors.white.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: done ? 0.5 : 0.3),
            ),
          ),
          child: done
              ? const Icon(IconlyLight.tick_square, size: 14, color: Colors.white)
              : Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: done
                ? Colors.white.withValues(alpha: 0.65)
                : Colors.white,
            fontSize: 14,
            fontWeight: done ? FontWeight.w400 : FontWeight.w600,
            decoration: done ? TextDecoration.lineThrough : null,
            decorationColor: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
