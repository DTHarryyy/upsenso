import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/validators.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/ui/status/status_snack.dart';
import 'package:pos/core/ui/status/status_type.dart';

import 'package:pos/features/business/domain/entities/business_template.dart';
import 'package:pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:pos/features/business/presentation/bloc/business_event.dart';
import 'package:pos/features/business/presentation/bloc/business_state.dart';

class BusinessProfilePage extends StatefulWidget {
  const BusinessProfilePage({super.key});

  @override
  State<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
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

    // TODO: DEBUG - Print Drift tables on page load
    sl<AppDatabase>().debugPrintAllTables();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _branchNameController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    if (_selectedTemplate == null) {
      StatusSnack.show(
        context,
        type: StatusType.warning,
        title: 'Select Template',
        message: 'Please select a business template to continue.',
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
          StatusSnack.show(
            context,
            type: StatusType.success,
            title: 'Success',
            message: 'Business profile created successfully!',
          );
          context.go(AppRoutes.home);
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

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header section
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.brandSoft,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.store_rounded,
                                size: 36,
                                color: AppColors.brand,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Set Up Your Business',
                              style: AppTextStyles.headline(
                                context,
                              ).copyWith(color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create your business profile to get started with your POS system',
                              style: AppTextStyles.body(
                                context,
                              ).copyWith(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Business Name Field
                      Text(
                        'Business Name',
                        style: AppTextStyles.subtitle(context).copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your business name',
                          prefixIcon: Icon(Icons.business_rounded),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            Validators.required(v, fieldName: 'Business name'),
                      ),

                      const SizedBox(height: 24),

                      // Branch Name Field
                      Text(
                        'Branch Name',
                        style: AppTextStyles.subtitle(context).copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Name for your first branch/location',
                        style: AppTextStyles.caption(
                          context,
                        ).copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _branchNameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g., Main Branch, Downtown Store',
                          prefixIcon: Icon(Icons.store_rounded),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            Validators.required(v, fieldName: 'Branch name'),
                      ),

                      const SizedBox(height: 24),

                      // Template Dropdown
                      Text(
                        'Business Type',
                        style: AppTextStyles.subtitle(context).copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select a template to customize your POS experience',
                        style: AppTextStyles.caption(
                          context,
                        ).copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<BusinessTemplate>(
                        initialValue: _selectedTemplate,
                        decoration: const InputDecoration(
                          hintText: 'Select a business template',
                          prefixIcon: Icon(Icons.category_rounded),
                        ),
                        isExpanded: true,
                        items: templates.map((template) {
                          return DropdownMenuItem<BusinessTemplate>(
                            value: template,
                            child: Text(template.name),
                          );
                        }).toList(),
                        onChanged: (template) {
                          setState(() {
                            _selectedTemplate = template;
                          });
                          if (template != null) {
                            context.read<BusinessBloc>().add(
                              SelectTemplate(template),
                            );
                          }
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a business template';
                          }
                          return null;
                        },
                      ),

                      // Template Details Card
                      if (_selectedTemplate != null) ...[
                        const SizedBox(height: 16),
                        _buildTemplateDetailsCard(_selectedTemplate!),
                      ],

                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: isLoading ? null : _onSubmit,
                          child: isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Create Business'),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Skip for now link
                      Center(
                        child: TextButton(
                          onPressed: () => context.go(AppRoutes.home),
                          child: Text(
                            'Skip for now',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTemplateDetailsCard(BusinessTemplate template) {
    // Extract enabled modules
    final enabledModules = template.defaultModules.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toList();

    // Extract roles
    final roles = template.defaultRoles
        .map((r) => r['name'] as String)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: AppColors.brand,
              ),
              const SizedBox(width: 8),
              Text(
                'Template Details',
                style: AppTextStyles.subtitle(context).copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Modules
          _buildDetailRow(
            icon: Icons.apps_rounded,
            label: 'Modules',
            value: enabledModules.join(', '),
          ),
          const SizedBox(height: 8),

          // Roles
          _buildDetailRow(
            icon: Icons.people_rounded,
            label: 'Roles',
            value: roles.join(', '),
          ),

          // Tax Rate
          if (template.defaultTaxRate != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              icon: Icons.percent_rounded,
              label: 'Default Tax Rate',
              value: '${template.defaultTaxRate}%',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
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
                  style: AppTextStyles.caption(
                    context,
                  ).copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
