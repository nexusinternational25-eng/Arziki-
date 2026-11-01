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

  group('Opérations', () {
    test('un membre voit les opérations PME ouvertes, un partenaire aussi les Entreprises', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final ctrl = c.read(operationsProvider.notifier);
      final membre = ctrl.ouvertesPour(Role.membre);
      final partenaire = ctrl.ouvertesPour(Role.partenaire);
      expect(membre.every((o) => o.estOuverte && !o.estEntreprises), isTrue);
      expect(partenaire.any((o) => o.estEntreprises), isTrue);
      expect(ctrl.ouvertesPour(Role.candidatCercle), isEmpty);
      expect(ctrl.ouvertesPour(Role.entreprise), isEmpty);
    });
    test('8 opérations de démonstration, dont une en retard et une en perte', () {
      expect(operationsDemo, hasLength(8));
      expect(operationsDemo.where((o) => o.statut == StatutOperation.enRetard), hasLength(1));
      expect(operationsDemo.where((o) => (o.resultatPct ?? 0) < 0), hasLength(1));
    });
    test('une participation est enregistrée « versement attendu », avec référence et audit', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final op = operationsDemo.first;
      final p = c.read(operationsProvider.notifier).participer(uid: 'u-membre-2', op: op, montant: 1000000);
      expect(p.statut, StatutParticipation.attenteVersement);
      expect(p.reference, startsWith('ARZ-'));
      expect(c.read(baseDemoProvider).journal.last.action, 'creer_participation');
    });
    test('calcul de marge', () {
      final m = calculerMarge(vente: 10000000, achat: 8000000, transport: 300000, autres: 200000);
      expect(m.brute, 2000000);
      expect(m.nette, 1500000);
      expect(m.nettePct, 15);
      expect(calculerMarge(vente: 0, achat: 0, transport: 0, autres: 0).nettePct, 0);
    });
    test('garanties selon le montant (section 8)', () {
      expect(garantiesPour(4000000), contains("Caution du dirigeant si l'historique est faible"));
      expect(garantiesPour(10000000), contains('Caution solidaire du dirigeant'));
      expect(garantiesPour(50000000), contains("Caution solidaire d'un tiers solvable"));
      expect(garantiesPour(150000000), contains('Assurance de la marchandise'));
      expect(formeActePour(150000000), contains('livre foncier'));
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
      expect(TextesLegaux.versionConditions, '1.0');
    });
    test('formats des montants et des dates', () {
      expect(fcfa(6000000), '6 000 000 FCFA');
      expect(dateLongue(DateTime(2026, 10, 31)), '31 octobre 2026');
      expect(dateLongue(DateTime(2026, 11, 1)), '1er novembre 2026');
    });
  });
}
