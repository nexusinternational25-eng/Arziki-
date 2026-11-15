// Pays de la sous-région (CLAUDE.md, section 23.1). Liste unique : tout ce qui
// dépend d'un pays (indicatif, longueur des numéros, portefeuilles mobiles,
// autorité de protection des données, ouverture) se lit ici et nulle part ailleurs.
//
// Les Cloud Functions lisent la même liste dans config/pays.json, produit à
// partir de ce fichier par `dart run tool/exporter_pays.dart`. Un test vérifie
// que les deux sont identiques : après toute modification ici, relancer l'export.
//
// Règles :
// - seul le Togo est ouvert au départ ;
// - un pays passe à « actif » seulement après validation juridique locale et
//   enregistrement d'un notaire partenaire dans ce pays (décision du super
//   administrateur, tracée dans le journal d'audit) ;
// - monnaie unique : FCFA (XOF), sans décimales ;
// - aucun drapeau : on affiche le nom du pays (section 21.3).

/// Ouverture d'un pays dans ARZIKI.
enum StatutPays {
  actif('actif'),
  aVenir('a_venir');

  const StatutPays(this.code);
  final String code;
}

class Pays {
  const Pays({
    required this.code,
    required this.nom,
    required this.dans,
    required this.indicatif,
    required this.longueurNumero,
    required this.exemple,
    required this.portefeuilles,
    required this.autoriteDonnees,
    this.prefixesNationaux = const [],
    this.notairePartenaire = false,
    this.statut = StatutPays.aVenir,
  });

  /// Code ISO 3166 sur deux lettres : TG, BJ, NE...
  final String code;
  final String nom;

  /// Nom précédé de sa préposition : « au Togo », « en Côte d'Ivoire ».
  final String dans;

  /// Indicatif international, avec le signe plus : +228.
  final String indicatif;

  /// Nombre de chiffres du numéro national, sans l'indicatif.
  final int longueurNumero;

  /// Exemple de numéro affiché dans le champ de saisie.
  final String exemple;

  /// Débuts obligatoires du numéro national (vide : pas de contrainte).
  final List<String> prefixesNationaux;

  /// Portefeuilles mobiles proposés dans le pays.
  final List<String> portefeuilles;

  /// Autorité de protection des données personnelles.
  final String autoriteDonnees;

  /// Vrai quand un notaire partenaire est enregistré dans ce pays.
  final bool notairePartenaire;

  final StatutPays statut;

  bool get estActif => statut == StatutPays.actif;

  /// Libellé d'une liste de choix : « Togo (+228) », « Niger (+227), bientôt ».
  String get libelleChoix => estActif ? '$nom ($indicatif)' : '$nom ($indicatif), bientôt';

  /// Message d'erreur si le numéro national est mal formé, sinon null.
  String? erreurNumero(String saisie) {
    final chiffres = saisie.replaceAll(RegExp(r'\D'), '');
    if (chiffres.length != longueurNumero) {
      return '${_majuscule(dans)}, le numéro compte $longueurNumero chiffres (exemple : $exemple).';
    }
    if (prefixesNationaux.isNotEmpty && !prefixesNationaux.any(chiffres.startsWith)) {
      return '${_majuscule(dans)}, le numéro commence par ${prefixesNationaux.join(' ou ')} (exemple : $exemple).';
    }
    return null;
  }

  static String _majuscule(String t) => t[0].toUpperCase() + t.substring(1);

  bool numeroValide(String saisie) => erreurNumero(saisie) == null;

  /// Numéro complet au format international : +22890123456.
  String numeroInternational(String saisie) => '$indicatif${saisie.replaceAll(RegExp(r'\D'), '')}';

  /// Numéro national lisible, par groupes de deux chiffres (trois en tête si
  /// la longueur est impaire) : 90 12 34 56, 77 123 45 67.
  String formaterNational(String chiffres) {
    final groupes = <String>[];
    var i = 0;
    if (chiffres.length.isOdd && chiffres.length > 2) {
      groupes.add(chiffres.substring(0, 2));
      groupes.add(chiffres.substring(2, 5));
      i = 5;
    }
    for (; i < chiffres.length; i += 2) {
      groupes.add(chiffres.substring(i, i + 2 > chiffres.length ? chiffres.length : i + 2));
    }
    return groupes.join(' ');
  }

  Map<String, Object> versJson() => {
        'code': code,
        'nom': nom,
        'indicatif': indicatif,
        'longueurNumero': longueurNumero,
        'prefixesNationaux': prefixesNationaux,
        'statut': statut.code,
      };
}

class PaysConfig {
  PaysConfig._();

  static const togo = Pays(
    code: 'TG',
    nom: 'Togo',
      dans: 'au Togo',
    indicatif: '+228',
    longueurNumero: 8,
    exemple: '90 12 34 56',
    portefeuilles: ['Mixx by Yas', 'Flooz'],
    autoriteDonnees: 'IPDCP',
    statut: StatutPays.actif,
  );

  /// Ordre d'affichage : le Togo, puis les prochains pays, puis le reste de l'UEMOA.
  static const tous = <Pays>[
    togo,
    Pays(
      code: 'BJ',
      nom: 'Bénin',
      dans: 'au Bénin',
      indicatif: '+229',
      // Depuis fin 2024, les numéros mobiles béninois ont 10 chiffres et commencent par 01.
      longueurNumero: 10,
      prefixesNationaux: ['01'],
      exemple: '01 97 12 34 56',
      portefeuilles: ['MTN MoMo', 'Moov Money', 'Celtiis Cash'],
      autoriteDonnees: 'APDP',
    ),
    Pays(
      code: 'NE',
      nom: 'Niger',
      dans: 'au Niger',
      indicatif: '+227',
      longueurNumero: 8,
      exemple: '90 12 34 56',
      portefeuilles: ['Airtel Money', 'Moov Money'],
      autoriteDonnees: 'HAPDP',
    ),
    Pays(
      code: 'CI',
      nom: "Côte d'Ivoire",
      dans: "en Côte d'Ivoire",
      indicatif: '+225',
      longueurNumero: 10,
      exemple: '07 12 34 56 78',
      portefeuilles: ['Orange Money', 'MTN MoMo', 'Moov Money', 'Wave'],
      autoriteDonnees: 'ARTCI',
    ),
    Pays(
      code: 'BF',
      nom: 'Burkina Faso',
      dans: 'au Burkina Faso',
      indicatif: '+226',
      longueurNumero: 8,
      exemple: '70 12 34 56',
      portefeuilles: ['Orange Money', 'Moov Money'],
      autoriteDonnees: 'CIL',
    ),
    Pays(
      code: 'SN',
      nom: 'Sénégal',
      dans: 'au Sénégal',
      indicatif: '+221',
      longueurNumero: 9,
      exemple: '77 123 45 67',
      portefeuilles: ['Wave', 'Orange Money', 'Mixx by Yas'],
      autoriteDonnees: 'CDP',
    ),
    Pays(
      code: 'ML',
      nom: 'Mali',
      dans: 'au Mali',
      indicatif: '+223',
      longueurNumero: 8,
      exemple: '70 12 34 56',
      portefeuilles: ['Orange Money', 'Moov Money'],
      autoriteDonnees: 'APDP',
    ),
  ];

  static const Pays parDefaut = togo;

  /// Monnaie de tous les pays de l'UEMOA.
  static const String monnaie = 'XOF';

  static List<Pays> get actifs => tous.where((p) => p.estActif).toList();

  static Pays? parCode(String? code) {
    for (final p in tous) {
      if (p.code == code) return p;
    }
    return null;
  }

  /// Pays d'un numéro international (+22890123456), d'après son indicatif.
  static Pays? depuisTelephone(String? numero) {
    if (numero == null) return null;
    for (final p in tous) {
      if (numero.startsWith(p.indicatif)) return p;
    }
    return null;
  }

  /// Contrôle complet d'un numéro international : pays connu, ouvert, numéro bien formé.
  /// Renvoie un message d'erreur, ou null si le numéro est accepté.
  static String? erreurTelephone(String numero, {bool exigerPaysActif = true}) {
    final pays = depuisTelephone(numero);
    if (pays == null) return 'Ce pays ne fait pas partie de la zone ARZIKI.';
    if (exigerPaysActif && !pays.estActif) {
      return "ARZIKI n'est pas encore ouvert ${pays.dans}. Nous vous préviendrons dès l'ouverture.";
    }
    return pays.erreurNumero(numero.substring(pays.indicatif.length));
  }
}
