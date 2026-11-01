# ARZIKI · Cahier des charges pour Claude Code

> Ce fichier s'appelle `CLAUDE.md`. Placez-le à la racine du dossier du projet : Claude Code le lit automatiquement à chaque session.
> Propriétaire du projet : MOUSSA SALEY ZOUZOU OUMARA, fondateur de NEXUS International (Lomé, Togo), administrateur principal de l'application.
> Langue de l'application : français uniquement en V1. Monnaie : FCFA (XOF), sans décimales.

---

## 0. Comment travailler (règles pour Claude Code)

1. Lis ce fichier en entier avant d'écrire du code. En cas de doute sur une règle métier, **demande au propriétaire** au lieu d'inventer.
2. Avance **jalon par jalon** (section 15). À la fin de chaque jalon : lance les tests, lance `flutter analyze`, fais un commit Git clair, et résume ce qui marche et ce qui reste.
3. Ne mets **jamais** de clé secrète dans le code ou dans Git (clés CinetPay, clés de service Firebase, mots de passe du keystore). Utilise les variables d'environnement, les secrets GitHub et les secrets Firebase Functions.
4. Tant que les vraies clés ne sont pas fournies, fais tourner l'application en **mode démonstration** (section 13) avec des données fictives et un paiement simulé.
5. Toute logique sensible (rôles, montants, statuts, paiements, calcul des marges) s'exécute **côté serveur** (Cloud Functions). L'application mobile n'est qu'une interface : elle ne décide jamais seule d'un statut ou d'un montant.
6. Écris du code simple, commenté en français, lisible par un développeur débutant.
7. Les textes affichés à l'écran doivent être en français correct, avec tous les accents, sans abréviations obscures.

---

## 1. Le produit en une page

ARZIKI (« prospérité » en haoussa) est une application de **Commande Financée** au Togo. Signature : **« Ta commande. Notre financement. »**

- Une **entreprise** (PME ou fournisseur de grand compte) a une **commande ferme** d'un acheteur identifié, mais pas la trésorerie pour acheter la marchandise.
- ARZIKI vérifie la commande. L'achat est financé soit par un **fournisseur qui accepte d'être payé plus tard**, soit par le **Cercle Arziki**, un cercle **privé, sur invitation**, de membres et de partenaires qui choisissent les opérations auxquelles ils participent.
- À la livraison, l'acheteur final paie sur un **compte désigné** (compte séquestre du notaire ou compte de l'opération). Le fournisseur est réglé, puis la **marge nette est partagée** selon le contrat.
- Chaque opération est **encadrée par un notaire**, avec des **garanties** proportionnées au montant.
- Un onglet **Services**, opéré par NEXUS International, vend des prestations de montage de dossiers (revenus réguliers).
- Plus tard (V2) : **ARZIKI Carnet**, un petit outil de gestion par abonnement pour les commerçants.

### Les 6 règles légales non négociables (à coder en dur)
1. **L'application ne détient jamais l'argent des opérations.** Les fonds vont directement au fournisseur ou sur le compte séquestre du notaire. L'app enregistre seulement des **intentions de participation** et des **preuves de virement** déposées par les membres, validées par l'administrateur.
2. **Aucun rendement garanti.** Les mots « garanti », « sans risque », « rendement assuré », « taux d'intérêt », « prêt » sont **interdits** dans tous les textes de l'app. On parle de « marge visée », « participation aux marges », « opération commerciale ».
3. **Cercle fermé** : on n'entre dans le Cercle que par **invitation** (code d'invitation nominatif) puis validation de l'administrateur. Aucune opération n'est visible par un utilisateur non validé.
4. **Pas d'espèces au-delà de 5 000 000 FCFA** : les participations se font par virement ou mobile money, avec justificatif. L'app affiche cette règle.
5. **Origine des fonds et identité vérifiées** (KYC) avant toute participation.
6. Les frais encaissés par l'app (dossiers, cotisations, abonnements) passent par un **agrégateur de paiement agréé** (CinetPay), jamais par un compte personnel.

---

## 2. Rôles et accès

L'application a **un seul code**, avec des accès séparés selon le rôle. Le rôle est stocké dans les **custom claims Firebase Auth** (attribués uniquement par une Cloud Function appelée par un administrateur) et recopié dans `users/{uid}.role` pour l'affichage.

| Rôle | Qui | Accès |
|---|---|---|
| `super_admin` | Le propriétaire (Oumara) | Tout. Seul à pouvoir créer d'autres admins, changer les règles de partage, publier une opération, valider un membre. Connexion avec double facteur obligatoire. |
| `admin` | Collaborateur de confiance | Comme super_admin sauf : gestion des admins, paramètres financiers globaux, suppression. |
| `analyste` | Employé | Vérifie les dossiers et les opérations, prépare les fiches, ne peut pas publier ni valider de paiement. |
| `entreprise` | PME ou grande entreprise cliente | Dépose ses commandes, suit ses opérations, achète des services. Ne voit jamais les autres entreprises ni les membres. |
| `membre` | Investisseur du Cercle (niveau Membre) | Voit les opérations PME ouvertes, déclare sa participation, suit ses opérations et son historique. |
| `partenaire` | Investisseur niveau Partenaire | Comme membre + opérations Entreprises (grands comptes). |
| `partenaire_strategique` | Investisseur niveau Partenaire stratégique | Comme partenaire + peut être désigné chef de file d'un pool. |
| `fournisseur` | Fournisseur partenaire | Reçoit les bons de commande ARZIKI qui le concernent, indique s'il accepte le paiement différé, déclare la livraison. |
| `notaire` | Notaire partenaire | Lecture seule des opérations qui lui sont assignées, dépôt des actes signés, confirmation des fonds reçus en séquestre. |

Un même utilisateur peut avoir **un seul rôle actif** en V1. Si une personne est à la fois chef d'entreprise et investisseur, on lui crée deux comptes (deux numéros ou adresses e-mail) : c'est plus simple et plus sûr.

### Deux portes d'entrée
- **Application mobile Android (APK)** : pour tous les rôles clients (entreprise, membre, partenaire, fournisseur, notaire). Les admins peuvent aussi l'utiliser en mode lecture rapide.
- **Console d'administration web** (même code Flutter, compilé en web, hébergée sur Firebase Hosting à une adresse séparée, par exemple `admin.arziki...`) : réservée à `super_admin`, `admin`, `analyste`. Toute tentative d'accès par un autre rôle redirige vers une page « Accès refusé » et est enregistrée dans le journal d'audit.

---

## 3. Pile technique (imposée)

- **Flutter** (dernière version stable) + **Dart**, une seule base de code pour Android et web (console admin).
- Gestion d'état : **Riverpod**. Navigation : **go_router** avec garde de rôle sur chaque route.
- **Firebase** :
  - Authentication : téléphone (OTP SMS) pour les clients, e-mail + mot de passe + **double facteur** pour les admins.
  - Cloud Firestore (base de données). Région à choisir au plus près : `africa-south1` (Johannesburg) si disponible pour tous les services utilisés, sinon `europe-west1`. **Mettre la région dans un seul fichier de configuration** : l'autorité togolaise de protection des données envisage d'imposer un stockage local, il faut pouvoir migrer.
  - Cloud Storage (documents, photos).
  - Cloud Functions (TypeScript, Node LTS) pour toute la logique sensible.
  - Cloud Messaging (notifications).
  - App Check (Play Integrity) pour bloquer les clients non officiels.
  - Crashlytics et Analytics (sans données personnelles dans les événements).
- **Paiement** : CinetPay (couvre T-Money / Mixx by Yas, Flooz et cartes au Togo). Paquet Flutter `cinetpay` pour ouvrir le guichet, **mais la confirmation officielle d'un paiement vient uniquement du webhook `notify_url` traité par une Cloud Function**, jamais du retour côté téléphone. Prévoir une interface `PaymentProvider` pour pouvoir changer d'agrégateur (PayDunya, Hub2...) sans réécrire l'app.
- Génération de PDF (contrats, reçus, fiches d'opération) : côté serveur dans une Cloud Function, stockés dans Cloud Storage.
- Android : `minSdkVersion 23`, `targetSdkVersion 36` (exigence Google Play pour les nouvelles apps depuis le 31 août 2026), `compileSdk` à jour.
- Taille de l'APK : viser moins de 40 Mo. Fonctionner sur des téléphones d'entrée de gamme (2 Go de RAM) et en 3G.

---

## 4. Identité visuelle

- Couleurs : **orange `#F28C28`** (actions principales), **vert `#1E8E4E`** (succès, confiance, en-têtes), **jaune `#F7C51E`** (mises en avant, badges), **blanc `#FFFFFF`** (fonds). Textes : gris foncé `#1D2733`. Erreurs : rouge `#C0392B`.
- Créer un fichier `lib/theme/arziki_theme.dart` avec toutes les couleurs, tailles et styles. Aucune couleur codée ailleurs.
- Police lisible (par exemple Poppins pour les titres, Inter pour le texte), tailles généreuses (texte de base 16).
- Logo : un fichier provisoire `assets/logo/arziki_logo.png` ; le vrai logo sera fourni plus tard. Prévoir l'icône d'application (adaptive icon) et l'écran de démarrage avec `flutter_launcher_icons` et `flutter_native_splash`.
- Images d'illustration : dossier `assets/images/` (une banque d'images togolaises sera fournie). En attendant, des aplats de couleur, jamais d'images libres trouvées au hasard.
- Ton des textes : simple, chaleureux, respectueux (vouvoiement), phrases courtes.

---

## 5. Parcours utilisateurs

### 5.1 Premier lancement (tous)
1. Écran de démarrage, puis 3 écrans de présentation (Commande Financée, Cercle Arziki, notaire), puis choix : « Je suis une entreprise » / « J'ai un code d'invitation au Cercle » / « Je suis fournisseur » / « Je suis notaire ».
2. Acceptation obligatoire des **conditions d'utilisation** et de la **politique de confidentialité** (case à cocher non pré-cochée, date et version enregistrées).
3. Inscription par numéro de téléphone (+228 par défaut, autres pays UEMOA possibles) et code SMS.
4. Profil de base, puis **vérification d'identité** (section 7).
5. Compte en statut `en_attente` jusqu'à validation par un admin. L'utilisateur voit un écran « Votre compte est en cours de vérification » avec la liste des pièces manquantes.

### 5.2 Entreprise
- **Tableau de bord** : opérations en cours (avec étape), demandes en attente, services achetés, notifications.
- **Nouvelle demande de Commande Financée** (formulaire en plusieurs étapes, brouillon sauvegardé automatiquement) :
  1. L'acheteur final : raison sociale, RCCM si connu, contact, secteur.
  2. La commande : description, quantité, prix de vente total, date de livraison, délai de paiement promis par l'acheteur, **bon de commande ou contrat** (photo ou PDF obligatoire).
  3. Le fournisseur : nom, contact, devis ou facture pro forma (obligatoire), conditions de paiement proposées.
  4. Les coûts : prix d'achat, transport, autres frais. L'app **calcule automatiquement** la marge brute et la marge nette prévisionnelles et affiche un avertissement si la marge nette est inférieure à 8 %.
  5. Les garanties disponibles (section 8) : l'app affiche celles qui seront exigées selon le montant.
  6. Récapitulatif, engagement sur l'honneur, envoi.
- **Suivi d'une opération** : frise des étapes (section 6), documents, messages avec ARZIKI, montant attendu.
- **Services** : catalogue, commande, paiement de l'acompte de 50 %, suivi, téléchargement du livrable, paiement du solde.
- **Mon entreprise** : RCCM, NIF, statuts, dirigeants, comptes, documents. Ces pièces servent pour toutes les demandes.

### 5.3 Membre / Partenaire du Cercle
- **Opérations ouvertes** : cartes avec secteur, montant total, montant déjà réuni (jauge), durée prévue, marge visée, part prévue pour les investisseurs, niveau de garanties, places restantes, date limite. Filtres par secteur, durée, montant. Un membre ne voit que les opérations PME ; un partenaire voit aussi les opérations Entreprises.
- **Fiche d'une opération** : résumé en langage simple, acheteur (nom affiché seulement si l'admin l'autorise, sinon « grand compte du secteur X »), fournisseur, calendrier, répartition prévue de la marge, garanties prises, notaire, **avertissement de risque** obligatoire en haut et en bas.
- **Je participe** : saisie du montant (minimum selon le niveau, maximum selon les plafonds), lecture du contrat de participation (PDF), case « J'ai lu et je comprends que je peux perdre tout ou partie de ma mise », validation par code PIN. Résultat : une **intention de participation** au statut `en_attente_versement`, avec les **instructions de versement** (compte séquestre du notaire ou compte du fournisseur, référence unique à indiquer).
- **Déposer la preuve de versement** (photo ou PDF). L'admin ou le notaire confirme : statut `versement_confirme`.
- **Mes opérations** : en cours, terminées, en retard, avec ce qui a été versé, ce qui est attendu et ce qui a été reçu.
- **Mon historique et mes documents** : contrats, rapports mensuels, attestations de fin d'opération.
- **Ma cotisation** : statut et paiement de la cotisation annuelle via CinetPay.
- **Parrainer** : demander à l'admin un code d'invitation pour une personne (l'admin décide).

### 5.4 Fournisseur
- Liste des bons de commande ARZIKI qui le concernent.
- Pour chaque bon : accepter, refuser, proposer un **paiement différé** (30, 45, 60 ou 90 jours) ou demander un paiement comptant.
- Déclarer la livraison (photos, bordereau signé), voir quand et combien il sera réglé.

### 5.5 Notaire
- Opérations assignées, pièces du dossier, garanties demandées.
- Dépôt des actes signés (convention-cadre, contrat de participation, actes de garantie).
- Confirmation des fonds reçus en séquestre, par participant et au total.
- Confirmation des décaissements (paiement du fournisseur, partage final).

### 5.6 Administrateur (console web + accès mobile)
- **Tableau de bord** : opérations par statut, capital engagé, retards, alertes de concentration, frais de dossier du mois, cotisations, nouveaux comptes à valider.
- **Comptes** : liste, recherche, validation KYC, changement de rôle et de niveau, suspension, réinitialisation. Création des **codes d'invitation** (nominatifs, à usage unique, avec date d'expiration).
- **Demandes de Commande Financée** : grille de vérification (section 9), notes internes, décision (accepter, refuser avec motif, demander des pièces), choix du format (PME ou Entreprises), choix du mode de financement (paiement différé ou Cercle), affectation du notaire et de l'analyste.
- **Publication d'une opération** au Cercle : paramètres (montant à réunir, minimum et maximum par participant, date limite, répartition de la marge), aperçu de la fiche telle que la verront les membres, puis publication. Seul `super_admin` ou `admin` peut publier.
- **Suivi des versements** : rapprochement des preuves, confirmation, relances automatiques.
- **Clôture d'une opération** : saisie du montant réellement encaissé, des frais réels ; la Cloud Function calcule la marge nette réelle et la part de chacun ; génération des attestations ; le notaire confirme les paiements.
- **Gestion des incidents** : retard, litige, défaut ; journal des actions ; communication aux participants.
- **Services** : commandes reçues, attribution, livraison du dossier, facturation.
- **Paramètres** (super_admin) : barèmes de frais, parts de marge par défaut, seuils de garanties, plafonds, textes légaux et leur version, comptes séquestres.
- **Rapports** : rapport mensuel aux membres (généré en PDF), export CSV des opérations et des paiements, tableau de bord des indicateurs (section 12).
- **Journal d'audit** : chaque action sensible (connexion admin, changement de rôle, publication, validation de versement, clôture, modification de paramètre) avec qui, quand, quoi, avant et après. Le journal n'est **jamais modifiable**, même par le super_admin.

---

## 6. Cycle de vie d'une opération (machine à états)

Les statuts ne changent **que** par une Cloud Function, qui vérifie le rôle de l'appelant et les conditions.

```
brouillon → soumise → en_verification → (refusee | pieces_demandees → en_verification)
en_verification → acceptee
acceptee → garanties_en_cours (actes chez le notaire)
garanties_en_cours → financement_ouvert (Cercle) | financement_fournisseur (paiement différé)
financement_ouvert → financement_complet (montant atteint et versements confirmés) | annulee (date limite dépassée, fonds restitués)
financement_complet | financement_fournisseur → achat_effectue → en_livraison → livree
livree → facturee → paiement_recu → partage_effectue → cloturee
à tout moment après acceptee : en_retard (paiement de l'acheteur en retard de plus de 15 jours), en_litige, en_defaut
```

- Chaque changement de statut crée un événement dans `operations/{id}/evenements`, envoie une notification aux personnes concernées et est inscrit au journal d'audit.
- Si une opération est `annulee` avant achat, les intentions de participation passent à `a_restituer` et l'admin suit la restitution par le notaire.

---

## 7. Vérification d'identité et origine des fonds (KYC)

- **Personne physique** : pièce d'identité recto-verso (CNI, passeport ou carte consulaire), selfie de contrôle, justificatif d'adresse, profession.
- **Entreprise** : RCCM, NIF, statuts, pièce d'identité du dirigeant, procès-verbal ou pouvoir du signataire si ce n'est pas le gérant.
- **Investisseur** : en plus, une déclaration d'origine des fonds (salaire, activité commerciale, épargne, vente d'un bien...), et pour les Partenaires, un justificatif bancaire récent.
- Les pièces sont stockées dans Cloud Storage, dans un dossier par utilisateur, accessibles seulement par l'utilisateur lui-même et les admins. Jamais de pièce d'identité dans Firestore en clair : seulement le chemin du fichier.
- Statuts KYC : `non_commence`, `en_cours`, `a_completer`, `valide`, `refuse`. Validation manuelle par un admin, avec date et nom du validateur.
- Re-vérification annuelle (rappel automatique 30 jours avant).

---

## 8. Garanties selon le montant (règle métier)

L'app propose automatiquement la liste des garanties attendues selon le montant de l'opération. Le notaire ajuste au cas par cas ; l'admin peut ajouter ou retirer une garantie en indiquant un motif. Les seuils sont **paramétrables** par le super_admin.

| Montant de l'opération | Garanties proposées | Forme de l'acte |
|---|---|---|
| Moins de 5 M FCFA | Bon de commande écrit, paiement sur compte désigné ; caution du dirigeant si l'historique est faible | Contrat signé, copie au notaire |
| 5 à 30 M FCFA | En plus : caution solidaire du dirigeant ; gage ou nantissement du stock ou du matériel | Contrat déposé chez le notaire |
| 30 à 100 M FCFA | En plus : cession de créance sur l'acheteur ou délégation de paiement ; nantissement du fonds de commerce ou d'un compte ; caution solidaire d'un tiers solvable | Acte notarié, nantissements inscrits au RCCM |
| Plus de 100 M FCFA | En plus : garantie foncière (hypothèque sur titre foncier, éventuellement d'un tiers garant) ; assurance de la marchandise | Acte notarié, hypothèque inscrite au livre foncier |

Pour chaque garantie, enregistrer : type, description, valeur estimée, propriétaire (entreprise, dirigeant ou tiers), pièces justificatives, statut (`demandee`, `fournie`, `acte_signe`, `inscrite`, `levee`), date. Un apport peut être **en espèces ou en nature** (marchandise, matériel) : dans ce cas, champ « valeur retenue après évaluation ».

Une opération ne peut pas passer à `financement_ouvert` ou `financement_fournisseur` tant que toutes les garanties obligatoires ne sont pas au statut `acte_signe` ou `inscrite`.

---

## 9. Grille de vérification d'une demande (analyste / admin)

Chaque point est coché avec un commentaire ; la décision est impossible tant que la grille n'est pas complète.
1. L'acheteur existe (RCCM, adresse, contact joint par téléphone par ARZIKI, pas par l'entreprise).
2. Le bon de commande est authentique (confirmé directement par l'acheteur).
3. Le fournisseur existe et le devis est cohérent avec les prix du marché.
4. La marge nette prévue est d'au moins 8 % après tous les frais.
5. Les délais de livraison et de paiement sont de 90 jours maximum (sauf dérogation super_admin).
6. Le dirigeant a été rencontré physiquement.
7. L'entreprise a un historique avec ARZIKI ou des références vérifiées.
8. Les garanties correspondent au montant (section 8).
9. Les plafonds de concentration sont respectés (section 10).
10. Note de risque : faible, moyen, élevé (élevé = refus sauf décision du super_admin).

---

## 10. Règles financières (paramétrables, valeurs par défaut)

- **Formats** :
  - PME : de 2 000 000 à 30 000 000 FCFA, partage de la marge nette par défaut : entreprise 45 %, investisseurs 30 %, ARZIKI 25 % ; frais de montage ARZIKI 100 000 FCFA.
  - Entreprises : de 30 000 000 à 300 000 000 FCFA, partage par défaut : ARZIKI 20 %, le reste entre entreprise et investisseurs selon le contrat ; frais de structuration ARZIKI 1 % du montant.
- **Participation minimale** : Membre 500 000 FCFA, Partenaire 10 000 000 FCFA, Partenaire stratégique 50 000 000 FCFA.
- **Plafonds** : une opération ne peut pas dépasser 20 % du capital total déclaré par le Cercle ; un même acheteur ne peut pas représenter plus de 25 % des opérations en cours ; un même secteur pas plus de 40 % ; la première année, 2 opérations Entreprises en cours au maximum. Alerte rouge sur le tableau de bord admin en cas de dépassement.
- **Cotisations annuelles** : Membre 50 000 FCFA, Partenaire 250 000 FCFA, Partenaire stratégique selon convention.
- **Calculs** (Cloud Function `calculerPartage`) : marge nette réelle = encaissement réel − prix d'achat − frais réels ; puis part ARZIKI, part entreprise, part investisseurs ; la part investisseurs est répartie **au prorata des versements confirmés**. Arrondi à l'unité inférieure, le reliquat d'arrondi va à la réserve de l'opération et apparaît dans le rapport. En cas de **perte**, elle est répartie selon le contrat (le moteur doit gérer une marge négative).
- Tous les montants sont stockés en **entiers** (FCFA), jamais en nombres à virgule.

---

## 11. Services (onglet secondaire, opéré par NEXUS International)

Catalogue paramétrable par l'admin, valeurs par défaut :

| Service | Frais de dossier | Commission de succès |
|---|---|---|
| Diagnostic express | 25 000 FCFA | aucune |
| Dossier PME clé en main | 150 000 à 300 000 FCFA (devis) | 2 % si financement obtenu |
| Projet structuré | 500 000 à 1 500 000 FCFA (devis) | 2 à 3 % |
| Grand projet avec arrangeur | provision de 2 à 5 M FCFA | 1 à 2 % |
| Banque et leasing au cas par cas | forfait sur devis | selon convention |

- Paiement : 50 % à la commande, 50 % à la livraison du dossier, via CinetPay, non remboursables (texte affiché avant paiement).
- Les services sont signés « opéré par NEXUS International » et n'apparaissent **pas** sur l'écran d'accueil, seulement dans l'onglet Services.
- Après un diagnostic, l'app demande : « Avez-vous une commande ferme ? » et propose, si oui, de créer une demande de Commande Financée.

---

## 12. Notifications, rapports et indicateurs

- **Notifications** (push + liste dans l'app ; SMS seulement pour les codes et les alertes critiques) : compte validé, pièce demandée, nouvelle opération ouverte (filtrée par niveau et préférences), versement confirmé, changement d'étape, retard, rapport mensuel disponible, cotisation à renouveler.
- **Rapport mensuel aux investisseurs** (PDF généré le 5 de chaque mois) : opérations en cours, terminées, retards, résultats, sans données personnelles des autres membres.
- **Indicateurs du tableau de bord admin** : nombre d'opérations par mois, volume financé, durée moyenne, marge nette moyenne, taux de défaut en montant (cible < 3 %), retards de plus de 30 jours (cible < 10 %), part en paiement différé fournisseur (cible ≥ 30 %), frais de dossier encaissés dans le mois (cible 1 600 000 FCFA), membres actifs, renouvellement des cotisations.

---

## 13. Modèle de données Firestore (à respecter, à compléter si besoin en demandant)

```
users/{uid}
  role, niveau (membre|partenaire|partenaire_strategique|null), statut (en_attente|actif|suspendu)
  nom, prenom, telephone, email, pays, ville, kycStatut, kycValideLe, kycValidePar
  cgVersionAcceptee, cgAccepteeLe, invitationCode, creeLe, majLe

entreprises/{entrepriseId}
  raisonSociale, rccm, nif, secteur, adresse, dirigeants[], proprietaireUid, documents{}, statut

invitations/{code}
  pourNom, pourTelephone, niveau, creePar, expireLe, utiliseLe, utilisePar

demandes/{demandeId}          (avant acceptation)
  entrepriseId, acheteur{}, commande{}, fournisseur{}, couts{}, margePrevue, documents{}, statut, grilleVerification{}, noteRisque

operations/{operationId}
  demandeId, format (pme|entreprises), modeFinancement (cercle|fournisseur_differe)
  montantVente, montantAchat, fraisPrevus, margeNettePrevue, partage{entreprise, investisseurs, arziki}
  montantAReunir, minParticipant, maxParticipant, dateLimite, montantConfirme
  garanties[] , notaireUid, analysteUid, statut, visibilite (membre|partenaire)
  dates{livraisonPrevue, paiementPrevu, ...}, resultat{encaisse, fraisReels, margeReelle, parts[]}
  operations/{operationId}/evenements/{eventId}
  operations/{operationId}/participations/{participationId}
      uid, montant, statut (en_attente_versement|versement_declare|versement_confirme|a_restituer|restitue|paye), preuveUrl, confirmePar, partFinale

paiements/{paiementId}        (uniquement frais, cotisations, services via CinetPay)
  uid, objet, objetId, montant, transactionId, statut (initie|accepte|refuse), recuUrl, creeLe

services_catalogue/{serviceId}, commandes_services/{commandeId}
notaires/{uid}, fournisseurs/{fournisseurId}
parametres/global             (barèmes, seuils, plafonds, textes légaux et versions)
audit/{logId}                 (écriture uniquement par Cloud Functions, jamais modifiable ni supprimable)
rapports/{rapportId}
```

### Règles de sécurité (à écrire et à tester avec l'émulateur)
- Par défaut, **tout est interdit**.
- Un utilisateur lit et met à jour **son** profil (sauf `role`, `niveau`, `statut`, `kycStatut` : lecture seule).
- Une entreprise lit ses demandes, ses opérations et leurs événements ; elle ne voit **jamais** les participations ni l'identité des investisseurs.
- Un membre lit les opérations dont `statut == financement_ouvert` et dont la `visibilite` correspond à son niveau, **seulement si** son compte est `actif` et son KYC `valide` ; il lit et crée **ses** participations (création limitée aux champs autorisés, statut forcé à `en_attente_versement`).
- Un fournisseur lit seulement les opérations où il est désigné. Un notaire seulement celles qui lui sont assignées.
- Les admins lisent tout ; les écritures sensibles passent par les Cloud Functions.
- Collections `audit`, `paiements` : aucune écriture côté client.
- Écrire des **tests des règles** (emulator suite) pour chaque rôle : ce qu'il peut faire et ce qu'il ne peut pas faire.

### Cloud Functions à créer (liste minimale)
`attribuerRole`, `validerKyc`, `creerInvitation`, `utiliserInvitation`, `soumettreDemande`, `deciderDemande`, `publierOperation`, `changerStatutOperation`, `creerParticipation`, `confirmerVersement`, `verifierPlafonds`, `calculerPartage`, `cloturerOperation`, `genererContratPdf`, `genererRapportMensuel` (planifiée), `relancesAutomatiques` (planifiée), `webhookCinetPay` (HTTP, vérifie la signature et le statut auprès de l'API CinetPay avant de marquer un paiement accepté), `ecrireAudit` (utilisée par toutes les autres).

---

## 14. Sécurité, confidentialité et conformité

- Loi togolaise n° 2019-014 sur la protection des données personnelles : la déclaration préalable du traitement auprès de l'**IPDCP** est à faire par le propriétaire avant le lancement public. L'app doit : recueillir un consentement explicite, afficher une politique de confidentialité claire, permettre à l'utilisateur de **télécharger ses données** et de **demander la suppression** de son compte (avec conservation légale des contrats et justificatifs pendant la durée imposée, indiquée dans la politique).
- Chiffrement : HTTPS partout ; données sensibles seulement dans Storage avec règles strictes ; aucune donnée personnelle dans les logs ou Analytics.
- Code PIN à 4 chiffres (ou empreinte) pour ouvrir l'app et pour valider toute participation.
- Déconnexion automatique après 15 minutes d'inactivité pour les admins.
- Captures d'écran bloquées sur les écrans de pièces d'identité et de contrats (FLAG_SECURE Android).
- Limitation des tentatives de connexion et des envois de SMS.
- Sauvegarde quotidienne automatique de Firestore (export planifié vers Cloud Storage).
- Les contrats signés dans l'app (signature électronique simple : case + code PIN + horodatage + empreinte du document) **complètent** l'acte notarié, ils ne le remplacent pas. Le Togo reconnaît la valeur juridique de l'écrit et de la signature électroniques sous conditions d'identification ; le notaire reste la référence.
- Textes légaux à intégrer (fournis par l'avocat du propriétaire, prévoir des fichiers modifiables) : conditions d'utilisation, politique de confidentialité, avertissement de risque, règlement du Cercle, convention-cadre (modèle), contrat de participation (modèle).

**Avertissement de risque type (à afficher sur chaque fiche d'opération et avant chaque participation) :**
« ARZIKI propose des participations à des opérations commerciales. Ce ne sont ni des prêts ni des placements garantis. Vous pouvez perdre tout ou partie de votre mise. Les marges indiquées sont des objectifs, pas des promesses. Ne participez qu'avec des sommes dont vous n'avez pas besoin à court terme. »

---

## 15. Jalons de développement (dans cet ordre)

Pour chaque jalon : code, tests, `flutter analyze` sans erreur, commit, court compte rendu.

1. **Socle** : projet Flutter, thème ARZIKI, navigation avec gardes de rôle, Firebase branché (avec émulateurs en local), mode démonstration, écran de démarrage et onboarding. *Critère : l'app démarre sur un émulateur Android et sur le web.*
2. **Comptes et accès** : inscription par téléphone, e-mail + double facteur pour admins, codes d'invitation, rôles par custom claims, écrans « en attente de validation », KYC avec dépôt de pièces, console admin de validation. *Critère : un super_admin crée une invitation, un membre s'inscrit avec, l'admin le valide, et chaque rôle ne voit que ses écrans (tests de règles qui passent).*
3. **Demandes de Commande Financée** : formulaire entreprise en étapes, calcul de marge, dépôt de pièces, grille de vérification, décision. *Critère : une demande va de brouillon à acceptée ou refusée, avec journal d'audit.*
4. **Garanties et notaire** : liste automatique selon le montant, suivi des actes, espace notaire. *Critère : impossible d'ouvrir le financement sans garanties signées.*
5. **Cercle et participations** : publication, fiches d'opérations, participation, instructions de versement, preuves, confirmation, plafonds. *Critère : trois membres participent, l'opération passe à financement_complet, les plafonds bloquent un dépassement.*
6. **Fournisseurs, livraison et clôture** : paiement différé, livraison, encaissement, calcul du partage (y compris en cas de perte), attestations PDF. *Critère : tests unitaires du calcul avec au moins 10 cas, dont marge négative et arrondis.*
7. **Paiements CinetPay** : cotisations et services, webhook, reçus PDF, mode simulé. *Critère : un paiement simulé accepté et un refusé sont correctement enregistrés ; aucun statut « accepté » sans webhook.*
8. **Services** : catalogue, commande, acompte et solde, livraison du dossier.
9. **Notifications, rapports et tableau de bord admin** : push, rapport mensuel PDF, indicateurs, exports CSV.
10. **Finitions et sortie** : textes légaux, accessibilité, performances sur téléphone d'entrée de gamme, icône et logo, **APK signé**, console admin déployée sur Firebase Hosting.

---

## 16. Construire l'APK

### Option A : sur l'ordinateur du propriétaire
1. Installer Flutter, Android Studio (SDK Android) et Java 17.
2. Créer une clé de signature une seule fois :
   `keytool -genkey -v -keystore arziki-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias arziki`
   **Conserver ce fichier et ses mots de passe en lieu sûr (deux copies hors ligne). Sans eux, impossible de mettre à jour l'application.**
3. Créer `android/key.properties` (jamais dans Git) avec les chemins et mots de passe.
4. Commandes :
   - APK de test : `flutter build apk --release --split-per-abi` (fichiers dans `build/app/outputs/flutter-apk/`)
   - Pour Google Play plus tard : `flutter build appbundle --release`

### Option B : construction automatique dans le cloud (GitHub Actions)
Créer `.github/workflows/build-apk.yml` qui, à chaque push sur la branche `main` :
- installe Java 17 et Flutter stable,
- recrée le keystore à partir du secret GitHub `KEYSTORE_BASE64` et écrit `key.properties` à partir des secrets `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`,
- recrée `google-services.json` à partir du secret `GOOGLE_SERVICES_JSON`,
- lance `flutter pub get`, `flutter analyze`, `flutter test`, puis `flutter build apk --release --split-per-abi`,
- publie les APK comme artefact téléchargeable.
Le propriétaire télécharge l'APK depuis l'onglet « Actions » de GitHub et l'installe sur son téléphone (autoriser « sources inconnues »).

### Distribution
- Phase pilote : APK partagé directement aux membres et entreprises invités (lien privé), ou piste de test interne Google Play.
- Phase publique : Google Play (compte développeur, fiche, politique de confidentialité en ligne, questionnaire sur la sécurité des données, cible API 36).

---

## 17. Mode démonstration et données de test

- Variable `APP_MODE=demo|prod`. En `demo` : bandeau jaune « Démonstration », paiements simulés, SMS simulés (code 123456), jeux de données fictifs.
- Données fictives : 1 super_admin, 1 analyste, 3 entreprises (pharmacie, BTP, fournisseur d'une mine), 6 membres, 2 partenaires, 2 fournisseurs, 1 notaire, 8 opérations à des étapes différentes, dont une en retard et une avec perte.
- Script `tool/seed_demo.dart` pour remplir l'émulateur.

---

## 18. Ce que le propriétaire devra fournir (Claude Code doit le demander au bon moment, pas avant)

1. Le projet Firebase (ou l'autorisation d'en créer un) et le fichier `google-services.json`.
2. Les identifiants CinetPay (API key, site ID) après ouverture du compte marchand (RCCM, NIF, pièce du représentant, compte bancaire togolais).
3. Le logo définitif et la banque d'images.
4. Les textes légaux validés par l'avocat, les coordonnées du notaire partenaire et des comptes séquestres.
5. Le nom de domaine pour la console admin.
6. Les adresses e-mail des administrateurs.

## 19. Interdits

- Pas de fonction « portefeuille » ni de solde stocké dans l'app. Pas de virement entre utilisateurs.
- Pas de calcul ou d'affichage d'un « taux d'intérêt » ou d'un « rendement annuel garanti ».
- Pas d'inscription au Cercle sans code d'invitation.
- Pas de suppression d'une opération ou d'une participation : seulement annulation tracée.
- Pas de clé, mot de passe ou fichier `google-services.json`, `key.properties`, `*.jks` dans Git (`.gitignore` à créer dès le jalon 1).
- Pas de bibliothèque abandonnée ou non maintenue sans en parler au propriétaire.

---

## 20. Premier message à envoyer à Claude Code

> « Lis entièrement CLAUDE.md. Résume-moi en 10 lignes ce que tu as compris du produit et des règles non négociables, liste les questions qui bloquent le jalon 1, puis commence le jalon 1 en mode démonstration. »

---

## 21. Décisions du propriétaire (à respecter, elles complètent les sections précédentes)

### 21.1 Accès des investisseurs (décision du 31 octobre 2026)

Le propriétaire ne crée pas lui-même les comptes des investisseurs : **chacun s'inscrit lui-même dans l'application**. Deux portes d'entrée coexistent, toutes deux sous le contrôle de l'administrateur :

1. **Investisseurs privés connus du propriétaire : invitation.** Depuis la console (« Investisseurs privés »), un `super_admin` ou un `admin` crée un **code nominatif** (`ARZ-XXXX-XXXX`), à usage unique, lié au **numéro de téléphone** de la personne, avec une date d'expiration (7, 30 ou 90 jours) et le **niveau** décidé par l'administrateur (membre, partenaire, partenaire stratégique). La console fournit un message prêt à envoyer (WhatsApp, SMS). La personne installe l'application, choisit « J'ai un code d'invitation au Cercle », crée son compte avec ce code et ce numéro, puis dépose ses pièces KYC. Son compte devient actif quand l'administrateur valide son identité.
2. **Investisseurs qui découvrent ARZIKI seuls : candidature.** Ils choisissent « Je souhaite rejoindre le Cercle » et créent un compte au rôle `candidat_cercle`. Ce rôle **ne voit aucune opération**. Ils déposent leurs pièces KYC et une candidature (niveau souhaité, tranche envisagée, source). L'administrateur décide : **admettre** (en fixant le niveau) ou **ne pas retenir** (motif obligatoire). Le compte n'est actif que si l'identité est validée **et** la candidature admise.

La règle légale n° 3 reste entière : **aucune opération n'est visible par une personne non admise et non vérifiée**, l'entrée dans le Cercle est toujours une décision de l'administrateur, tracée au journal d'audit. L'interdit « Pas d'inscription au Cercle sans code d'invitation » (section 19) se lit désormais : *pas d'entrée dans le Cercle sans invitation ou admission par un administrateur*.

**Plafond de taille du Cercle.** Dans l'UMOA, une offre diffusée au-delà d'un cercle de **100 personnes** sans lien juridique entre elles est réputée faire appel public à l'épargne (visa de l'AMF-UMOA). L'application affiche une alerte dès 90 personnes et **bloque toute admission au-delà de 100**. Ces seuils sont à confirmer par l'avocat du propriétaire. Le rôle `candidat_cercle` et cette limite doivent figurer dans les Cloud Functions et les règles Firestore.

### 21.2 Comptes de l'administration

- Le compte `super_admin` du propriétaire n'est **jamais** créé depuis l'application : il est créé une seule fois par le script `functions/scripts/creer-super-admin.ts` (custom claim posé avec les droits du projet Firebase).
- Chaque collaborateur a **son propre compte** (`admin` ou `analyste`), créé uniquement par le `super_admin` depuis la page « Équipe » ; il reçoit un lien pour choisir son mot de passe et active son double facteur. Personne ne modifie son propre rôle ; seul le `super_admin` touche aux comptes d'administration.
- Les administrateurs ne se connectent jamais par SMS : uniquement e-mail + mot de passe + double facteur.
- **Console en mode démonstration** (décision du 31 octobre 2026) : aucun compte d'administration de démonstration, aucun identifiant affiché à l'écran ni sur le site. Seul le super administrateur entre, avec son identifiant (`oumara`), son mot de passe et le code à 6 chiffres de son application d'authentification (TOTP). Le dépôt ne contient que l'empreinte PBKDF2 du mot de passe et la clé TOTP chiffrée par ce mot de passe (`lib/auth/acces_admin.dart`) ; ne jamais y écrire le mot de passe ni la clé en clair. Blocage de 15 minutes après 5 erreurs. Pour changer le mot de passe, générer de nouvelles valeurs (sel, empreinte, clé chiffrée) et les remettre au propriétaire seulement.

### 21.3 Supports de communication

Deux affiches fournies portent la mention « Croissance garantie ». Elle est contraire à la règle légale n° 2 et ne doit apparaître **ni dans l'application ni dans ses fiches Google Play**. Un test automatique (`test/textes_test.dart`) bloque ces formules dans le code.

**Pas de drapeau du Togo** (décision du propriétaire) : aucune image, icône ou illustration de l'application, de la console ou des fiches Google Play ne doit montrer le drapeau togolais. Plusieurs affiches fournies en contiennent : n'en reprendre que des parties sans drapeau.

### 21.4 Compléments au modèle de données (section 13)

```
candidatures/{uid}     uid, nomComplet, telephone, niveauSouhaite, trancheEnvisagee,
                       commentNousConnu, soumiseLe, statut (soumise|admise|refusee),
                       decidePar, decideLe, motif
kyc/{uid}              pieces{code: chemin Cloud Storage}, origineFonds, soumisLe
invitations/{code}     + note, creeLe, annuleeLe
operations/{id}        + entrepriseUid, fournisseurUids[] (copies des identifiants,
                       nécessaires aux règles de sécurité)
users/{uid}.role       + valeur candidat_cercle
```

Cloud Functions ajoutées : `inscrire` (crée le profil après la vérification du numéro par SMS et consomme l'invitation), `annulerInvitation`, `deposerCandidature`, `deciderCandidature`, `soumettreKyc`, `demanderComplementKyc`, `changerStatutCompte`, `creerCompteEquipe`, `signalerAccesRefuse`. Les actions d'administration exigent le double facteur dans le jeton (`firebase.sign_in_second_factor`), côté fonctions comme côté règles.

---

## 22. Collaboration avec le propriétaire (règles permanentes, décision du 1er novembre 2026)

Le propriétaire n'est pas développeur. Claude Code travaille comme un chef de projet et développeur senior qui livre un produit fini à un client non technique.

1. **Ces règles s'appliquent à toutes les sessions.**
2. **Décider seul de tout ce qui est technique** (bibliothèques, architecture, structure du code, corrections). Ne poser une question que pour une décision d'affaires (prix, textes légaux, règles du Cercle, ce qu'un client doit voir), en français simple, avec 2 ou 3 choix et une recommandation.
3. **Ne jamais demander au propriétaire de taper des commandes, de modifier du code ou de configurer quelque chose lui-même.** Si une action de sa part est indispensable (créer un compte, fournir une clé, déposer une image), l'expliquer étape par étape, comme à un débutant, avec ce qu'il doit voir à l'écran et des liens directs.
4. **Viser le niveau d'une application financière professionnelle** (banque mobile, fintech reconnue) : design soigné, navigation claire, textes impeccables, aucune page vide, aucun bouton qui ne mène nulle part.
5. **Vérifier son propre travail avant de le montrer** : lancer l'application, parcourir chaque écran pour chaque rôle, prendre des captures, les relire comme un client exigeant (alignements, couleurs, fautes, textes coupés, images floues, écrans vides), corriger puis recommencer jusqu'à ce que ce soit irréprochable ; vérifier qu'aucun mot interdit n'apparaît (garanti, sans risque, rendement assuré, taux d'intérêt, prêt).
6. **Terminer chaque étape par un compte rendu simple**, sans jargon : ce qui a été fait (5 à 10 points), les captures des nouveaux écrans, le lien de la page Vercel et l'endroit où télécharger le nouvel APK, ce qu'il faut tester sur le téléphone, ce qui reste à faire.
7. **Ne pas s'arrêter à mi-chemin** : découper soi-même les tâches longues et enchaîner ; en cas d'interruption, reprendre exactement là où le travail s'était arrêté.
8. **Avant de dire « c'est fini »** : tests au vert, aucune erreur d'analyse, fusion dans `main`, nouvel APK construit, page Vercel à jour.

### 22.1 Livraison (comment le produit arrive au propriétaire)

- GitHub Actions (`.github/workflows/livraison.yml`) teste, construit l'APK et les versions web, puis publie la branche `livraison`.
- Vercel (projet `arziki`, équipe `nexusinternational25-engs-projects`) affiche la branche `livraison` : https://arziki-rosy.vercel.app (page d'accueil, `ARZIKI.apk`, `/app/`, `/console/`).
- Publication en production : le projet Vercel ignore tout ce qui ne vient pas de la branche `livraison`. Après chaque livraison réussie, publier la branche `livraison` en production (outil Vercel « create_deployment », `gitSource` sur `livraison`, `target: production`), puis vérifier https://arziki-rosy.vercel.app.
- Lien direct et permanent de l'APK : https://github.com/nexusinternational25-eng/Arziki-/releases/latest/download/ARZIKI.apk
- Banque d'images : `assets/images` (27 photos, liste dans `lib/core/images.dart`). La photo n° 13 du document fourni est écartée (drapeau), la n° 16 est recadrée.
- Logo principal : le « A » au chariot (`assets/logo/arziki_logo.png`, version blanche pour les fonds verts et le mode sombre, symbole seul pour l'icône).

### 22.2 Nom du propriétaire et textes légaux (décision du 1er novembre 2026)

- Le nom du propriétaire n'apparaît **nulle part** dans l'application, la console ni le site : on écrit seulement « CEO de NEXUS International ». Le test `test/refonte_test.dart` le vérifie.
- Les textes légaux sont publiés en **version 1.0** (1er novembre 2026), sans mention « provisoire » ni « en attente de validation ». Toute révision par l'avocat donnera une nouvelle version (1.1, 2.0...), que les utilisateurs accepteront de nouveau.

### 22.3 Vérification du numéro : WhatsApp d'abord, SMS en secours (décision du 1er novembre 2026)

- **Voie principale** : le client appuie sur « Vérifier avec WhatsApp ». WhatsApp s'ouvre avec un message déjà écrit (contenant un code), adressé au numéro WhatsApp Business d'ARZIKI ; le client l'envoie. Le webhook `webhookWhatsapp` (signature Meta vérifiée) confirme la vérification si le numéro de l'expéditeur et le code correspondent. Recevoir un message ne coûte rien à ARZIKI.
- **Secours** : code à 6 chiffres envoyé par WhatsApp (modèle d'authentification `arziki_code`, en français), puis par SMS (Firebase Authentication) en dernier recours.
- Fonctions : `demarrerVerification`, `finaliserVerification` (renvoie un jeton de connexion Firebase avec la revendication `telephone_verifie`), `webhookWhatsapp`. Logique pure et testée dans `functions/src/whatsapp.ts`. Collections `verifications` et `limites_verification` : aucun accès depuis l'application.
- Règles : code haché, valable 10 minutes, 5 essais, 5 demandes par heure et par numéro, une vérification ne sert qu'une fois.
- Le client ne peut pas être débité du coût d'un message reçu : le coût (faible) est couvert par les cotisations et frais de dossier. Au quotidien, l'application s'ouvre avec le code PIN ou l'empreinte (gratuit).
- Réglages (jamais dans Git) : secrets Firebase `WHATSAPP_JETON`, `WHATSAPP_SECRET_APP`, `WHATSAPP_JETON_WEBHOOK` ; paramètres `WHATSAPP_ID_NUMERO`, `WHATSAPP_NUMERO_ARZIKI`. Tant qu'ils ne sont pas remplis, l'application propose le SMS.
- À fournir par le propriétaire : une puce dédiée à ARZIKI (non utilisée dans l'application WhatsApp ordinaire) et la vérification de NEXUS International chez Meta (guide : `docs/mise_en_service.md`).
- Administrateurs : jamais de WhatsApp ni de SMS, seulement e-mail, mot de passe et double facteur.
