// Vente à terme : mêmes cas que le serveur (test/vecteurs/operations.json).

import 'dart:convert';
import 'dart:io';

import 'package:arziki/operations/vente_a_terme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final v = jsonDecode(File('test/vecteurs/operations.json').readAsStringSync()) as Map<String, dynamic>;

  ConditionsVente conditions(Map<String, dynamic> c) => ConditionsVente(
        prixAchat: (c['prixAchat'] as num).toInt(),
        majoration: (c['majoration'] as num).toInt(),
        dureeJours: (c['dureeJours'] as num).toInt(),
      );
  List<Apport> apports(Map<String, dynamic> r) =>
      [for (final a in r['apports'] as List) Apport(a[0] as String, (a[1] as num).toInt())];

  group('Prix de revente et coût annuel équivalent', () {
    for (final c in (v['conditions'] as List).cast<Map<String, dynamic>>()) {
      test(c['cas'] as String, () {
        final cv = conditions(c);
        expect(cv.prixRevente, c['prixRevente']);
        expect(cv.coutAnnuelEquivalent, (c['coutAnnuel'] as num).toDouble());
        expect(cv.alerte(), c['alerte']);
      });
    }
    for (final c in (v['invalides'] as List).cast<Map<String, dynamic>>()) {
      // Le cas « montant à virgule » n'existe pas en Dart (montants en int).
      if ((c['prixAchat'] as num) is double) continue;
      test('refuse : ${c['cas']}', () => expect(() => conditions(c).prixRevente, throwsA(isA<ErreurVente>())));
    }
  });

  group('Répartition entre partenaires', () {
    for (final r in (v['repartitions'] as List).cast<Map<String, dynamic>>()) {
      test(r['cas'] as String, () {
        final parts = repartir(conditions(r), apports(r));
        expect([for (final p in parts) [p.partenaireUid, p.partMajoration, p.aRecevoir]], r['attendu']);
        expect(parts.fold<int>(0, (s, p) => s + p.aRecevoir), (r['prixAchat'] as int) + (r['majoration'] as int));
      });
    }
    for (final r in (v['repartitionsInvalides'] as List).cast<Map<String, dynamic>>()) {
      test('refuse : ${r['cas']}', () => expect(() => repartir(conditions(r), apports(r)), throwsA(isA<ErreurVente>())));
    }
  });

  group('Cycle de vie et plafond', () {
    test('les transitions sont les mêmes que sur le serveur', () {
      final ts = File('functions/src/operations.ts').readAsStringSync();
      for (final s in StatutVente.values) {
        final ligne = RegExp('  ${s.code}: \\[([^\\]]*)\\]').firstMatch(ts);
        expect(ligne, isNotNull, reason: s.code);
        final attendus = RegExp('"([a-z_]+)"').allMatches(ligne!.group(1)!).map((m) => m.group(1)).toList();
        expect(transitionsVente[s]!.map((x) => x.code).toList(), attendus, reason: s.code);
      }
    });

    test('plafond : 50 par défaut, jamais au-delà de 99', () {
      verifierPlaceDisponible(49);
      expect(() => verifierPlaceDisponible(50), throwsA(isA<ErreurVente>()));
      verifierPlaceDisponible(98, 99);
      expect(() => verifierPlaceDisponible(10, 100), throwsA(isA<ErreurVente>()));
    });
  });
}
