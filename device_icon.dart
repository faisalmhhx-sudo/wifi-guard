import 'package:flutter/material.dart';
import '../../models/network_device.dart';

/// يحوّل نوع الجهاز إلى أيقونة Material مناسبة.
IconData deviceIcon(DeviceType type) {
  switch (type) {
    case DeviceType.router:
      return Icons.router;
    case DeviceType.phone:
      return Icons.smartphone;
    case DeviceType.laptop:
      return Icons.laptop_mac;
    case DeviceType.desktop:
      return Icons.desktop_windows;
    case DeviceType.tablet:
      return Icons.tablet_mac;
    case DeviceType.tv:
      return Icons.tv;
    case DeviceType.camera:
      return Icons.videocam;
    case DeviceType.printer:
      return Icons.print;
    case DeviceType.gameConsole:
      return Icons.sports_esports;
    case DeviceType.smartHome:
      return Icons.home;
    case DeviceType.wearable:
      return Icons.watch;
    case DeviceType.unknown:
      return Icons.device_unknown;
  }
}
