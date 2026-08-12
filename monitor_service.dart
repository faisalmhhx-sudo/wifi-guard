import 'dart:async';
import 'package:workmanager/workmanager.dart';

import '../models/network_device.dart';
import 'network_scanner.dart';
import 'notifications_service.dart';
import 'storage_service.dart';

const String kScanTaskName = 'wifi_guard_periodic_scan';

/// نقطة دخول المهام الخلفية (يجب أن تكون دالة عليا top-level).
@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == kScanTaskName) {
      await MonitorService().runScanAndAlert();
    }
    return true;
  });
}

/// خدمة المراقبة الدورية في الخلفية:
/// تمسح الشبكة، تقارن بالأجهزة المعروفة، وتنبّه عند أي دخول جديد.
class MonitorService {
  final _scanner = NetworkScanner();
  final _storage = StorageService();

  Future<void> initWorkmanager() async {
    await Workmanager().initialize(
      backgroundCallbackDispatcher,
      isInDebugMode: false,
    );
  }

  /// تفعيل/إيقاف المراقبة الدورية.
  Future<void> setEnabled(bool enabled, {int intervalMinutes = 15}) async {
    await _storage.setMonitorEnabled(enabled);
    if (enabled) {
      // الحد الأدنى لدورية Workmanager على أندرويد هو 15 دقيقة.
      final minutes = intervalMinutes < 15 ? 15 : intervalMinutes;
      await Workmanager().registerPeriodicTask(
        kScanTaskName,
        kScanTaskName,
        frequency: Duration(minutes: minutes),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
    } else {
      await Workmanager().cancelByUniqueName(kScanTaskName);
    }
  }

  /// المسح الفعلي في الخلفية والمقارنة والتنبيه.
  Future<List<NetworkDevice>> runScanAndAlert() async {
    final known = await _storage.loadKnownDevices();
    final knownKeys = known.map((d) => d.key).toSet();

    final result = <NetworkDevice>[];
    final completer = Completer<List<NetworkDevice>>();

    final sub = _scanner.scan().listen((event) {
      if (event.type == ScanEventType.done) {
        completer.complete(event.devices ?? []);
      } else if (event.type == ScanEventType.error) {
        if (!completer.isCompleted) completer.complete([]);
      }
    });

    final devices = await completer.future;
    await sub.cancel();
    result.addAll(devices);

    // كشف الأجهزة الجديدة.
    final knownByKey = {for (final d in known) d.key: d};
    for (final dev in devices) {
      final existing = knownByKey[dev.key];
      if (existing == null) {
        // جهاز جديد كلياً.
        if (!dev.isThisDevice) {
          await _notifyNew(dev);
        }
      } else {
        // تحديث آخر ظهور والحفاظ على الإعدادات السابقة.
        dev.customName = existing.customName;
        dev.isTrusted = existing.isTrusted;
        dev.isBlocked = existing.isBlocked;
        dev.firstSeen = existing.firstSeen;
      }
    }

    // دمج القائمة المعروفة مع المكتشفة حديثاً.
    final merged = <String, NetworkDevice>{};
    for (final d in known) {
      merged[d.key] = d;
    }
    for (final d in devices) {
      merged[d.key] = d;
    }
    await _storage.saveKnownDevices(merged.values.toList());

    return result;
  }

  Future<void> _notifyNew(NetworkDevice dev) async {
    final detail =
        '${dev.type.arabicLabel} • ${dev.vendor ?? 'شركة غير معروفة'} • ${dev.ip}';
    await NotificationsService.instance.showNewDevice(dev.displayName, detail);
    await _storage.addAlert(AlertEvent(
      title: 'دخل جهاز جديد على الشبكة',
      body: '${dev.displayName} — $detail',
      deviceKey: dev.key,
      severity: AlertSeverity.critical,
    ));
  }
}
