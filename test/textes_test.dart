// Règle légale n° 2 : aucun texte de l'application ne promet un gain.
// Ce test lit toutes les chaînes de caractères du dossier lib/.

import 'dart:io';

import 'package:arziki/core/textes_legaux.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('aucune expression interdite dans les textes affichés', () {
    // Le fichier des textes légaux contient l'avertissement, qui cite ces mots
    // pour les nier (« ni des prêts ni des placements garantis ») : on l'exclut.
    final fichiers = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('textes_legaux.dart'));

    final chaine = RegExp(r"'(?:[^'\\]|\\.)*'" '|' r'"(?:[^"\\]|\\.)*"');
    final problemes = <String>[];
    for (final f in fichiers) {
      for (final m in chaine.allMatches(f.readAsStringSync())) {
        for (final interdit in TextesLegaux.expressionsInterdites) {
          if (interdit.hasMatch(m.group(0)!)) problemes.add('${f.path} : ${m.group(0)}');
        }
      }
    }
    expect(problemes, isEmpty);
  });

  test('le détecteur repère bien les formules interdites', () {
    bool interdit(String t) => TextesLegaux.expressionsInterdites.any((r) => r.hasMatch(t));
    expect(interdit('Croissance garantie'), isTrue);
    expect(interdit('rendement garanti de 12 %'), isTrue);
    expect(interdit('placement sans risque'), isTrue);
    expect(interdit("taux d'intérêt"), isTrue);
    expect(interdit('un prêt rapide'), isTrue);
    // Le vocabulaire autorisé passe.
    expect(interdit('marge visée'), isFalse);
    expect(interdit('garanties proportionnées au montant'), isFalse);
    expect(interdit('participation aux marges'), isFalse);
  });
}
