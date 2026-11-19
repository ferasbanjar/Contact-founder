import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'policies.dart';

Future<bool> hasAcceptedPolicies() async {
  final p = await SharedPreferences.getInstance();
  return p.getString('accepted_policies') == kPoliciesVersion;
}

class PolicyViewer extends StatelessWidget {
  final String title;
  final String text;
  const PolicyViewer({super.key, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(text, style: const TextStyle(height: 1.8)),
      ),
    );
  }
}

class PolicyLinks extends StatelessWidget {
  const PolicyLinks({super.key});

  Widget _tile(BuildContext c, String title, String text) => ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(title),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => Navigator.of(c).push(MaterialPageRoute(
            builder: (_) => PolicyViewer(title: title, text: text))),
      );

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _tile(context, 'الشروط والأحكام', kTermsText),
      _tile(context, 'سياسة الخصوصية', kPrivacyText),
      _tile(context, 'سياسة الاحتفاظ بالبيانات', kRetentionText),
    ]);
  }
}

/// صفحة تعرض الوثائق من داخل التطبيق (من القائمة).
class PoliciesPage extends StatelessWidget {
  const PoliciesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الشروط والسياسات')),
      body: ListView(children: const [PolicyLinks()]),
    );
  }
}

/// شاشة الموافقة الإلزامية عند أول تشغيل.
class ConsentPage extends StatefulWidget {
  final VoidCallback onAccepted;
  const ConsentPage({super.key, required this.onAccepted});

  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  bool _ok = false;

  Future<void> _accept() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('accepted_policies', kPoliciesVersion);
    widget.onAccepted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مرحبًا بك في دليلي')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                Text('قبل البدء، يرجى قراءة الوثائق التالية. لا يمكن استخدام التطبيق دون الموافقة عليها.'),
                SizedBox(height: 8),
                PolicyLinks(),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  CheckboxListTile(
                    value: _ok,
                    onChanged: (v) => setState(() => _ok = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                        'قرأت ووافقت على الشروط والأحكام وسياسة الخصوصية وسياسة الاحتفاظ بالبيانات'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                            onPressed: _ok ? _accept : null,
                            child: const Text('أوافق')),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                            onPressed: () => SystemNavigator.pop(),
                            child: const Text('لا أوافق')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
