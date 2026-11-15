# Texte à coller dans la session Claude Code ARZIKI

Lis CLAUDE.md en entier, en particulier la section 23 (extension sous-régionale et passage en production), puis `docs/passage_en_production.md`.

Travaille jalon par jalon. À la fin de chaque jalon : lance `flutter analyze` et `flutter test`, les tests des Cloud Functions et des règles, fais un commit clair, et résume en langage simple ce qui marche et ce qui reste.

Jalon A : configuration des pays (section 23.1) et sélecteur de pays à l'inscription avec validation des numéros (section 23.2). Togo actif, Bénin et Niger visibles en « à venir ».

Jalon B : champ pays sur les utilisateurs, entreprises, opérations, notaires et fournisseurs ; filtres par pays dans la console ; une opération ne se publie que s'il existe un notaire actif dans son pays.

Jalon C : choix de l'agrégateur de paiement par pays derrière l'interface PaymentProvider, avec le mode simulé conservé et le repli « virement, preuve à déposer » (section 23.3).

Jalon D : branchement du projet Firebase réel. Demande-moi au bon moment, avec les liens directs et ce que je dois voir à l'écran, les éléments que je dois fournir. Je suis profane en développement : explique chaque étape simplement.

Jalon E : version signée pour Google Play et préparation du pilote.

Ne mets jamais mon nom dans l'application ni sur le site. Ne promets aucun rendement. L'application n'encaisse jamais les fonds des opérations.
