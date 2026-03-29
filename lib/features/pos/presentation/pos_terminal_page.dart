import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/ui/status/status_snack.dart';
import 'package:pos/core/ui/status/status_type.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pos/features/pos/data/models/cart_model.dart';
import 'package:pos/features/pos/presentation/pages/checkout_payment_page.dart';

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

  final _variantsDao = sl<ProductVariantsDao>();
  final _productsDao = sl<ProductsDao>();

  bool _permissionDenied = false;
  bool _torchEnabled = false;
  bool _isCollapsed = false;
  bool _scanning = false;
  DateTime? _lastScanTime;
  String? _lastScannedCode;
  final List<CartItem> _cartItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _checkCameraPermission(),
      );
    }
  }

  @override
  void didUpdateWidget(PosTerminalPage old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _checkCameraPermission();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.isActive) return;
    if (state == AppLifecycleState.resumed) {
      _checkCameraPermission();
    }
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() => _permissionDenied = !status.isGranted);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    _sheetController.dispose();
    _tabletScrollController.dispose();
    super.dispose();
  }

  double get _subtotal => _cartItems.fold(0.0, (s, i) => s + i.total);
  double get _tax => _cartItems.fold(0.0, (s, i) => s + i.taxAmount);
  double get _grandTotal => _subtotal + _tax;

  String _fmt(double v) => '₱${v.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+\.)'),
        (m) => '${m[1]},',
      )}';

  void _toggleTorch() {
    _scannerController.toggleTorch();
    setState(() => _torchEnabled = !_torchEnabled);
  }

  void _removeItem(int i) => setState(() => _cartItems.removeAt(i));

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
    if (_cartItems.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cart'),
        content: Text(
          'Remove all ${_cartItems.length} '
          '${_cartItems.length == 1 ? 'item' : 'items'} from the order?',
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
      setState(() => _cartItems.clear());
    }
  }

  void _checkout() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutPaymentPage(
          items: List.unmodifiable(_cartItems),
          subtotal: _subtotal,
          tax: _tax,
          total: _grandTotal,
          onPaymentConfirmed: () => setState(() => _cartItems.clear()),
        ),
      ),
    );
  }

  void _increment(int i) => setState(() => _cartItems[i].qty += 1);
  void _decrement(int i) {
    if (_cartItems[i].qty <= 1) {
      _removeItem(i);
    } else {
      setState(() => _cartItems[i].qty -= 1);
    }
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
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;
      final businessId = authState.user.businessId;
      if (businessId == null) return;

      final variant = await _variantsDao.getByBarcode(code, businessId);
      if (variant != null) {
        if (!variant.isActive) {
          _showFeedback('This variant is inactive', isError: true);
          return;
        }
        final product = await _productsDao.getById(variant.productId);
        final productName = product?.name ?? variant.name;
        final showVariant = product?.hasVariants ?? false;
        _addOrIncrement(
          variantId: variant.id,
          name: productName,
          variant: showVariant ? variant.name : '',
          unitPrice: variant.price,
          taxRate: product?.tax,
        );
        return;
      }

      // Fallback: product-level barcode (simple products)
      final product = await _productsDao.getByBarcode(code, businessId);
      if (product != null) {
        final variants = await _variantsDao.getByProductId(product.id);
        final active = variants.where((v) => v.isActive).toList();
        if (active.isEmpty) {
          _showFeedback('${product.name}: no active variants', isError: true);
          return;
        }
        if (active.length > 1) {
          _showFeedback(
            '${product.name}: scan a specific variant barcode',
            isError: true,
          );
          return;
        }
        final v = active.first;
        _addOrIncrement(
          variantId: v.id,
          name: product.name,
          variant: '',
          unitPrice: v.price,
          taxRate: product.tax,
        );
        return;
      }

      _showAddProductDialog(code);
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
    setState(() {
      final idx = _cartItems.indexWhere((i) => i.variantId == variantId);
      if (idx >= 0) {
        _cartItems[idx].qty += 1;
      } else {
        _cartItems.add(CartItem(
          variantId: variantId,
          name: name,
          variant: variant,
          unitPrice: unitPrice,
          taxRate: taxRate,
        ));
      }
    });
    final label = variant.isNotEmpty ? '$name · $variant' : name;
    _showFeedback("$label added to cart");
    if (_isCollapsed && _sheetController.isAttached) {
      _sheetController.animateTo(
        0.50,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
      StatusSnack.show(context, type: StatusType.success, message: message);
    
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
              MobileScanner(
                controller: _scannerController,
                onDetect: _onBarcodeDetected,
                errorBuilder: (context, error, child) =>
                    const ColoredBox(color: Colors.black),
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
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _onBarcodeDetected,
                    errorBuilder: (context, error, child) =>
                        const ColoredBox(color: Colors.black),
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
        child: _isCollapsed
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
                      _cartItems.isNotEmpty && constraints.maxHeight >= 340;
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
                        child: _cartItems.isEmpty
                            ? _buildCartEmptyState()
                            : ListView.separated(
                                controller: sc,
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  bottom: 12,
                                ),
                                itemCount: _cartItems.length,
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
              _cartItems.isEmpty
                  ? Icons.shopping_cart_outlined
                  : Icons.shopping_cart_rounded,
              size: 20,
              color: AppColors.brand,
            ),
            const SizedBox(width: 8),
            Text(
              '${_cartItems.length} ${_cartItems.length == 1 ? 'item' : 'items'}',
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
              '${_cartItems.length} ${_cartItems.length == 1 ? 'item' : 'items'}',
              style: getOutfitStyle(
                color: AppColors.brand,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
          const Spacer(),
          if (_cartItems.isNotEmpty)
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: AppFilledButton(
            label: _cartItems.isEmpty
                ? 'Checkout'
                : 'Checkout · ${_fmt(_grandTotal)}',
            onPressed: _cartItems.isEmpty ? null : _checkout,
          ),
        ),
      ],
    );
  }


  Widget _buildCartPanelContent(ScrollController sc) {
    return Column(
      children: [
        _buildCartHeader(),
        Expanded(
          child: _cartItems.isEmpty
              ? _buildCartEmptyState()
              : ListView.separated(
                  controller: sc,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _cartItems.length,
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
      key: ValueKey(_cartItems[i].variantId),
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
    final item = _cartItems[index];
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


