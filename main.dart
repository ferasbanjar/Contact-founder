import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'api.dart';
import 'login_page.dart';
import 'search_page.dart';
import 'terms_page.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  ThemeData _theme(Brightness b) => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: b,
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دليلي',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const _Gate(),
    );
  }
}

/// يوجّه: الموافقة على الشروط ← تسجيل الدخول ← البحث.
class _Gate extends StatefulWidget {
  const _Gate();

  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  late Future<List<Object>> _f = _load();

  Future<List<Object>> _load() async =>
      [await hasAcceptedPolicies(), await ServerSettings.load()];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Object>>(
      future: _f,
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final accepted = snap.data![0] as bool;
        final s = snap.data![1] as ServerSettings;
        if (!accepted) {
          return ConsentPage(onAccepted: () => setState(() => _f = _load()));
        }
        return s.token.isEmpty ? const LoginPage() : const SearchPage();
      },
    );
  }
}
