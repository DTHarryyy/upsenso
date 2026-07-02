import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/features/ai_assistant/models/ai_models.dart';
import 'package:pos/features/ai_assistant/services/ai_tool_service.dart';
import 'package:pos/features/insights/domain/insight.dart';
import 'package:pos/features/insights/domain/insights_generator.dart';
import 'package:pos/features/insights/domain/insights_metrics.dart';

/// Gathers the deterministic numbers (via [AiToolService]) and runs the pure
/// [InsightsGenerator] to produce the dashboard insight card content.
///
/// Permission is enforced here, in business logic — a caller without
/// `insights.view` gets an empty list regardless of what the UI renders. The
/// `insights.view` key is reports-module-gated, so a business that disabled the
/// reports module also yields nothing.
class InsightsRepository {
  final AiToolService _toolService;
  final PermissionService _permissionService;
  final InsightsGenerator _generator;

  InsightsRepository({
    required AiToolService toolService,
    required PermissionService permissionService,
    InsightsGenerator generator = const InsightsGenerator(),
  })  : _toolService = toolService,
        _permissionService = permissionService,
        _generator = generator;

  /// How many products to pull for the best-seller and margin insights — the
  /// generator only uses the leader, but a small list keeps room for future
  /// "top 3" phrasing without another query.
  static const int _productSampleSize = 3;

  /// Loads today's insights for the given tenant/branch. Returns an empty list
  /// when the user lacks `insights.view`, when there is no active business, or
  /// when there is simply nothing to say. Throws on a genuine data error so the
  /// caller can show a graceful error state rather than a silent blank.
  Future<List<Insight>> loadInsights({
    required String businessId,
    required String cashierId,
    required String? branchId,
  }) async {
    if (!_permissionService.can(PermissionKeys.insightsView)) return const [];
    if (businessId.trim().isEmpty) return const [];

    final period = AiDateFilter.today();

    final salesTrend = await _toolService.getSalesTrend(
      businessId,
      cashierId,
      period,
      branchId: branchId,
    );
    final approvedExpenseTotal = await _toolService.getApprovedExpenseTotal(
      businessId,
      period,
      branchId: branchId,
    );
    final topProducts = await _toolService.getTopProducts(
      businessId,
      cashierId,
      period,
      branchId: branchId,
      limit: _productSampleSize,
    );
    final marginMovers = await _toolService.getMarginMovers(
      businessId,
      cashierId,
      period,
      branchId: branchId,
      limit: _productSampleSize,
    );
    final lowStockCount = await _toolService.getLowStockCount(businessId);

    return _generator.generate(InsightsMetrics(
      salesTrend: salesTrend,
      approvedExpenseTotal: approvedExpenseTotal,
      topProducts: topProducts,
      marginMovers: marginMovers,
      lowStockCount: lowStockCount,
    ));
  }
}
