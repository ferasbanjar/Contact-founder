import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'contacts_service.dart';

class ContactAvatar extends StatelessWidget {
  final Contact contact;
  final double radius;
  const ContactAvatar({super.key, required this.contact, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final thumb = contact.thumbnail;
    if (thumb != null && thumb.isNotEmpty) {
      return CircleAvatar(radius: radius, backgroundImage: MemoryImage(thumb));
    }
    final name = contact.displayName.trim();
    return CircleAvatar(
      radius: radius,
      child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
          style: TextStyle(fontSize: radius * 0.8)),
    );
  }
}

class DetailPage extends StatelessWidget {
  final Contact contact;
  const DetailPage({super.key, required this.contact});

  Future<void> _open(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) _snack(context, 'تعذّر فتح التطبيق');
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          Center(child: ContactAvatar(contact: contact, radius: 48)),
          const SizedBox(height: 12),
          Center(
            child: Text(
              contact.displayName.isEmpty ? 'بدون اسم' : contact.displayName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 16),
          for (final p in contact.phones)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.number,
                      textDirection: TextDirection.ltr,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.call, size: 18),
                          label: const Text('اتصال'),
                          onPressed: () => _open(
                              context, Uri(scheme: 'tel', path: p.number)),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.sms, size: 18),
                          label: const Text('رسالة'),
                          onPressed: () => _open(
                              context, Uri(scheme: 'sms', path: p.number)),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.chat, size: 18),
                          label: const Text('واتساب'),
                          onPressed: () => _open(
                              context,
                              Uri.parse(
                                  'https://wa.me/${digitsOnly(p.number)}')),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.copy, size: 18),
                          label: const Text('نسخ'),
                          onPressed: () async {
                            await Clipboard.setData(
                                ClipboardData(text: p.number));
                            if (context.mounted) {
                              _snack(context, 'تم نسخ الرقم');
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (contact.phones.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('لا توجد أرقام لهذه الجهة')),
            ),
        ],
      ),
    );
  }
}
