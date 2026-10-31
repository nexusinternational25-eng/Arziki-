// Région Firebase (Cloud Functions, Firestore, Storage).
//
// La valeur vient d'un seul fichier : config/firebase.json.
// L'application la reçoit à la compilation :
//   flutter run --dart-define-from-file=config/firebase.json
// Les Cloud Functions lisent le même fichier (functions/src/region.ts).
// Pour migrer (par exemple vers un stockage au Togo), on change ce fichier et rien d'autre.

const String regionFirebase =
    String.fromEnvironment('FIREBASE_REGION', defaultValue: 'africa-south1');
