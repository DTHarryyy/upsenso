import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// Writes the workbook to a temp file then hands it to the OS share sheet so the
// user picks where it lands (Files → on-device Downloads, Drive, email, …).
// Returns true only when the user actually completed the share — a sandbox
// write alone is invisible to the user and must not be reported as success.
Future<bool> saveAndShareExcel(List<int> bytes, String filename) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);

  final result = await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: _xlsxMime, name: filename)],
      subject: filename,
    ),
  );
  return result.status == ShareResultStatus.success;
}

const _xlsxMime =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
