/// Pure domain entity — no Drift/Supabase types leak in here.
class ReceiptSettings {
  // Identity
  final String id;
  final String businessId;

  // Business details
  final String businessName;
  final String storeName;
  final String ownerName;
  final String address;
  final String contactNumber;
  final String email;
  final String website;
  final String tinNumber;
  final String permitNumber;

  // Receipt content
  final String headerText;
  final String footerText;
  final String returnPolicy;
  final String customNotes;

  // Logo
  final bool showLogo;
  final String logoLocalPath;
  final String logoUrl;

  // Toggles
  final bool showQrCode;
  final bool showTaxBreakdown;
  final bool showCashierName;
  final bool showCustomerName;
  final bool showDateTime;
  final bool showOrderId;

  // Printing
  final String paperSize;   // '58mm' | '80mm'
  final String fontSize;    // 'small' | 'medium' | 'large'
  final String textAlignment; // 'left' | 'center' | 'right'
  final bool autoPrintAfterCheckout;
  final bool printDuplicateCopy;
  final bool thermalPrinterEnabled;

  // Timestamps
  final DateTime updatedAt;

  const ReceiptSettings({
    required this.id,
    required this.businessId,
    this.businessName = '',
    this.storeName = '',
    this.ownerName = '',
    this.address = '',
    this.contactNumber = '',
    this.email = '',
    this.website = '',
    this.tinNumber = '',
    this.permitNumber = '',
    this.headerText = '',
    this.footerText = 'Thank you for your purchase!',
    this.returnPolicy = '',
    this.customNotes = '',
    this.showLogo = true,
    this.logoLocalPath = '',
    this.logoUrl = '',
    this.showQrCode = false,
    this.showTaxBreakdown = true,
    this.showCashierName = true,
    this.showCustomerName = false,
    this.showDateTime = true,
    this.showOrderId = true,
    this.paperSize = '80mm',
    this.fontSize = 'medium',
    this.textAlignment = 'center',
    this.autoPrintAfterCheckout = false,
    this.printDuplicateCopy = false,
    this.thermalPrinterEnabled = false,
    required this.updatedAt,
  });

  /// Default empty settings for a new business.
  factory ReceiptSettings.empty(String businessId) => ReceiptSettings(
        id: businessId,
        businessId: businessId,
        updatedAt: DateTime.now(),
      );

  ReceiptSettings copyWith({
    String? businessName,
    String? storeName,
    String? ownerName,
    String? address,
    String? contactNumber,
    String? email,
    String? website,
    String? tinNumber,
    String? permitNumber,
    String? headerText,
    String? footerText,
    String? returnPolicy,
    String? customNotes,
    bool? showLogo,
    String? logoLocalPath,
    String? logoUrl,
    bool? showQrCode,
    bool? showTaxBreakdown,
    bool? showCashierName,
    bool? showCustomerName,
    bool? showDateTime,
    bool? showOrderId,
    String? paperSize,
    String? fontSize,
    String? textAlignment,
    bool? autoPrintAfterCheckout,
    bool? printDuplicateCopy,
    bool? thermalPrinterEnabled,
  }) =>
      ReceiptSettings(
        id: id,
        businessId: businessId,
        businessName: businessName ?? this.businessName,
        storeName: storeName ?? this.storeName,
        ownerName: ownerName ?? this.ownerName,
        address: address ?? this.address,
        contactNumber: contactNumber ?? this.contactNumber,
        email: email ?? this.email,
        website: website ?? this.website,
        tinNumber: tinNumber ?? this.tinNumber,
        permitNumber: permitNumber ?? this.permitNumber,
        headerText: headerText ?? this.headerText,
        footerText: footerText ?? this.footerText,
        returnPolicy: returnPolicy ?? this.returnPolicy,
        customNotes: customNotes ?? this.customNotes,
        showLogo: showLogo ?? this.showLogo,
        logoLocalPath: logoLocalPath ?? this.logoLocalPath,
        logoUrl: logoUrl ?? this.logoUrl,
        showQrCode: showQrCode ?? this.showQrCode,
        showTaxBreakdown: showTaxBreakdown ?? this.showTaxBreakdown,
        showCashierName: showCashierName ?? this.showCashierName,
        showCustomerName: showCustomerName ?? this.showCustomerName,
        showDateTime: showDateTime ?? this.showDateTime,
        showOrderId: showOrderId ?? this.showOrderId,
        paperSize: paperSize ?? this.paperSize,
        fontSize: fontSize ?? this.fontSize,
        textAlignment: textAlignment ?? this.textAlignment,
        autoPrintAfterCheckout:
            autoPrintAfterCheckout ?? this.autoPrintAfterCheckout,
        printDuplicateCopy: printDuplicateCopy ?? this.printDuplicateCopy,
        thermalPrinterEnabled:
            thermalPrinterEnabled ?? this.thermalPrinterEnabled,
        updatedAt: DateTime.now(),
      );
}
