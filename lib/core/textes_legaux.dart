// Textes légaux et vocabulaire réglementé (CLAUDE.md, sections 1 et 14).
// Version 2.0 publiée le 21 novembre 2026 : vente à terme, invitation seule (section 24).

class TextesLegaux {
  TextesLegaux._();

  /// Version des conditions d'utilisation et de la politique de confidentialité.
  /// Toute modification du texte impose d'augmenter ce numéro.
  static const String versionConditions = '2.0';

  /// Avertissement imposé (règle R8), affiché dans l'application et sur arziki.html.
  static const String avertissementR8 =
      "ARZIKI ne fait ni crédit ni collecte d'épargne. "
      "Chaque opération fait l'objet de contrats passés devant notaire. "
      'Toute participation comporte un risque de perte.';

  /// Avertissement de risque, affiché sur chaque fiche d'opération proposée à un partenaire.
  static const String avertissementRisque =
      '$avertissementR8 '
      "La manifestation d'intérêt n'engage pas : seule la signature devant notaire engage. "
      "Ne vous engagez qu'avec des sommes dont vous n'avez pas besoin à court terme.";

  /// Mention affichée près du bouton « Je suis intéressé » (règle R4).
  static const String interetNonEngageant =
      "Cette manifestation d'intérêt ne vous engage pas. Seule la signature devant notaire vous engage.";

  /// Règle des espèces (règle R6) : aucune option de paiement en espèces.
  static const String regleEspeces =
      'Aucun paiement en espèces : virement, mobile money ou carte, avec justificatif.';

  /// Expressions interdites dans tous les textes de l'application (règles R2 et R4, section 24).
  /// Un test automatique vérifie qu'aucune n'apparaît dans les textes affichés.
  /// Exceptions voulues : les formules juridiques négatives (« ni crédit ni collecte d'épargne »,
  /// « appel public à l'épargne ») et « manifestation d'intérêt ».
  static final List<RegExp> expressionsInterdites = [
    RegExp(r'(?<!ni )\bcr[ée]dit', caseSensitive: false),
    RegExp(r"(?<!collecte d'|appel public à l')[ée]pargne", caseSensitive: false),
    RegExp(r'int[ée]r[êe]ts\b', caseSensitive: false),
    RegExp(r'd[ée]p[ôo]ts?\b', caseSensitive: false),
    RegExp(r'\bplacements?\b', caseSensitive: false),
    RegExp(r'encadr[ée]+s?\s+par\s+(un\s+|le\s+)?notaire|encadrement\s+notarial|garantie?s?\s+par\s+le\s+notaire', caseSensitive: false),
    RegExp(r'\bgaranti\b', caseSensitive: false),
    RegExp(r'(rendement|croissance|gain|placement|profit|revenu|marge)s?\s+garanti', caseSensitive: false),
    RegExp(r'sans\s+risque', caseSensitive: false),
    RegExp(r'rendement\s+assur', caseSensitive: false),
    RegExp(r'taux\s+d.int[ée]r[êe]t', caseSensitive: false),
    RegExp(r'\bpr[êe]ts?\b', caseSensitive: false),
    RegExp(r'rendement\s+annuel', caseSensitive: false),
  ];
}
