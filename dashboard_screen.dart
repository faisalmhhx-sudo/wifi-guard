import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../widgets/stat_card.dart';

/// الشاشة الرئيسية: نظرة عامة على الشبكة وزر المسح.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final wifi = state.wifiInfo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('حارس الواي فاي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: state.scanning ? null : () => state.startScan(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => state.startScan(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _wifiCard(context, wifi?.ssid, wifi?.ip, wifi?.gateway),
            const SizedBox(height: 16),
            _scanButton(context, state),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                StatCard(
                  value: '${state.onlineCount}',
                  label: 'أجهزة متصلة الآن',
                  icon: Icons.devices,
                  color: AppColors.primary,
                ),
                StatCard(
                  value: '${state.trustedCount}',
                  label: 'أجهزة موثوقة',
                  icon: Icons.verified_user,
                  color: AppColors.accent,
                ),
                StatCard(
                  value: '${state.unknownCount}',
                  label: 'أجهزة غير موثوقة',
                  icon: Icons.help_outline,
                  color: AppColors.warning,
                ),
                StatCard(
                  value: '${state.alerts.length}',
                  label: 'تنبيهات',
                  icon: Icons.notifications_active,
                  color: AppColors.danger,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.error != null)
              Card(
                color: AppColors.danger.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.danger),
                      const SizedBox(width: 12),
                      Expanded(child: Text(state.error!)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _wifiCard(
      BuildContext context, String? ssid, String? ip, String? gateway) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.wifi, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ssid ?? 'غير متصل بواي فاي',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('عنوانك: ${ip ?? '—'}',
                      style: const TextStyle(color: Colors.grey)),
                  Text('الراوتر: ${gateway ?? '—'}',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scanButton(BuildContext context, AppState state) {
    if (state.scanning) {
      final p = state.progress;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'جاري فحص الشبكة… ${p != null ? '${p.scanned}/${p.total}' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: () => state.cancelScan(),
                    child: const Text('إيقاف'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: p?.fraction,
                borderRadius: BorderRadius.circular(8),
                minHeight: 8,
              ),
              if (p != null) ...[
                const SizedBox(height: 8),
                Text('تم العثور على ${p.found} جهاز',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ],
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => state.startScan(),
        icon: const Icon(Icons.radar),
        label: const Text('فحص الشبكة الآن',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
