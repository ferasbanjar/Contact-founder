import 'package:flutter/material.dart';
import 'api.dart';
import 'search_page.dart';

/// تسجيل الخروج والعودة لشاشة الدخول.
Future<void> signOut(BuildContext context) async {
  final s = await ServerSettings.load();
  await s.clearSession();
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (_) => false,
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _url = TextEditingController();
  final _phone = TextEditingController();
  final _code = TextEditingController();
  ServerSettings? _s;
  bool _sent = false;
  bool _busy = false;
  String _msg = '';

  @override
  void initState() {
    super.initState();
    ServerSettings.load().then((s) {
      _url.text = s.url;
      setState(() => _s = s);
    });
  }

  Future<void> _guard(Future<void> Function() job) async {
    setState(() {
      _busy = true;
      _msg = '';
    });
    try {
      await job();
    } on ApiError catch (e) {
      _msg = e.message;
    } catch (_) {
      _msg = 'تعذّر الاتصال بالخادم، تأكد من العنوان والشبكة.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _request() async {
    final p = normalizeSa(_phone.text);
    if (p == null) {
      setState(() => _msg = 'أدخل رقم جوال سعوديًا صحيحًا');
      return;
    }
    await _guard(() async {
      _s!.url = _url.text.trim();
      await _s!.save();
      await Api(_s!).requestOtp(p);
      _sent = true;
      _msg = 'تم إرسال رمز التحقق إلى $p';
    });
  }

  Future<void> _verify() async {
    final p = normalizeSa(_phone.text);
    if (p == null) return;
    await _guard(() async {
      final token = await Api(_s!).verifyOtp(p, _code.text.trim());
      _s!.token = token;
      _s!.phone = p;
      await _s!.save();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SearchPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول')),
      body: _s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('أدخل رقم جوالك السعودي لتصلك رسالة برمز التحقق.'),
                const SizedBox(height: 16),
                TextField(
                  controller: _phone,
                  enabled: !_sent,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                      labelText: 'رقم الجوال',
                      hintText: '05XXXXXXXX',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                if (_sent) ...[
                  TextField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                        labelText: 'رمز التحقق', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                      onPressed: _busy ? null : _verify, child: const Text('تأكيد')),
                  TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _sent = false;
                                _code.clear();
                              }),
                      child: const Text('تغيير الرقم / إعادة الإرسال')),
                ] else
                  FilledButton(
                      onPressed: _busy ? null : _request,
                      child: const Text('إرسال الرمز')),
                if (_busy)
                  const Padding(
                      padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
                if (_msg.isNotEmpty)
                  Padding(padding: const EdgeInsets.all(8), child: Text(_msg)),
                const Divider(height: 40),
                ExpansionTile(
                  title: const Text('إعدادات الخادم (للتجربة)'),
                  children: [
                    TextField(
                      controller: _url,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                          labelText: 'عنوان الخادم',
                          hintText: 'http://192.168.1.10:8000',
                          border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
