# ARZIKI

**Ta commande. Notre financement.**

Application de Commande Financée au Togo, éditée par NEXUS International (Lomé).
Le cahier des charges complet est dans [`CLAUDE.md`](CLAUDE.md).

- Application mobile Android : entreprises, membres et partenaires du Cercle, fournisseurs, notaires.
- Console d'administration web : super administrateur, administrateurs, analystes.
- Un seul code Flutter pour les deux.

## Lancer l'application

Prérequis : Flutter stable (3.47 ou plus récent), Java 17, Android Studio pour l'émulateur Android.

```bash
flutter pub get

# Application mobile (émulateur ou téléphone branché), mode démonstration
flutter run --dart-define-from-file=config/firebase.json

# Console d'administration dans le navigateur
flutter run -d chrome --dart-define-from-file=config/firebase.json

# Application mobile dans le navigateur (pratique pour une démonstration sans téléphone)
flutter run -d chrome --dart-define-from-file=config/firebase.json --dart-define=CIBLE=mobile
```

Vérifications avant chaque commit :

```bash
flutter analyze
flutter test
```

## Mode démonstration

Tant que le projet Firebase n'est pas fourni, l'application tourne avec des données fictives
(bandeau jaune « Démonstration »). Le code SMS est toujours `123456`.

| Profil | Connexion |
|---|---|
| Super administrateur | `admin@arziki.demo` / `demo1234`, puis code `123456` |
| Administrateur | `afi@arziki.demo` / `demo1234` |
| Analyste | `analyste@arziki.demo` / `demo1234` |
| Membre du Cercle | téléphone `90 00 00 21` |
| Partenaire | téléphone `90 00 00 31` |
| Entreprise | téléphone `90 00 00 11` |
| Fournisseur | téléphone `90 00 00 41` |
| Notaire | téléphone `90 00 00 51` |
| Candidat au Cercle | téléphone `90 00 00 61` |
| Investisseur privé invité | code `ARZ-DEMO-2026` avec le `90 00 00 71` |

## Qui a accès à quoi

Voir `CLAUDE.md`, sections 2 et 21. En résumé :

- **Le super administrateur** (le fondateur) a tous les droits, crée les comptes de son équipe
  et invite les investisseurs privés qu'il connaît.
- **L'équipe** (administrateurs, analystes) a chacun son propre compte, avec double facteur.
- **Les investisseurs** s'inscrivent eux-mêmes : avec un code d'invitation nominatif s'ils ont été
  invités, ou en déposant une candidature sinon. Personne n'entre dans le Cercle sans décision
  d'un administrateur.

## Organisation du code

```
lib/
  config/        mode (demo/prod), cible (mobile/console), région Firebase
  theme/         charte ARZIKI (seul endroit où sont définies les couleurs)
  core/          rôles, pièces KYC, textes légaux et vocabulaire interdit
  models/        utilisateur, invitation, candidature, journal d'audit
  auth/          authentification et session
  comptes/       gestion des accès (contrat commun démo / Firebase)
  demo/          base fictive en mémoire
  router/        navigation et garde de rôle
  ecrans/        écrans, rangés par espace
config/firebase.json   région Firebase, un seul fichier
functions/       Cloud Functions (TypeScript)
firestore.rules, storage.rules
```

## Secrets

Aucun secret dans Git : `google-services.json`, `android/key.properties`, `*.jks`, clés CinetPay
et comptes de service sont exclus par `.gitignore`. Voir `CLAUDE.md`, section 16, pour la clé de
signature de l'APK.
