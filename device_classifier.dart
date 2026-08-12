import '../models/network_device.dart';

/// يحاول تخمين نوع الجهاز اعتماداً على:
/// - الشركة المصنّعة (vendor)
/// - اسم المضيف (hostname)
/// - المنافذ المفتوحة (openPorts)
/// - كونه البوابة (gateway)
///
/// هذا تقريب ذكي (Heuristic) مشابه لفكرة Device Intelligence في Fing،
/// لكن بدون قاعدة بياناتهم الضخمة. كل ما زادت الإشارات دقّ التصنيف.
class DeviceClassifier {
  static DeviceType classify(NetworkDevice d) {
    if (d.isGateway) return DeviceType.router;

    final vendor = (d.vendor ?? '').toLowerCase();
    final host = (d.hostname ?? '').toLowerCase();
    final text = '$vendor $host';
    final ports = d.openPorts;

    // مطابقات نصية على الشركة/الاسم.
    bool has(List<String> keys) => keys.any((k) => text.contains(k));

    if (has(['iphone', 'ipad', 'ipod'])) {
      return host.contains('ipad') ? DeviceType.tablet : DeviceType.phone;
    }
    if (has(['galaxy', 'pixel', 'oneplus', 'huawei-phone', 'redmi', 'poco'])) {
      return DeviceType.phone;
    }
    if (has(['macbook', 'thinkpad', 'laptop', 'notebook'])) {
      return DeviceType.laptop;
    }
    if (has(['imac', 'desktop', 'pc-'])) return DeviceType.desktop;
    if (has(['playstation', 'ps4', 'ps5', 'xbox', 'nintendo', 'switch'])) {
      return DeviceType.gameConsole;
    }
    if (has(['tv', 'bravia', 'lg-', 'samsungtv', 'chromecast', 'appletv',
        'roku', 'firetv', 'shield'])) {
      return DeviceType.tv;
    }
    if (has(['hikvision', 'dahua', 'camera', 'cam-', 'ipcam', 'reolink',
        'wyze', 'nest-cam'])) {
      return DeviceType.camera;
    }
    if (has(['printer', 'hp-', 'canon', 'epson', 'brother'])) {
      return DeviceType.printer;
    }
    if (has(['echo', 'alexa', 'google-home', 'nest', 'philips', 'hue',
        'tuya', 'sonoff', 'shelly', 'smartthings'])) {
      return DeviceType.smartHome;
    }
    if (has(['watch', 'band', 'fitbit', 'garmin'])) {
      return DeviceType.wearable;
    }
    if (has(['apple'])) {
      // Apple بدون تفصيل — نرجّح جوال.
      return DeviceType.phone;
    }
    if (has(['samsung', 'xiaomi', 'oppo', 'vivo', 'realme'])) {
      return DeviceType.phone;
    }

    // مطابقة على المنافذ المفتوحة.
    if (ports.contains(631) || ports.contains(9100)) return DeviceType.printer;
    if (ports.contains(554) || ports.contains(8554)) return DeviceType.camera;
    if (ports.contains(8009) || ports.contains(7000)) return DeviceType.tv;
    if (ports.contains(3389)) return DeviceType.desktop;

    return DeviceType.unknown;
  }
}
