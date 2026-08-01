import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:pos/core/errors/app_error_mapper.dart';
import 'package:pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:pos/features/business/domain/repositories/business_repository.dart';
import 'package:pos/features/business/presentation/bloc/business_event.dart';
import 'package:pos/features/business/presentation/bloc/business_state.dart';

class BusinessBloc extends Bloc<BusinessEvent, BusinessState> {
  final BusinessRepository businessRepository;
  final AuthRepository authRepository;

  // Survive across retries of the same signup so a second attempt reuses one
  // identity instead of provisioning another business. Cleared on success.
  String? _pendingBusinessId;
  String? _pendingBranchId;

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
    } catch (e, st) {
      debugPrint('[BusinessBloc] Error in _onLoadTemplates: $e\n$st');
      emit(BusinessError(AppErrorMapper.message(e)));
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

      // One identity for the whole attempt sequence. This bloc re-emits the
      // templates state on failure so the user can retry, and a retry MUST
      // reuse these ids — a fresh uuid per attempt is what left 8 orphaned
      // businesses on the server on 2026-07-26.
      _pendingBusinessId ??= const Uuid().v4();
      _pendingBranchId ??= const Uuid().v4();

      final business = await businessRepository.createBusiness(
        name: event.name,
        ownerId: currentUser.id,
        templateId: event.templateId,
        branchName: event.branchName,
        businessId: _pendingBusinessId,
        branchId: _pendingBranchId,
      );

      _pendingBusinessId = null;
      _pendingBranchId = null;
      emit(BusinessCreated(business));
    } catch (e, st) {
      debugPrint('[BusinessBloc] Error creating business: $e\n$st');

      emit(BusinessError(AppErrorMapper.message(e)));
      // Re-emit templates loaded state so user can retry
      emit(currentState);
    }
  }
}
