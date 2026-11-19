import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'api.dart';
import 'contacts_service.dart';
import 'login_page.dart';

/// شاشة الحساب والمزامنة.
class ServerPage extends StatefulWidget {
  final List<Contact> contacts;
  const ServerPage({super.key, this.contacts = const []});

  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  final _url = TextEditingController();
  ServerSettings? _s;
  String _msg = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ServerSettings.load().then((s) {
      _url.text = s.url;
      setState(() => _s = s);
    });
  }

  Future<void> _guard(Future<void> Function(Api api) job) async {
    final s = _s!;
    setState(() {
      _busy = true;
      _msg = '';
    });
    try {
      s.url = _url.text.trim();
      await s.save();
      await job(Api(s));
    } on ApiError catch (e) {
      _msg = e.message;
      if (e.status == 401 && mounted) {
        await signOut(context);
        return;
      }
    } catch (_) {
      _msg = 'تعذّر الاتصال بالخادم، تأكد من العنوان والشبكة.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title, String text, String yes) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(yes)),
        ],
      ),
    );
    return r == true;
  }

  Future<void> _upload() async {
    final ok = await _confirm(
      'رفع جهات الاتصال',
      'سيتم رفع أسماء وأرقام جهات اتصالك السعودية إلى الخادم، وقد يظهر الاسم لمن يبحث عن الرقم. '
          'يمكنك حذف بياناتك لاحقًا من هذه الشاشة. هل توافق؟',
      'أوافق وأرفع',
    );
    if (!ok) return;
    await _guard((api) async {
      var list = widget.contacts;
      if (list.isEmpty) {
        final repo = ContactsRepo();
        if (!await repo.requestPermission()) {
          _msg = 'لم يُمنح إذن جهات الاتصال';
          return;
        }
        list = await repo.loadAll();
      }
      final items = <Map<String, String>>[
        for (final c in list)
          for (final p in c.phones)
            if (c.displayName.trim().isNotEmpty)
              {'name': c.displayName.trim(), 'number': p.number},
      ];
      final n = await api.sync(items);
      _msg = 'تم رفع $n رقم سعودي';
    });
  }

  Future<void> _delete() async {
    final ok = await _confirm(
      'حذف الحساب',
      'سيتم حذف حسابك وجهات الاتصال التي رفعتها وسجل بحثك من الخادم. لا يمكن التراجع.',
      'احذف',
    );
    if (!ok) return;
    await _guard((api) async {
      await api.deleteAccount();
      await _s!.clearSession();
      if (!mounted) return;
      await signOut(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الحساب والمزامنة')),
      body: _s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  leading: const Icon(Icons.phone_android),
                  title: Text(_s!.phone, textDirection: TextDirection.ltr, textAlign: TextAlign.right),
                  subtitle: const Text('الحساب الحالي'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _url,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                      labelText: 'عنوان الخادم', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: _busy ? null : _upload, child: const Text('رفع جهات اتصالي')),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: _busy ? null : () => signOut(context), child: const Text('تسجيل الخروج')),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy ? null : _delete,
                  style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                  child: const Text('حذف حسابي وبياناتي'),
                ),
                if (_busy) const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
                if (_msg.isNotEmpty) Padding(padding: const EdgeInsets.all(8), child: Text(_msg)),
              ],
            ),
    );
  }
}
