// Tests de la refonte : mode visiteur, opérations visibles par niveau,
// services (commande complète), calculs, formats, contenus modifiables.

import 'dart:io';

import 'package:arziki/auth/session.dart';
import 'package:arziki/config/app_config.dart';
import 'package:arziki/contenu/contenus.dart';
import 'package:arziki/core/roles.dart';
import 'package:arziki/core/textes_legaux.dart';
import 'package:arziki/models/utilisateur.dart';
import 'package:arziki/operations/operations.dart';
import 'package:arziki/router/garde_roles.dart';
import 'package:arziki/services_nexus/services.dart';
import 'package:arziki/ui/composants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

EtatSession session(Role role, {StatutCompte statut = StatutCompte.actif}) => EtatSession(
      utilisateur: Utilisateur(uid: 'u', role: role, statut: statut, kycStatut: StatutKyc.valide),
      presentationVue: true,
    );

void main() {
  group('Mode visiteur', () {
    const visiteur = EtatSession(presentationVue: true);
    test('pages publiques et catalogue ouverts', () {
      expect(redirection(visiteur, Chemins.decouvrir, CibleApp.mobile), isNull);
      expect(redirection(visiteur, Chemins.info(PagesId.aPropos), CibleApp.mobile), isNull);
      expect(redirection(visiteur, Chemins.faq, CibleApp.mobile), isNull);
      expect(redirection(visiteur, Chemins.services, CibleApp.mobile), isNull);
      expect(redirection(visiteur, Chemins.offre('diagnostic'), CibleApp.mobile), isNull);
      expect(redirection(visiteur, Chemins.formations, CibleApp.mobile), isNull);
    });
    test('aucune opération du Cercle, pas de commande sans compte', () {
      expect(redirection(visiteur, Chemins.cercle, CibleApp.mobile), Chemins.choix);
      expect(redirection(visiteur, Chemins.operationCercle('op-pharma'), CibleApp.mobile), Chemins.choix);
      expect(redirection(visiteur, Chemins.commanderOffre('diagnostic'), CibleApp.mobile), Chemins.choix);
      expect(redirection(visiteur, Chemins.notifications, CibleApp.mobile), Chemins.choix);
    });
    test('la console reste fermée aux visiteurs', () {
      expect(redirection(visiteur, Chemins.info(PagesId.aPropos), CibleApp.console), Chemins.connexionAdmin);
    });
    test('une personne connectée garde accès aux pages publiques', () {
      expect(redirection(session(Role.entreprise), Chemins.info(PagesId.aPropos), CibleApp.mobile), isNull);
      expect(redirection(session(Role.entreprise), Chemins.decouvrir, CibleApp.mobile), Chemins.entreprise);
      expect(redirection(session(Role.membre, statut: StatutCompte.enAttente), Chemins.services, CibleApp.mobile), isNull);
    });
    test('seuls les administrateurs ouvrent Services et Contenus de la console', () {
      expect(redirection(session(Role.admin), Chemins.adminServices, CibleApp.console), isNull);
      expect(redirection(session(Role.analyste), Chemins.adminContenus, CibleApp.console), Chemins.admin);
    });
  });

  group('Opérations en vente à terme (démonstration)', () {
    ProviderContainer conteneur() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      return c;
    }

    test('un partenaire ne voit que les opérations qui lui sont proposées, et seulement vérifié', () {
      final ctrl = conteneur().read(operationsProvider.notifier);
      final membre = ctrl.proposeesA('u-membre-1', verifie: true);
      expect(membre, isNotEmpty);
      expect(membre.every((o) => o.partenairesProposes.contains('u-membre-1')), isTrue);
      expect(membre.any((o) => o.id == 'op-mine'), isFalse);
      expect(ctrl.proposeesA('u-membre-1', verifie: false), isEmpty);
      expect(ctrl.proposeesA('u-inconnu', verifie: true), isEmpty);
    });

    test('jeu de démonstration : toutes les étapes, un retard, aucune marge partagée', () {
      final ops = operationsDemo();
      expect(ops.length, greaterThanOrEqualTo(8));
      expect(ops.where((o) => o.statut == StatutVente.enRetard), hasLength(1));
      expect(ops.map((o) => o.statut).toSet().length, greaterThanOrEqualTo(8));
      for (final o in ops.where((o) => o.apportsRetenus.isNotEmpty)) {
        expect(o.apportsRetenus.fold<int>(0, (s, a) => s + a.montant), o.prixAchat, reason: o.id);
      }
    });

    test('parcours complet : analyse, conditions, proposition, intérêt, apports, signature, clôture', () {
      final c = conteneur();
      final ctrl = c.read(operationsProvider.notifier);
      const id = 'op-demande';
      ctrl.changerStatut('u-admin', id, StatutVente.enAnalyse);
      ctrl.definirConditions('u-admin', id, prixAchat: 8000000, majoration: 240000, dureeJours: 60);
      expect(c.read(operationsProvider).parId(id)!.prixRevente, 8240000);
      ctrl.proposer('u-admin', id, ['u-membre-1', 'u-membre-2']);
      expect(() => ctrl.manifesterInteret(uid: 'u-membre-3', id: id, montant: 1000000), throwsA(isA<ErreurVente>()));
      ctrl.manifesterInteret(uid: 'u-membre-1', id: id, montant: 5000000);
      ctrl.manifesterInteret(uid: 'u-membre-2', id: id, montant: 3000000);
      expect(c.read(operationsProvider).parId(id)!.statut, StatutVente.interetManifeste);
      // Pas de signature sans apports exacts ni garantie.
      expect(() => ctrl.changerStatut('u-admin', id, StatutVente.signee), throwsA(isA<ErreurVente>()));
      ctrl.retenirApports('u-admin', id, const [Apport('u-membre-1', 5000000), Apport('u-membre-2', 3000000)]);
      expect(() => ctrl.changerStatut('u-admin', id, StatutVente.signee), throwsA(isA<ErreurVente>()));
      ctrl.majGarantie('u-admin', id, TypeGarantie.reservePropriete, StatutGarantie.aConstituer);
      ctrl.changerStatut('u-notaire', id, StatutVente.signee);
      // Pas de paiement au fournisseur tant que la garantie n'est pas signée.
      expect(() => ctrl.changerStatut('u-notaire', id, StatutVente.fournisseurPaye), throwsA(isA<ErreurVente>()));
      ctrl.majGarantie('u-notaire', id, TypeGarantie.reservePropriete, StatutGarantie.signee);
      for (final s in [StatutVente.fournisseurPaye, StatutVente.livree, StatutVente.echeancePayee, StatutVente.cloturee]) {
        ctrl.changerStatut('u-admin', id, s);
      }
      final o = c.read(operationsProvider).parId(id)!;
      expect(o.statut, StatutVente.cloturee);
      expect(o.repartition.fold<int>(0, (s, p) => s + p.aRecevoir), 8240000);
      expect(c.read(baseDemoProvider).journal.where((e) => e.cible == 'operations/$id').length, greaterThanOrEqualTo(10));
    });

    test('un refus exige un motif', () {
      final ctrl = conteneur().read(operationsProvider.notifier);
      ctrl.changerStatut('u-admin', 'op-demande', StatutVente.enAnalyse);
      expect(() => ctrl.changerStatut('u-admin', 'op-demande', StatutVente.refusee), throwsA(isA<ErreurVente>()));
      ctrl.changerStatut('u-admin', 'op-demande', StatutVente.refusee, motif: 'Client final injoignable');
    });

    test('garanties suggérées selon le montant', () {
      expect(garantiesSuggerees(3000000), [TypeGarantie.reservePropriete]);
      expect(garantiesSuggerees(10000000), contains(TypeGarantie.cautionnement));
      expect(garantiesSuggerees(50000000), contains(TypeGarantie.nantissementCreance));
      expect(garantiesSuggerees(150000000), contains(TypeGarantie.hypotheque));
    });
  });

  group('Services', () {
    test('parcours complet : besoin, devis, acompte, travail, livrable, solde', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final s = c.read(servicesProvider.notifier);
      final cmd = s.commander(uid: 'u-ent-btp', offreId: 'diagnostic', besoin: 'Diagnostic de ma capacité à financer un camion.');
      expect(() => s.payer(uid: 'u-ent-btp', commandeId: cmd.id), throwsA(isA<ErreurService>()));
      s.envoyerDevis(acteur: 'u-admin', commandeId: cmd.id, montant: 25000);
      expect(() => s.payer(uid: 'u-autre', commandeId: cmd.id), throwsA(isA<ErreurService>()));
      s.payer(uid: 'u-ent-btp', commandeId: cmd.id);
      expect(s.commande(cmd.id).etape, EtapeCommande.acompteRegle);
      expect(s.commande(cmd.id).paiements.single.$2, 12500);
      s.demarrer(acteur: 'u-admin', commandeId: cmd.id);
      s.livrer(acteur: 'u-admin', commandeId: cmd.id, livrable: 'Note de diagnostic (PDF)');
      s.payer(uid: 'u-ent-btp', commandeId: cmd.id);
      expect(s.commande(cmd.id).etape, EtapeCommande.soldeRegle);
      expect(s.commande(cmd.id).paiements.fold<int>(0, (t, p) => t + p.$2), 25000);
      final actions = c.read(baseDemoProvider).journal.map((e) => e.action);
      expect(actions, containsAll(['commander_service', 'envoyer_devis_service', 'payer_acompte_service', 'livrer_service', 'payer_solde_service']));
    });
    test('un besoin trop court est refusé', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(() => c.read(servicesProvider.notifier).commander(uid: 'u', offreId: 'diagnostic', besoin: 'court'), throwsA(isA<ErreurService>()));
    });
    test('inscription à une formation : places et doublons', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final s = c.read(servicesProvider.notifier);
      s.inscrire(uid: 'u-membre-1', sessionId: 's2');
      expect(() => s.inscrire(uid: 'u-membre-1', sessionId: 's2'), throwsA(isA<ErreurService>()));
    });
    test('les quatre familles sont au catalogue, dont ARZIKI Carnet « bientôt »', () {
      for (final f in FamilleService.values) {
        expect(catalogueParDefaut.any((o) => o.famille == f), isTrue, reason: f.libelle);
      }
      expect(catalogueParDefaut.firstWhere((o) => o.id == 'carnet').bientot, isTrue);
      expect(catalogueParDefaut.firstWhere((o) => o.id == 'diagnostic').prix, '25 000 FCFA');
      expect(formationsParDefaut, hasLength(5));
    });
  });

  group('Contenus et formats', () {
    test('une page modifiée depuis la console est tracée', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(contenusProvider.notifier).modifierPage('u-super-admin', PagesId.aPropos,
          titre: 'À propos', intro: 'Nouvelle introduction', sections: const []);
      expect(c.read(contenusProvider).pages[PagesId.aPropos]!.intro, 'Nouvelle introduction');
      expect(c.read(baseDemoProvider).journal.last.action, 'modifier_contenu');
    });
    test('le fondateur et les mentions légales sont présents', () {
      final apropos = pagesParDefaut[PagesId.aPropos]!.sections.map((s) => s.texte).join();
      expect(apropos, contains('CEO de NEXUS International'));
      expect(apropos, contains('USAID'));
      final mentions = pagesParDefaut[PagesId.mentions]!.sections.map((s) => s.texte).join();
      expect(mentions, contains('TG-LFW-01-2025-A10-03200'));
      expect(mentions, contains('18 rue Léopold Sédar Senghor'));
      expect(const Contacts().whatsappChiffres, '22891978080');
    });
    test("le nom du propriétaire et la mention « provisoire » n'apparaissent nulle part", () {
      final fichiers = [
        ...Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')),
        File('livraison/index.html'),
      ];
      for (final f in fichiers) {
        final texte = f.readAsStringSync().toLowerCase();
        for (final interdit in ['moussa', 'zouzou', 'saley', 'version provisoire', 'en attente de validation par l']) {
          expect(texte.contains(interdit), isFalse, reason: '${f.path} contient « $interdit »');
        }
      }
      expect(TextesLegaux.versionConditions, '2.0');
    });
    test('formats des montants et des dates', () {
      expect(fcfa(6000000), '6 000 000 FCFA');
      expect(dateLongue(DateTime(2026, 10, 31)), '31 octobre 2026');
      expect(dateLongue(DateTime(2026, 11, 1)), '1er novembre 2026');
    });
  });
}
