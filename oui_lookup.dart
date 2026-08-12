import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

/// خدمة معرفة الشركة المصنّعة من عنوان MAC عبر بادئة OUI.
///
/// أولاً: قاعدة محلية مجمّعة في الأصول (سريعة وبدون إنترنت).
/// ثانياً: بحث عبر الإنترنت (macvendors) كخيار احتياطي مع تخزين مؤقت.
class OuiLookup {
  OuiLookup._();
  static final OuiLookup instance = OuiLookup._();

  final Map<String, String> _local = {};
  final Map<String, String> _cache = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString('assets/oui_prefixes.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      data.forEach((k, v) {
        if (k.startsWith('_')) return;
        _local[_normalize(k)] = v as String;
      });
    } catch (_) {
      // في حال عدم توفر الأصول لا نُفشل التطبيق.
    }
    _loaded = true;
  }

  String _normalize(String mac) =>
      mac.replaceAll(RegExp('[^0-9A-Fa-f]'), '').toUpperCase();

  /// يبحث عن الشركة المصنّعة. يرجع null إذا لم توجد.
  Future<String?> vendorFor(String mac) async {
    if (mac.isEmpty) return null;
    final clean = _normalize(mac);
    if (clean.length < 6) return null;
    final prefix = clean.substring(0, 6);

    if (_cache.containsKey(prefix)) return _cache[prefix];

    await load();
    // مطابقة على أول 6 خانات (OUI القياسي).
    if (_local.containsKey(prefix)) {
      _cache[prefix] = _local[prefix]!;
      return _local[prefix];
    }
    // مطابقة جزئية لبعض المدخلات الأطول.
    for (final entry in _local.entries) {
      if (clean.startsWith(entry.key)) {
        _cache[prefix] = entry.value;
        return entry.value;
      }
    }

    // خيار احتياطي عبر الإنترنت.
    final online = await _onlineLookup(clean);
    if (online != null) _cache[prefix] = online;
    return online;
  }

  Future<String?> _onlineLookup(String mac) async {
    try {
      final formatted =
          '${mac.substring(0, 2)}:${mac.substring(2, 4)}:${mac.substring(4, 6)}';
      final res = await http
          .get(Uri.parse('https://api.macvendors.com/$formatted'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        return res.body.trim();
      }
    } catch (_) {
      // لا إنترنت أو تجاوز الحد — نتجاهل بهدوء.
    }
    return null;
  }
}
