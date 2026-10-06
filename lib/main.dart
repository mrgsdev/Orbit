import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

import 'data/crypto.dart';
import 'ui/lock_screen.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru');
  final root = await getApplicationSupportDirectory();
  final vault = Vault(root);
  await vault.load();
  runApp(ContactsApp(root: root, vault: vault));
}

class ContactsApp extends StatelessWidget {
  final Directory root;
  final Vault vault;

  const ContactsApp({super.key, required this.root, required this.vault});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orbit',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messengerKey,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: AppGate(root: root, vault: vault),
    );
  }
}
