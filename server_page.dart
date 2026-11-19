import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'api.dart';

class ServerPage extends StatefulWidget {
  final List<Contact> contacts;
  const ServerPage({super.key, required this.contacts});

  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  final _url = TextEditingController();
  final _key = TextEditingController();
  final _q = TextEditingController();
  ServerSettings? _s;
  List<Map<String, dynamic>> _results = [];
  String _msg = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ServerSettings.load().then((s) {
      _url.text = s.url;
      _key.text = s.key;
      setState(() => _s = s);
    });
  }

  Future<void> _run(Future<void> Function(Api api) job) async {
    final s = _s!;
    s.url = _url.text;
    s.key = _key.text;
    setState(() {
      _busy = true;
      _msg = '';
    });
    try {
      await s.save();
      await job(Api(s));
    } catch (e) {
      _msg = 'تعذّر تنفيذ الطلب: تأكد من العنوان والمفتاح والشبكة.\n$e';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _test() => _run((api) async {
        _msg = await api.health() ? 'الاتصال ناجح ✅' : 'الخادم لا يستجيب';
      });

  Future<void> _upload() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('رفع جهات الاتصال'),
        content: const Text(
            'سيتم رفع أسماء وأرقام جهات اتصالك إلى الخادم المحدد، وقد تظهر لمن يبحث عن هذه الأرقام. '
            'يمكنك حذفها لاحقًا من هنا. هل توافق؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('أوافق وأرفع')),
        ],
      ),
    );
    if (ok != true) return;
    final items = <Map<String, String>>[
      for (final c in widget.contacts)
        for (final p in c.phones)
          if (c.displayName.trim().isNotEmpty)
            {'name': c.displayName.trim(), 'number': p.number},
    ];
    await _run((api) async {
      final n = await api.sync(items);
      _msg = 'تم رفع $n رقم';
    });
  }

  Future<void> _delete() => _run((api) async {
        await api.deleteMine();
        _msg = 'تم حذف بياناتك من الخادم';
      });

  Future<void> _search() => _run((api) async {
        _results = await api.search(_q.text.trim());
        if (_results.isEmpty) _msg = 'لا توجد نتائج';
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الخادم')),
      body: _s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _url,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                      labelText: 'عنوان الخادم',
                      hintText: 'http://192.168.1.10:8000',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _key,
                  textDirection: TextDirection.ltr,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'مفتاح API', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  FilledButton(onPressed: _busy ? null : _test, child: const Text('حفظ واختبار')),
                  OutlinedButton(onPressed: _busy ? null : _upload, child: const Text('رفع جهات اتصالي')),
                  OutlinedButton(onPressed: _busy ? null : _delete, child: const Text('حذف بياناتي')),
                ]),
                if (_busy) const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
                if (_msg.isNotEmpty) Padding(padding: const EdgeInsets.all(8), child: Text(_msg)),
                const Divider(height: 32),
                TextField(
                  controller: _q,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    labelText: 'ابحث في الخادم (اسم أو رقم)',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _busy ? null : _search),
                  ),
                ),
                for (final r in _results)
                  ListTile(
                    title: Text('${r['name']}'),
                    subtitle: Text('${r['number'] ?? ''}', textDirection: TextDirection.ltr, textAlign: TextAlign.right),
                    trailing: Text('×${r['count']}'),
                  ),
              ],
            ),
    );
  }
}
