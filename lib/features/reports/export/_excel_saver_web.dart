import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

// Browser download via an object-URL anchor; the file lands in the browser's
// Downloads automatically, so it always counts as delivered.
Future<bool> saveAndShareExcel(List<int> bytes, String filename) async {
  final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  final blob = web.Blob(
    [data.toJS].toJS,
    web.BlobPropertyBag(
      type:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    ),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  web.URL.revokeObjectURL(url);
  return true;
}
