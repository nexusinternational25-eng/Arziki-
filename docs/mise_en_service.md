# ARZIKI : passer en service réel (guide pour le propriétaire)

Ce guide dit ce que **vous** aurez à faire, une seule fois, pour que l'application fonctionne avec de vraies personnes. Tout le reste (configuration, installation, essais) est fait par Claude. Au moment de chaque étape, Claude vous enverra les liens directs et ce que vous devez voir à l'écran.

## Ce que vous préparez dès maintenant (démarches hors application)

1. **Le notaire partenaire** : son accord et les coordonnées du compte séquestre.
2. **L'avocat** : relecture des textes légaux (version 1.0 en ligne) et confirmation de la règle des 100 personnes du Cercle.
3. **L'IPDCP** : déclaration du traitement des données personnelles avant d'accueillir de vrais utilisateurs.
4. **Une puce téléphonique dédiée à ARZIKI** (Togocom ou Moov). Elle servira de numéro WhatsApp officiel. Ne l'installez pas dans l'application WhatsApp ordinaire : elle sera reliée au service WhatsApp pour les entreprises.

## Étape 1 : Firebase (environ 15 minutes)

Firebase est le service de Google qui garde les comptes, les documents et fait les vérifications de sécurité.

1. Ouvrez https://console.firebase.google.com avec le compte Google de NEXUS International.
2. Cliquez sur « Créer un projet », nommez-le « arziki », acceptez les conditions. Vous pouvez refuser Google Analytics à cette étape.
3. Quand le projet est prêt, cliquez sur « Passer à la formule Blaze » (en bas à gauche) et ajoutez une carte bancaire. Ce n'est pas un abonnement : vous payez seulement ce qui dépasse le quota gratuit.
4. Claude vous indiquera ensuite comment lui donner l'accès d'installation (une clé à coller dans GitHub, en suivant un pas à pas avec captures).

Claude met en place une **alerte de budget** pour que vous soyez prévenu par e-mail avant toute dépense inhabituelle.

## Étape 2 : WhatsApp pour les entreprises (Meta)

1. Ouvrez https://business.facebook.com et créez (ou ouvrez) le compte « NEXUS International ».
2. Dans « Paramètres de l'entreprise », lancez la **vérification de l'entreprise** : RCCM, adresse, site internet. Meta répond en général en quelques jours à quelques semaines.
3. Ajoutez le **numéro de la puce dédiée** comme numéro WhatsApp Business, avec le nom affiché « ARZIKI ». Meta envoie un code sur cette puce pour confirmer.
4. Claude s'occupe du reste : le modèle de message du code, le branchement au serveur, les essais.

En attendant la réponse de Meta, l'application fonctionne déjà avec les SMS. Dès que Meta valide, WhatsApp devient la voie principale, sans rien changer pour les utilisateurs.

## Étape 3 : le pilote

- 1 ou 2 entreprises connues, 5 à 10 investisseurs invités par code, votre notaire.
- Une seule opération réelle de 2 à 5 millions de FCFA, de préférence avec un fournisseur qui accepte d'être payé plus tard.
- Durée : 6 à 8 semaines, puis bilan et corrections avant d'ouvrir plus largement.
