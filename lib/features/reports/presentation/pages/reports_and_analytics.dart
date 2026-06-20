import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/branch/branch_state.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/errors/app_error_mapper.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/domain/repositories/i_reports_repository.dart';
import 'package:pos/features/reports/export/report_excel_exporter.dart';
import 'package:pos/features/reports/pdf/report_pdf_exporter.dart';
import 'package:pos/features/reports/presentation/cubit/reports_cubit.dart';
import 'package:pos/features/reports/presentation/cubit/reports_state.dart';
import 'package:pos/features/reports/presentation/widgets/branch_comparison.dart';
import 'package:pos/features/reports/presentation/widgets/inventory_health_tab.dart';
import 'package:pos/features/reports/presentation/widgets/profit_summary_tab.dart';
import 'package:pos/features/reports/presentation/widgets/report_nav_chip.dart';
import 'package:pos/features/reports/presentation/widgets/reports_header.dart';
import 'package:pos/features/reports/presentation/widgets/reports_skeleton.dart';
import 'package:pos/features/reports/presentation/widgets/sales_report_tab.dart';

// ─── Page ─────────────────────────────────────────────────────────────────────

class ReportsAndAnalyticsPage extends StatefulWidget {
  const ReportsAndAnalyticsPage({super.key});

  @override
  State<ReportsAndAnalyticsPage> createState() =>
      _ReportsAndAnalyticsPageState();
}

class _ReportsAndAnalyticsPageState extends State<ReportsAndAnalyticsPage> {
  late final ReportsCubit _cubit;

  int _selectedTab = 0;
  ReportPeriod _period = ReportPeriod.today;
  DateTimeRange? _customRange;
  bool _exportingPdf = false;
  bool _exportingExcel = false;

  // Short labels keep the segmented nav balanced; full titles live on the
  // section headers inside each tab.
  static const _tabs = [
    ReportTab(icon: IconlyLight.chart, label: 'Sales'),
    ReportTab(icon: IconlyLight.category, label: 'Inventory'),
    ReportTab(icon: IconlyLight.wallet, label: 'Profit'),
    ReportTab(icon: IconlyLight.work, label: 'Branches'),
  ];

  @override
  void initState() {
    super.initState();
    _cubit = ReportsCubit(sl<IReportsRepository>());
    WidgetsBinding.instance.addPostFrameCallback((_) => _startWatching());
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _startWatching() {
    if (!mounted) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    _cubit.startWatching(
      businessId: authState.user.businessId ?? '',
      branchId: context.read<BranchCubit>().getSelectedBranchIdForFiltering(),
      period: _period,
      customRange: _customRange,
    );
  }

  void _onPeriodDropdownChanged(ReportPeriod? v) async {
    if (v == null) return;
    if (v == ReportPeriod.custom) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: _customRange,
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.brand,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
              secondaryContainer: AppColors.brandSoft,
              onSecondaryContainer: AppColors.brand,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.brand),
            ),
          ),
          child: child!,
        ),
      );
      if (picked != null && mounted) {
        setState(() {
          _period = ReportPeriod.custom;
          _customRange = picked;
        });
        _cubit.changePeriod(ReportPeriod.custom, customRange: picked);
      }
    } else {
      setState(() {
        _period = v;
        _customRange = null;
      });
      _cubit.changePeriod(v);
    }
  }

  // ── Export handlers ──────────────────────────────────────────────────────────

  Future<void> _onExportPdf(
    ReportsData data,
    String businessName,
    String branchLabel,
  ) async {
    if (_exportingPdf || _exportingExcel) return;
    setState(() => _exportingPdf = true);
    try {
      final delivered = await ReportPdfExporter.export(
        data: data,
        period: _period,
        businessName: businessName,
        branchLabel: branchLabel,
      );
      if (mounted) _showExportResult(delivered, 'PDF');
    } catch (e, st) {
      debugPrint('[ReportsPage] Error in _onExportPdf: $e\n$st');
      if (mounted) {
        AppToast.show(
          context,
          'Export Failed',
          subtitle: AppErrorMapper.message(e),
          variant: AppToastVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  Future<void> _onExportExcel(
    ReportsData data,
    String businessName,
    String branchLabel,
  ) async {
    if (_exportingPdf || _exportingExcel) return;
    setState(() => _exportingExcel = true);
    try {
      final delivered = await ReportExcelExporter.export(
        data: data,
        period: _period,
        businessName: businessName,
        branchLabel: branchLabel,
      );
      if (mounted) _showExportResult(delivered, 'Excel');
    } catch (e, st) {
      debugPrint('[ReportsPage] Error in _onExportExcel: $e\n$st');
      if (mounted) {
        AppToast.show(
          context,
          'Export Failed',
          subtitle: AppErrorMapper.message(e),
          variant: AppToastVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _exportingExcel = false);
    }
  }

  // Honest feedback: success only when the file actually left the app. On the
  // web the browser download is immediate; on mobile the user picks a target
  // and may dismiss the share sheet — that's a cancel, not a success.
  void _showExportResult(bool delivered, String kind) {
    if (delivered) {
      AppToast.show(
        context,
        '$kind report ready',
        subtitle: kIsWeb
            ? 'Your download has started.'
            : 'Saved to the location you chose.',
        duration: const Duration(seconds: 3),
      );
    } else {
      AppToast.show(
        context,
        'Export cancelled',
        subtitle: 'No file was saved. Tap export to try again.',
        variant: AppToastVariant.info,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: MultiBlocListener(
        listeners: [
          BlocListener<BranchCubit, BranchState>(
            listenWhen: (p, c) => p.selectedBranchId != c.selectedBranchId,
            listener: (_, _) => _cubit.changeBranch(
              context.read<BranchCubit>().getSelectedBranchIdForFiltering(),
            ),
          ),
        ],
        child: BlocBuilder<ReportsCubit, ReportsState>(
          builder: (ctx, state) {
            final data = state is ReportsLoaded
                ? state.data
                : ReportsData.empty();
            final isLoading = state is ReportsLoading;

            final authState = ctx.read<AuthBloc>().state;
            final businessName = authState is AuthAuthenticated
                ? (authState.user.businessName ?? '')
                : '';
            final branchLabel =
                ctx.read<BranchCubit>().state.selectedBranch ?? 'All Branches';

            final hp = Breakpoints.horizontalPadding(context);
            final isPhone = Breakpoints.isPhone(context);

            final navBar = ReportNavChipBar(
              tabs: _tabs,
              selectedIndex: _selectedTab,
              onTabSelected: (i) => setState(() => _selectedTab = i),
            );
            final controls = ReportsControls(
              period: _period,
              customRangeLabel: _customRangeLabel,
              onPeriodChanged: _onPeriodDropdownChanged,
              exportButton: _ExportDropdown(
                isExportingPdf: _exportingPdf,
                isExportingExcel: _exportingExcel,
                onExportPdf: () => _onExportPdf(data, businessName, branchLabel),
                onExportExcel: () =>
                    _onExportExcel(data, businessName, branchLabel),
              ),
            );

            return Scaffold(
              backgroundColor: AppColors.background,
              body: RefreshIndicator(
                onRefresh: () async => _startWatching(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Phone: controls scroll away above the pinned tabs —
                    // pinning both would permanently eat too much of a
                    // small screen. Tablet+: tabs and controls share one
                    // pinned row since there's room for both.
                    if (isPhone)
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hp, 16, hp, 12),
                        sliver: SliverToBoxAdapter(child: controls),
                      ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _NavBarDelegate(
                        horizontalPadding: hp,
                        child: isPhone
                            ? navBar
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(child: navBar),
                                  const SizedBox(width: 16),
                                  controls,
                                ],
                              ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(hp, 16, hp, 28),
                      sliver: SliverToBoxAdapter(
                        child: _buildBody(state, data, isLoading: isLoading),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    ReportsState state,
    ReportsData data, {
    required bool isLoading,
  }) {
    // Inventory Health drives its own adaptive skeleton/empty handling.
    if (_selectedTab != 1) {
      if (isLoading) return const ReportsTabSkeleton();
      if (state is ReportsError) {
        return isNetworkErrorMessage(state.message)
            ? NetworkErrorView(message: state.message, onRetry: _startWatching)
            : _ErrorView(message: state.message, onRetry: _startWatching);
      }
    }
    return _buildTabContent(data, isLoading: isLoading);
  }

  Widget _buildTabContent(ReportsData data, {bool isLoading = false}) {
    switch (_selectedTab) {
      case 0:
        return SalesReportTab(data: data);
      case 1:
        return InventoryHealthTab(data: data, isLoading: isLoading);
      case 2:
        return ProfitSummaryTab(data: data);
      case 3:
        return BranchComparisonTab(data: data);
      default:
        return const SizedBox.shrink();
    }
  }

  String get _customRangeLabel {
    if (_customRange == null) return 'Custom range...';
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final s = _customRange!.start;
    final e = _customRange!.end;
    final sameDay = s.year == e.year && s.month == e.month && s.day == e.day;
    return sameDay ? fmt(s) : '${fmt(s)} – ${fmt(e)}';
  }
}

// ─── Sticky nav delegate ──────────────────────────────────────────────────────

class _NavBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double horizontalPadding;

  _NavBarDelegate({required this.child, required this.horizontalPadding});

  static const double _height = 66;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.fromLTRB(horizontalPadding, 4, horizontalPadding, 14),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _NavBarDelegate old) =>
      old.child != child || old.horizontalPadding != horizontalPadding;
}

// ─── Export dropdown ──────────────────────────────────────────────────────────

enum _ExportType { pdf, excel }

class _ExportDropdown extends StatelessWidget {
  final bool isExportingPdf;
  final bool isExportingExcel;
  final VoidCallback onExportPdf;
  final VoidCallback onExportExcel;

  const _ExportDropdown({
    required this.isExportingPdf,
    required this.isExportingExcel,
    required this.onExportPdf,
    required this.onExportExcel,
  });

  @override
  Widget build(BuildContext context) {
    final busy = isExportingPdf || isExportingExcel;
    final hint = isExportingPdf
        ? 'Preparing PDF…'
        : isExportingExcel
        ? 'Preparing Excel…'
        : 'Export';

    return AppPopupMenu<_ExportType>(
      hint: hint,
      leadingIcon: IconlyLight.upload,
      dense: true,
      busy: busy,
      items: [
        AppPopupMenuItem(
          value: _ExportType.pdf,
          label: 'Export as PDF',
          icon: IconlyLight.document,
          iconColor: AppColors.error,
        ),
        AppPopupMenuItem(
          value: _ExportType.excel,
          label: 'Export as Excel (.xlsx)',
          icon: IconlyLight.chart,
          iconColor: AppColors.success,
        ),
      ],
      onSelected: (v) {
        if (v == _ExportType.pdf) onExportPdf();
        if (v == _ExportType.excel) onExportExcel();
      },
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                IconlyLight.danger,
                size: 32,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load reports',
              style: AppTextStyles.subtitle(
                context,
              ).copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption(
                  context,
                ).copyWith(color: AppColors.textMuted, height: 1.4),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: AppColors.brand),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
