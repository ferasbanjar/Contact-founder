import 'package:flutter/material.dart';
import 'api.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'server_page.dart';
import 'terms_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _ctrl = TextEditingController();
  List<String>? _names;
  bool _busy = false;
  String _msg = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final n = normalizeSa(_ctrl.text);
    if (n == null) {
      setState(() => _msg = 'أدخل رقم جوال سعوديًا صحيحًا');
      return;
    }
    setState(() {
      _busy = true;
      _msg = '';
      _names = null;
    });
    try {
      final s = await ServerSettings.load();
      final names = await Api(s).lookup(n);
      if (mounted) setState(() => _names = names);
    } on ApiError catch (e) {
      if (e.status == 401) {
        if (mounted) await signOut(context);
        return;
      }
      if (mounted) setState(() => _msg = e.message);
    } catch (_) {
      if (mounted) setState(() => _msg = 'تعذّر الاتصال بالخادم');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _menu(String v) {
    switch (v) {
      case 'contacts':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HomePage()));
      case 'account':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ServerPage()));
      case 'policies':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PoliciesPage()));
      case 'logout':
        signOut(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دليلي'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _menu,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'contacts', child: Text('جهات اتصالي')),
              PopupMenuItem(value: 'account', child: Text('الحساب والمزامنة')),
              PopupMenuItem(value: 'policies', child: Text('الشروط والسياسات')),
              PopupMenuItem(value: 'logout', child: Text('تسجيل الخروج')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 24),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            onSubmitted: (_) => _search(),
            decoration: const InputDecoration(
                labelText: 'رقم الجوال',
                hintText: '05XXXXXXXX',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _search,
            icon: const Icon(Icons.search),
            label: const Text('بحث'),
          ),
          if (_busy)
            const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
          if (_msg.isNotEmpty) Padding(padding: const EdgeInsets.all(12), child: Text(_msg)),
          if (_names != null) ...[
            const SizedBox(height: 16),
            if (_names!.isEmpty)
              const Center(child: Text('لا توجد نتائج لهذا الرقم'))
            else
              for (final n in _names!)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(n),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
