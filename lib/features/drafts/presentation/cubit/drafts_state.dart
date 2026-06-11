import 'package:equatable/equatable.dart';
import 'package:pos/features/drafts/domain/entities/draft_sale.dart';

abstract class DraftsState extends Equatable {
  const DraftsState();

  @override
  List<Object?> get props => [];
}

class DraftsInitial extends DraftsState {
  const DraftsInitial();
}

class DraftsLoading extends DraftsState {
  const DraftsLoading();
}

class DraftsLoaded extends DraftsState {
  final List<DraftSale> drafts;

  const DraftsLoaded(this.drafts);

  @override
  List<Object?> get props => [drafts];
}

class DraftsError extends DraftsState {
  final String message;

  const DraftsError(this.message);

  @override
  List<Object?> get props => [message];
}
