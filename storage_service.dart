import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/network_device.dart';

/// حدث تنبيه محفوظ (دخول جهاز جديد، عودة جهاز، إلخ).
class AlertEvent {
  final String title;
  final String body;
  final String deviceKey;
  final DateTime time;
  final AlertSeverity severity;

  AlertEvent({
    required this.title,
    required this.body,
    required this.deviceKey,
    required this.severity,
    DateTime? time,
  }) : time = time ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'deviceKey': deviceKey,
        'time': time.toIso8601String(),
        'severity': severity.name,
      };

  factory AlertEvent.fromJson(Map<String, dynamic> j) => AlertEvent(
        title: j['title'],
        body: j['body'],
        deviceKey: j['deviceKey'] ?? '',
        time: DateTime.tryParse(j['time'] ?? ''),
        severity: AlertSeverity.values.firstWhere(
          (s) => s.name == j['severity'],
          orElse: () => AlertSeverity.info,
        ),
      );
}

enum AlertSeverity { info, warning, critical }

/// تخزين الأجهزة المعروفة، سجل التنبيهات، والإعدادات.
class StorageService {
  static const _kKnownDevices = 'known_devices';
  static const _kAlerts = 'alerts_log';
  static const _kMonitorEnabled = 'monitor_enabled';
  static const _kScanInterval = 'scan_interval_min';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<NetworkDevice>> loadKnownDevices() async {
    final p = await _prefs;
    final raw = p.getString(_kKnownDevices);
    if (raw == null) return [];
    try {
      return NetworkDevice.decodeList(raw);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveKnownDevices(List<NetworkDevice> devices) async {
    final p = await _prefs;
    await p.setString(_kKnownDevices, NetworkDevice.encodeList(devices));
  }

  Future<List<AlertEvent>> loadAlerts() async {
    final p = await _prefs;
    final raw = p.getString(_kAlerts);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => AlertEvent.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addAlert(AlertEvent event) async {
    final p = await _prefs;
    final alerts = await loadAlerts();
    alerts.insert(0, event);
    // نحتفظ بآخر 200 حدث.
    final trimmed = alerts.take(200).toList();
    await p.setString(
      _kAlerts,
      jsonEncode(trimmed.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clearAlerts() async {
    final p = await _prefs;
    await p.remove(_kAlerts);
  }

  Future<bool> monitorEnabled() async =>
      (await _prefs).getBool(_kMonitorEnabled) ?? false;

  Future<void> setMonitorEnabled(bool v) async =>
      (await _prefs).setBool(_kMonitorEnabled, v);

  Future<int> scanIntervalMinutes() async =>
      (await _prefs).getInt(_kScanInterval) ?? 15;

  Future<void> setScanIntervalMinutes(int v) async =>
      (await _prefs).setInt(_kScanInterval, v);
}
