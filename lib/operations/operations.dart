// Opérations de Commande Financée, participations, demandes et notifications.
// Mode démonstration : 8 opérations fictives à des étapes différentes, dont une
// en retard et une avec perte (CLAUDE.md, section 17). Les changements de statut
// réels passeront par les Cloud Functions (jalons 3 à 6).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session.dart';
import '../core/images.dart';
import '../core/roles.dart';

/// Étapes affichées dans la frise d'une opération (CLAUDE.md, section 6, simplifiée).
const etapesOperation = [
  'Demande vérifiée',
  'Garanties signées chez le notaire',
  'Financement réuni',
  'Achat et livraison',
  "Paiement de l'acheteur",
  'Partage de la marge',
];

enum StatutOperation {
  financementOuvert('Financement ouvert', 2),
  financementComplet('Financement complet', 3),
  enLivraison('En livraison', 3),
  livree('Livrée, paiement attendu', 4),
  enRetard('En retard', 4),
  cloturee('Clôturée', 6),
  garantiesEnCours('Garanties en cours', 1);

  const StatutOperation(this.libelle, this.etape);
  final String libelle;

  /// Index de l'étape en cours dans [etapesOperation].
  final int etape;
}

class Operation {
  const Operation({
    required this.id,
    required this.titre,
    required this.secteur,
    required this.image,
    required this.format,
    required this.statut,
    required this.montantAReunir,
    required this.montantReuni,
    required this.dureeJours,
    required this.margeViseePct,
    required this.partInvestisseursPct,
    required this.niveauGaranties,
    required this.placesRestantes,
    required this.dateLimite,
    required this.entrepriseUid,
    required this.acheteur,
    required this.fournisseur,
    required this.resume,
    this.minParticipant = 500000,
    this.maxParticipant = 5000000,
    this.resultatPct,
  });

  final String id;
  final String titre;
  final String secteur;
  final String image;

  /// « pme » ou « entreprises » : un membre ne voit que les opérations PME.
  final String format;
  final StatutOperation statut;
  final int montantAReunir;
  final int montantReuni;
  final int dureeJours;
  final double margeViseePct;
  final int partInvestisseursPct;
  final String niveauGaranties;
  final int placesRestantes;
  final DateTime dateLimite;
  final String entrepriseUid;

  /// Nom affiché seulement si l'admin l'autorise ; sinon « grand compte du secteur X ».
  final String acheteur;
  final String fournisseur;
  final String resume;
  final int minParticipant;
  final int maxParticipant;

  /// Résultat final en pourcentage de la mise (négatif en cas de perte).
  final double? resultatPct;

  bool get estEntreprises => format == 'entreprises';
  bool get estOuverte => statut == StatutOperation.financementOuvert;
}

final operationsDemo = <Operation>[
  Operation(
    id: 'op-pharma',
    titre: 'Réassort de médicaments génériques',
    secteur: 'Santé',
    image: Images.opPharmacie,
    format: 'pme',
    statut: StatutOperation.financementOuvert,
    montantAReunir: 12000000,
    montantReuni: 7800000,
    dureeJours: 60,
    margeViseePct: 14,
    partInvestisseursPct: 30,
    niveauGaranties: 'Contrat déposé chez le notaire, caution du dirigeant',
    placesRestantes: 6,
    dateLimite: DateTime(2026, 11, 20),
    entrepriseUid: 'u-ent-pharma',
    acheteur: 'Grand compte du secteur santé',
    fournisseur: 'Grossiste pharmaceutique agréé, Lomé',
    resume: "Une pharmacie de Lomé a une commande ferme d'un réseau de cliniques. Le financement sert à acheter "
        'le stock chez un grossiste agréé ; les cliniques paient à 45 jours sur le compte désigné.',
  ),
  Operation(
    id: 'op-btp',
    titre: 'Ciment et fers pour un chantier à Agoè',
    secteur: 'BTP',
    image: Images.opBtp,
    format: 'pme',
    statut: StatutOperation.financementOuvert,
    montantAReunir: 24000000,
    montantReuni: 9600000,
    dureeJours: 75,
    margeViseePct: 12,
    partInvestisseursPct: 30,
    niveauGaranties: 'Caution solidaire et nantissement du matériel',
    placesRestantes: 11,
    dateLimite: DateTime(2026, 11, 28),
    entrepriseUid: 'u-ent-btp',
    acheteur: 'Promoteur immobilier, Lomé',
    fournisseur: 'Négoce de matériaux, zone portuaire',
    resume: "Une entreprise de BTP fournit le ciment et les fers d'un programme de logements. Le négociant livre "
        'en trois fois, le promoteur paie à la réception de chaque lot.',
  ),
  Operation(
    id: 'op-mine',
    titre: "Pièces d'usure pour un site minier",
    secteur: 'Mines et industrie',
    image: Images.equipementIndustriel,
    format: 'entreprises',
    statut: StatutOperation.financementOuvert,
    montantAReunir: 85000000,
    montantReuni: 51000000,
    dureeJours: 90,
    margeViseePct: 11,
    partInvestisseursPct: 35,
    niveauGaranties: 'Acte notarié, cession de créance sur l\'acheteur',
    placesRestantes: 3,
    dateLimite: DateTime(2026, 11, 25),
    entrepriseUid: 'u-ent-mine',
    acheteur: 'Grand compte du secteur minier',
    fournisseur: 'Équipementier industriel',
    resume: "Un fournisseur référencé d'une société minière doit livrer des pièces d'usure. La créance sur l'acheteur "
        'est cédée au profit de l\'opération, devant notaire.',
    minParticipant: 10000000,
    maxParticipant: 30000000,
  ),
  Operation(
    id: 'op-cereales',
    titre: 'Stock de maïs et de riz pour une coopérative',
    secteur: 'Agriculture',
    image: Images.opCereales,
    format: 'pme',
    statut: StatutOperation.enLivraison,
    montantAReunir: 9000000,
    montantReuni: 9000000,
    dureeJours: 50,
    margeViseePct: 13,
    partInvestisseursPct: 30,
    niveauGaranties: 'Contrat déposé chez le notaire, gage du stock',
    placesRestantes: 0,
    dateLimite: DateTime(2026, 10, 10),
    entrepriseUid: 'u-ent-pharma',
    acheteur: 'Société de transformation, région des Plateaux',
    fournisseur: 'Coopérative agricole des Plateaux',
    resume: 'Achat de céréales auprès d\'une coopérative pour une société de transformation qui paie à 30 jours.',
  ),
  Operation(
    id: 'op-bureau',
    titre: 'Équipements informatiques pour une administration',
    secteur: 'Équipements',
    image: Images.opBureau,
    format: 'pme',
    statut: StatutOperation.livree,
    montantAReunir: 6500000,
    montantReuni: 6500000,
    dureeJours: 45,
    margeViseePct: 15,
    partInvestisseursPct: 30,
    niveauGaranties: 'Contrat déposé chez le notaire',
    placesRestantes: 0,
    dateLimite: DateTime(2026, 9, 30),
    entrepriseUid: 'u-ent-btp',
    acheteur: 'Grand compte du secteur public',
    fournisseur: 'Distributeur informatique, Lomé',
    resume: 'Livraison terminée, procès-verbal de réception signé. Le paiement de l\'acheteur est attendu.',
  ),
  Operation(
    id: 'op-intrants',
    titre: 'Engrais et semences de la campagne 2026',
    secteur: 'Agriculture',
    image: Images.opIntrants,
    format: 'pme',
    statut: StatutOperation.enRetard,
    montantAReunir: 15000000,
    montantReuni: 15000000,
    dureeJours: 60,
    margeViseePct: 12,
    partInvestisseursPct: 30,
    niveauGaranties: 'Caution solidaire et nantissement du stock',
    placesRestantes: 0,
    dateLimite: DateTime(2026, 8, 15),
    entrepriseUid: 'u-ent-pharma',
    acheteur: 'Union de coopératives, Atakpamé',
    fournisseur: "Distributeur d'intrants agricoles",
    resume: "Le paiement de l'acheteur a plus de 15 jours de retard. ARZIKI et le notaire suivent le dossier ; "
        'un échéancier est en cours de signature.',
  ),
  Operation(
    id: 'op-flotte',
    titre: 'Pièces détachées pour une flotte de camions',
    secteur: 'Transport et logistique',
    image: Images.opFlotte,
    format: 'pme',
    statut: StatutOperation.cloturee,
    montantAReunir: 8000000,
    montantReuni: 8000000,
    dureeJours: 40,
    margeViseePct: 14,
    partInvestisseursPct: 30,
    niveauGaranties: 'Contrat déposé chez le notaire',
    placesRestantes: 0,
    dateLimite: DateTime(2026, 6, 30),
    entrepriseUid: 'u-ent-btp',
    acheteur: 'Transporteur de la zone portuaire',
    fournisseur: 'Garage poids lourds, port de Lomé',
    resume: 'Opération clôturée : marge nette réelle de 13,1 %, partagée selon le contrat.',
    resultatPct: 3.9,
  ),
  Operation(
    id: 'op-perte',
    titre: 'Lot de matériaux de finition',
    secteur: 'BTP',
    image: Images.livraisonChantier,
    format: 'pme',
    statut: StatutOperation.cloturee,
    montantAReunir: 5000000,
    montantReuni: 5000000,
    dureeJours: 70,
    margeViseePct: 10,
    partInvestisseursPct: 30,
    niveauGaranties: 'Contrat signé, copie au notaire',
    placesRestantes: 0,
    dateLimite: DateTime(2026, 5, 31),
    entrepriseUid: 'u-ent-mine',
    acheteur: 'Entreprise de second œuvre',
    fournisseur: 'Négoce de matériaux',
    resume: "Opération clôturée avec une perte : l'acheteur a refusé une partie du lot. Après mise en jeu de la "
        'caution, la perte nette est de 4,2 % de la mise, répartie selon le contrat.',
    resultatPct: -4.2,
  ),
];

enum StatutParticipation {
  attenteVersement('Versement attendu'),
  versementDeclare('Preuve en vérification'),
  versementConfirme('Versement confirmé'),
  paye('Partage reçu');

  const StatutParticipation(this.libelle);
  final String libelle;
}

class Participation {
  const Participation(this.id, this.uid, this.operationId, this.montant, this.statut, {this.reference});
  final String id;
  final String uid;
  final String operationId;
  final int montant;
  final StatutParticipation statut;
  final String? reference;
}

final participationsDemo = <Participation>[
  const Participation('p1', 'u-membre-1', 'op-pharma', 1000000, StatutParticipation.versementConfirme, reference: 'ARZ-OP-PH-0001'),
  const Participation('p2', 'u-membre-1', 'op-cereales', 1500000, StatutParticipation.versementConfirme),
  const Participation('p3', 'u-membre-1', 'op-intrants', 800000, StatutParticipation.versementConfirme),
  const Participation('p4', 'u-membre-1', 'op-flotte', 1200000, StatutParticipation.paye),
  const Participation('p5', 'u-partenaire-1', 'op-mine', 15000000, StatutParticipation.versementConfirme),
  const Participation('p6', 'u-partenaire-1', 'op-bureau', 2000000, StatutParticipation.versementConfirme),
];

class Avis {
  const Avis(this.titre, this.texte, this.date, {this.lue = false});
  final String titre;
  final String texte;
  final DateTime date;
  final bool lue;
}

List<Avis> notificationsPour(Role role) => switch (role) {
      Role.entreprise => [
          Avis('Pièce demandée', 'Merci de joindre le devis signé du fournisseur pour votre demande « Réassort de médicaments ».', DateTime(2026, 10, 31)),
          Avis('Étape franchie', '« Stock de maïs et de riz » : la livraison a commencé.', DateTime(2026, 10, 29)),
          Avis('Compte validé', 'Votre identité a été vérifiée. Bienvenue sur ARZIKI.', DateTime(2026, 10, 2), lue: true),
        ],
      Role.membre || Role.partenaire || Role.partenaireStrategique => [
          Avis('Nouvelle opération ouverte', '« Ciment et fers pour un chantier à Agoè » est ouverte jusqu\'au 28 novembre.', DateTime(2026, 10, 31)),
          Avis('Versement confirmé', 'Votre versement de 1 000 000 FCFA pour « Réassort de médicaments » est confirmé par le notaire.', DateTime(2026, 10, 30)),
          Avis('Retard de paiement', "« Engrais et semences » : l'acheteur a plus de 15 jours de retard. Suivi en cours.", DateTime(2026, 10, 20)),
          Avis('Rapport mensuel disponible', 'Le rapport de septembre est disponible dans Rapports.', DateTime(2026, 10, 5), lue: true),
        ],
      Role.fournisseur => [
          Avis('Nouveau bon de commande', 'Un bon de commande ARZIKI vous attend : pièces détachées, 8 000 000 FCFA.', DateTime(2026, 10, 30)),
        ],
      Role.notaire => [
          Avis('Acte à déposer', 'Convention-cadre de « Ciment et fers pour un chantier à Agoè ».', DateTime(2026, 10, 30)),
        ],
      _ => [
          Avis('Bienvenue', 'Votre compte est en cours de vérification. Nous vous prévenons dès qu\'il est activé.', DateTime(2026, 10, 31)),
        ],
    };

/// Demande de Commande Financée déposée par une entreprise.
class Demande {
  const Demande({
    required this.id,
    required this.uid,
    required this.titre,
    required this.acheteur,
    required this.montantVente,
    required this.prixAchat,
    required this.frais,
    required this.creeLe,
    this.statut = 'Soumise',
  });
  final String id;
  final String uid;
  final String titre;
  final String acheteur;
  final int montantVente;
  final int prixAchat;
  final int frais;
  final DateTime creeLe;
  final String statut;

  int get margeNette => montantVente - prixAchat - frais;
  double get margeNettePct => montantVente == 0 ? 0 : margeNette * 100 / montantVente;
}

/// Calcul de marge prévisionnelle (affiché en direct dans le formulaire).
({int brute, int nette, double nettePct}) calculerMarge({required int vente, required int achat, required int transport, required int autres}) {
  final brute = vente - achat;
  final nette = brute - transport - autres;
  return (brute: brute, nette: nette, nettePct: vente == 0 ? 0 : nette * 100 / vente);
}

/// Garanties proposées selon le montant (CLAUDE.md, section 8).
List<String> garantiesPour(int montant) {
  final g = <String>['Bon de commande écrit', 'Paiement sur compte désigné'];
  if (montant < 5000000) {
    g.add("Caution du dirigeant si l'historique est faible");
    return g;
  }
  g.addAll(['Caution solidaire du dirigeant', 'Gage ou nantissement du stock ou du matériel']);
  if (montant < 30000000) return g;
  g.addAll([
    "Cession de créance sur l'acheteur ou délégation de paiement",
    "Nantissement du fonds de commerce ou d'un compte",
    "Caution solidaire d'un tiers solvable",
  ]);
  if (montant < 100000000) return g;
  g.addAll(['Garantie foncière (hypothèque sur titre foncier)', 'Assurance de la marchandise']);
  return g;
}

String formeActePour(int montant) {
  if (montant < 5000000) return 'Contrat signé, copie au notaire';
  if (montant < 30000000) return 'Contrat déposé chez le notaire';
  if (montant < 100000000) return 'Acte notarié, nantissements inscrits au RCCM';
  return 'Acte notarié, hypothèque inscrite au livre foncier';
}

class EtatOperations {
  const EtatOperations({required this.operations, required this.participations, required this.demandes});
  final List<Operation> operations;
  final List<Participation> participations;
  final List<Demande> demandes;

  Operation? parId(String id) => operations.where((o) => o.id == id).firstOrNull;
}

class ControleurOperations extends Notifier<EtatOperations> {
  @override
  EtatOperations build() => EtatOperations(
        operations: List.of(operationsDemo),
        participations: List.of(participationsDemo),
        demandes: [
          Demande(
            id: 'd1',
            uid: 'u-ent-pharma',
            titre: 'Réassort de médicaments, deuxième lot',
            acheteur: 'Réseau de cliniques, Lomé',
            montantVente: 9500000,
            prixAchat: 7600000,
            frais: 650000,
            creeLe: DateTime(2026, 10, 27),
            statut: 'En vérification',
          ),
        ],
      );

  /// Opérations visibles pour un rôle (règle légale n° 3 : rien pour un non-admis).
  List<Operation> ouvertesPour(Role role) {
    if (!role.estMembreDuCercle) return const [];
    return state.operations
        .where((o) => o.estOuverte && (!o.estEntreprises || role.voitOperationsEntreprises))
        .toList();
  }

  /// Intention de participation (démonstration : statut forcé « versement attendu »).
  Participation participer({required String uid, required Operation op, required int montant}) {
    final p = Participation(
      'p${state.participations.length + 1}',
      uid,
      op.id,
      montant,
      StatutParticipation.attenteVersement,
      reference: 'ARZ-${op.id.substring(3).toUpperCase()}-${(state.participations.length + 1).toString().padLeft(4, '0')}',
    );
    state = EtatOperations(operations: state.operations, participations: [...state.participations, p], demandes: state.demandes);
    ref.read(baseDemoProvider).auditer(uid, 'creer_participation', 'operations/${op.id}/participations/${p.id}', apres: '$montant');
    return p;
  }

  Demande soumettreDemande(Demande d) {
    state = EtatOperations(operations: state.operations, participations: state.participations, demandes: [d, ...state.demandes]);
    ref.read(baseDemoProvider).auditer(d.uid, 'soumettre_demande', 'demandes/${d.id}', apres: '${d.montantVente}');
    return d;
  }
}

final operationsProvider = NotifierProvider<ControleurOperations, EtatOperations>(ControleurOperations.new);
