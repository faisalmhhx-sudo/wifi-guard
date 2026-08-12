import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

/// شاشة الإعدادات: المراقبة الخلفية، الصلاحيات، عن التطبيق.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('المراقبة والتنبيهات'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.shield_outlined),
                  title: const Text('المراقبة في الخلفية'),
                  subtitle: const Text(
                      'يفحص الشبكة دورياً وينبّهك عند دخول جهاز جديد'),
                  value: state.monitorEnabled,
                  onChanged: (v) async {
                    if (v) {
                      await _requestPermissions();
                    }
                    await state.setMonitor(v);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: const Text('فترة الفحص'),
                  subtitle: Text('كل ${state.scanIntervalMin} دقيقة'),
                  trailing: DropdownButton<int>(
                    value: state.scanIntervalMin,
                    items: const [15, 30, 60, 120]
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text('$m دقيقة'),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) state.setScanInterval(v);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('الصلاحيات'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('صلاحية الموقع'),
                  subtitle: const Text(
                      'مطلوبة لمسح شبكات الواي فاي على أندرويد'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => Permission.location.request(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('صلاحية الإشعارات'),
                  subtitle: const Text('لإرسال تنبيهات دخول جهاز جديد'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => Permission.notification.request(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('عن التطبيق'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('حارس الواي فاي'),
                  subtitle: Text('الإصدار 1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lightbulb_outline,
                      color: AppColors.warning),
                  title: const Text('كيف يعمل؟'),
                  subtitle: const Text('شرح مبسّط لطريقة الاكتشاف والحدود'),
                  onTap: () => _howItWorks(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 4),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.grey)),
      );

  Future<void> _requestPermissions() async {
    await [
      Permission.location,
      Permission.notification,
    ].request();
  }

  void _howItWorks(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: const [
            Text('كيف يعمل التطبيق؟',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('١) اكتشاف الأجهزة',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'يفحص التطبيق كل عناوين الشبكة الفرعية (مثل 192.168.1.1 حتى .254) '
              'ويحدد الأجهزة الحيّة، ثم يقرأ جدول ARP لمعرفة عنوان MAC لكل جهاز.',
            ),
            SizedBox(height: 12),
            Text('٢) نوع الجهاز والشركة',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'من عنوان MAC نعرف الشركة المصنّعة (OUI)، ومع اسم المضيف والمنافذ '
              'المفتوحة نخمّن نوع الجهاز (جوال، كاميرا، تلفزيون…).',
            ),
            SizedBox(height: 12),
            Text('٣) التنبيهات',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'عند تفعيل المراقبة الخلفية، يفحص التطبيق دورياً ويقارن بالأجهزة '
              'المعروفة، وينبّهك فوراً عند ظهور أي جهاز جديد.',
            ),
            SizedBox(height: 12),
            Text('٤) حدود مهمة',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.danger)),
            Text(
              '• طرد/حظر جهاز يتم عبر الراوتر فقط (لا يمكن لأي تطبيق فعلها بدونه).\n'
              '• على آيفون: قراءة عناوين MAC ومسح الشبكات المجاورة محدودة بقيود النظام.\n'
              '• على أندرويد: مسح الواي فاي يتطلّب تفعيل صلاحية الموقع.',
            ),
          ],
        ),
      ),
    );
  }
}
