import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/wifi_network.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

/// شاشة تحليل الواي فاي: نقاط الوصول المجاورة، قوة الإشارة، القنوات.
class WifiAnalyzerScreen extends StatefulWidget {
  const WifiAnalyzerScreen({super.key});

  @override
  State<WifiAnalyzerScreen> createState() => _WifiAnalyzerScreenState();
}

class _WifiAnalyzerScreenState extends State<WifiAnalyzerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().scanAccessPoints();
    });
  }

  Color _signalColor(int percent) {
    if (percent >= 66) return AppColors.accent;
    if (percent >= 33) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final aps = state.accessPoints;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تحليل الواي فاي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => state.scanAccessPoints(),
          ),
        ],
      ),
      body: aps.isEmpty
          ? _empty(context, state)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('شبكات مجاورة: ${aps.length}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                  'كل ما زاد التداخل في القناة، ضعف أداء شبكتك. اختر قناة أقل ازدحاماً.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ...aps.map((ap) => _apCard(context, ap)),
              ],
            ),
    );
  }

  Widget _apCard(BuildContext context, WifiAccessPoint ap) {
    final color = _signalColor(ap.signalPercent);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wifi, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ap.ssid.isEmpty ? '(شبكة مخفية)' : ap.ssid,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('${ap.level} dBm',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: ap.signalPercent / 100,
              color: color,
              backgroundColor: color.withOpacity(0.15),
              minHeight: 6,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _tag('القناة ${ap.channel}', Icons.settings_input_antenna),
                _tag(ap.band, Icons.speed),
                _tag(ap.security, Icons.lock),
                _tag('${ap.signalPercent}%', Icons.signal_cellular_alt),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(text, style: const TextStyle(fontSize: 12)),
          ],
        ),
      );

  Widget _empty(BuildContext context, AppState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_find,
                size: 72, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('لا توجد نتائج',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'مسح الشبكات المجاورة يعمل على أندرويد ويتطلّب صلاحية الموقع.\n'
              'على آيفون هذه الميزة محدودة بسبب قيود النظام.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => state.scanAccessPoints(),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المسح'),
            ),
          ],
        ),
      ),
    );
  }
}
