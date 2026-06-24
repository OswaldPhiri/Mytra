import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../providers/app_providers.dart';
import '../../../../services/export/export_service.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  bool _isLoading = false;

  Future<void> _export(Future<void> Function(ExportService) exportAction) async {
    setState(() => _isLoading = true);
    try {
      final db = ref.read(databaseProvider);
      final service = ExportService(db);
      await exportAction(service);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export ready for sharing!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Data')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Export your transaction history to analyze it in other tools or keep a backup.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
              const SizedBox(height: 24),
              _ExportCard(
                title: 'Export to Excel',
                subtitle: 'Full transaction history formatted for Microsoft Excel (.xlsx)',
                icon: Icons.table_view_rounded,
                color: const Color(0xFF107C41), // Excel Green
                onTap: () => _export((s) => s.exportExcel()),
              ),
              const SizedBox(height: 12),
              _ExportCard(
                title: 'Export to CSV',
                subtitle: 'Raw comma-separated values for universal spreadsheet compatibility (.csv)',
                icon: Icons.data_array_rounded,
                color: AppColors.seedColor,
                onTap: () => _export((s) => s.exportCsv()),
              ),
              const SizedBox(height: 12),
              _ExportCard(
                title: 'Export to JSON',
                subtitle: 'Structured data format for developers and automated tools (.json)',
                icon: Icons.code_rounded,
                color: const Color(0xFFF59E0B),
                onTap: () => _export((s) => s.exportJson()),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _ExportCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ExportCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
