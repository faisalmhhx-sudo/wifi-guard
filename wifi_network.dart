/// معلومات نقطة وصول واي فاي (من مسح الشبكات المجاورة).
class WifiAccessPoint {
  final String ssid;
  final String bssid;
  final int level; // قوة الإشارة dBm (مثلاً -55)
  final int frequency; // بالميغاهيرتز
  final String capabilities; // نوع التشفير WPA2/WPA3...

  WifiAccessPoint({
    required this.ssid,
    required this.bssid,
    required this.level,
    required this.frequency,
    required this.capabilities,
  });

  /// رقم القناة المحسوب من التردد.
  int get channel {
    if (frequency >= 2412 && frequency <= 2484) {
      if (frequency == 2484) return 14;
      return ((frequency - 2412) ~/ 5) + 1;
    }
    if (frequency >= 5000 && frequency <= 5900) {
      return ((frequency - 5000) ~/ 5);
    }
    if (frequency >= 5955) {
      // نطاق 6 غيغاهيرتز (Wi-Fi 6E)
      return ((frequency - 5955) ~/ 5) + 1;
    }
    return 0;
  }

  String get band {
    if (frequency < 2500) return '2.4 GHz';
    if (frequency < 5925) return '5 GHz';
    return '6 GHz';
  }

  /// جودة الإشارة كنسبة مئوية تقريبية من الـ dBm.
  int get signalPercent {
    if (level <= -100) return 0;
    if (level >= -50) return 100;
    return 2 * (level + 100);
  }

  String get security {
    final c = capabilities.toUpperCase();
    if (c.contains('WPA3')) return 'WPA3';
    if (c.contains('WPA2')) return 'WPA2';
    if (c.contains('WPA')) return 'WPA';
    if (c.contains('WEP')) return 'WEP (ضعيف)';
    if (c.contains('OWE')) return 'مفتوحة (مشفّرة)';
    return 'مفتوحة (غير آمنة)';
  }
}

/// معلومات الشبكة الحالية المتصل بها.
class CurrentWifiInfo {
  final String? ssid;
  final String? bssid;
  final String? ip;
  final String? gateway;
  final String? subnet;
  final String? broadcast;

  CurrentWifiInfo({
    this.ssid,
    this.bssid,
    this.ip,
    this.gateway,
    this.subnet,
    this.broadcast,
  });
}
