// Point d'entrée de l'application ARZIKI.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/session.dart';
import 'config/app_config.dart';
import 'config/firebase_bootstrap.dart';
import 'preferences/preferences.dart';
import 'router/app_router.dart';
import 'theme/arziki_theme.dart';
import 'ui/composants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await demarrerFirebase();
  runApp(const ProviderScope(child: ArzikiApp()));
}

class ArzikiApp extends ConsumerStatefulWidget {
  const ArzikiApp({super.key});

  @override
  ConsumerState<ArzikiApp> createState() => _ArzikiAppState();
}

class _ArzikiAppState extends ConsumerState<ArzikiApp> {
  Timer? _surveillance;

  @override
  void initState() {
    super.initState();
    // Vérifie chaque minute l'inactivité des administrateurs.
    _surveillance = Timer.periodic(const Duration(minutes: 1), (_) {
      ref.read(sessionProvider.notifier).verifierInactivite();
    });
  }

  @override
  void dispose() {
    _surveillance?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(preferencesProvider);
    return Listener(
      onPointerDown: (_) => ref.read(sessionProvider.notifier).activite(),
      child: MaterialApp.router(
        title: AppConfig.estConsole ? 'ARZIKI · Console' : 'ARZIKI',
        debugShowCheckedModeBanner: false,
        theme: ArzikiTheme.clair,
        darkTheme: ArzikiTheme.sombre,
        themeMode: preferences.modeTheme,
        routerConfig: ref.watch(routeurProvider),
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        // Taille du texte choisie dans les paramètres, ajoutée à celle du téléphone.
        builder: (context, enfant) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              (MediaQuery.textScalerOf(context).scale(16) / 16 * preferences.tailleTexte).clamp(1.0, 1.6),
            ),
          ),
          child: BandeauDemo(child: enfant ?? const SizedBox()),
        ),
      ),
    );
  }
}
