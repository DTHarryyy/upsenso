import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/features/dashboard/data/dashboard_data.dart';
import 'package:pos/features/dashboard/presentation/widgets/dashboard_empty_state.dart';

class LowStockAlertsCard extends StatelessWidget {
  final List<LowStockItem> items;
  const LowStockAlertsCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(IconlyBold.danger,
                  size: 20, color: Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Low Stock Alerts',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              if (items.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: DashboardEmptyState(
                icon: IconlyLight.category,
                iconColor: Color(0xFF16A34A),
                iconBg: Color(0xFFDCFCE7),
                title: 'All stocked up!',
                subtitle: 'Inventory levels\nlook great',
              ),
            )
          else
            ...items.take(5).map((item) => _StockRow(item: item)),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text(
                'Manage Stock',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  final LowStockItem item;
  const _StockRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final severity = _severity(item.currentStock, item.reorderAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Severity dot
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: severity.color,
                  shape: BoxShape.circle,
                ),
              ),
              // Product name
              Expanded(
                child: Text(
                  item.displayName,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Stock count badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: severity.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${item.currentStock} left',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: severity.color,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 2),
            child: Row(
              children: [
                // Severity label
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: severity.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    severity.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: severity.color,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                if (item.reorderAt != null)
                  Text(
                    'Reorder at: ${item.reorderAt}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Divider(height: 1, color: Colors.grey.shade100),
        ],
      ),
    );
  }

  _Severity _severity(int stock, int? threshold) {
    if (stock <= 0) {
      return const _Severity(
        label: 'OUT OF STOCK',
        color: Color(0xFFDC2626),
      );
    }
    if (threshold != null && stock <= threshold ~/ 2) {
      return const _Severity(
        label: 'CRITICAL',
        color: Color(0xFFEF4444),
      );
    }
    return const _Severity(
      label: 'LOW',
      color: Color(0xFFF59E0B),
    );
  }
}

class _Severity {
  final String label;
  final Color color;
  const _Severity({required this.label, required this.color});
}
