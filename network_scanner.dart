import 'dart:async';
import 'dart:io';
import 'package:dart_ping/dart_ping.dart';

import '../models/network_device.dart';
import 'device_classifier.dart';
import 'oui_lookup.dart';
import 'wifi_info_service.dart';

/// حالة تقدّم المسح لعرضها في الواجهة.
class ScanProgress {
  final int scanned;
  final int total;
  final int found;
  ScanProgress(this.scanned, this.total, this.found);
  double get fraction => total == 0 ? 0 : scanned / total;
}

/// الماسح الأساسي للشبكة المحلية.
///
/// الخطوات:
/// 1) تحديد الشبكة الفرعية من IP الجهاز.
/// 2) مسح العناوين 1..254 بالـ ping (بتزامن محدود).
/// 3) قراءة جدول ARP (على أندرويد) لربط IP بعنوان MAC.
/// 4) عكس DNS لمعرفة اسم المضيف.
/// 5) فحص سريع لأشهر المنافذ لتحسين تصنيف نوع الجهاز.
/// 6) معرفة الشركة المصنّعة من OUI وتصنيف النوع.
class NetworkScanner {
  final WifiInfoService _wifi = WifiInfoService();

  static const List<int> _commonPorts = [
    22, 80, 443, 554, 631, 3389, 8009, 8080, 9100, 62078,
  ];

  /// يُجري مسحاً كاملاً ويُرجع تدفّقاً بالأجهزة المكتشفة والتقدّم.
  Stream<ScanEvent> scan({int concurrency = 40}) async* {
    final info = await _wifi.current();
    final prefix = WifiInfoService.subnetPrefix(info.ip);
    if (prefix == null) {
      yield ScanEvent.error('تعذّر تحديد الشبكة. تأكّد من الاتصال بالواي فاي.');
      return;
    }

    final myIp = info.ip;
    final gatewayIp = info.gateway;
    final targets = [for (var i = 1; i <= 254; i++) '$prefix.$i'];
    final found = <String, NetworkDevice>{};
    var scanned = 0;

    final controller = StreamController<ScanEvent>();
    var active = 0;
    var index = 0;

    // فحص عنوان واحد وتحديث التقدّم.
    Future<void> runOne(String ip) async {
      final alive = await _isAlive(ip);
      scanned++;
      if (alive) {
        found[ip] = NetworkDevice(
          ip: ip,
          isGateway: ip == gatewayIp,
          isThisDevice: ip == myIp,
        );
      }
      controller.add(ScanEvent.progress(
          ScanProgress(scanned, targets.length, found.length)));
    }

    // مُنفّذ بتزامن محدود.
    Future<void> pump() async {
      final futures = <Future>[];
      while (index < targets.length || active > 0) {
        while (active < concurrency && index < targets.length) {
          final ip = targets[index++];
          active++;
          final f = runOne(ip).whenComplete(() => active--);
          futures.add(f);
        }
        await Future.delayed(const Duration(milliseconds: 15));
      }
      await Future.wait(futures);
      await _enrich(found, controller);
      controller.add(ScanEvent.done(found.values.toList()));
      await controller.close();
    }

    unawaited(pump());
    yield* controller.stream;
  }

  /// إثراء الأجهزة: MAC من ARP، hostname، المنافذ، الشركة، والنوع.
  Future<void> _enrich(
    Map<String, NetworkDevice> found,
    StreamController<ScanEvent> controller,
  ) async {
    final arp = await _readArpTable();

    for (final dev in found.values) {
      // MAC من جدول ARP.
      final mac = arp[dev.ip];
      if (mac != null && mac.isNotEmpty && mac != '00:00:00:00:00:00') {
        dev.mac = mac;
        dev.vendor = await OuiLookup.instance.vendorFor(mac);
      }

      // اسم المضيف عبر عكس DNS.
      dev.hostname = await _reverseDns(dev.ip);

      // فحص سريع لأشهر المنافذ.
      dev.openPorts = await _scanPorts(dev.ip);

      // تصنيف النوع.
      dev.type = DeviceClassifier.classify(dev);

      controller.add(ScanEvent.device(dev));
    }
  }

  /// فحص هل العنوان حيّ عبر ping واحد سريع.
  Future<bool> _isAlive(String ip) async {
    try {
      final ping = Ping(ip, count: 1, timeout: 1, interval: 1);
      await for (final r in ping.stream) {
        if (r.response != null && r.error == null) return true;
        if (r.error != null) return false;
      }
    } catch (_) {}
    // احتياطي: محاولة اتصال TCP سريع على منفذ شائع.
    return _tcpProbe(ip);
  }

  Future<bool> _tcpProbe(String ip) async {
    for (final port in [80, 443, 22, 62078]) {
      try {
        final s = await Socket.connect(ip, port,
            timeout: const Duration(milliseconds: 350));
        s.destroy();
        return true;
      } catch (_) {}
    }
    return false;
  }

  /// قراءة جدول ARP لنظام أندرويد/لينكس من /proc/net/arp.
  /// على iOS هذا غير متاح (قيود النظام) فيرجع فارغاً.
  Future<Map<String, String>> _readArpTable() async {
    final map = <String, String>{};
    try {
      final file = File('/proc/net/arp');
      if (!await file.exists()) return map;
      final lines = await file.readAsLines();
      for (var i = 1; i < lines.length; i++) {
        final parts =
            lines[i].split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
        if (parts.length >= 4) {
          final ip = parts[0];
          final mac = parts[3];
          if (mac != '00:00:00:00:00:00') {
            map[ip] = mac.toUpperCase();
          }
        }
      }
    } catch (_) {}
    return map;
  }

  Future<String?> _reverseDns(String ip) async {
    try {
      final rev = await InternetAddress(ip)
          .reverse()
          .timeout(const Duration(seconds: 1));
      final host = rev.host;
      if (host.isNotEmpty && host != ip) return host;
    } catch (_) {}
    return null;
  }

  Future<List<int>> _scanPorts(String ip) async {
    final open = <int>[];
    await Future.wait(_commonPorts.map((port) async {
      try {
        final s = await Socket.connect(ip, port,
            timeout: const Duration(milliseconds: 300));
        s.destroy();
        open.add(port);
      } catch (_) {}
    }));
    open.sort();
    return open;
  }
}

/// أحداث المسح المتدفّقة.
class ScanEvent {
  final ScanEventType type;
  final ScanProgress? progress;
  final NetworkDevice? device;
  final List<NetworkDevice>? devices;
  final String? message;

  ScanEvent._(this.type,
      {this.progress, this.device, this.devices, this.message});

  factory ScanEvent.progress(ScanProgress p) =>
      ScanEvent._(ScanEventType.progress, progress: p);
  factory ScanEvent.device(NetworkDevice d) =>
      ScanEvent._(ScanEventType.device, device: d);
  factory ScanEvent.done(List<NetworkDevice> list) =>
      ScanEvent._(ScanEventType.done, devices: list);
  factory ScanEvent.error(String m) =>
      ScanEvent._(ScanEventType.error, message: m);
}

enum ScanEventType { progress, device, done, error }
