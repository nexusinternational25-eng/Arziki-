// L'application démarre en mode démonstration et affiche la présentation.

import 'package:arziki/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('démarrage, présentation puis choix du parcours', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    await tester.pumpWidget(const ProviderScope(child: ArzikiApp()));
    expect(find.textContaining('Démonstration'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();
    expect(find.text('La Commande Financée'), findsOneWidget);

    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();
    expect(find.text("J'ai un code d'invitation au Cercle"), findsOneWidget);
    expect(find.text('Je souhaite rejoindre le Cercle'), findsOneWidget);
  });
}
