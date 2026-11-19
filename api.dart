import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'contacts_service.dart';

/// يحوّل أي صيغة سعودية (05..، 5..، +966..، 00966..) إلى +966XXXXXXXXX أو null.
String? normalizeSa(String input) {
  var d = digitsOnly(input);
  if (d.startsWith('00966')) {
    d = d.substring(5);
  } else if (d.startsWith('966')) {
    d = d.substring(3);
  } else if (d.startsWith('0')) {
    d = d.substring(1);
  }
  return RegExp(r'^[1-9]\d{8}$').hasMatch(d) ? '+966$d' : null;
}

class ServerSettings {
  String url;
  String token;
  String phone;
  ServerSettings({this.url = '', this.token = '', this.phone = ''});

  static Future<ServerSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return ServerSettings(
      url: p.getString('url') ?? '',
      token: p.getString('token') ?? '',
      phone: p.getString('phone') ?? '',
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('url', url);
    await p.setString('token', token);
    await p.setString('phone', phone);
  }

  Future<void> clearSession() async {
    token = '';
    phone = '';
    await save();
  }
}

class ApiError implements Exception {
  final String message;
  final int status;
  ApiError(this.message, [this.status = 0]);
  @override
  String toString() => message;
}

class Api {
  final ServerSettings s;
  Api(this.s);

  Uri _u(String path, [Map<String, String>? q]) {
    final base = s.url.trim().replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base$path').replace(queryParameters: q);
  }

  Map<String, String> get _h => {
        'Content-Type': 'application/json; charset=utf-8',
        if (s.token.isNotEmpty) 'Authorization': 'Bearer ${s.token}',
      };

  Future<dynamic> _send(Future<http.Response> req,
      [Duration t = const Duration(seconds: 15)]) async {
    final r = await req.timeout(t);
    final body = r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
    if (r.statusCode != 200) {
      final d = (body is Map && body['detail'] is String)
          ? body['detail'] as String
          : 'خطأ من الخادم (${r.statusCode})';
      throw ApiError(d, r.statusCode);
    }
    return body;
  }

  Future<void> requestOtp(String phone) => _send(http.post(
      _u('/v1/auth/request'),
      headers: _h,
      body: jsonEncode({'phone': phone})));

  Future<String> verifyOtp(String phone, String code) async {
    final b = await _send(http.post(_u('/v1/auth/verify'),
        headers: _h, body: jsonEncode({'phone': phone, 'code': code})));
    return b['token'] as String;
  }

  /// يرجع اسمين كحد أقصى (الحد يفرضه الخادم أيضًا).
  Future<List<String>> lookup(String number) async {
    final b = await _send(http.get(_u('/v1/lookup', {'number': number}), headers: _h));
    return (b['names'] as List).map((e) => e['name'] as String).toList();
  }

  Future<int> sync(List<Map<String, String>> contacts) async {
    var total = 0;
    for (var i = 0; i < contacts.length; i += 500) {
      final batch = contacts.sublist(i, min(i + 500, contacts.length));
      final b = await _send(
          http.post(_u('/v1/contacts/sync'),
              headers: _h, body: jsonEncode({'consent': true, 'contacts': batch})),
          const Duration(seconds: 40));
      total += b['saved'] as int;
    }
    return total;
  }

  Future<void> deleteAccount() => _send(http.delete(_u('/v1/me'), headers: _h));
}
