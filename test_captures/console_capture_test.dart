// Captures d'écran de la console (vérification visuelle, hors tests automatiques).
// Lancer : flutter test test_captures/console_capture_test.dart
// Les images sont écrites dans build/captures/.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:arziki/auth/session.dart';
import 'package:arziki/ecrans/admin/console_operations.dart';
import 'package:arziki/theme/arziki_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _police(String famille, List<String> fichiers) async {
  final l = FontLoader(famille);
  for (final f in fichiers) {
    l.addFont(Future.value(ByteData.view(File(f).readAsBytesSync().buffer)));
  }
  await l.load();
}

Future<void> _capturer(WidgetTester tester, Widget page, String nom, {Size taille = const Size(1280, 1500)}) async {
  await tester.binding.setSurfaceSize(taille);
  final cle = GlobalKey();
  final c = ProviderContainer();
  final base = c.read(baseDemoProvider);
  c.read(sessionProvider.notifier).connecter(base.utilisateurs['u-admin']!);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: RepaintBoundary(
      key: cle,
      child: MaterialApp(debugShowCheckedModeBanner: false, theme: ArzikiTheme.clair, home: page),
    ),
  ));
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.runAsync(() async {
    final b = cle.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await b.toImage(pixelRatio: 1);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/captures').createSync(recursive: true);
    File('build/captures/$nom.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    await _police('Poppins', ['assets/fonts/Poppins-SemiBold.ttf', 'assets/fonts/Poppins-Bold.ttf']);
    await _police('Inter', ['assets/fonts/Inter-Regular.otf', 'assets/fonts/Inter-SemiBold.otf', 'assets/fonts/Inter-Bold.otf']);
    await _police('MaterialIcons', ['/opt/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf']);
  });

  testWidgets('console : opérations', (tester) async {
    await _capturer(tester, const PageOperationsAdmin(), 'console_operations');
    await _capturer(tester, const PageOperationAdmin(id: 'op-analyse'), 'console_operation_analyse', taille: const Size(1280, 2000));
    await _capturer(tester, const PageOperationAdmin(id: 'op-btp'), 'console_operation_interets', taille: const Size(1280, 2000));
  });
}
