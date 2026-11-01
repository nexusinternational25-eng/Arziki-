// Textes légaux et vocabulaire réglementé (CLAUDE.md, sections 1 et 14).
// Version 1.0 publiée le 1er novembre 2026 (décision du propriétaire).

class TextesLegaux {
  TextesLegaux._();

  /// Version des conditions d'utilisation et de la politique de confidentialité.
  /// Toute modification du texte impose d'augmenter ce numéro.
  static const String versionConditions = '1.0';

  /// Avertissement de risque, affiché sur chaque fiche d'opération et avant chaque participation.
  static const String avertissementRisque =
      'ARZIKI propose des participations à des opérations commerciales. '
      'Ce ne sont ni des prêts ni des placements garantis. '
      'Vous pouvez perdre tout ou partie de votre mise. '
      'Les marges indiquées sont des objectifs, pas des promesses. '
      "Ne participez qu'avec des sommes dont vous n'avez pas besoin à court terme.";

  /// Règle des espèces (règle légale n° 4).
  static const String regleEspeces =
      'Aucun versement en espèces au-delà de 5 000 000 FCFA : '
      'les participations se font par virement ou mobile money, avec justificatif.';

  /// Rappel affiché aux candidats : le Cercle est privé.
  static const String cerclePrive =
      'Le Cercle Arziki est un cercle privé. Votre inscription ne vous donne pas accès aux opérations : '
      'un administrateur examine chaque candidature et décide seul de l\'admission, '
      'après vérification de votre identité et de l\'origine de vos fonds.';

  /// Expressions interdites dans tous les textes de l'application (règle légale n° 2).
  /// Un test automatique vérifie qu'aucune n'apparaît dans les textes affichés.
  static final List<RegExp> expressionsInterdites = [
    RegExp(r'\bgaranti\b', caseSensitive: false),
    RegExp(r'(rendement|croissance|gain|placement|profit|revenu|marge)s?\s+garanti', caseSensitive: false),
    RegExp(r'sans\s+risque', caseSensitive: false),
    RegExp(r'rendement\s+assur', caseSensitive: false),
    RegExp(r'taux\s+d.int[ée]r[êe]t', caseSensitive: false),
    RegExp(r'\bpr[êe]ts?\b', caseSensitive: false),
    RegExp(r'rendement\s+annuel', caseSensitive: false),
  ];
}
