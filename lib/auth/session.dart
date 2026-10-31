// État de la session (qui est connecté) et fournisseurs Riverpod partagés.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../comptes/depot_comptes.dart';
import '../config/app_config.dart';
import '../core/roles.dart';
import '../demo/base_demo.dart';
import '../demo/depot_auth_demo.dart';
import '../demo/depot_comptes_demo.dart';
import '../models/utilisateur.dart';
import 'depot_auth.dart';

/// Base fictive utilisée en mode démonstration.
final baseDemoProvider = Provider<BaseDemo>((ref) => BaseDemo());

final depotComptesProvider = Provider<DepotComptes>((ref) {
  if (AppConfig.estDemo) return DepotComptesDemo(ref.watch(baseDemoProvider));
  // Le branchement Firebase arrive dès que le projet Firebase est fourni
  // (CLAUDE.md, section 18, point 1).
  throw StateError('Mode production : projet Firebase non configuré.');
});

final depotAuthProvider = Provider<DepotAuth>((ref) {
  if (AppConfig.estDemo) {
    return DepotAuthDemo(ref.watch(baseDemoProvider), ref.watch(depotComptesProvider) as DepotComptesDemo);
  }
  throw StateError('Mode production : projet Firebase non configuré.');
});

class EtatSession {
  const EtatSession({this.utilisateur, this.presentationVue = false});

  final Utilisateur? utilisateur;

  /// Les 3 écrans de présentation ont été vus.
  final bool presentationVue;

  bool get estConnecte => utilisateur != null;
  Role? get role => utilisateur?.role;

  EtatSession avec({Utilisateur? utilisateur, bool? presentationVue, bool deconnecte = false}) {
    return EtatSession(
      utilisateur: deconnecte ? null : (utilisateur ?? this.utilisateur),
      presentationVue: presentationVue ?? this.presentationVue,
    );
  }
}

class ControleurSession extends Notifier<EtatSession> {
  DateTime _derniereActivite = DateTime.now();

  @override
  EtatSession build() => const EtatSession();

  void presentationTerminee() => state = state.avec(presentationVue: true);

  void connecter(Utilisateur u) {
    _derniereActivite = DateTime.now();
    state = state.avec(utilisateur: u, presentationVue: true);
  }

  /// Relit le profil (après une validation par un administrateur, par exemple).
  void rafraichir() {
    final u = state.utilisateur;
    if (u == null || !AppConfig.estDemo) return;
    final frais = ref.read(baseDemoProvider).utilisateurs[u.uid];
    if (frais != null) state = state.avec(utilisateur: frais);
  }

  Future<void> deconnecter() async {
    await ref.read(depotAuthProvider).deconnecter();
    state = state.avec(deconnecte: true);
  }

  /// À appeler à chaque interaction de l'utilisateur.
  void activite() => _derniereActivite = DateTime.now();

  /// Déconnexion automatique des admins après 15 minutes sans activité.
  Future<bool> verifierInactivite() async {
    final role = state.role;
    if (role == null || !role.estAdministration) return false;
    if (DateTime.now().difference(_derniereActivite) > AppConfig.inactiviteMaxAdmin) {
      await deconnecter();
      return true;
    }
    return false;
  }
}

final sessionProvider = NotifierProvider<ControleurSession, EtatSession>(ControleurSession.new);
