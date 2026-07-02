import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pos/features/crm/domain/entities/customer_purchase.dart';
import 'package:pos/features/crm/domain/repositories/i_customer_repository.dart';

sealed class CustomerDetailState {}

class CustomerDetailLoading extends CustomerDetailState {}

class CustomerDetailLoaded extends CustomerDetailState {
  final List<CustomerPurchase> purchases;
  final CustomerStats stats;

  CustomerDetailLoaded({required this.purchases, required this.stats});
}

class CustomerDetailError extends CustomerDetailState {
  final String message;
  CustomerDetailError(this.message);
}

/// Streams one customer's purchase history and derives their aggregate stats.
/// Read-only companion to [CustomerCubit] (which owns create/edit/archive).
class CustomerDetailCubit extends Cubit<CustomerDetailState> {
  final ICustomerRepository _repository;
  final String businessId;
  final String customerId;

  StreamSubscription? _sub;

  CustomerDetailCubit({
    required ICustomerRepository repository,
    required this.businessId,
    required this.customerId,
  })  : _repository = repository,
        super(CustomerDetailLoading());

  void watch() {
    emit(CustomerDetailLoading());
    _sub?.cancel();
    _sub = _repository
        .watchPurchases(businessId: businessId, customerId: customerId)
        .listen(
      (purchases) {
        emit(
          CustomerDetailLoaded(
            purchases: purchases,
            stats: CustomerStats.fromPurchases(purchases),
          ),
        );
      },
      onError: (Object e, StackTrace st) {
        debugPrint('[CustomerDetailCubit] watch error: $e\n$st');
        emit(CustomerDetailError('Failed to load purchase history.'));
      },
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
