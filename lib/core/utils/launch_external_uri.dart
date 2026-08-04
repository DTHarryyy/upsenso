import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens an external `tel:`/`mailto:`/etc. URI from anywhere in the app,
/// showing a friendly snackbar on failure instead of a raw exception.
/// [feature] tags the debug log so errors are traceable to their origin
/// (e.g. `'CustomersPage'`, `'CustomerDetail'`).
Future<void> launchExternalUri(
  BuildContext context,
  String uri, {
  required String feature,
}) async {
  try {
    final ok = await launchUrl(Uri.parse(uri));
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No app available to handle that.')),
      );
    }
  } catch (e, st) {
    debugPrint('[$feature] Error launching $uri: $e\n$st');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that link.')),
      );
    }
  }
}
