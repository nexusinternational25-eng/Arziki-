# ARZIKI : sortir de la démonstration (ce que vous faites, ce que Claude fait)

Ce guide complète `mise_en_service.md`. Il est écrit pour le propriétaire, sans vocabulaire technique.

## Ce que vous seul pouvez faire

| N° | Action | Durée | Pourquoi |
|---|---|---|---|
| 1 | Créer le projet Firebase « arziki » avec le compte Google de NEXUS International, puis passer à la formule Blaze | 15 minutes | C'est la vraie base de données et l'inscription par téléphone |
| 2 | Demander une offre écrite à deux agrégateurs de paiement agréés par la BCEAO (par exemple PayDunya et CinetPay), en précisant les pays : Togo, Bénin, Niger | 1 semaine | Pour encaisser les frais de service par mobile money et carte |
| 3 | Ouvrir le compte marchand chez l'agrégateur retenu : RCCM, NIF, pièce d'identité, compte bancaire | 1 à 2 semaines | Sans lui, aucun paiement réel |
| 4 | Déposer la marque ARZIKI à l'OAPI | 1 journée de démarche | Un seul dépôt protège le nom dans toute la zone |
| 5 | Déclarer le traitement des données à l'IPDCP | selon l'autorité | Obligatoire avant d'accueillir de vrais utilisateurs |
| 6 | Faire valider par l'avocat les conventions et la règle du Cercle, y compris pour un membre résidant hors du Togo | 1 à 2 semaines | Rester hors de l'appel public à l'épargne |
| 7 | Trouver un notaire partenaire dans chaque nouveau pays (Bénin, Niger) | variable | Un pays ne s'ouvre pas sans notaire local |
| 8 | Créer le compte Google Play développeur au nom de NEXUS International | 1 heure | Pour publier l'application sans fichier APK |

## Ce que Claude Code fait ensuite, dans votre session ARZIKI

1. Relie l'application au projet Firebase et installe les règles de sécurité.
2. Ajoute le choix du pays à l'inscription et les numéros de chaque pays.
3. Branche l'agrégateur de paiement retenu, avec un deuxième en secours.
4. Prépare la version signée pour Google Play.
5. Lance un pilote : une ou deux entreprises, cinq à dix investisseurs invités, votre notaire.

## Sans attendre

Vous pouvez réaliser une première opération réelle à la main : commande vérifiée par vous, contrat chez le notaire, fonds sur le compte du notaire, suivi dans un tableau. L'application sert alors de vitrine.

## Comment lancer le développement

Ouvrez votre session Claude Code ARZIKI et collez le texte du fichier `docs/prompt_prochaine_session.md`.
