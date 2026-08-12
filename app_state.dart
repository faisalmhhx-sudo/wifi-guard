import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/network_device.dart';
import '../models/wifi_network.dart';
import '../services/monitor_service.dart';
import '../services/network_scanner.dart';
import '../services/notifications_service.dart';
import '../services/storage_service.dart';
import '../services/wifi_info_service.dart';

/// الحالة المركزية للتطبيق (Provider / ChangeNotifier).
class AppState extends ChangeNotifier {
  final _scanner = NetworkScanner();
  final _wifi = WifiInfoService();
  final _storage = StorageService();
  final _monitor = MonitorService();

  final List<NetworkDevice> _devices = [];
  List<AlertEvent> _alerts = [];
  CurrentWifiInfo? _wifiInfo;
  List<WifiAccessPoint> _accessPoints = [];

  bool _scanning = false;
  ScanProgress? _progress;
  String? _error;
  bool _monitorEnabled = false;
  int _scanIntervalMin = 15;

  StreamSubscription<ScanEvent>? _sub;

  // Getters
  List<NetworkDevice> get devices => List.unmodifiable(_devices);
  List<AlertEvent> get alerts => List.unmodifiable(_alerts);
  CurrentWifiInfo? get wifiInfo => _wifiInfo;
  List<WifiAccessPoint> get accessPoints => List.unmodifiable(_accessPoints);
  bool get scanning => _scanning;
  ScanProgress? get progress => _progress;
  String? get error => _error;
  bool get monitorEnabled => _monitorEnabled;
  int get scanIntervalMin => _scanIntervalMin;

  int get onlineCount => _devices.where((d) => d.isOnline).length;
  int get trustedCount => _devices.where((d) => d.isTrusted).length;
  int get unknownCount =>
      _devices.where((d) => !d.isTrusted && !d.isThisDevice).length;

  /// تهيئة عند بدء التطبيق.
  Future<void> init() async {
    await NotificationsService.instance.init();
    await _monitor.initWorkmanager();
    _monitorEnabled = await _storage.monitorEnabled();
    _scanIntervalMin = await _storage.scanIntervalMinutes();
    _alerts = await _storage.loadAlerts();
    final known = await _storage.loadKnownDevices();
    _devices
      ..clear()
      ..addAll(known.map((d) => d..isOnline = false));
    await refreshWifiInfo();
    notifyListeners();
  }

  Future<void> refreshWifiInfo() async {
    _wifiInfo = await _wifi.current();
    notifyListeners();
  }

  /// مسح الشبكة (تفاعلي مع تحديث التقدّم).
  Future<void> startScan() async {
    if (_scanning) return;
    _scanning = true;
    _error = null;
    _progress = null;
    // نضع كل الأجهزة "غير متصلة" ثم نحدّث المكتشفة.
    for (final d in _devices) {
      d.isOnline = false;
    }
    notifyListeners();

    await refreshWifiInfo();
    final known = await _storage.loadKnownDevices();
    final knownByKey = {for (final d in known) d.key: d};
    final newlyDiscovered = <NetworkDevice>[];

    _sub = _scanner.scan().listen((event) async {
      switch (event.type) {
        case ScanEventType.progress:
          _progress = event.progress;
          notifyListeners();
          break;
        case ScanEventType.device:
          final dev = event.device!;
          final prev = knownByKey[dev.key];
          if (prev != null) {
            dev.customName = prev.customName;
            dev.isTrusted = prev.isTrusted;
            dev.isBlocked = prev.isBlocked;
            dev.firstSeen = prev.firstSeen;
          } else if (!dev.isThisDevice) {
            newlyDiscovered.add(dev);
          }
          _upsert(dev);
          notifyListeners();
          break;
        case ScanEventType.done:
          await _finishScan(event.devices ?? [], newlyDiscovered);
          break;
        case ScanEventType.error:
          _error = event.message;
          _scanning = false;
          notifyListeners();
          break;
      }
    });
  }

  Future<void> _finishScan(
    List<NetworkDevice> all,
    List<NetworkDevice> newlyDiscovered,
  ) async {
    _scanning = false;
    _progress = null;

    // تنبيه على الأجهزة الجديدة.
    for (final dev in newlyDiscovered) {
      final detail =
          '${dev.type.arabicLabel} • ${dev.vendor ?? 'شركة غير معروفة'} • ${dev.ip}';
      await NotificationsService.instance
          .showNewDevice(dev.displayName, detail);
      final alert = AlertEvent(
        title: 'دخل جهاز جديد على الشبكة',
        body: '${dev.displayName} — $detail',
        deviceKey: dev.key,
        severity: AlertSeverity.critical,
      );
      await _storage.addAlert(alert);
      _alerts.insert(0, alert);
    }

    // حفظ الأجهزة (دمج).
    final merged = <String, NetworkDevice>{};
    for (final d in _devices) {
      merged[d.key] = d;
    }
    await _storage.saveKnownDevices(merged.values.toList());
    notifyListeners();
  }

  void _upsert(NetworkDevice dev) {
    final i = _devices.indexWhere((d) => d.key == dev.key);
    if (i >= 0) {
      _devices[i] = dev;
    } else {
      _devices.add(dev);
    }
    _devices.sort((a, b) {
      // البوابة أولاً، ثم جهازي، ثم بقية الأجهزة حسب IP.
      if (a.isGateway != b.isGateway) return a.isGateway ? -1 : 1;
      if (a.isThisDevice != b.isThisDevice) return a.isThisDevice ? -1 : 1;
      return _ipNum(a.ip).compareTo(_ipNum(b.ip));
    });
  }

  int _ipNum(String ip) {
    final p = ip.split('.');
    if (p.length != 4) return 0;
    return (int.tryParse(p[3]) ?? 0);
  }

  Future<void> cancelScan() async {
    await _sub?.cancel();
    _scanning = false;
    _progress = null;
    notifyListeners();
  }

  /// مسح نقاط الوصول المجاورة (لشاشة تحليل الواي فاي).
  Future<void> scanAccessPoints() async {
    _accessPoints = await _wifi.scanAccessPoints();
    notifyListeners();
  }

  // إجراءات على الأجهزة.
  Future<void> renameDevice(NetworkDevice dev, String name) async {
    dev.customName = name;
    await _persist();
    notifyListeners();
  }

  Future<void> setTrusted(NetworkDevice dev, bool trusted) async {
    dev.isTrusted = trusted;
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await _storage.saveKnownDevices(_devices);
  }

  // المراقبة الخلفية.
  Future<void> setMonitor(bool enabled) async {
    _monitorEnabled = enabled;
    await _monitor.setEnabled(enabled, intervalMinutes: _scanIntervalMin);
    notifyListeners();
  }

  Future<void> setScanInterval(int minutes) async {
    _scanIntervalMin = minutes;
    await _storage.setScanIntervalMinutes(minutes);
    if (_monitorEnabled) {
      await _monitor.setEnabled(true, intervalMinutes: minutes);
    }
    notifyListeners();
  }

  Future<void> clearAlerts() async {
    await _storage.clearAlerts();
    _alerts = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
