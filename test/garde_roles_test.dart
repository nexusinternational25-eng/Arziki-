// Tests de la garde de navigation : chaque rôle ne voit que ses écrans.

import 'package:arziki/auth/session.dart';
import 'package:arziki/config/app_config.dart';
import 'package:arziki/core/roles.dart';
import 'package:arziki/models/utilisateur.dart';
import 'package:arziki/router/garde_roles.dart';
import 'package:flutter_test/flutter_test.dart';

EtatSession session(Role role, {StatutCompte statut = StatutCompte.actif}) => EtatSession(
      utilisateur: Utilisateur(uid: 'u', role: role, statut: statut, kycStatut: StatutKyc.valide),
      presentationVue: true,
    );

void main() {
  const mobile = CibleApp.mobile;
  const console = CibleApp.console;

  group('Personne non connectée', () {
    test('mobile : écrans publics ouverts, le reste renvoie à la présentation', () {
      const e = EtatSession();
      expect(redirection(e, Chemins.choix, mobile), isNull);
      expect(redirection(e, Chemins.invitation, mobile), isNull);
      expect(redirection(e, Chemins.cercle, mobile), Chemins.presentation);
      expect(redirection(e, Chemins.admin, mobile), Chemins.presentation);
    });

    test('console : seule la connexion administrateur est ouverte', () {
      const e = EtatSession();
      expect(redirection(e, Chemins.connexionAdmin, console), isNull);
      expect(redirection(e, Chemins.choix, console), Chemins.connexionAdmin);
      expect(redirection(e, Chemins.admin, console), Chemins.connexionAdmin);
    });
  });

  group('Console web réservée à l\'administration', () {
    for (final role in Role.values) {
      test('${role.code} sur la console', () {
        final r = redirection(session(role), Chemins.admin, console);
        if (role.accesConsole) {
          expect(r, isNull);
        } else {
          expect(r, Chemins.accesRefuse);
        }
      });
    }
  });

  group('Chaque rôle ne voit que son espace', () {
    final espaces = [Chemins.entreprise, Chemins.cercle, Chemins.fournisseur, Chemins.notaire, Chemins.admin];
    for (final role in Role.values.where((r) => r != Role.candidatCercle)) {
      test(role.code, () {
        for (final chemin in espaces) {
          final r = redirection(session(role), chemin, mobile);
          final attendu = accueilDe(role) == chemin;
          expect(r == null, attendu, reason: '${role.code} -> $chemin');
        }
      });
    }
  });

  test('seul le super administrateur ouvre la page Équipe', () {
    expect(redirection(session(Role.superAdmin), Chemins.adminEquipe, console), isNull);
    expect(redirection(session(Role.admin), Chemins.adminEquipe, console), Chemins.admin);
    expect(redirection(session(Role.analyste), Chemins.adminEquipe, console), Chemins.admin);
  });

  test("l'analyste ne gère ni invitations ni candidatures", () {
    expect(redirection(session(Role.analyste), Chemins.adminInvitations, console), Chemins.admin);
    expect(redirection(session(Role.analyste), Chemins.adminCandidatures, console), Chemins.admin);
    expect(redirection(session(Role.analyste), Chemins.adminComptes, console), isNull);
  });

  test('un compte en attente reste sur les écrans de vérification', () {
    final e = session(Role.membre, statut: StatutCompte.enAttente);
    expect(redirection(e, Chemins.cercle, mobile), Chemins.enAttente);
    expect(redirection(e, Chemins.identite, mobile), isNull);
    expect(redirection(e, Chemins.candidature, mobile), Chemins.enAttente);
  });

  test('un candidat au Cercle ne voit jamais les opérations', () {
    final e = session(Role.candidatCercle, statut: StatutCompte.enAttente);
    expect(redirection(e, Chemins.cercle, mobile), Chemins.enAttente);
    expect(redirection(e, Chemins.candidature, mobile), isNull);
    // Même actif par erreur, il ne peut pas ouvrir le Cercle.
    expect(redirection(session(Role.candidatCercle), Chemins.cercle, mobile), Chemins.enAttente);
  });

  test('un compte suspendu ne voit que l\'écran de suspension', () {
    final e = session(Role.partenaire, statut: StatutCompte.suspendu);
    expect(redirection(e, Chemins.cercle, mobile), Chemins.suspendu);
    expect(redirection(e, Chemins.suspendu, mobile), isNull);
  });
}
