enum AlertSeverity { high, medium, low }

enum AlertStatus { newAlert, investigating, resolved }

enum AlertType {
  refund,
  priceOverride,
  shiftHours,
  inventoryShrinkage,
  transferMismatch,
}

class FraudAlert {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final AlertStatus status;
  final AlertType type;
  final String author;
  final String store;
  final DateTime date;
  final Map<String, String> evidence;
  final List<String> relatedRecords;

  const FraudAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.status,
    required this.type,
    required this.author,
    required this.store,
    required this.date,
    required this.evidence,
    required this.relatedRecords,
  });
}

final List<FraudAlert> mockFraudAlerts = [
  FraudAlert(
    id: '1',
    title: 'Multiple refunds detected',
    description:
        'User processed 8 refunds in the last 2 hours, exceeding the threshold of 5',
    severity: AlertSeverity.high,
    status: AlertStatus.newAlert,
    type: AlertType.refund,
    author: 'Sarah M.',
    store: 'Downtown Store',
    date: DateTime(2026, 2, 18, 14, 30),
    evidence: {
      'Refund Count': '8',
      'Threshold': '5',
      'Timeframe': '2 hours',
      'Total Amount': '\$156.50',
    },
    relatedRecords: [
      'Transaction: TXN-001',
      'Transaction: TXN-003',
      'Transaction: TXN-007',
    ],
  ),
  FraudAlert(
    id: '2',
    title: 'Price override threshold exceeded',
    description: 'Discount of 45% applied, exceeding allowed maximum of 30%',
    severity: AlertSeverity.medium,
    status: AlertStatus.investigating,
    type: AlertType.priceOverride,
    author: 'Mike T.',
    store: 'Mall Outlet',
    date: DateTime(2026, 2, 18, 11, 15),
    evidence: {
      'Applied Discount': '45%',
      'Max Allowed': '30%',
      'Excess': '15%',
      'Item': 'Samsung TV 55"',
    },
    relatedRecords: [
      'Transaction: TXN-012',
      'Override Log: OVR-004',
    ],
  ),
  FraudAlert(
    id: '3',
    title: 'Sales made outside shift hours',
    description: '3 transactions recorded after shift closing time',
    severity: AlertSeverity.medium,
    status: AlertStatus.newAlert,
    type: AlertType.shiftHours,
    author: 'John Doe',
    store: 'Downtown Store',
    date: DateTime(2026, 2, 17, 22, 45),
    evidence: {
      'Transactions': '3',
      'Shift End': '9:00 PM',
      'First Occurrence': '10:05 PM',
      'Last Occurrence': '10:45 PM',
    },
    relatedRecords: [
      'Transaction: TXN-021',
      'Transaction: TXN-022',
      'Transaction: TXN-023',
      'Shift Log: SHF-017',
    ],
  ),
  FraudAlert(
    id: '4',
    title: 'Sudden inventory shrinkage',
    description: 'Coffee Beans stock decreased by 15 units without corresponding sales',
    severity: AlertSeverity.high,
    status: AlertStatus.newAlert,
    type: AlertType.inventoryShrinkage,
    author: 'System',
    store: 'Mall Outlet',
    date: DateTime(2026, 2, 17, 18, 0),
    evidence: {
      'Units Missing': '15',
      'Product': 'Coffee Beans 1kg',
      'Expected Stock': '42',
      'Actual Stock': '27',
    },
    relatedRecords: [
      'Stock Audit: AUD-008',
      'Inventory Log: INV-2024',
    ],
  ),
  FraudAlert(
    id: '5',
    title: 'Transfer quantity mismatch',
    description: 'Receiving branch reported 2 units less than sent',
    severity: AlertSeverity.low,
    status: AlertStatus.resolved,
    type: AlertType.transferMismatch,
    author: 'Mike T.',
    store: 'Mall Outlet',
    date: DateTime(2026, 2, 16, 15, 30),
    evidence: {
      'Sent Quantity': '50',
      'Received Quantity': '48',
      'Discrepancy': '2 units',
      'Product': 'Wireless Mouse',
    },
    relatedRecords: [
      'Transfer: TRF-009',
      'Receipt: RCP-031',
    ],
  ),
];
