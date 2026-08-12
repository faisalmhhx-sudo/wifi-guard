import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/network_device.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../widgets/device_icon.dart';
import 'router_screen.dart';

/// شاشة تفاصيل جهاز واحد + إجراءات (تسمية، توثيق، حظر).
class DeviceDetailScreen extends StatelessWidget {
  final NetworkDevice device;
  const DeviceDetailScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: Text(device.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  child: Icon(deviceIcon(device.type),
                      size: 44, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(device.displayName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                Text(device.type.arabicLabel,
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: (device.isOnline ? AppColors.accent : Colors.grey)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    device.isOnline ? 'متصل الآن' : 'غير متصل',
                    style: TextStyle(
                      color: device.isOnline ? AppColors.accent : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _infoCard([
            _row('عنوان IP', device.ip),
            _row('عنوان MAC', device.mac.isEmpty ? 'غير متاح' : device.mac),
            _row('الشركة المصنّعة', device.vendor ?? 'غير معروفة'),
            _row('اسم المضيف', device.hostname ?? '—'),
            _row('المنافذ المفتوحة',
                device.openPorts.isEmpty ? 'لا يوجد' : device.openPorts.join(', ')),
            _row('أول ظهور', _fmt(device.firstSeen)),
            _row('آخر ظهور', _fmt(device.lastSeen)),
          ]),
          const SizedBox(height: 16),
          _actions(context, state),
        ],
      ),
    );
  }

  Widget _infoCard(List<Widget> rows) => Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(children: rows),
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _actions(BuildContext context, AppState state) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.edit),
          title: const Text('إعادة تسمية الجهاز'),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          tileColor: Theme.of(context).cardColor,
          onTap: () => _renameDialog(context, state),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          secondary: const Icon(Icons.verified_user),
          title: const Text('جهاز موثوق'),
          subtitle: const Text('لن يصلك تنبيه عند اتصاله'),
          value: device.isTrusted,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          tileColor: Theme.of(context).cardColor,
          onChanged: (v) => state.setTrusted(device, v),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.block, color: AppColors.danger),
          title: const Text('حظر / طرد من الشبكة',
              style: TextStyle(color: AppColors.danger)),
          subtitle: const Text('يتم عبر إعدادات الراوتر'),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          tileColor: Theme.of(context).cardColor,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RouterScreen(targetMac: device.mac),
            ),
          ),
        ),
      ],
    );
  }

  void _renameDialog(BuildContext context, AppState state) {
    final ctrl = TextEditingController(text: device.customName ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تسمية الجهاز'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'مثال: جوال أحمد',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              state.renameDevice(device, ctrl.text.trim());
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}/${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
