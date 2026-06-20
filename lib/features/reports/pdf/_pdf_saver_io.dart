import 'dart:typed_data';

import 'package:printing/printing.dart';

// Hands the PDF to the native share/print sheet so the user chooses the
// destination (Files, Drive, print, …). Returns true when they followed
// through — Printing reports false if the sheet is dismissed.
Future<bool> sharePdfBytes(Uint8List bytes, String filename) =>
    Printing.sharePdf(bytes: bytes, filename: filename);
