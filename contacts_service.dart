import 'package:flutter_contacts/flutter_contacts.dart';

/// يحوّل الأرقام العربية-الهندية إلى لاتينية ويُبقي الأرقام فقط.
String digitsOnly(String s) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  final buf = StringBuffer();
  for (final ch in s.split('')) {
    final i = arabic.indexOf(ch);
    if (i >= 0) {
      buf.write(i);
    } else if (RegExp(r'[0-9]').hasMatch(ch)) {
      buf.write(ch);
    }
  }
  return buf.toString();
}

class ContactsRepo {
  Future<bool> requestPermission() =>
      FlutterContacts.requestPermission(readonly: true);

  Future<List<Contact>> loadAll() async {
    final list = await FlutterContacts.getContacts(
      withProperties: true,
      withThumbnail: true,
    );
    list.removeWhere((c) => c.displayName.trim().isEmpty && c.phones.isEmpty);
    list.sort((a, b) => a.displayName.compareTo(b.displayName));
    return list;
  }

  /// بحث بالاسم أو بجزء من الرقم (يتجاهل الصفر الأول ورمز الدولة).
  static List<Contact> search(List<Contact> all, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    var qDigits = digitsOnly(q);
    if (qDigits.startsWith('0')) qDigits = qDigits.substring(1);
    return all.where((c) {
      if (c.displayName.toLowerCase().contains(q)) return true;
      if (qDigits.isEmpty) return false;
      return c.phones.any((p) => digitsOnly(p.number).contains(qDigits));
    }).toList();
  }

  static String letter(Contact c) {
    final n = c.displayName.trim();
    if (n.isEmpty) return '#';
    final ch = n[0].toUpperCase();
    return RegExp(r'\p{L}', unicode: true).hasMatch(ch) ? ch : '#';
  }
}
