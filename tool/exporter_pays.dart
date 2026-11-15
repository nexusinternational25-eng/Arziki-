// Écrit la liste des pays pour les Cloud Functions (functions/src/pays.json)
// à partir de lib/core/pays.dart, qui reste la seule source.
// À relancer après toute modification des pays : dart run tool/exporter_pays.dart

import 'dart:convert';
import 'dart:io';

import 'package:arziki/core/pays.dart';

String contenuPaysJson() => '${const JsonEncoder.withIndent('  ').convert({
      'parDefaut': PaysConfig.parDefaut.code,
      'pays': [for (final p in PaysConfig.tous) p.versJson()],
    })}\n';

void main() {
  File('functions/src/pays.json').writeAsStringSync(contenuPaysJson());
  stdout.writeln('functions/src/pays.json mis à jour (${PaysConfig.tous.length} pays).');
}
