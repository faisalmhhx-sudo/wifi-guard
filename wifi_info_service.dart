import 'package:network_info_plus/network_info_plus.dart';
import 'package:wifi_scan/wifi_scan.dart';
import '../models/wifi_network.dart';

/// خدمة معلومات الواي فاي الحالي ومسح الشبكات المجاورة.
class WifiInfoService {
  final NetworkInfo _info = NetworkInfo();

  /// معلومات الشبكة المتصل بها حالياً (SSID، IP، البوابة، الشبكة الفرعية).
  Future<CurrentWifiInfo> current() async {
    String? clean(String? v) {
      if (v == null) return null;
      // بعض الأجهزة تُرجع SSID محاطاً بعلامتي اقتباس.
      return v.replaceAll('"', '');
    }

    final ssid = clean(await _info.getWifiName());
    final bssid = await _info.getWifiBSSID();
    final ip = await _info.getWifiIP();
    final gateway = await _info.getWifiGatewayIP();
    final subnet = await _info.getWifiSubmask();
    final broadcast = await _info.getWifiBroadcast();

    return CurrentWifiInfo(
      ssid: ssid,
      bssid: bssid,
      ip: ip,
      gateway: gateway,
      subnet: subnet,
      broadcast: broadcast,
    );
  }

  /// يستخرج بادئة الشبكة الفرعية مثل "192.168.1" من عنوان IP.
  static String? subnetPrefix(String? ip) {
    if (ip == null) return null;
    final parts = ip.split('.');
    if (parts.length != 4) return null;
    return '${parts[0]}.${parts[1]}.${parts[2]}';
  }

  /// مسح نقاط الوصول المجاورة (يعمل على أندرويد؛ محدود على iOS).
  Future<List<WifiAccessPoint>> scanAccessPoints() async {
    try {
      final can = await WiFiScan.instance.canStartScan();
      if (can != CanStartScan.yes) return [];
      await WiFiScan.instance.startScan();
      final results = await WiFiScan.instance.getScannedResults();
      return results
          .map((r) => WifiAccessPoint(
                ssid: r.ssid,
                bssid: r.bssid,
                level: r.level,
                frequency: r.frequency,
                capabilities: r.capabilities,
              ))
          .toList()
        ..sort((a, b) => b.level.compareTo(a.level));
    } catch (_) {
      return [];
    }
  }
}
