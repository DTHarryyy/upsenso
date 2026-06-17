import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<void> sharePdfBytes(Uint8List bytes, String filename) async {
  final dir = await _targetDir();
  await File('${dir.path}/$filename').writeAsBytes(bytes);
}

Future<Directory> _targetDir() async {
  if (Platform.isAndroid) {
    // getDownloadsDirectory() → /storage/emulated/0/Download on Android 10+
    // No WRITE_EXTERNAL_STORAGE permission needed on API 29+.
    final dl = await getDownloadsDirectory();
    if (dl != null) return dl;
  }
  // iOS: Documents folder is visible in Files app when UIFileSharingEnabled = true
  return getApplicationDocumentsDirectory();
}
