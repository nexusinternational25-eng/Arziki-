// Tests du modèle d'accès : investisseurs privés invités, candidatures,
// validation, rôles et équipe. Mêmes règles que les Cloud Functions.

import 'package:arziki/auth/depot_auth.dart';
import 'package:arziki/comptes/depot_comptes.dart';
import 'package:arziki/core/roles.dart';
import 'package:arziki/demo/base_demo.dart';
import 'package:arziki/demo/depot_auth_demo.dart';
import 'package:arziki/demo/depot_comptes_demo.dart';
import 'package:arziki/models/acces.dart';
import 'package:arziki/models/utilisateur.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime maintenant;
  late BaseDemo base;
  late DepotComptesDemo comptes;
  late DepotAuthDemo auth;

  Utilisateur u(String uid) => base.utilisateurs[uid]!;
  Utilisateur superAdmin() => u('u-super-admin');
  Utilisateur admin() => u('u-admin');
  Utilisateur analyste() => u('u-analyste');

  setUp(() {
    maintenant = DateTime(2026, 11, 1, 10);
    base = BaseDemo(horloge: () => maintenant);
    comptes = DepotComptesDemo(base);
    auth = DepotAuthDemo(base, comptes);
  });

  Future<Utilisateur> inscrire(Parcours p, String tel, {String? code}) async {
    await auth.envoyerCodeSms(tel);
    return auth.inscrireParTelephone(
      DemandeInscription(parcours: p, telephone: tel, cgVersion: '1.0', codeInvitation: code),
      '123456',
    );
  }

  group('Investisseur privé invité par le super administrateur', () {
    test('parcours complet : invitation, inscription, validation, accès au Cercle', () async {
      final inv = await comptes.creerInvitation(
        acteur: superAdmin(),
        pourNom: 'Awa Traoré',
        pourTelephone: '90 12 34 56',
        niveau: NiveauCercle.partenaire,
      );
      expect(inv.code, matches(RegExp(r'^ARZ-[A-Z2-9]{4}-[A-Z2-9]{4}$')));
      expect(inv.pourTelephone, '+22890123456');

      final nouveau = await inscrire(Parcours.invitation, '+22890123456', code: inv.code);
      expect(nouveau.role, Role.partenaire, reason: "le niveau vient de l'invitation");
      expect(nouveau.statut, StatutCompte.enAttente);
      expect(base.invitations[inv.code]!.estUtilisee, isTrue);

      await comptes.validerKyc(acteur: admin(), uid: nouveau.uid);
      expect(u(nouveau.uid).statut, StatutCompte.actif);
      expect(base.journal.map((e) => e.action),
          containsAll(['creer_invitation', 'utiliser_invitation', 'inscription', 'valider_kyc']));
    });

    test('le code est à usage unique', () async {
      final inv = await comptes.creerInvitation(
          acteur: superAdmin(), pourNom: 'Awa Traoré', pourTelephone: '+22890123456', niveau: NiveauCercle.membre);
      await inscrire(Parcours.invitation, '+22890123456', code: inv.code);
      expect(() => comptes.verifierInvitation(code: inv.code, telephone: '+22890123456'),
          throwsA(isA<ErreurAcces>()));
    });

    test('le code ne marche qu\'avec le numéro invité', () async {
      final inv = await comptes.creerInvitation(
          acteur: superAdmin(), pourNom: 'Awa Traoré', pourTelephone: '+22890123456', niveau: NiveauCercle.membre);
      expect(() => inscrire(Parcours.invitation, '+22899999999', code: inv.code), throwsA(isA<ErreurAcces>()));
    });

    test('un code expiré ou annulé est refusé', () async {
      final inv = await comptes.creerInvitation(
          acteur: superAdmin(),
          pourNom: 'Awa Traoré',
          pourTelephone: '+22890123456',
          niveau: NiveauCercle.membre,
          joursValidite: 7);
      maintenant = maintenant.add(const Duration(days: 8));
      expect(() => comptes.verifierInvitation(code: inv.code, telephone: '+22890123456'),
          throwsA(isA<ErreurAcces>()));

      final inv2 = await comptes.creerInvitation(
          acteur: superAdmin(), pourNom: 'Kofi Mensah', pourTelephone: '+22890123457', niveau: NiveauCercle.membre);
      await comptes.annulerInvitation(acteur: admin(), code: inv2.code);
      expect(() => comptes.verifierInvitation(code: inv2.code, telephone: '+22890123457'),
          throwsA(isA<ErreurAcces>()));
    });

    test("l'analyste ne peut pas inviter", () {
      expect(
        () => comptes.creerInvitation(
            acteur: analyste(), pourNom: 'Awa Traoré', pourTelephone: '+22890123456', niveau: NiveauCercle.membre),
        throwsA(isA<ErreurAcces>()),
      );
    });

    test('pas d\'inscription au Cercle sans code', () async {
      expect(() => inscrire(Parcours.invitation, '+22890123456'), throwsA(isA<ErreurAcces>()));
    });
  });

  group('Investisseur inscrit seul : candidature', () {
    test('il reste candidat, sans accès, jusqu\'à son admission', () async {
      final c = await inscrire(Parcours.candidature, '+22891000000');
      expect(c.role, Role.candidatCercle);
      expect(c.role.estMembreDuCercle, isFalse);

      await comptes.deposerCandidature(
          candidat: c,
          prenom: 'Yawa',
          nom: 'Ekué',
          niveauSouhaite: NiveauCercle.membre,
          trancheEnvisagee: '500 000 à 2 000 000 FCFA',
          commentNousConnu: 'Autre');
      expect(u(c.uid).nomComplet, 'Yawa Ekué');

      // L'identité vérifiée ne suffit pas : il faut l'admission.
      await comptes.validerKyc(acteur: admin(), uid: c.uid);
      expect(u(c.uid).statut, StatutCompte.enAttente);
      expect(u(c.uid).role, Role.candidatCercle);

      await comptes.admettreCandidat(acteur: admin(), uid: c.uid, niveau: NiveauCercle.membre);
      expect(u(c.uid).role, Role.membre);
      expect(u(c.uid).statut, StatutCompte.actif);
      expect(base.candidatures[c.uid]!.statut, StatutCandidature.admise);
    });

    test('admis avant la vérification d\'identité : reste en attente', () async {
      await comptes.admettreCandidat(acteur: admin(), uid: 'u-candidat-1', niveau: NiveauCercle.membre);
      expect(u('u-candidat-1').role, Role.membre);
      expect(u('u-candidat-1').statut, StatutCompte.enAttente);
    });

    test('un refus exige un motif', () async {
      expect(() => comptes.refuserCandidat(acteur: admin(), uid: 'u-candidat-1', motif: ' '),
          throwsA(isA<ErreurAcces>()));
      await comptes.refuserCandidat(acteur: admin(), uid: 'u-candidat-1', motif: 'Origine des fonds non justifiée');
      expect(base.candidatures['u-candidat-1']!.statut, StatutCandidature.refusee);
    });

    test('le Cercle ne dépasse pas la limite de 100 personnes', () async {
      for (var i = 0; i < limiteTailleCercle; i++) {
        base.utilisateurs['m$i'] =
            const Utilisateur(uid: 'x', role: Role.membre, statut: StatutCompte.actif, kycStatut: StatutKyc.valide);
      }
      expect(() => comptes.admettreCandidat(acteur: admin(), uid: 'u-candidat-1', niveau: NiveauCercle.membre),
          throwsA(isA<ErreurAcces>()));
    });
  });

  group('Rôles et équipe', () {
    test('personne ne modifie son propre rôle', () {
      expect(() => comptes.attribuerRole(acteur: admin(), uid: admin().uid, role: Role.membre),
          throwsA(isA<ErreurAcces>()));
    });

    test('un admin ne crée pas d\'admin et ne touche pas au super admin', () {
      expect(() => comptes.attribuerRole(acteur: admin(), uid: 'u-membre-1', role: Role.admin),
          throwsA(isA<ErreurAcces>()));
      expect(() => comptes.attribuerRole(acteur: admin(), uid: 'u-super-admin', role: Role.membre),
          throwsA(isA<ErreurAcces>()));
      expect(() => comptes.suspendre(acteur: admin(), uid: 'u-analyste', motif: 'test'),
          throwsA(isA<ErreurAcces>()));
    });

    test('un admin change le niveau d\'un investisseur', () async {
      await comptes.attribuerRole(acteur: admin(), uid: 'u-membre-1', role: Role.partenaire);
      expect(u('u-membre-1').role, Role.partenaire);
    });

    test('le rôle super administrateur ne se donne jamais depuis l\'application', () {
      expect(() => comptes.attribuerRole(acteur: superAdmin(), uid: 'u-admin', role: Role.superAdmin),
          throwsA(isA<ErreurAcces>()));
    });

    test('seul le super admin crée un compte d\'équipe', () async {
      expect(
          () => comptes.creerCompteEquipe(
              acteur: admin(), prenom: 'A', nom: 'B', email: 'a@b.tg', role: Role.analyste),
          throwsA(isA<ErreurAcces>()));
      final cree = await comptes.creerCompteEquipe(
          acteur: superAdmin(), prenom: 'Kafui', nom: 'Doe', email: 'kafui@arziki.tg', role: Role.analyste);
      expect(cree.role, Role.analyste);
      await auth.connecterAdmin('kafui@arziki.tg', 'demo1234');
      expect((await auth.verifierDoubleFacteur('123456')).uid, cree.uid);
    });

    test('un compte suspendu ne peut plus se connecter à la console', () async {
      await comptes.suspendre(acteur: superAdmin(), uid: 'u-admin', motif: 'départ');
      await auth.connecterAdmin('afi@arziki.demo', 'demo1234');
      expect(() => auth.verifierDoubleFacteur('123456'), throwsA(isA<ErreurAuth>()));
    });
  });

  group('Connexion', () {
    test('un administrateur ne se connecte pas par SMS', () async {
      expect(() => auth.connecterParTelephone('+22890000001', '123456'), throwsA(isA<ErreurAuth>()));
    });

    test('mauvais code : refus, puis blocage après 5 essais', () async {
      for (var i = 0; i < 5; i++) {
        await expectLater(auth.connecterParTelephone('+22890000021', '000000'), throwsA(isA<ErreurAuth>()));
      }
      await expectLater(
        auth.connecterParTelephone('+22890000021', '123456'),
        throwsA(predicate((e) => e.toString().contains('Trop de tentatives'))),
      );
    });

    test('limite de 5 SMS par heure et par numéro', () async {
      for (var i = 0; i < 5; i++) {
        await auth.envoyerCodeSms('+22890000021');
      }
      expect(() => auth.envoyerCodeSms('+22890000021'), throwsA(isA<ErreurAuth>()));
    });

    test('un numéro déjà inscrit ne crée pas un second compte', () {
      expect(() => inscrire(Parcours.entreprise, '+22890000011'), throwsA(isA<ErreurAuth>()));
    });
  });

  test('les codes générés évitent les caractères ambigus', () {
    for (var i = 0; i < 200; i++) {
      expect(Invitation.genererCode(), isNot(matches(RegExp('[01OIL]'))));
    }
  });
}
