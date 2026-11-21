// Vente à terme (CLAUDE.md, section 24) : mêmes règles que le serveur
// (functions/src/operations.ts), vérifiées par les mêmes cas de test
// (test/vecteurs/operations.json). L'application s'en sert pour afficher et
// pour le mode démonstration ; en production, seul le serveur décide.
//
// Une opération est un achat-revente : le ou les partenaires achètent la
// marchandise au fournisseur (prix d'achat), puis la revendent à l'entreprise
// au prix de revente = prix d'achat + majoration fixe, payable à l'échéance.

/// Statuts d'une opération (règle R4), dans l'ordre du parcours.
enum StatutVente {
  soumise('soumise', 'Demande envoyée', 0),
  enAnalyse('en_analyse', 'En analyse', 1),
  piecesDemandees('pieces_demandees', 'Pièces demandées', 1),
  refusee('refusee', 'Non retenue', 1),
  proposee('proposee', 'Proposée aux partenaires', 2),
  interetManifeste('interet_manifeste', 'Intérêt manifesté', 3),
  signee('signee', 'Contrats signés devant notaire', 4),
  fournisseurPaye('fournisseur_paye', 'Fournisseur payé', 5),
  livree('livree', 'Livrée', 6),
  echeancePayee('echeance_payee', 'Échéance payée', 7),
  cloturee('cloturee', 'Clôturée', 8),
  enRetard('en_retard', 'En retard', 6),
  enRecouvrement('en_recouvrement', 'En recouvrement', 6),
  annulee('annulee', 'Annulée', 0);

  const StatutVente(this.code, this.libelle, this.etape);
  final String code;
  final String libelle;

  /// Index de l'étape en cours dans [etapesVente].
  final int etape;

  static StatutVente depuisCode(String code) => StatutVente.values.firstWhere((s) => s.code == code);
}

/// Étapes affichées dans la frise d'une opération.
const etapesVente = [
  'Demande',
  'Analyse',
  'Proposition aux partenaires',
  "Manifestation d'intérêt",
  'Signature devant notaire',
  'Paiement au fournisseur',
  'Livraison',
  "Paiement à l'échéance",
  'Clôture',
];

/// Passages autorisés d'un statut à l'autre (identiques au serveur).
const Map<StatutVente, List<StatutVente>> transitionsVente = {
  StatutVente.soumise: [StatutVente.enAnalyse, StatutVente.annulee],
  StatutVente.enAnalyse: [StatutVente.piecesDemandees, StatutVente.refusee, StatutVente.proposee, StatutVente.annulee],
  StatutVente.piecesDemandees: [StatutVente.enAnalyse, StatutVente.annulee],
  StatutVente.refusee: [],
  StatutVente.proposee: [StatutVente.interetManifeste, StatutVente.annulee],
  StatutVente.interetManifeste: [StatutVente.signee, StatutVente.proposee, StatutVente.annulee],
  StatutVente.signee: [StatutVente.fournisseurPaye, StatutVente.annulee],
  StatutVente.fournisseurPaye: [StatutVente.livree, StatutVente.enRetard],
  StatutVente.livree: [StatutVente.echeancePayee, StatutVente.enRetard],
  StatutVente.enRetard: [StatutVente.echeancePayee, StatutVente.enRecouvrement],
  StatutVente.enRecouvrement: [StatutVente.echeancePayee, StatutVente.cloturee],
  StatutVente.echeancePayee: [StatutVente.cloturee],
  StatutVente.cloturee: [],
  StatutVente.annulee: [],
};

/// Garanties OHADA (règle R4).
enum TypeGarantie {
  reservePropriete('reserve_propriete', 'Réserve de propriété'),
  nantissementCreance('nantissement_creance', 'Nantissement de créance sur le client final'),
  cautionnement('cautionnement', 'Cautionnement'),
  hypotheque('hypotheque', 'Hypothèque'),
  nantissementMateriel('nantissement_materiel', 'Nantissement de matériel'),
  nantissementFondsCommerce('nantissement_fonds_commerce', 'Nantissement du fonds de commerce');

  const TypeGarantie(this.code, this.libelle);
  final String code;
  final String libelle;
}

enum StatutGarantie {
  aConstituer('a_constituer', 'À constituer'),
  signee('signee', 'Signée'),
  inscriteRccm('inscrite_rccm', 'Inscrite au RCCM');

  const StatutGarantie(this.code, this.libelle);
  final String code;
  final String libelle;
}

class Garantie {
  const Garantie(this.type, this.statut, {this.piece});
  final TypeGarantie type;
  final StatutGarantie statut;

  /// Chemin de la pièce jointe (acte), jamais un lien public.
  final String? piece;

  bool get constituee => statut != StatutGarantie.aConstituer;
}

class ErreurVente implements Exception {
  const ErreurVente(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Seuil d'alerte par défaut du coût annuel équivalent (paramétrable).
const seuilAlerteCoutAnnuel = 24.0;

/// Conditions d'une vente à terme. Montants entiers en FCFA.
class ConditionsVente {
  const ConditionsVente({required this.prixAchat, required this.majoration, required this.dureeJours});
  final int prixAchat;
  final int majoration;
  final int dureeJours;

  void verifier() {
    if (prixAchat <= 0) throw const ErreurVente("Le prix d'achat doit être un montant positif.");
    if (majoration < 0) throw const ErreurVente('La majoration ne peut pas être négative.');
    if (dureeJours < 1 || dureeJours > 365) throw const ErreurVente('La durée doit être comprise entre 1 et 365 jours.');
  }

  int get prixRevente {
    verifier();
    return prixAchat + majoration;
  }

  /// Coût annuel équivalent, en pourcentage arrondi au centième :
  /// majoration / prix d'achat × 365 / durée. Réservé à l'administrateur.
  double get coutAnnuelEquivalent {
    verifier();
    return (majoration / prixAchat * (365 / dureeJours) * 100 * 100).round() / 100;
  }

  bool alerte([double seuil = seuilAlerteCoutAnnuel]) => coutAnnuelEquivalent > seuil;
}

class Apport {
  const Apport(this.partenaireUid, this.montant);
  final String partenaireUid;
  final int montant;
}

class PartPartenaire {
  const PartPartenaire(this.partenaireUid, this.montant, this.partMajoration);
  final String partenaireUid;
  final int montant;
  final int partMajoration;
  int get aRecevoir => montant + partMajoration;
}

/// Répartit le prix de revente au prorata des apports (identique au serveur) :
/// arrondi à l'unité inférieure, reliquat au plus gros apport (le premier en cas d'égalité).
List<PartPartenaire> repartir(ConditionsVente c, List<Apport> apports) {
  c.verifier();
  if (apports.isEmpty) throw const ErreurVente('Au moins un partenaire est nécessaire.');
  if (apports.map((a) => a.partenaireUid).toSet().length != apports.length) {
    throw const ErreurVente('Un partenaire apparaît deux fois.');
  }
  if (apports.any((a) => a.montant <= 0)) throw const ErreurVente('Chaque apport doit être positif.');
  final total = apports.fold<int>(0, (s, a) => s + a.montant);
  if (total != c.prixAchat) {
    throw ErreurVente("Les apports ($total FCFA) doivent couvrir exactement le prix d'achat (${c.prixAchat} FCFA).");
  }
  final parts = [for (final a in apports) a.montant * c.majoration ~/ c.prixAchat];
  final reliquat = c.majoration - parts.fold<int>(0, (s, p) => s + p);
  var indexMax = 0;
  for (var i = 1; i < apports.length; i++) {
    if (apports[i].montant > apports[indexMax].montant) indexMax = i;
  }
  parts[indexMax] += reliquat;
  return [for (var i = 0; i < apports.length; i++) PartPartenaire(apports[i].partenaireUid, apports[i].montant, parts[i])];
}

/// Plafond de partenaires (règle R3) : 50 par défaut, blocage dur à 99.
const plafondPartenairesDefaut = 50;
const plafondPartenairesMaximum = 99;

void verifierPlaceDisponible(int occupes, [int plafond = plafondPartenairesDefaut]) {
  if (plafond < 1 || plafond > plafondPartenairesMaximum) {
    throw const ErreurVente('Le plafond de partenaires doit être compris entre 1 et $plafondPartenairesMaximum.');
  }
  if (occupes >= plafond) {
    throw ErreurVente('Plafond atteint : $plafond partenaires au maximum. Le Cercle reste privé.');
  }
}
