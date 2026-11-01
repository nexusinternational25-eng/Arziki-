// L'application démarre en mode démonstration, présente ARZIKI en 4 écrans,
// puis propose le choix du profil (dont le mode visiteur).

import 'package:arziki/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('démarrage, présentation puis choix du profil', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    await tester.pumpWidget(const ProviderScope(child: ArzikiApp()));
    expect(find.textContaining('Démonstration'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();
    expect(find.text('Votre commande, financée'), findsOneWidget);

    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();
    expect(find.text('Bienvenue sur ARZIKI'), findsOneWidget);
    expect(find.text('Membre du Cercle'), findsOneWidget);
    expect(find.text('Je veux juste découvrir'), findsOneWidget);
  });

  testWidgets('le visiteur découvre ARZIKI sans compte', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    await tester.pumpWidget(const ProviderScope(child: ArzikiApp()));
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Je veux juste découvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Je veux juste découvrir'));
    await tester.pumpAndSettle();
    expect(find.text('Ta commande. Notre financement.'), findsWidgets);
    expect(find.text('Créer mon compte'), findsOneWidget);
  });
}
