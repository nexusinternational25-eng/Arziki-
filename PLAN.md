# PLAN : ARZIKI opérationnelle et refonte d'amanexus.com

Mission reçue le 21 novembre 2026 (fichier `PROMPT_CLAUDE_CODE_ARZIKI_AMANEXUS.md`).
Une case n'est cochée qu'après un test réel. Les décisions attendues du propriétaire sont marquées **[DÉCISION]**.

## État des lieux (21 novembre 2026)

- **Pile ARZIKI** : Flutter (application Android et web, une seule base de code), Riverpod, go_router ; serveur Firebase (authentification, Firestore, Storage, Cloud Functions en TypeScript). Pile saine : on la garde. Elle est compatible avec LWS : l'application web se compile en fichiers statiques, le serveur reste chez Firebase.
- **Ce qui marche pour de vrai** : comptes et rôles, invitations nominatives, KYC, journal d'audit, vérification du numéro (WhatsApp puis SMS), pays (Togo ouvert, autres à venir). Tout cela est écrit côté serveur et couvert par des tests (règles d'accès sur émulateur), mais **n'a jamais été branché à un vrai projet Firebase**.
- **Ce qui est fictif** : toute l'application tourne en mode démonstration. Les opérations, les demandes, les services, les paiements et les notifications sont des données en mémoire ; le paiement est simulé ; aucun e-mail ne part ; aucun PDF n'est produit.
- **Ce qui manque** : projet Firebase réel, opérations et services côté serveur, agrégateur de paiement, e-mails, projets de contrats PDF, anglais, hébergement sur LWS.
- **Site amanexus.com actuel** : application React déjà compilée (on ne peut pas la modifier proprement, il faut la refaire), un formulaire PHP, couleurs or et beige. Il affiche des chiffres à confirmer (« taux de réussite 94 % », « 100 milliards FCFA recouvrés ») et une page « Témoignages ».
- **Fichiers manquants** : `services.html` et `arziki.html` ne sont pas dans l'archive reçue (elle ne contient que le site actuel).
- **Déjà disponible** : une version Next.js du Desk Algérie-Niger (branche `ccr-b4432f57-wqppqd`), dont on peut reprendre les textes pour une page statique.

## Écarts entre la nouvelle mission et le cahier des charges actuel (CLAUDE.md)

Ces points touchent les règles R1 à R8 : rien n'est codé avant la décision du propriétaire.

1. **Décidé le 21 novembre : vente à terme.** Modèle juridique (R2) : le cahier des charges prévoit une participation aux marges, partagées à la clôture et pouvant être négatives. La mission impose une vente à terme avec une majoration fixe en FCFA. Cela change le calcul, les écrans des partenaires, les contrats et le vocabulaire.
2. **Décidé le 21 novembre : invitation seule.** Accès des partenaires (R3) : la mission veut uniquement l'invitation nominative, avec un plafond de 50 par défaut et un blocage à 99. Aujourd'hui, il existe aussi la candidature spontanée au Cercle, le plafond est de 100, et les pages publiques présentent le Cercle et un simulateur de marge.
3. **[DÉCISION] Agrégateur de paiement** : comparer FedaPay, CinetPay et PayDunya, puis attendre le choix du propriétaire (étape 4).
4. **Décidé le 21 novembre : retirés.** Chiffres du site actuel (94 %, 100 milliards FCFA, témoignages) : les garder seulement s'ils sont exacts et prouvables.
5. **[DÉCISION] Services payants à activer** : Firebase en formule Blaze, service d'envoi d'e-mails. Rien n'est souscrit sans l'accord du propriétaire.
6. Langues : la mission demande le français et l'anglais (le cahier des charges disait français seul en V1). Pris en compte.
7. Couleurs : la mission fixe orange `#F57C00`, vert `#1B9E4B`, jaune `#FFC300`. Le thème de l'application sera aligné.
8. Contacts : e-mail principal nexusinternational25@gmail.com, copie operation@amanexus.com, WhatsApp +228 91 97 80 80.

## 1. État des lieux

- [x] Lire le code ARZIKI et le site actuel
- [x] Rédiger ce plan
- [ ] Recevoir `services.html` et `arziki.html`
- [x] Recevoir les décisions 1, 2 et 4

## 2. Serveur ARZIKI et sécurité

- [x] Modèle des opérations selon la décision 1 (calcul, statuts, garanties OHADA)
- [x] Coût annuel équivalent de la majoration, alerte au-delà de 24 % (paramétrable)
- [x] Accès des partenaires selon la décision 2 (invitation seule, plafond paramétrable, blocage dur) : côté serveur
- [x] Cycle de vie complet des opérations côté serveur (Cloud Functions), journal d'audit
- [ ] Manifestation d'intérêt non engageante, avec la mention à l'écran
- [x] KYC : bénéficiaire effectif (entreprises), personne politiquement exposée (partenaires), conservation 10 ans, aucune suppression par l'utilisateur
- [x] Champ du numéro de déclaration IPDCP (paramètres) : côté serveur, écran à faire
- [x] Fichiers : PDF, JPG, PNG seulement, 10 Mo maximum ; documents d'opération par lien temporaire de 15 minutes, chaque téléchargement inscrit au journal
- [x] Tests : calculs, cycle de vie, règles d'accès, plafond de partenaires (56 tests serveur, 17 tests de règles, 20 tests application)
- [ ] Environnements de test et de production séparés (deux projets Firebase : à créer avec le propriétaire)
- [ ] Journaliser aussi la consultation des pièces KYC par l'équipe (passer par un lien temporaire)

## 3. Espaces de l'application

- [x] Vitrine publique sans mention des partenaires ni des marges ; lien discret « Espace partenaires (sur invitation) » (application et site Vercel)
- [x] Espace Entreprise : soumission d'une commande (5 étapes), suivi, notifications (démonstration)
- [ ] Espace Entreprise : messagerie simple avec l'administrateur
- [x] Espace Partenaires : opérations proposées, « Je suis intéressé » (non engageant), mes opérations, documents, échéances
- [x] Espace Administrateur : KYC, invitations, plafond, opérations (analyse, conditions, coût annuel, proposition, apports, garanties, étapes), paramètres (plafond, seuil, TVA, IPDCP), tableau de bord
- [ ] Espace Administrateur : factures, export CSV, projets de contrats en PDF
- [x] Rôle Notaire : dossiers assignés, garanties, confirmation de la signature et du paiement au fournisseur
- [ ] Notifications par e-mail, copie aux deux adresses de l'administration ; point d'extension WhatsApp
- [ ] Anglais en plus du français

## 4. Paiements

- [ ] Comparatif FedaPay, CinetPay, PayDunya et recommandation
- [ ] **[DÉCISION]** Choix de l'agrégateur
- [ ] Intégration en mode test (sandbox), webhook vérifié côté serveur, facture automatique

## 5. Pages légales et avertissements

- [x] CGU Entreprises, CGU Partenaires financiers, confidentialité, mentions légales (version 2.0, à faire relire par l'avocat)
- [x] Avertissement R8 dans l'application et sur le site Vercel
- [ ] Avertissement R8 sur arziki.html
- [ ] Projets de contrats PDF avec filigrane « PROJET À VALIDER PAR LE NOTAIRE »

## 6. Site amanexus.com

- [ ] Sauvegarde de l'ancien site
- [ ] **[DÉCISION]** Proposition de structure et de textes, sans rien supprimer d'existant sans accord
- [ ] En-tête et pied de page communs, Poppins, FR/EN, couleurs vives, mobile d'abord
- [ ] Accueil, Nos expertises, Formations, Contact (formulaires vers les deux adresses, anti-spam, WhatsApp)
- [ ] services.html intégrée au nouveau design
- [ ] arziki.html corrigée (section 8 de la mission)
- [ ] algerie-niger.html (arabe de droite à gauche, français, anglais si simple)
- [ ] SEO : titres, descriptions, réseaux sociaux, sitemap.xml, robots.txt

## 7. Construction

- [ ] Application web dans `/arziki/app/` (chemin configurable), option `app.amanexus.com`
- [ ] APK Android relié au même serveur

## 8. Déploiement LWS et guides

- [ ] Dossier `deploiement-lws/` et son ZIP, `.htaccess` (HTTPS, routes de l'application, cache)
- [ ] `DEPLOIEMENT_LWS.md`, `ACTIVATION_FORMULAIRES.md`, `ADMIN.md`, guide d'installation de l'APK
- [ ] Liste des textes à faire valider (avocat, arabophone)
