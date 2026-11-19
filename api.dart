import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ServerSettings {
  String url;
  String key;
  final String ownerId;
  ServerSettings({this.url = '', this.key = '', required this.ownerId});

  static Future<ServerSettings> load() async {
    final p = await SharedPreferences.getInstance();
    var owner = p.getString('owner');
    if (owner == null) {
      final r = Random.secure();
      owner = List.generate(
          16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      await p.setString('owner', owner);
    }
    return ServerSettings(
      url: p.getString('url') ?? '',
      key: p.getString('key') ?? '',
      ownerId: owner,
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('url', url);
    await p.setString('key', key);
  }
}

class Api {
  final ServerSettings s;
  Api(this.s);

  static const _timeout = Duration(seconds: 15);

  Uri _u(String path, [Map<String, String>? q]) {
    final base = s.url.trim().replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base$path').replace(queryParameters: q);
  }

  Map<String, String> get _h => {
        'Content-Type': 'application/json; charset=utf-8',
        'X-API-Key': s.key.trim(),
      };

  Future<bool> health() async {
    final r = await http.get(_u('/health')).timeout(_timeout);
    return r.statusCode == 200;
  }

  Future<List<Map<String, dynamic>>> search(String q) async {
    final r = await http.get(_u('/v1/search', {'q': q}), headers: _h).timeout(_timeout);
    if (r.statusCode != 200) throw Exception('خطأ من الخادم (${r.statusCode})');
    return (jsonDecode(utf8.decode(r.bodyBytes)) as List).cast<Map<String, dynamic>>();
  }

  Future<int> sync(List<Map<String, String>> contacts) async {
    var total = 0;
    for (var i = 0; i < contacts.length; i += 500) {
      final batch = contacts.sublist(i, min(i + 500, contacts.length));
      final r = await http
          .post(_u('/v1/contacts/sync'),
              headers: _h,
              body: jsonEncode({'owner': s.ownerId, 'consent': true, 'contacts': batch}))
          .timeout(const Duration(seconds: 40));
      if (r.statusCode != 200) throw Exception('فشل الرفع (${r.statusCode})');
      total += (jsonDecode(r.body)['saved'] as int);
    }
    return total;
  }

  Future<void> deleteMine() async {
    final r = await http.delete(_u('/v1/me', {'owner': s.ownerId}), headers: _h).timeout(_timeout);
    if (r.statusCode != 200) throw Exception('فشل الحذف (${r.statusCode})');
  }
}
