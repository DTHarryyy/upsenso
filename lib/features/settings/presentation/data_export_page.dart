import 'package:flutter/material.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/export/data_export_service.dart';
import 'package:pos/core/widgets/app_filled_button.dart';
import 'package:pos/core/widgets/app_section_card.dart';

/// Manual data export — reachable on every tier including Free/lapsed (§4.7).
class DataExportPage extends StatefulWidget {
  const DataExportPage({super.key});

  @override
  State<DataExportPage> createState() => _DataExportPageState();
}

class _DataExportPageState extends State<DataExportPage> {
  bool _busy = false;

  Future<void> _export() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ok = await sl<DataExportService>().exportCsvBundle();
      if (!mounted) return;
      if (!ok) {
        _snack('There\'s no data to export yet.');
      }
    } catch (e) {
      if (mounted) _snack('Export failed. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Export My Data'),
        backgroundColor: AppColors.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppSectionCard(
            title: 'Download a copy',
            icon: Icons.download_outlined,
            children: [
              const Text(
                'Export your products, sales, expenses, inventory and customers '
                'as a spreadsheet-friendly file (CSV) you can keep or hand to '
                'your accountant. This works on any plan, online or offline.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              AppFilledButton(
                label: 'Export data',
                icon: Icons.ios_share_rounded,
                loading: _busy,
                onPressed: _export,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
