import 'package:pos/features/business/domain/entities/business.dart';
import 'package:pos/features/business/domain/entities/business_template.dart';

abstract class BusinessState {}

class BusinessInitial extends BusinessState {}

class BusinessLoading extends BusinessState {}

class BusinessTemplatesLoaded extends BusinessState {
  final List<BusinessTemplate> templates;
  final BusinessTemplate? selectedTemplate;

  BusinessTemplatesLoaded({required this.templates, this.selectedTemplate});

  BusinessTemplatesLoaded copyWith({
    List<BusinessTemplate>? templates,
    BusinessTemplate? selectedTemplate,
  }) {
    return BusinessTemplatesLoaded(
      templates: templates ?? this.templates,
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
    );
  }
}

class BusinessCreated extends BusinessState {
  final Business business;
  BusinessCreated(this.business);
}

class BusinessError extends BusinessState {
  final String message;
  BusinessError(this.message);
}
