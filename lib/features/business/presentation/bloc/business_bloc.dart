import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:pos/features/business/domain/repositories/business_repository.dart';
import 'package:pos/features/business/presentation/bloc/business_event.dart';
import 'package:pos/features/business/presentation/bloc/business_state.dart';

class BusinessBloc extends Bloc<BusinessEvent, BusinessState> {
  final BusinessRepository businessRepository;
  final AuthRepository authRepository;

  BusinessBloc({required this.businessRepository, required this.authRepository})
    : super(BusinessInitial()) {
    on<LoadBusinessTemplates>(_onLoadTemplates);
    on<SelectTemplate>(_onSelectTemplate);
    on<CreateBusinessRequested>(_onCreateBusiness);
  }

  Future<void> _onLoadTemplates(
    LoadBusinessTemplates event,
    Emitter<BusinessState> emit,
  ) async {
    emit(BusinessLoading());

    try {
      final templates = await businessRepository.getBusinessTemplates();
      emit(BusinessTemplatesLoaded(templates: templates));
    } catch (e) {
      emit(BusinessError(e.toString()));
    }
  }

  void _onSelectTemplate(SelectTemplate event, Emitter<BusinessState> emit) {
    final currentState = state;
    if (currentState is BusinessTemplatesLoaded) {
      emit(currentState.copyWith(selectedTemplate: event.template));
    }
  }

  Future<void> _onCreateBusiness(
    CreateBusinessRequested event,
    Emitter<BusinessState> emit,
  ) async {
    final currentState = state;
    if (currentState is! BusinessTemplatesLoaded) return;

    emit(BusinessLoading());

    try {
      final currentUser = authRepository.getCurrentUser();
      if (currentUser == null) {
        emit(BusinessError('User not authenticated'));
        return;
      }

      final business = await businessRepository.createBusiness(
        name: event.name,
        ownerId: currentUser.id,
        templateId: event.templateId,
      );

      emit(BusinessCreated(business));
    } catch (e) {
      emit(BusinessError(e.toString()));
      // Re-emit templates loaded state so user can retry
      emit(currentState);
    }
  }
}
