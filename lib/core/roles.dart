// Rôles et statuts des comptes ARZIKI (CLAUDE.md, section 2 et section 21).
//
// Le rôle officiel est stocké dans les custom claims Firebase Auth,
// attribués uniquement par une Cloud Function appelée par un administrateur.
// Ce fichier ne sert qu'à l'affichage et à la navigation : il ne donne aucun droit.

enum Role {
  superAdmin('super_admin', 'Super administrateur'),
  admin('admin', 'Administrateur'),
  analyste('analyste', 'Analyste'),
  entreprise('entreprise', 'Entreprise'),
  membre('membre', 'Membre du Cercle'),
  partenaire('partenaire', 'Partenaire du Cercle'),
  partenaireStrategique('partenaire_strategique', 'Partenaire stratégique'),
  fournisseur('fournisseur', 'Fournisseur'),
  notaire('notaire', 'Notaire'),

  /// Personne qui s'est inscrite seule et demande à rejoindre le Cercle.
  /// Elle ne voit aucune opération tant qu'un administrateur ne l'a pas admise.
  candidatCercle('candidat_cercle', 'Candidat au Cercle');

  const Role(this.code, this.libelle);

  /// Valeur stockée dans Firestore et dans les custom claims.
  final String code;

  /// Libellé affiché à l'écran.
  final String libelle;

  static Role? depuisCode(String? code) {
    for (final role in Role.values) {
      if (role.code == code) return role;
    }
    return null;
  }

  /// Rôles qui ont accès à la console d'administration web.
  bool get accesConsole =>
      this == Role.superAdmin || this == Role.admin || this == Role.analyste;

  /// Rôles d'administration (connexion par e-mail + double facteur).
  bool get estAdministration => accesConsole;

  /// Investisseurs admis dans le Cercle.
  bool get estMembreDuCercle =>
      this == Role.membre || this == Role.partenaire || this == Role.partenaireStrategique;

  /// Un partenaire voit aussi les opérations Entreprises (grands comptes).
  bool get voitOperationsEntreprises =>
      this == Role.partenaire || this == Role.partenaireStrategique;

  /// Peut créer d'autres administrateurs et modifier les paramètres financiers globaux.
  bool get peutGererAdmins => this == Role.superAdmin;

  /// Peut valider un compte, créer une invitation, admettre un candidat.
  bool get peutValiderComptes => this == Role.superAdmin || this == Role.admin;
}

/// Niveau d'un investisseur du Cercle. Il découle directement du rôle.
enum NiveauCercle {
  membre('membre', 'Membre', 500000),
  partenaire('partenaire', 'Partenaire', 10000000),
  partenaireStrategique('partenaire_strategique', 'Partenaire stratégique', 50000000);

  const NiveauCercle(this.code, this.libelle, this.participationMinimale);

  final String code;
  final String libelle;

  /// Participation minimale par défaut, en FCFA (CLAUDE.md, section 10).
  final int participationMinimale;

  Role get role => switch (this) {
        NiveauCercle.membre => Role.membre,
        NiveauCercle.partenaire => Role.partenaire,
        NiveauCercle.partenaireStrategique => Role.partenaireStrategique,
      };

  static NiveauCercle? depuisCode(String? code) {
    for (final n in NiveauCercle.values) {
      if (n.code == code) return n;
    }
    return null;
  }
}

/// Statut d'un compte.
enum StatutCompte {
  enAttente('en_attente', 'En cours de vérification'),
  actif('actif', 'Actif'),
  suspendu('suspendu', 'Suspendu');

  const StatutCompte(this.code, this.libelle);
  final String code;
  final String libelle;

  static StatutCompte depuisCode(String? code) =>
      StatutCompte.values.firstWhere((s) => s.code == code, orElse: () => StatutCompte.enAttente);
}

/// Statut de la vérification d'identité (CLAUDE.md, section 7).
enum StatutKyc {
  nonCommence('non_commence', 'Non commencée'),
  enCours('en_cours', 'En cours'),
  aCompleter('a_completer', 'À compléter'),
  valide('valide', 'Validée'),
  refuse('refuse', 'Refusée');

  const StatutKyc(this.code, this.libelle);
  final String code;
  final String libelle;

  static StatutKyc depuisCode(String? code) =>
      StatutKyc.values.firstWhere((s) => s.code == code, orElse: () => StatutKyc.nonCommence);
}
