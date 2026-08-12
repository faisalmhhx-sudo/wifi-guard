import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/storage_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

/// شاشة سجل التنبيهات (دخول جهاز جديد، إلخ).
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  Color _color(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.critical:
        return AppColors.danger;
      case AlertSeverity.warning:
        return AppColors.warning;
      case AlertSeverity.info:
        return AppColors.primary;
    }
  }

  IconData _icon(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.critical:
        return Icons.warning_amber_rounded;
      case AlertSeverity.warning:
        return Icons.info_outline;
      case AlertSeverity.info:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final alerts = state.alerts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('التنبيهات'),
        actions: [
          if (alerts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => state.clearAlerts(),
              tooltip: 'مسح السجل',
            ),
        ],
      ),
      body: alerts.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 72, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('لا توجد تنبيهات',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'فعّل "المراقبة في الخلفية" من الإعدادات لتصلك تنبيهات '
                      'فورية عند دخول أي جهاز جديد على شبكتك.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: alerts.length,
              itemBuilder: (_, i) {
                final a = alerts[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _color(a.severity).withOpacity(0.15),
                      child: Icon(_icon(a.severity), color: _color(a.severity)),
                    ),
                    title: Text(a.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.body),
                        const SizedBox(height: 4),
                        Text(_fmt(a.time),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}/${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
