// Navigation de l'application (go_router), avec garde de rôle sur chaque route.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/depot_auth.dart';
import '../auth/session.dart';
import '../config/app_config.dart';
import '../ecrans/admin/console.dart';
import '../ecrans/auth/ecrans_auth.dart';
import '../ecrans/compte/ecrans_compte.dart';
import '../ecrans/entree/ecrans_entree.dart';
import '../ecrans/espaces/espaces.dart';
import 'garde_roles.dart';

final routeurProvider = Provider<GoRouter>((ref) {
  // Prévient le routeur à chaque changement de session, sans le recréer.
  final changement = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => changement.value++);
  ref.onDispose(changement.dispose);

  return GoRouter(
    initialLocation: Chemins.demarrage,
    refreshListenable: changement,
    redirect: (context, etat) =>
        redirection(ref.read(sessionProvider), etat.matchedLocation, AppConfig.cible),
    routes: [
      GoRoute(path: Chemins.demarrage, builder: (_, _) => const EcranDemarrage()),
      GoRoute(path: Chemins.presentation, builder: (_, _) => const EcranPresentation()),
      GoRoute(path: Chemins.choix, builder: (_, _) => const EcranChoix()),
      GoRoute(path: Chemins.invitation, builder: (_, _) => const EcranInvitation()),
      GoRoute(
        path: Chemins.inscription,
        builder: (_, etat) {
          final q = etat.uri.queryParameters;
          return EcranInscription(
            parcours: Parcours.depuisCode(q['parcours']) ?? Parcours.entreprise,
            codeInvitation: q['code'],
            telephone: q['tel'],
            nomInvite: q['nom'],
          );
        },
      ),
      GoRoute(path: Chemins.connexion, builder: (_, _) => const EcranConnexion()),
      GoRoute(path: Chemins.connexionAdmin, builder: (_, _) => const EcranConnexionAdmin()),
      GoRoute(path: Chemins.doubleFacteur, builder: (_, _) => const EcranDoubleFacteur()),
      GoRoute(path: Chemins.enAttente, builder: (_, _) => const EcranEnAttente()),
      GoRoute(path: Chemins.identite, builder: (_, _) => const EcranIdentite()),
      GoRoute(path: Chemins.candidature, builder: (_, _) => const EcranCandidature()),
      GoRoute(path: Chemins.suspendu, builder: (_, _) => const EcranSuspendu()),
      GoRoute(path: Chemins.accesRefuse, builder: (_, _) => const EcranAccesRefuse()),
      GoRoute(path: Chemins.entreprise, builder: (_, _) => const EspaceEntreprise()),
      GoRoute(path: Chemins.cercle, builder: (_, _) => const EspaceCercle()),
      GoRoute(path: Chemins.fournisseur, builder: (_, _) => const EspaceFournisseur()),
      GoRoute(path: Chemins.notaire, builder: (_, _) => const EspaceNotaire()),
      GoRoute(path: Chemins.admin, builder: (_, _) => const TableauDeBordAdmin()),
      GoRoute(path: Chemins.adminComptes, builder: (_, _) => const PageComptes()),
      GoRoute(path: Chemins.adminInvitations, builder: (_, _) => const PageInvitations()),
      GoRoute(path: Chemins.adminCandidatures, builder: (_, _) => const PageCandidatures()),
      GoRoute(path: Chemins.adminEquipe, builder: (_, _) => const PageEquipe()),
      GoRoute(path: Chemins.adminJournal, builder: (_, _) => const PageJournal()),
    ],
  );
});
