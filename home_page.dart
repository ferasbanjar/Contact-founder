import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'contacts_service.dart';
import 'detail_page.dart';

enum _Status { loading, denied, ready }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _repo = ContactsRepo();
  final _ctrl = TextEditingController();
  List<Contact> _all = [];
  List<Contact> _shown = [];
  _Status _status = _Status.loading;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _status = _Status.loading);
    if (!await _repo.requestPermission()) {
      setState(() => _status = _Status.denied);
      return;
    }
    final list = await _repo.loadAll();
    setState(() {
      _all = list;
      _shown = ContactsRepo.search(list, _ctrl.text);
      _status = _Status.ready;
    });
  }

  void _onSearch(String q) =>
      setState(() => _shown = ContactsRepo.search(_all, q));

  List<Object> _items() {
    if (_ctrl.text.trim().isNotEmpty) return List<Object>.from(_shown);
    final out = <Object>[];
    String? last;
    for (final c in _shown) {
      final l = ContactsRepo.letter(c);
      if (l != last) {
        out.add(l);
        last = l;
      }
      out.add(c);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('دليلي'),
        actions: [
          if (_status == _Status.ready)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text('${_shown.length} / ${_all.length}',
                    style: Theme.of(context).textTheme.labelLarge),
              ),
            ),
        ],
      ),
      body: switch (_status) {
        _Status.loading => const Center(child: CircularProgressIndicator()),
        _Status.denied => _Denied(onRetry: _load),
        _Status.ready => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SearchBar(
                  controller: _ctrl,
                  hintText: 'ابحث بالاسم أو الرقم',
                  leading: const Icon(Icons.search),
                  trailing: [
                    if (_ctrl.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _ctrl.clear();
                          _onSearch('');
                        },
                      ),
                  ],
                  onChanged: _onSearch,
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: _shown.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 120),
                          Center(child: Text('لا توجد نتائج')),
                        ])
                      : ListView.builder(
                          itemCount: _items().length,
                          itemBuilder: (_, i) {
                            final item = _items()[i];
                            if (item is String) {
                              return Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 14, 20, 4),
                                child: Text(item,
                                    style: TextStyle(
                                        color: cs.primary,
                                        fontWeight: FontWeight.bold)),
                              );
                            }
                            final c = item as Contact;
                            final phone =
                                c.phones.isNotEmpty ? c.phones.first.number : '';
                            return ListTile(
                              leading: ContactAvatar(contact: c),
                              title: Text(c.displayName.isEmpty
                                  ? 'بدون اسم'
                                  : c.displayName),
                              subtitle: Text(phone,
                                  textDirection: TextDirection.ltr,
                                  textAlign: TextAlign.right),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => DetailPage(contact: c)),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
      },
    );
  }
}

class _Denied extends StatelessWidget {
  final VoidCallback onRetry;
  const _Denied({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.contacts_outlined, size: 72),
            const SizedBox(height: 16),
            const Text(
              'نحتاج إذن الوصول إلى جهات الاتصال للبحث فيها.\nبياناتك تبقى على جهازك ولا تُرسل لأي جهة.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('السماح')),
            const SizedBox(height: 8),
            const Text('إن رُفض الطلب، فعّل الإذن من إعدادات الهاتف.',
                style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
