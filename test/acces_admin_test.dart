// Tests de l'accès sécurisé de l'administration : mot de passe (PBKDF2),
// codes à 6 chiffres (TOTP), blocage après 5 erreurs. Aucun vrai mot de passe ici.

import 'dart:convert';
import 'dart:typed_data';

import 'package:arziki/auth/acces_admin.dart';
import 'package:arziki/auth/depot_auth.dart';
import 'package:arziki/core/roles.dart';
import 'package:arziki/demo/base_demo.dart';
import 'package:arziki/demo/depot_auth_demo.dart';
import 'package:arziki/demo/depot_comptes_demo.dart';
import 'package:flutter_test/flutter_test.dart';

String hex(List<int> o) => o.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

/// Fabrique des paramètres de test à partir d'un mot de passe et d'une clé connus.
ParametresAccesAdmin parametresDeTest(String motDePasse, List<int> cleTotp) {
  const sel = '00112233445566778899aabbccddeeff';
  final d = pbkdf2(utf8.encode(motDePasse), hexVersOctets(sel), 1000, 52);
  return ParametresAccesAdmin(
    identifiant: 'oumara',
    uid: 'u-super-admin',
    sel: sel,
    iterations: 1000,
    empreinte: hex(d.sublist(0, 32)),
    cleTotpChiffree: hex([for (var i = 0; i < cleTotp.length; i++) cleTotp[i] ^ d[32 + i]]),
  );
}

void main() {
  test('PBKDF2-HMAC-SHA256 : valeur de référence', () {
    expect(hex(pbkdf2(utf8.encode('password'), utf8.encode('salt'), 1, 32)),
        '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b');
    expect(hex(pbkdf2(utf8.encode('password'), utf8.encode('salt'), 2, 32)),
        'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43');
  });

  test('TOTP : valeurs de référence de la RFC 6238', () {
    final cle = utf8.encode('12345678901234567890');
    expect(codeTotp(cle, DateTime.fromMillisecondsSinceEpoch(59 * 1000, isUtc: true)), '287082');
    expect(codeTotp(cle, DateTime.fromMillisecondsSinceEpoch(1111111109 * 1000, isUtc: true)), '081804');
    expect(codeTotp(cle, DateTime.fromMillisecondsSinceEpoch(1234567890 * 1000, isUtc: true)), '005924');
  });

  test('le compte officiel ne contient pas de mot de passe en clair', () {
    const p = ParametresAccesAdmin.proprietaire;
    expect(p.empreinte, hasLength(64));
    expect(p.iterations, greaterThanOrEqualTo(20000));
    expect(verifierMotDePasse(p, 'demo1234'), isNull);
    expect(verifierMotDePasse(p, ''), isNull);
  });

  group('connexion à la console', () {
    late DateTime maintenant;
    late BaseDemo base;
    late DepotAuthDemo auth;
    final cle = Uint8List.fromList(List.generate(20, (i) => i * 7 + 3));

    setUp(() {
      maintenant = DateTime.utc(2026, 11, 1, 10);
      base = BaseDemo(horloge: () => maintenant);
      auth = DepotAuthDemo(base, DepotComptesDemo(base), proprietaire: parametresDeTest('Bon-Mot-De-Passe', cle));
    });

    test('bon identifiant, bon mot de passe et bon code : connecté', () async {
      await auth.connecterAdmin('  Oumara ', 'Bon-Mot-De-Passe');
      final u = await auth.verifierDoubleFacteur(codeTotp(cle, maintenant));
      expect(u.role, Role.superAdmin);
      expect(base.journal.last.action, 'connexion_admin');
    });

    test('un code de 30 secondes plus tôt est encore accepté, pas au-delà', () async {
      await auth.connecterAdmin('oumara', 'Bon-Mot-De-Passe');
      final ancien = codeTotp(cle, maintenant.subtract(const Duration(seconds: 90)));
      await expectLater(auth.verifierDoubleFacteur(ancien), throwsA(isA<ErreurAuth>()));
      final recent = codeTotp(cle, maintenant.subtract(const Duration(seconds: 30)));
      expect((await auth.verifierDoubleFacteur(recent)).uid, 'u-super-admin');
    });

    test('mauvais mot de passe : refus, sans dire si l\'identifiant existe', () async {
      await expectLater(auth.connecterAdmin('oumara', 'faux'),
          throwsA(predicate((e) => e.toString() == 'Identifiant ou mot de passe incorrect.')));
      await expectLater(auth.connecterAdmin('inconnu', 'faux'),
          throwsA(predicate((e) => e.toString() == 'Identifiant ou mot de passe incorrect.')));
    });

    test('les anciens comptes de démonstration n\'ouvrent plus la console', () async {
      for (final id in ['admin@arziki.demo', 'afi@arziki.demo', 'analyste@arziki.demo']) {
        await expectLater(auth.connecterAdmin(id, 'demo1234'), throwsA(isA<ErreurAuth>()));
      }
    });

    test('le code 123456 ne suffit pas pour le super administrateur', () async {
      await auth.connecterAdmin('oumara', 'Bon-Mot-De-Passe');
      final faux = codeTotp(cle, maintenant) == '123456' ? '654321' : '123456';
      await expectLater(auth.verifierDoubleFacteur(faux), throwsA(isA<ErreurAuth>()));
    });

    test('5 erreurs : blocage de 15 minutes, même avec le bon mot de passe', () async {
      for (var i = 0; i < 5; i++) {
        await expectLater(auth.connecterAdmin('oumara', 'faux$i'), throwsA(isA<ErreurAuth>()));
      }
      await expectLater(auth.connecterAdmin('oumara', 'Bon-Mot-De-Passe'),
          throwsA(predicate((e) => e.toString().contains('bloqué'))));
      maintenant = maintenant.add(const Duration(minutes: 16));
      await auth.connecterAdmin('oumara', 'Bon-Mot-De-Passe');
    });
  });
}
