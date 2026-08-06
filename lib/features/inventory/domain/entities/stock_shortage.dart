import 'package:equatable/equatable.dart';

class StockShortage extends Equatable {
  final String variantId;
  final double available;
  final double requested;

  const StockShortage({
    required this.variantId,
    required this.available,
    required this.requested,
  });

  @override
  List<Object?> get props => [variantId, available, requested];
}
