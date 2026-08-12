import 'dart:convert';
import 'package:http/http.dart' as http;

/// نتيجة عملية على الراوتر.
class RouterResult {
  final bool success;
  final String message;
  RouterResult(this.success, this.message);
}

/// التحكم بالراوتر (حظر/طرد جهاز) عبر واجهة الراوتر.
///
/// مهم جداً: لا يمكن لأي تطبيق جوال طرد جهاز من الواي فاي بدون المرور
/// على الراوتر. هذه الخدمة تتكامل مع صفحة إدارة الراوتر (HTTP) أو عبر
/// بروتوكولات مثل TR-069 / UPnP-IGD حسب طراز الراوتر.
///
/// نظراً لاختلاف كل راوتر، هذا الملف يوفّر:
/// 1) فتح صفحة إدارة الراوتر للمستخدم.
/// 2) هيكل جاهز لتسجيل الدخول وإرسال أمر الحظر (يُخصّص حسب الطراز).
/// 3) اكتشاف نوع الراوتر من عنوان البوابة.
class RouterControl {
  final String gatewayIp;
  RouterControl(this.gatewayIp);

  /// رابط صفحة إدارة الراوتر (يفتحه المستخدم في المتصفح).
  Uri get adminUrl => Uri.parse('http://$gatewayIp/');

  /// محاولة التعرّف على نوع الراوتر من ترويسات الصفحة.
  Future<String> detectVendor() async {
    try {
      final res = await http
          .get(adminUrl)
          .timeout(const Duration(seconds: 5));
      final server = res.headers['server'] ?? '';
      final body = res.body.toLowerCase();
      if (body.contains('tp-link') || server.contains('tp-link')) {
        return 'TP-Link';
      }
      if (body.contains('huawei')) return 'Huawei';
      if (body.contains('mikrotik')) return 'MikroTik';
      if (body.contains('asus')) return 'ASUS';
      if (body.contains('netgear')) return 'Netgear';
      if (body.contains('unifi') || body.contains('ubiquiti')) {
        return 'Ubiquiti';
      }
      if (server.isNotEmpty) return server;
      return 'راوتر غير معروف';
    } catch (_) {
      return 'تعذّر الوصول للراوتر';
    }
  }

  /// قالب عام لحظر جهاز عبر عنوان MAC.
  ///
  /// هذا يتطلّب تخصيصاً حسب طراز الراوتر (نقطة تسجيل الدخول ومسار الأمر).
  /// أمثلة الطرق الشائعة:
  /// - TP-Link: تسجيل دخول ثم POST إلى /cgi?... مع قائمة MAC filtering.
  /// - MikroTik: REST API على /rest/interface/wireless/access-list.
  /// - OpenWrt: LuCI RPC (ubus) call.
  ///
  /// نُرجع رسالة إرشادية حتى يُدخل المطوّر/المستخدم بيانات راوتره.
  Future<RouterResult> blockDeviceByMac({
    required String mac,
    String? username,
    String? password,
    RouterVendor vendor = RouterVendor.generic,
  }) async {
    switch (vendor) {
      case RouterVendor.mikrotik:
        return _blockMikroTik(mac, username, password);
      case RouterVendor.openwrt:
      case RouterVendor.tplink:
      case RouterVendor.generic:
        return RouterResult(
          false,
          'حظر MAC ($mac) يحتاج تسجيل دخول لراوترك. افتح صفحة إدارة الراوتر '
          'من التطبيق، أو أدخل بيانات الدخول في الإعدادات لتفعيل الحظر التلقائي.',
        );
    }
  }

  /// مثال فعلي: MikroTik عبر REST API (RouterOS 7+).
  Future<RouterResult> _blockMikroTik(
    String mac,
    String? user,
    String? pass,
  ) async {
    if (user == null || pass == null) {
      return RouterResult(false, 'أدخل اسم المستخدم وكلمة المرور للراوتر.');
    }
    try {
      final uri = Uri.parse(
          'http://$gatewayIp/rest/interface/wireless/access-list');
      final auth =
          'Basic ${base64.encode(utf8.encode('$user:$pass'))}';
      final res = await http.put(
        uri,
        headers: {
          'Authorization': auth,
          'Content-Type': 'application/json',
        },
        body: '{"mac-address":"$mac","authentication":"no","forwarding":"no"}',
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return RouterResult(true, 'تم حظر الجهاز $mac بنجاح.');
      }
      return RouterResult(false, 'فشل الحظر (رمز ${res.statusCode}).');
    } catch (e) {
      return RouterResult(false, 'تعذّر الاتصال بالراوتر: $e');
    }
  }
}

enum RouterVendor { generic, tplink, mikrotik, openwrt }
