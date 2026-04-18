import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation, SystemChrome;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/services/cart_service.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/ui/status/status_snack.dart';
import 'package:pos/core/ui/status/status_type.dart';
import 'package:pos/features/pos/domain/usecases/resolve_barcode_use_case.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pos/features/pos/data/models/cart_model.dart';
import 'package:pos/features/pos/presentation/widgets/discount_sheet.dart';
import 'package:pos/features/products/checkout/product_checkout_page.dart';

class PosTerminalPage extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onClose;

  const PosTerminalPage({
    super.key,
    this.isActive = true,
    this.onClose,
  });

  @override
  State<PosTerminalPage> createState() => _PosTerminalPageState();
}

class _PosTerminalPageState extends State<PosTerminalPage>
    with WidgetsBindingObserver {
  final _scannerController = MobileScannerController();
  final _sheetController = DraggableScrollableController();
  final _tabletScrollController = ScrollController();
  final _audioPlayer = AudioPlayer();

  final _resolveBarcode = sl<ResolveBarcodeUseCase>();
  final _cartService = sl<CartService>();

  bool _permissionDenied = false;
  bool _torchEnabled = false;
  bool _isCollapsed = false;
  bool _scanning = false;
  DateTime? _lastScanTime;
  String? _lastScannedCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isActive) {
      _unlockOrientation();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _checkCameraPermission(),
      );
    }
  }

  @override
  void didUpdateWidget(PosTerminalPage old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _unlockOrientation();
      _checkCameraPermission();
    } else if (!widget.isActive && old.isActive) {
      _lockToPortrait();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.isActive) return;
    if (state == AppLifecycleState.resumed) {
      _checkCameraPermission();
    }
  }

  @override
  void didChangeMetrics() {
    if (!widget.isActive || _permissionDenied) return;
    // Restart the camera so the native session picks up the new orientation.
    _scannerController.stop().then((_) => _scannerController.start());
  }

  void _unlockOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _lockToPortrait() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  Future<void> _checkCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    if (!mounted) return;
    setState(() => _permissionDenied = !status.isGranted);
  }

  @override
  void dispose() {
    _lockToPortrait();
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    _sheetController.dispose();
    _tabletScrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  double get _subtotal => _cartService.items.fold(0.0, (s, i) => s + i.total);
  double get _tax => _cartService.items.fold(0.0, (s, i) => s + i.taxAmount);
  double get _discountAmount => _cartService.discountAmount(_subtotal);
  double get _grandTotal => (_subtotal - _discountAmount + _tax).clamp(0.0, double.infinity);

  String _fmt(double v) => '₱${v.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+\.)'),
        (m) => '${m[1]},',
      )}';

  void _toggleTorch() {
    _scannerController.toggleTorch();
    setState(() => _torchEnabled = !_torchEnabled);
  }

  void _removeItem(int i) {
    _cartService.remove(_cartService.items[i].variantId);
  }

  void _tapDragHandle() {
    if (!_sheetController.isAttached) return;
    final target = _sheetController.size >= 0.6 ? 0.10 : 0.76;
    _sheetController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _clearCart() async {
    if (_cartService.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cart'),
        content: Text(
          'Remove all ${_cartService.itemCount} '
          '${_cartService.itemCount == 1 ? 'item' : 'items'} from the order?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _cartService.clear();
    }
  }

  void _checkout() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductCheckoutPage(
          items: List.from(_cartService.items),
          subtotal: _subtotal,
          tax: _tax,
          total: _grandTotal,
          discountAmount: _discountAmount,
          onPaymentConfirmed: () {
            if (mounted) _cartService.clear();
          },
        ),
      ),
    );
  }

  void _showDiscountSheet() {
    showDiscountSheet(context, _cartService, _subtotal);
  }

  void _increment(int i) {
    final item = _cartService.items[i];
    _cartService.setQty(item.variantId, item.qty + 1);
  }

  void _decrement(int i) {
    final item = _cartService.items[i];
    _cartService.setQty(item.variantId, item.qty - 1);
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;

    // Debounce: ignore same barcode within 1.5 s
    final now = DateTime.now();
    if (code == _lastScannedCode &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!).inMilliseconds < 1500) {
      return;
    }
    if (_scanning) return;

    _lastScannedCode = code;
    _lastScanTime = now;
    _scanning = true;

    try {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;
      final businessId = authState.user.businessId;
      if (businessId == null) return;

      final result = await _resolveBarcode(code, businessId);
      switch (result) {
        case BarcodeResolved(
          :final variantId,
          :final productName,
          :final variantLabel,
          :final unitPrice,
          :final taxRate,
        ):
          _addOrIncrement(
            variantId: variantId,
            name: productName,
            variant: variantLabel,
            unitPrice: unitPrice,
            taxRate: taxRate,
          );
        case BarcodeInactive():
          _showFeedback('This variant is inactive', isError: true);
        case BarcodeNoVariants(:final productName):
          _showFeedback('$productName: no active variants', isError: true);
        case BarcodeAmbiguous(:final productName):
          _showFeedback(
            '$productName: scan a specific variant barcode',
            isError: true,
          );
        case BarcodeUnknown():
          _showAddProductDialog(code);
      }
    } catch (_) {
      _showFeedback('Scan error. Try again.', isError: true);
    } finally {
      _scanning = false;
    }
  }

  void _addOrIncrement({
    required String variantId,
    required String name,
    required String variant,
    required double unitPrice,
    double? taxRate,
  }) {
    _cartService.addOrIncrement(
      variantId: variantId,
      name: name,
      variant: variant,
      unitPrice: unitPrice,
      taxRate: taxRate,
    );
    try {
      _audioPlayer.play(AssetSource('sounds/barcodeScanned.mp3'));
    } catch (_) {}
    if (_isCollapsed && _sheetController.isAttached) {
      try {
        _sheetController.animateTo(
          0.50,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } catch (_) {}
    }
  }

  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    StatusSnack.show(
      context,
      type: isError ? StatusType.error : StatusType.success,
      message: message,
    );
  }

  Future<void> _showAddProductDialog(String barcode) async {
    if (!mounted) return;
    final shouldAdd = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Product Not Found'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('No product matches this barcode.'),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                barcode,
                style: getOutfitStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Would you like to add it as a new product?',
              style: AppTextStyles.body(context)
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.brand),
            child: const Text('Add Product'),
          ),
        ],
      ),
    );
    if (shouldAdd == true && mounted) {
      context.push('/home/add-product', extra: barcode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Breakpoints.isTablet(context)
        ? _buildTablet(context)
        : _buildMobile(context);
  }

  //  mobile layout
  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: NotificationListener<DraggableScrollableNotification>(
        onNotification: (n) {
          final collapsed = n.extent <= 0.15;
          if (collapsed != _isCollapsed) {
            setState(() => _isCollapsed = collapsed);
          }
          return false;
        },
        child: Stack(
          children: [
            // Full-screen camera background
            if (widget.isActive && !_permissionDenied)
              OrientationBuilder(
                builder: (ctx, orientation) => MobileScanner(
                  key: ValueKey(orientation),
                  controller: _scannerController,
                  fit: BoxFit.cover,
                  onDetect: _onBarcodeDetected,
                  errorBuilder: (context, error, child) =>
                      const ColoredBox(color: Colors.black),
                ),
              )
            else
              const ColoredBox(color: Colors.black),
            // Scan frame + controls overlay
            _ScannerOverlay(
              torchEnabled: _torchEnabled,
              onToggleTorch: _permissionDenied ? null : _toggleTorch,
              onClose: widget.onClose,
              sheetController: _sheetController,
            ),
            // Permission denied overlay
            if (_permissionDenied) _buildPermissionDenied(),
            // Cart sheet
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.50,
              minChildSize: 0.10,
              maxChildSize: 0.76,
              snap: true,
              snapSizes: const [0.10, 0.50, 0.76],
              builder: (ctx, sc) => _buildCartSheet(sc),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTablet(BuildContext context) {
    final panelWidth = Breakpoints.isDesktop(context) ? 400.0 : 340.0;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          Expanded(
            child: Stack(
              children: [
                if (widget.isActive && !_permissionDenied)
                  OrientationBuilder(
                    builder: (ctx, orientation) => MobileScanner(
                      key: ValueKey(orientation),
                      controller: _scannerController,
                      fit: BoxFit.cover,
                      onDetect: _onBarcodeDetected,
                      errorBuilder: (context, error, child) =>
                          const ColoredBox(color: Colors.black),
                    ),
                  )
                else
                  const ColoredBox(color: Colors.black),
                _ScannerOverlay(
                  torchEnabled: _torchEnabled,
                  onToggleTorch: _permissionDenied ? null : _toggleTorch,
                  onClose: widget.onClose,
                ),
                if (_permissionDenied) _buildPermissionDenied(),
              ],
            ),
          ),
          Container(
            width: panelWidth,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                left: BorderSide(color: AppColors.borderSoft),
              ),
            ),
            child: SafeArea(child: _buildCartPanelContent(_tabletScrollController)),
          ),
        ],
      ),
    );
  }


  Widget _buildCartSheet(ScrollController sc) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: ListenableBuilder(
          listenable: _cartService,
          builder: (_, _) => _isCollapsed
            ? SingleChildScrollView(
                controller: sc,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _tapDragHandle,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.borderSoft,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    _buildCollapsedStrip(),
                  ],
                ),
              )
            : LayoutBuilder(
                builder: (ctx, constraints) {
                  final showFooter =
                      _cartService.isNotEmpty && constraints.maxHeight >= 340;
                  return Column(
                    children: [
                      GestureDetector(
                        onTap: _tapDragHandle,
                        onVerticalDragUpdate: (details) {
                          if (!_sheetController.isAttached) return;
                          final screenH = MediaQuery.sizeOf(context).height;
                          final delta = -(details.primaryDelta ?? 0) / screenH;
                          _sheetController.jumpTo(
                            (_sheetController.size + delta).clamp(0.10, 0.76),
                          );
                        },
                        onVerticalDragEnd: (details) {
                          if (!_sheetController.isAttached) return;
                          final current = _sheetController.size;
                          const snapPoints = [0.10, 0.50, 0.76];
                          final nearest = snapPoints.reduce((a, b) =>
                              (a - current).abs() < (b - current).abs()
                                  ? a
                                  : b);
                          _sheetController.animateTo(
                            nearest,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.borderSoft,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      _buildCartHeader(),
                      Expanded(
                        child: _cartService.isEmpty
                            ? _buildCartEmptyState()
                            : ListView.separated(
                                controller: sc,
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  bottom: 12,
                                ),
                                itemCount: _cartService.itemCount,
                                separatorBuilder: (_, _) => const Divider(
                                    height: 1, color: AppColors.borderSoft),
                                itemBuilder: (_, i) =>
                                    _buildDismissibleItemRow(i),
                              ),
                      ),
                      if (showFooter) _buildCartFooter(),
                    ],
                  );
                },
              ),
        ),
      ),
    );
  }

  // ── Collapsed strip ────────────────────────────────────────────────────────

  Widget _buildCollapsedStrip() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _tapDragHandle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Row(
          children: [
            Icon(
              _cartService.isEmpty
                  ? Icons.shopping_cart_outlined
                  : Icons.shopping_cart_rounded,
              size: 20,
              color: AppColors.brand,
            ),
            const SizedBox(width: 8),
            Text(
              '${_cartService.itemCount} ${_cartService.itemCount == 1 ? 'item' : 'items'}',
              style: getOutfitStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Text(
              _fmt(_grandTotal),
              style: getOutfitStyle(
                color: AppColors.brand,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_up_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  // cart sub widgets

  Widget _buildCartHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Text(
            'Current Order',
            style: AppTextStyles.subtitle(context).copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_cartService.itemCount} ${_cartService.itemCount == 1 ? 'item' : 'items'}',
              style: getOutfitStyle(
                color: AppColors.brand,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
          const Spacer(),
          if (_cartService.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
              onPressed: _clearCart,
              tooltip: 'Clear cart',
            ),
        ],
      ),
    );
  }

  Widget _buildCartEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.qr_code_scanner, size: 44, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(
            'Scan a barcode to add items',
            style: AppTextStyles.body(context).copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCartFooter() {
    final hasDiscount = _cartService.hasDiscount;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 1, color: AppColors.borderSoft),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            children: [
              _summaryRow('Subtotal', _fmt(_subtotal)),
              if (hasDiscount) ...[
                const SizedBox(height: 4),
                _discountSummaryRow(),
              ],
              if (_tax > 0) ...[
                const SizedBox(height: 4),
                _summaryRow('Tax', _fmt(_tax)),
              ],
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.borderSoft),
              const SizedBox(height: 10),
              _summaryRow('Total', _fmt(_grandTotal), isBig: true),
            ],
          ),
        ),
        // Discount button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: GestureDetector(
            onTap: _cartService.isEmpty ? null : _showDiscountSheet,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: hasDiscount
                    ? AppColors.successSoft
                    : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasDiscount
                      ? AppColors.success
                      : AppColors.borderSoft,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasDiscount
                        ? Icons.local_offer_rounded
                        : Icons.local_offer_outlined,
                    size: 15,
                    color: hasDiscount
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasDiscount
                        ? 'Discount applied · tap to change'
                        : 'Add Discount',
                    style: getOutfitStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: hasDiscount
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: AppFilledButton(
            label: _cartService.isEmpty
                ? 'Checkout'
                : 'Checkout · ${_fmt(_grandTotal)}',
            onPressed: _cartService.isEmpty ? null : _checkout,
          ),
        ),
      ],
    );
  }

  Widget _discountSummaryRow() {
    final cs = _cartService;
    final label = cs.discountType == DiscountType.percentage
        ? 'Discount (${cs.discountValue.toStringAsFixed(cs.discountValue % 1 == 0 ? 0 : 1)}%)'
        : 'Discount (Fixed)';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              label,
              style: getOutfitStyle(
                  color: AppColors.success, fontSize: 13),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _cartService.clearDiscount,
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        Text(
          '− ${_fmt(_discountAmount)}',
          style: getOutfitStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
              fontSize: 13),
        ),
      ],
    );
  }


  Widget _buildCartPanelContent(ScrollController sc) {
    return Column(
      children: [
        _buildCartHeader(),
        Expanded(
          child: _cartService.isEmpty
              ? _buildCartEmptyState()
              : ListView.separated(
                  controller: sc,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _cartService.itemCount,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: AppColors.borderSoft),
                  itemBuilder: (_, i) => _buildDismissibleItemRow(i),
                ),
        ),
        _buildCartFooter(),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool isBig = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBig
              ? AppTextStyles.subtitle(context).copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                )
              : AppTextStyles.body(context)
                  .copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: isBig
              ? getOutfitStyle(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                )
              : getOutfitStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
        ),
      ],
    );
  }

  Widget _buildDismissibleItemRow(int i) {
    return Dismissible(
      key: ValueKey(_cartService.items[i].variantId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        color: AppColors.error,
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
      onDismissed: (_) => _removeItem(i),
      child: _buildCartItemRow(i),
    );
  }

  Widget _buildCartItemRow(int index) {
    final item = _cartService.items[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: getOutfitStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.variant.isNotEmpty)
                  Text(
                    item.variant,
                    style: getOutfitStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              _qtyBtn(Icons.remove_rounded, () => _decrement(index)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  item.qty.toInt().toString(),
                  style: getOutfitStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              _qtyBtn(Icons.add_rounded, () => _increment(index)),
            ],
          ),
          const SizedBox(width: 12),
          Text(
            _fmt(item.total),
            style: getOutfitStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xCC000000),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.no_photography_outlined,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                Text(
                  'Camera Permission Required',
                  style: getOutfitStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Grant camera access to scan barcodes',
                  style: getOutfitStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  icon: const Icon(Icons.settings_rounded),
                  label: const Text('Open Settings'),
                  onPressed: openAppSettings,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.textSecondary),
      ),
    );
  }
}

// scanner ovelay

class _ScannerOverlay extends StatelessWidget {
  final bool torchEnabled;
  final VoidCallback? onToggleTorch;
  final VoidCallback? onClose;
  final DraggableScrollableController? sheetController;

  const _ScannerOverlay({
    required this.torchEnabled,
    this.onToggleTorch,
    this.onClose,
    this.sheetController,
  });

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    return SizedBox.expand(
      child: Stack(
      children: [
        // Top gradient for readability
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 110,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xCC000000), Colors.transparent],
              ),
            ),
          ),
        ),

        // Title + torch button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                if (onClose != null)
                  _OverlayIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: onClose,
                  )
                else
                  const SizedBox(width: 4),
                const SizedBox(width: 8),
                Text(
                  'Scan Barcode',
                  style: getOutfitStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Opacity(
                  opacity: onToggleTorch == null ? 0.4 : 1.0,
                  child: _OverlayIconButton(
                    icon: torchEnabled
                        ? Icons.flashlight_off_rounded
                        : Icons.flashlight_on_rounded,
                    onTap: onToggleTorch,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Scan frame — dynamically centred in visible camera area
        if (sheetController != null)
          AnimatedBuilder(
            animation: sheetController!,
            builder: (ctx, _) {
              final extent = sheetController!.isAttached
                  ? sheetController!.size
                  : 0.50;
              return Positioned.fill(
                bottom: screenH * extent,
                child: const Center(child: _ScanFrame()),
              );
            },
          )
        else
          const Positioned.fill(
            child: Center(child: _ScanFrame()),
          ),
      ],
      ),
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _OverlayIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0x33FFFFFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ── Scan Frame ────────────────────────────────────────────────────────────────

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final frameW = screenW * 0.72;
    final frameH = frameW * 0.42;
    const cs = 28.0; // corner arm length
    const ct = 2.5; // corner thickness

    return SizedBox(
      width: frameW,
      height: frameH,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: _corner(top: true, left: true, s: cs, t: ct),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _corner(top: true, left: false, s: cs, t: ct),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: _corner(top: false, left: true, s: cs, t: ct),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: _corner(top: false, left: false, s: cs, t: ct),
          ),
          // Static red alignment line at vertical centre
          Positioned(
            top: frameH / 2 - 1.5,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withAlpha(0),
                    Colors.red,
                    Colors.red.withAlpha(0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner({
    required bool top,
    required bool left,
    required double s,
    required double t,
  }) {
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        border: Border(
          top: top
              ? BorderSide(color: Colors.white, width: t)
              : BorderSide.none,
          bottom: !top
              ? BorderSide(color: Colors.white, width: t)
              : BorderSide.none,
          left: left
              ? BorderSide(color: Colors.white, width: t)
              : BorderSide.none,
          right: !left
              ? BorderSide(color: Colors.white, width: t)
              : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: top && left ? const Radius.circular(4) : Radius.zero,
          topRight: top && !left ? const Radius.circular(4) : Radius.zero,
          bottomLeft: !top && left ? const Radius.circular(4) : Radius.zero,
          bottomRight: !top && !left ? const Radius.circular(4) : Radius.zero,
        ),
      ),
    );
  }
}

// ── Cart Item model ───────────────────────────────────────────────────────────

