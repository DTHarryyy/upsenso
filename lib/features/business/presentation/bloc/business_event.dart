import 'package:pos/features/business/domain/entities/business_template.dart';

abstract class BusinessEvent {}

class LoadBusinessTemplates extends BusinessEvent {}

class CreateBusinessRequested extends BusinessEvent {
  final String name;
  final String templateId;
  final String branchName;

  CreateBusinessRequested({
    required this.name,
    required this.templateId,
    required this.branchName,
  });
}

class SelectTemplate extends BusinessEvent {
  final BusinessTemplate template;

  SelectTemplate(this.template);
}
