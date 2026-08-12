import 'package:flutter/material.dart';
import '../../models/network_device.dart';
import '../../theme/app_theme.dart';
import 'device_icon.dart';

/// عنصر عرض جهاز في القائمة.
class DeviceTile extends StatelessWidget {
  final NetworkDevice device;
  final VoidCallback? onTap;

  const DeviceTile({super.key, required this.device, this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = device.isOnline ? AppColors.accent : Colors.grey;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
      child: ListTile(
        onTap: onTap,
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: Icon(deviceIcon(device.type), color: AppColors.primary),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).cardColor,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                device.displayName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (device.isThisDevice) _badge('جهازك', AppColors.primary),
            if (device.isGateway) _badge('راوتر', AppColors.warning),
            if (device.isTrusted) _badge('موثوق', AppColors.accent),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text('${device.type.arabicLabel} • ${device.ip}'),
            if (device.vendor != null)
              Text(
                device.vendor!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_left),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.bold),
        ),
      );
}
