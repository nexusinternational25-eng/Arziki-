// Pays de la sous-région (CLAUDE.md, section 23.1 et 23.2).

import 'dart:io';

import 'package:arziki/auth/depot_auth.dart';
import 'package:arziki/comptes/depot_comptes.dart';
import 'package:arziki/core/pays.dart';
import 'package:arziki/core/roles.dart';
import 'package:arziki/demo/base_demo.dart';
import 'package:arziki/demo/depot_auth_demo.dart';
import 'package:arziki/demo/depot_comptes_demo.dart';
import 'package:arziki/ui/composants.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/exporter_pays.dart';

void main() {
  group('Configuration des pays', () {
    test('le Togo est le pays par défaut et le seul ouvert', () {
      expect(PaysConfig.parDefaut.code, 'TG');
      expect(PaysConfig.actifs.map((p) => p.code), ['TG']);
    });

    test('le Bénin et le Niger sont visibles, « à venir »', () {
      for (final code in ['BJ', 'NE']) {
        final p = PaysConfig.parCode(code)!;
        expect(p.estActif, isFalse);
        expect(p.libelleChoix, endsWith('bientôt'));
      }
    });

    test('chaque pays est complet et unique', () {
      final codes = <String>{};
      final indicatifs = <String>{};
      for (final p in PaysConfig.tous) {
        expect(codes.add(p.code), isTrue, reason: p.code);
        expect(indicatifs.add(p.indicatif), isTrue, reason: p.indicatif);
        expect(p.indicatif, matches(r'^\+\d{3}$'));
        expect(p.portefeuilles, isNotEmpty, reason: p.nom);
        expect(p.autoriteDonnees, isNotEmpty, reason: p.nom);
        // L'exemple affiché respecte la règle du pays.
        expect(p.numeroValide(p.exemple), isTrue, reason: '${p.nom} : ${p.exemple}');
      }
    });

    test('un pays ouvert a un notaire partenaire ou est le Togo', () {
      for (final p in PaysConfig.actifs) {
        expect(p.code == 'TG' || p.notairePartenaire, isTrue, reason: p.nom);
      }
    });

    test('la liste des Cloud Functions est à jour (dart run tool/exporter_pays.dart)', () {
      expect(File('functions/src/pays.json').readAsStringSync(), contenuPaysJson());
    });
  });

  group('Validation des numéros', () {
    test('Togo : 8 chiffres', () {
      final tg = PaysConfig.togo;
      expect(tg.erreurNumero('90123456'), isNull);
      expect(tg.erreurNumero('90 12 34 56'), isNull);
      expect(tg.erreurNumero('9012345'), contains('8 chiffres'));
      expect(tg.numeroInternational('90 12 34 56'), '+22890123456');
    });

    test('Bénin : 10 chiffres commençant par 01', () {
      final bj = PaysConfig.parCode('BJ')!;
      expect(bj.erreurNumero('0197123456'), isNull);
      expect(bj.erreurNumero('97123456'), contains('10 chiffres'));
      expect(bj.erreurNumero('9712345678'), contains('commence par 01'));
    });

    test('numéro complet : pays connu, ouvert, bien formé', () {
      expect(PaysConfig.erreurTelephone('+22890123456'), isNull);
      expect(PaysConfig.erreurTelephone('+22790123456'), contains('pas encore ouvert au Niger'));
      expect(PaysConfig.erreurTelephone('+22790123456', exigerPaysActif: false), isNull);
      expect(PaysConfig.erreurTelephone('+33612345678'), contains('zone ARZIKI'));
      expect(PaysConfig.depuisTelephone('+2250712345678')?.code, 'CI');
    });

    test('affichage lisible selon le pays', () {
      expect(telephoneLisible('+22890000011'), '+228 90 00 00 11');
      expect(telephoneLisible('+221771234567'), '+221 77 123 45 67');
      expect(telephoneLisible('+2290197123456'), '+229 01 97 12 34 56');
      expect(telephoneLisible('inconnu'), 'inconnu');
    });
  });

  group('Inscription selon le pays (démonstration)', () {
    late DepotAuthDemo auth;
    late DepotComptesDemo comptes;
    late BaseDemo base;

    setUp(() {
      base = BaseDemo();
      comptes = DepotComptesDemo(base);
      auth = DepotAuthDemo(base, comptes);
    });

    test('un numéro togolais crée un compte au pays TG', () async {
      await auth.envoyerCode('+22890776655', CanalCode.sms);
      final u = await auth.inscrireParTelephone(
        const DemandeInscription(parcours: Parcours.entreprise, telephone: '+22890776655', cgVersion: '1.0'),
        const PreuveCode('123456'),
      );
      expect(u.pays, 'TG');
    });

    test('aucune vérification pour un pays à venir ou un numéro mal formé', () async {
      expect(() => auth.envoyerCode('+22790123456', CanalCode.sms), throwsA(isA<ErreurAuth>()));
      expect(() => auth.demarrerVerificationParMessage('+2290197123456'), throwsA(isA<ErreurAuth>()));
      expect(() => auth.envoyerCode('+228901234', CanalCode.whatsapp), throwsA(isA<ErreurAuth>()));
    });

    test("pas d'invitation vers un pays à venir", () async {
      final superAdmin = base.utilisateurs['u-super-admin']!;
      expect(
        () => comptes.creerInvitation(
          acteur: superAdmin,
          pourNom: 'Aïcha Maïga',
          pourTelephone: '+22790123456',
          niveau: NiveauCercle.membre,
        ),
        throwsA(isA<ErreurAcces>()),
      );
    });
  });
}
