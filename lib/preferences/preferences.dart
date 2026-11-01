// Préférences de l'utilisateur (Paramètres) : apparence, notifications, sécurité.
// Elles s'appliquent immédiatement à toute l'application.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TypeNotification {
  compte('Mon compte', 'Validation, pièces demandées'),
  operations('Opérations', 'Nouvelles opérations, changements d\'étape, retards'),
  versements('Versements', 'Confirmations de versement et de partage'),
  services('Services', 'Devis, livrables, formations'),
  rapports('Rapports', 'Rapport mensuel, cotisation à renouveler');

  const TypeNotification(this.libelle, this.detail);
  final String libelle;
  final String detail;
}

class Preferences {
  const Preferences({
    this.modeTheme = ThemeMode.light,
    this.tailleTexte = 1.0,
    this.notifications = const {
      TypeNotification.compte: true,
      TypeNotification.operations: true,
      TypeNotification.versements: true,
      TypeNotification.services: true,
      TypeNotification.rapports: true,
    },
    this.codePin,
    this.empreinte = false,
    this.langue = 'fr',
  });

  final ThemeMode modeTheme;

  /// Facteur de taille du texte : 1.0 (normal), 1.15 (grand), 1.3 (très grand).
  final double tailleTexte;
  final Map<TypeNotification, bool> notifications;

  /// Code PIN à 4 chiffres (démonstration : gardé en mémoire ; en production,
  /// stocké de façon chiffrée dans le coffre-fort du téléphone).
  final String? codePin;
  final bool empreinte;
  final String langue;

  Preferences copier({
    ThemeMode? modeTheme,
    double? tailleTexte,
    Map<TypeNotification, bool>? notifications,
    String? codePin,
    bool effacerPin = false,
    bool? empreinte,
  }) =>
      Preferences(
        modeTheme: modeTheme ?? this.modeTheme,
        tailleTexte: tailleTexte ?? this.tailleTexte,
        notifications: notifications ?? this.notifications,
        codePin: effacerPin ? null : (codePin ?? this.codePin),
        empreinte: empreinte ?? this.empreinte,
        langue: langue,
      );
}

class ControleurPreferences extends Notifier<Preferences> {
  @override
  Preferences build() => const Preferences();

  void modeSombre(bool actif) => state = state.copier(modeTheme: actif ? ThemeMode.dark : ThemeMode.light);
  void tailleTexte(double f) => state = state.copier(tailleTexte: f);
  void notification(TypeNotification t, bool actif) =>
      state = state.copier(notifications: {...state.notifications, t: actif});
  void definirPin(String pin) => state = state.copier(codePin: pin);
  void retirerPin() => state = state.copier(effacerPin: true, empreinte: false);
  void empreinte(bool actif) => state = state.copier(empreinte: actif);
}

final preferencesProvider = NotifierProvider<ControleurPreferences, Preferences>(ControleurPreferences.new);
