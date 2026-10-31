// Configuration générale de l'application ARZIKI.
//
// Toutes les valeurs viennent des options de compilation (--dart-define),
// jamais d'une clé écrite en dur dans le code.
//
// Exemples :
//   flutter run --dart-define=APP_MODE=demo
//   flutter run -d chrome --dart-define=CIBLE=mobile   (tester l'app mobile dans le navigateur)
//   flutter run --dart-define=APP_MODE=prod --dart-define=USE_EMULATORS=true

import 'package:flutter/foundation.dart' show kIsWeb;

/// Mode de fonctionnement : démonstration (données fictives) ou production.
enum ModeApp { demo, prod }

/// Ce que l'on affiche : l'application mobile (tous les rôles clients)
/// ou la console d'administration web (admins uniquement).
enum CibleApp { mobile, console }

class AppConfig {
  AppConfig._();

  static const String _mode = String.fromEnvironment('APP_MODE', defaultValue: 'demo');
  static const String _cible = String.fromEnvironment('CIBLE', defaultValue: '');

  /// Mode actuel. Par défaut : démonstration, tant que les vraies clés ne sont pas fournies.
  static ModeApp get mode => _mode == 'prod' ? ModeApp.prod : ModeApp.demo;

  static bool get estDemo => mode == ModeApp.demo;

  /// Sur le web, l'application est la console d'administration,
  /// sauf si l'on force CIBLE=mobile (pratique pour faire une démonstration sans téléphone).
  static CibleApp get cible {
    if (_cible == 'mobile') return CibleApp.mobile;
    if (_cible == 'console') return CibleApp.console;
    return kIsWeb ? CibleApp.console : CibleApp.mobile;
  }

  static bool get estConsole => cible == CibleApp.console;

  /// Brancher l'application sur les émulateurs Firebase locaux.
  static const bool utiliserEmulateurs = bool.fromEnvironment('USE_EMULATORS');

  /// Adresse de la machine qui fait tourner les émulateurs.
  /// Sur l'émulateur Android, la machine hôte s'appelle 10.0.2.2.
  static const String hoteEmulateurs =
      String.fromEnvironment('EMULATOR_HOST', defaultValue: 'localhost');

  /// Code SMS simulé en mode démonstration (CLAUDE.md, section 17).
  static const String codeSmsDemo = '123456';

  /// Déconnexion automatique des admins après 15 minutes d'inactivité.
  static const Duration inactiviteMaxAdmin = Duration(minutes: 15);
}
