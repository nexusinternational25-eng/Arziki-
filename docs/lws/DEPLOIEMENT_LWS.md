# Mettre le nouveau site en ligne chez LWS

Durée : environ 20 minutes. Rien à installer sur votre ordinateur.

## Ce que contient le dossier

Le fichier `amanexus-lws.zip` contient deux dossiers :

- `public_html` : tout le site amanexus.com, avec l'application ARZIKI (`arziki/app/`) et la console d'administration (`arziki/console/`) ;
- `guides` : ces guides. Ils ne sont pas à mettre en ligne.

Téléchargez toujours la dernière version ici :
https://github.com/nexusinternational25-eng/Arziki-/releases/latest/download/amanexus-lws.zip

## Étape 1 : garder une copie de l'ancien site

Une copie de l'ancien site est déjà conservée dans le projet (dossier `sauvegardes`). Par prudence, gardez aussi celle du serveur :

1. Connectez-vous sur https://panel.lws.fr avec vos identifiants LWS.
2. Ouvrez **« Mes services »**, puis cliquez sur **« Gérer »** à côté de l'hébergement amanexus.com.
3. Ouvrez le **« Gestionnaire de fichiers »**. Vous voyez le dossier `htdocs` (ou `public_html`, selon votre formule) : c'est la racine du site.
4. Créez à côté un dossier nommé `ancien-site-2026` et déplacez-y tout le contenu actuel de la racine.

## Étape 2 : déposer le nouveau site

1. Toujours dans le gestionnaire de fichiers, entrez dans le dossier racine du site (maintenant vide).
2. Cliquez sur **« Envoyer »** (ou « Upload ») et choisissez `amanexus-lws.zip`.
3. Faites un clic droit sur le fichier envoyé, puis **« Extraire »**.
4. Un dossier `public_html` apparaît. Ouvrez-le, sélectionnez tout son contenu, et déplacez-le d'un niveau vers le haut, dans la racine du site.
5. Supprimez ensuite le dossier `public_html` vide, le dossier `guides` et le fichier ZIP.

Important : le fichier `.htaccess` commence par un point. Il est parfois masqué. Cochez **« Afficher les fichiers cachés »** pour vérifier qu'il est bien dans la racine.

Si le bouton « Extraire » n'existe pas dans votre gestionnaire de fichiers, dites-le-moi : je vous expliquerai la méthode avec le logiciel gratuit FileZilla.

## Étape 3 : activer le HTTPS

1. Dans l'espace de l'hébergement, ouvrez **« SSL »** ou **« Certificat SSL »**.
2. Activez le certificat gratuit **Let's Encrypt** pour `amanexus.com` et `www.amanexus.com`.

Le site oblige ensuite automatiquement l'adresse sécurisée `https://www.amanexus.com`.

## Étape 4 : vérifier

Ouvrez ces adresses sur votre téléphone :

- https://www.amanexus.com : la page d'accueil ;
- https://www.amanexus.com/services.html : Business Services ;
- https://www.amanexus.com/arziki.html, puis le bouton qui ouvre l'application ;
- https://www.amanexus.com/arziki/app/ : l'application ARZIKI ;
- https://www.amanexus.com/en/ : la version anglaise ;
- https://www.amanexus.com/ar/algerie-niger.html : le Desk en arabe.

Envoyez ensuite un message d'essai avec le formulaire de la page Contact (voir `ACTIVATION_FORMULAIRES.md`).

## Si quelque chose ne va pas

Remettez l'ancien site : supprimez le contenu de la racine et remettez celui du dossier `ancien-site-2026`. Puis écrivez-moi ce que vous avez vu à l'écran.

## Bon à savoir

- L'application web est pour l'instant en **mode démonstration** (données fictives), comme sur le site Vercel. Elle passera en service réel quand le projet Firebase sera ouvert.
- Pour une mise à jour, refaites l'étape 2 avec le nouveau ZIP. Vos réglages LWS ne changent pas.
