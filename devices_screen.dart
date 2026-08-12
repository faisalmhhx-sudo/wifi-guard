import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../widgets/device_tile.dart';
import 'device_detail_screen.dart';

/// شاشة قائمة كل الأجهزة المكتشفة على الشبكة.
class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    var devices = state.devices;

    if (_filter == 'online') {
      devices = devices.where((d) => d.isOnline).toList();
    } else if (_filter == 'trusted') {
      devices = devices.where((d) => d.isTrusted).toList();
    } else if (_filter == 'unknown') {
      devices = devices
          .where((d) => !d.isTrusted && !d.isThisDevice && !d.isGateway)
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('الأجهزة (${state.devices.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: state.scanning ? null : () => state.startScan(),
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _chip('all', 'الكل'),
                _chip('online', 'المتصلة'),
                _chip('trusted', 'الموثوقة'),
                _chip('unknown', 'غير الموثوقة'),
              ],
            ),
          ),
          Expanded(
            child: devices.isEmpty
                ? _emptyState(context, state)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: devices.length,
                    itemBuilder: (_, i) => DeviceTile(
                      device: devices[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DeviceDetailScreen(device: devices[i]),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String value, String label) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  Widget _emptyState(BuildContext context, AppState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_find,
                size: 72, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'لا توجد أجهزة بعد',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'اضغط "فحص الشبكة" لاكتشاف الأجهزة المتصلة بالواي فاي.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: state.scanning ? null : () => state.startScan(),
              icon: const Icon(Icons.radar),
              label: const Text('فحص الشبكة'),
            ),
          ],
        ),
      ),
    );
  }
}
