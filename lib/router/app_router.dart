// Navigation de l'application (go_router), avec garde de rôle sur chaque route.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/depot_auth.dart';
import '../auth/session.dart';
import '../config/app_config.dart';
import '../ecrans/admin/console.dart';
import '../ecrans/admin/console_contenus_services.dart';
import '../ecrans/auth/ecrans_auth.dart';
import '../ecrans/compte/ecrans_compte.dart';
import '../ecrans/entree/ecrans_entree.dart';
import '../ecrans/espaces/espaces.dart';
import '../ecrans/espaces/operations_ecrans.dart';
import '../ecrans/profil/profil.dart';
import '../ecrans/public/pages_publiques.dart';
import '../ecrans/services/ecrans_services.dart';
import 'garde_roles.dart';

final routeurProvider = Provider<GoRouter>((ref) {
  // Prévient le routeur à chaque changement de session, sans le recréer.
  final changement = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => changement.value++);
  ref.onDispose(changement.dispose);

  return GoRouter(
    initialLocation: Chemins.demarrage,
    refreshListenable: changement,
    redirect: (context, etat) => redirection(ref.read(sessionProvider), etat.matchedLocation, AppConfig.cible),
    routes: [
      // Entrée
      GoRoute(path: Chemins.demarrage, builder: (_, _) => const EcranDemarrage()),
      GoRoute(path: Chemins.presentation, builder: (_, _) => const EcranPresentation()),
      GoRoute(path: Chemins.choix, builder: (_, _) => const EcranChoix()),
      GoRoute(path: Chemins.decouvrir, builder: (_, _) => const EcranDecouvrir()),
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

      // Compte
      GoRoute(path: Chemins.enAttente, builder: (_, _) => const EcranEnAttente()),
      GoRoute(path: Chemins.identite, builder: (_, _) => const EcranIdentite()),
      GoRoute(path: Chemins.candidature, builder: (_, _) => const EcranCandidature()),
      GoRoute(path: Chemins.suspendu, builder: (_, _) => const EcranSuspendu()),
      GoRoute(path: Chemins.accesRefuse, builder: (_, _) => const EcranAccesRefuse()),
      GoRoute(path: Chemins.notifications, builder: (_, _) => const EcranNotifications()),
      GoRoute(path: Chemins.profil, builder: (_, _) => const EcranProfil()),
      GoRoute(path: Chemins.parametres, builder: (_, _) => const EcranParametres()),
      GoRoute(path: Chemins.documents, builder: (_, _) => const EcranDocuments()),

      // Pages d'information
      GoRoute(path: Chemins.faq, builder: (_, _) => const EcranFaq()),
      GoRoute(path: '${Chemins.infos}/:id', builder: (_, etat) => PageInfo(id: etat.pathParameters['id']!)),

      // Services
      GoRoute(path: Chemins.services, builder: (_, _) => const CatalogueServices()),
      GoRoute(path: Chemins.formations, builder: (_, _) => const EcranFormations()),
      GoRoute(path: '/services/offre/:id', builder: (_, etat) => FicheOffre(id: etat.pathParameters['id']!)),
      GoRoute(path: '/services/offre/:id/commander', builder: (_, etat) => CommanderOffre(id: etat.pathParameters['id']!)),
      GoRoute(path: '/services/commande/:id', builder: (_, etat) => SuiviCommande(id: etat.pathParameters['id']!)),

      // Espaces
      GoRoute(path: Chemins.entreprise, builder: (_, _) => const EspaceEntreprise()),
      GoRoute(
        path: Chemins.nouvelleDemande,
        builder: (_, etat) {
          final depuis = etat.uri.queryParameters['depuis'];
          return EcranNouvelleDemande(prefill: depuis == null ? null : 'Commande liée à : $depuis');
        },
      ),
      GoRoute(path: '/entreprise/operation/:id', builder: (_, etat) => FicheOperation(id: etat.pathParameters['id']!, vueEntreprise: true)),
      GoRoute(path: Chemins.cercle, builder: (_, _) => const EspaceCercle()),
      GoRoute(path: '/cercle/operation/:id', builder: (_, etat) => FicheOperation(id: etat.pathParameters['id']!)),
      GoRoute(path: Chemins.fournisseur, builder: (_, _) => const EspaceFournisseur()),
      GoRoute(path: Chemins.notaire, builder: (_, _) => const EspaceNotaire()),

      // Console
      GoRoute(path: Chemins.admin, builder: (_, _) => const TableauDeBordAdmin()),
      GoRoute(path: Chemins.adminComptes, builder: (_, _) => const PageComptes()),
      GoRoute(path: Chemins.adminInvitations, builder: (_, _) => const PageInvitations()),
      GoRoute(path: Chemins.adminCandidatures, builder: (_, _) => const PageCandidatures()),
      GoRoute(path: Chemins.adminServices, builder: (_, _) => const PageServicesAdmin()),
      GoRoute(path: Chemins.adminContenus, builder: (_, _) => const PageContenusAdmin()),
      GoRoute(path: Chemins.adminEquipe, builder: (_, _) => const PageEquipe()),
      GoRoute(path: Chemins.adminJournal, builder: (_, _) => const PageJournal()),
    ],
  );
});
