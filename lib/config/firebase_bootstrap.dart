// Démarrage de Firebase.
//
// - Mode démonstration : Firebase n'est pas démarré, tout fonctionne hors ligne.
// - Mode production : Firebase démarre avec les options générées par
//   `flutterfire configure` (fichier lib/config/firebase_options.dart, à créer
//   quand le projet Firebase sera fourni) et, si USE_EMULATORS=true,
//   se branche sur les émulateurs locaux.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app_config.dart';
import 'region.dart';

/// Options Firebase, transmises à la compilation tant que firebase_options.dart n'existe pas :
/// --dart-define=FIREBASE_API_KEY=... --dart-define=FIREBASE_APP_ID=... etc.
FirebaseOptions? _optionsDepuisEnvironnement() {
  const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  const appId = String.fromEnvironment('FIREBASE_APP_ID');
  const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  const senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  if (apiKey.isEmpty || appId.isEmpty || projectId.isEmpty) return null;
  return const FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    projectId: projectId,
    messagingSenderId: senderId,
    storageBucket: '$projectId.appspot.com',
  );
}

Future<void> demarrerFirebase() async {
  if (AppConfig.estDemo) return;

  final options = _optionsDepuisEnvironnement();
  if (options == null) {
    throw StateError(
      'Mode production : options Firebase absentes. Lancez `flutterfire configure` '
      'ou passez FIREBASE_API_KEY, FIREBASE_APP_ID et FIREBASE_PROJECT_ID.',
    );
  }
  await Firebase.initializeApp(options: options);

  if (AppConfig.utiliserEmulateurs) {
    const hote = AppConfig.hoteEmulateurs;
    await FirebaseAuth.instance.useAuthEmulator(hote, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(hote, 8080);
    FirebaseFunctions.instanceFor(region: regionFirebase).useFunctionsEmulator(hote, 5001);
  }
}
