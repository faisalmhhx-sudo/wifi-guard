import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/router_control.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

/// شاشة التحكم بالراوتر (حظر/طرد جهاز).
///
/// توضّح بصدق أن الطرد يتم عبر الراوتر، وتوفّر طريقتين:
/// 1) فتح صفحة إدارة الراوتر مباشرة.
/// 2) حظر تلقائي عبر بيانات الراوتر (للراوترات المدعومة مثل MikroTik).
class RouterScreen extends StatefulWidget {
  final String? targetMac;
  const RouterScreen({super.key, this.targetMac});

  @override
  State<RouterScreen> createState() => _RouterScreenState();
}

class _RouterScreenState extends State<RouterScreen> {
  String? _vendor;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final gateway = state.wifiInfo?.gateway;

    return Scaffold(
      appBar: AppBar(title: const Text('التحكم بالراوتر')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppColors.warning.withOpacity(0.1),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'طرد أو حظر جهاز من الواي فاي يتم عبر الراوتر — لا يمكن '
                      'لأي تطبيق فعلها بدون ذلك (قيود نظامي أندرويد و iOS).',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('راوترك: ${gateway ?? 'غير معروف'}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (_vendor != null) ...[
                    const SizedBox(height: 4),
                    Text('النوع: $_vendor',
                        style: const TextStyle(color: Colors.grey)),
                  ],
                  if (widget.targetMac != null &&
                      widget.targetMac!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('الجهاز المستهدف: ${widget.targetMac}',
                        style: const TextStyle(color: Colors.grey)),
                  ],
                  const SizedBox(height: 12),
                  if (gateway != null)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                _loading ? null : () => _detect(gateway),
                            icon: _loading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.search),
                            label: const Text('تعرّف على الراوتر'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed:
                gateway == null ? null : () => _openAdmin(gateway, context),
            icon: const Icon(Icons.open_in_new),
            label: const Text('فتح صفحة إدارة الراوتر'),
          ),
          const SizedBox(height: 12),
          Text(
            'الخطوات: افتح صفحة الراوتر ← ادخل باسم المستخدم وكلمة المرور ← '
            'اذهب لقائمة الأجهزة أو "تصفية MAC" ← احظر الجهاز المطلوب.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 24),
          _autoBlockSection(context, gateway),
        ],
      ),
    );
  }

  Widget _autoBlockSection(BuildContext context, String? gateway) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('الحظر التلقائي (للراوترات المدعومة)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'بعض الراوترات (مثل MikroTik وOpenWrt) تدعم الحظر مباشرة من '
              'التطبيق عبر واجهتها البرمجية. أدخل بيانات الدخول لتفعيلها.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: (gateway == null ||
                      widget.targetMac == null ||
                      widget.targetMac!.isEmpty)
                  ? null
                  : () => _autoBlockDialog(context, gateway),
              icon: const Icon(Icons.block),
              label: const Text('حظر هذا الجهاز تلقائياً'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _detect(String gateway) async {
    setState(() => _loading = true);
    final v = await RouterControl(gateway).detectVendor();
    if (mounted) {
      setState(() {
        _vendor = v;
        _loading = false;
      });
    }
  }

  Future<void> _openAdmin(String gateway, BuildContext context) async {
    final uri = Uri.parse('http://$gateway/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('افتح المتصفح على العنوان: http://$gateway')),
      );
    }
  }

  void _autoBlockDialog(BuildContext context, String gateway) {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    RouterVendor vendor = RouterVendor.mikrotik;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('بيانات الراوتر'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<RouterVendor>(
                value: vendor,
                decoration: const InputDecoration(labelText: 'نوع الراوتر'),
                items: const [
                  DropdownMenuItem(
                      value: RouterVendor.mikrotik, child: Text('MikroTik')),
                  DropdownMenuItem(
                      value: RouterVendor.openwrt, child: Text('OpenWrt')),
                  DropdownMenuItem(
                      value: RouterVendor.tplink, child: Text('TP-Link')),
                  DropdownMenuItem(
                      value: RouterVendor.generic, child: Text('أخرى')),
                ],
                onChanged: (v) => setSt(() => vendor = v!),
              ),
              TextField(
                controller: userCtrl,
                decoration:
                    const InputDecoration(labelText: 'اسم المستخدم'),
              ),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'كلمة المرور'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final res = await RouterControl(gateway).blockDeviceByMac(
                  mac: widget.targetMac!,
                  username: userCtrl.text,
                  password: passCtrl.text,
                  vendor: vendor,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res.message)),
                  );
                }
              },
              child: const Text('حظر'),
            ),
          ],
        ),
      ),
    );
  }
}
