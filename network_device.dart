import 'dart:convert';

/// نوع الجهاز المكتشَف (يُستخدم لاختيار الأيقونة والتصنيف).
enum DeviceType {
  router,
  phone,
  laptop,
  desktop,
  tablet,
  tv,
  camera,
  printer,
  gameConsole,
  smartHome,
  wearable,
  unknown,
}

extension DeviceTypeX on DeviceType {
  String get arabicLabel {
    switch (this) {
      case DeviceType.router:
        return 'راوتر / بوابة';
      case DeviceType.phone:
        return 'جوال';
      case DeviceType.laptop:
        return 'لابتوب';
      case DeviceType.desktop:
        return 'كمبيوتر مكتبي';
      case DeviceType.tablet:
        return 'تابلت';
      case DeviceType.tv:
        return 'تلفزيون / شاشة';
      case DeviceType.camera:
        return 'كاميرا مراقبة';
      case DeviceType.printer:
        return 'طابعة';
      case DeviceType.gameConsole:
        return 'جهاز ألعاب';
      case DeviceType.smartHome:
        return 'جهاز منزل ذكي';
      case DeviceType.wearable:
        return 'جهاز يُلبس (ساعة)';
      case DeviceType.unknown:
        return 'غير معروف';
    }
  }

  String get iconAsset {
    // أسماء أيقونات Material يتم تحويلها في الواجهة.
    switch (this) {
      case DeviceType.router:
        return 'router';
      case DeviceType.phone:
        return 'smartphone';
      case DeviceType.laptop:
        return 'laptop';
      case DeviceType.desktop:
        return 'desktop_windows';
      case DeviceType.tablet:
        return 'tablet';
      case DeviceType.tv:
        return 'tv';
      case DeviceType.camera:
        return 'videocam';
      case DeviceType.printer:
        return 'print';
      case DeviceType.gameConsole:
        return 'sports_esports';
      case DeviceType.smartHome:
        return 'home';
      case DeviceType.wearable:
        return 'watch';
      case DeviceType.unknown:
        return 'device_unknown';
    }
  }
}

/// يمثّل جهازاً واحداً مكتشفاً على الشبكة المحلية.
class NetworkDevice {
  final String ip;
  String mac; // قد تكون فارغة على iOS لقيود النظام (تُحدَّث بعد قراءة ARP)
  String? hostname;
  String? vendor; // الشركة المصنّعة (من OUI)
  String? customName; // اسم يضعه المستخدم
  DeviceType type;
  bool isOnline;
  bool isGateway;
  bool isThisDevice; // جهاز المستخدم نفسه
  bool isTrusted; // موثوق (لا ينبّه)
  bool isBlocked; // محظور (عبر الراوتر)
  DateTime firstSeen;
  DateTime lastSeen;
  List<int> openPorts;
  int? signalHint; // تلميح لقوة الاتصال إن توفر

  NetworkDevice({
    required this.ip,
    this.mac = '',
    this.hostname,
    this.vendor,
    this.customName,
    this.type = DeviceType.unknown,
    this.isOnline = true,
    this.isGateway = false,
    this.isThisDevice = false,
    this.isTrusted = false,
    this.isBlocked = false,
    DateTime? firstSeen,
    DateTime? lastSeen,
    List<int>? openPorts,
    this.signalHint,
  })  : firstSeen = firstSeen ?? DateTime.now(),
        lastSeen = lastSeen ?? DateTime.now(),
        openPorts = openPorts ?? [];

  /// الاسم المعروض: الاسم المخصّص ثم hostname ثم الشركة ثم IP.
  String get displayName {
    if (customName != null && customName!.trim().isNotEmpty) {
      return customName!;
    }
    if (hostname != null && hostname!.trim().isNotEmpty) return hostname!;
    if (vendor != null && vendor!.trim().isNotEmpty) return vendor!;
    return ip;
  }

  /// مفتاح فريد للجهاز: MAC إن وُجد، وإلا IP.
  String get key => mac.isNotEmpty ? mac.toUpperCase() : ip;

  Map<String, dynamic> toJson() => {
        'ip': ip,
        'mac': mac,
        'hostname': hostname,
        'vendor': vendor,
        'customName': customName,
        'type': type.name,
        'isTrusted': isTrusted,
        'isBlocked': isBlocked,
        'firstSeen': firstSeen.toIso8601String(),
        'lastSeen': lastSeen.toIso8601String(),
        'openPorts': openPorts,
      };

  factory NetworkDevice.fromJson(Map<String, dynamic> j) => NetworkDevice(
        ip: j['ip'] as String,
        mac: (j['mac'] ?? '') as String,
        hostname: j['hostname'] as String?,
        vendor: j['vendor'] as String?,
        customName: j['customName'] as String?,
        type: DeviceType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => DeviceType.unknown,
        ),
        isTrusted: (j['isTrusted'] ?? false) as bool,
        isBlocked: (j['isBlocked'] ?? false) as bool,
        firstSeen: DateTime.tryParse(j['firstSeen'] ?? '') ?? DateTime.now(),
        lastSeen: DateTime.tryParse(j['lastSeen'] ?? '') ?? DateTime.now(),
        openPorts: (j['openPorts'] as List?)?.cast<int>() ?? [],
      );

  static String encodeList(List<NetworkDevice> list) =>
      jsonEncode(list.map((d) => d.toJson()).toList());

  static List<NetworkDevice> decodeList(String raw) {
    final data = jsonDecode(raw) as List;
    return data
        .map((e) => NetworkDevice.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
