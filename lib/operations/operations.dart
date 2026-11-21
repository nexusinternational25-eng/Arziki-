// Opérations ARZIKI en vente à terme (CLAUDE.md, section 24), notifications.
//
// Mode démonstration : 9 opérations fictives à des étapes différentes, dont une
// en retard et une en recouvrement. Les règles (calculs, statuts, garanties,
// partenaires proposés) sont celles du serveur (functions/src/operations.ts),
// via vente_a_terme.dart. En production, seul le serveur décide.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session.dart';
import '../core/images.dart';
import '../core/roles.dart';
import 'vente_a_terme.dart';

export 'vente_a_terme.dart';

class Operation {
  const Operation({
    required this.id,
    required this.titre,
    required this.secteur,
    required this.image,
    required this.statut,
    required this.entrepriseUid,
    required this.clientFinal,
    required this.fournisseur,
    required this.resume,
    required this.montantCommande,
    required this.creeLe,
    this.prixAchat,
    this.majoration,
    this.dureeJours,
    this.echeance,
    this.commissionArziki = 0,
    this.garanties = const [],
    this.garantiesProposees = const [],
    this.partenairesProposes = const [],
    this.manifestations = const {},
    this.apportsRetenus = const [],
    this.notaireUid,
    this.pays = 'TG',
    this.motif,
  });

  final String id;
  final String titre;
  final String secteur;
  final String image;
  final StatutVente statut;
  final String entrepriseUid;

  /// Client final de l'entreprise. Montré aux partenaires seulement sous une forme
  /// anonyme (« grand compte du secteur X ») tant que l'administrateur ne l'autorise pas.
  final String clientFinal;
  final String fournisseur;
  final String resume;

  /// Montant de la commande du client final (ce que l'entreprise facturera).
  final int montantCommande;
  final DateTime creeLe;

  /// Conditions de la vente à terme, fixées par l'administrateur pendant l'analyse.
  final int? prixAchat;
  final int? majoration;
  final int? dureeJours;
  final DateTime? echeance;
  final int commissionArziki;

  final List<Garantie> garanties;

  /// Garanties proposées par l'entreprise à la soumission.
  final List<TypeGarantie> garantiesProposees;

  /// Partenaires à qui l'opération a été proposée (seuls à la voir, R3).
  final List<String> partenairesProposes;

  /// Manifestations d'intérêt (non engageantes) : partenaire -> montant indicatif.
  final Map<String, int> manifestations;

  /// Apports retenus pour la signature devant notaire.
  final List<Apport> apportsRetenus;
  final String? notaireUid;
  final String pays;

  /// Dernier motif saisi (refus, pièces demandées, annulation).
  final String? motif;

  bool get conditionsFixees => prixAchat != null && majoration != null && dureeJours != null;

  ConditionsVente? get conditions =>
      conditionsFixees ? ConditionsVente(prixAchat: prixAchat!, majoration: majoration!, dureeJours: dureeJours!) : null;

  int? get prixRevente => conditions?.prixRevente;

  /// Indicateur réservé à l'administrateur (jamais affiché comme un « taux »).
  double? get coutAnnuelEquivalent => conditions?.coutAnnuelEquivalent;

  bool get ouverteAuxManifestations => statut == StatutVente.proposee || statut == StatutVente.interetManifeste;
  bool get terminee => statut == StatutVente.cloturee || statut == StatutVente.refusee || statut == StatutVente.annulee;

  /// Ce que recevra chaque partenaire retenu à l'échéance.
  List<PartPartenaire> get repartition =>
      conditionsFixees && apportsRetenus.isNotEmpty ? repartir(conditions!, apportsRetenus) : const [];

  Operation copier({
    StatutVente? statut,
    int? prixAchat,
    int? majoration,
    int? dureeJours,
    DateTime? echeance,
    int? commissionArziki,
    List<Garantie>? garanties,
    List<String>? partenairesProposes,
    Map<String, int>? manifestations,
    List<Apport>? apportsRetenus,
    String? notaireUid,
    String? motif,
  }) =>
      Operation(
        id: id,
        titre: titre,
        secteur: secteur,
        image: image,
        statut: statut ?? this.statut,
        entrepriseUid: entrepriseUid,
        clientFinal: clientFinal,
        fournisseur: fournisseur,
        resume: resume,
        montantCommande: montantCommande,
        creeLe: creeLe,
        prixAchat: prixAchat ?? this.prixAchat,
        majoration: majoration ?? this.majoration,
        dureeJours: dureeJours ?? this.dureeJours,
        echeance: echeance ?? this.echeance,
        commissionArziki: commissionArziki ?? this.commissionArziki,
        garanties: garanties ?? this.garanties,
        garantiesProposees: garantiesProposees,
        partenairesProposes: partenairesProposes ?? this.partenairesProposes,
        manifestations: manifestations ?? this.manifestations,
        apportsRetenus: apportsRetenus ?? this.apportsRetenus,
        notaireUid: notaireUid ?? this.notaireUid,
        pays: pays,
        motif: motif ?? this.motif,
      );
}

/// Garanties suggérées selon le montant (le notaire et l'administrateur ajustent).
List<TypeGarantie> garantiesSuggerees(int montant) {
  final g = <TypeGarantie>[TypeGarantie.reservePropriete];
  if (montant >= 5000000) g.addAll([TypeGarantie.cautionnement, TypeGarantie.nantissementMateriel]);
  if (montant >= 30000000) g.addAll([TypeGarantie.nantissementCreance, TypeGarantie.nantissementFondsCommerce]);
  if (montant >= 100000000) g.add(TypeGarantie.hypotheque);
  return g;
}

DateTime _jour(int decalage) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day).add(Duration(days: decalage));
}

const _membres = ['u-membre-1', 'u-membre-2', 'u-membre-3', 'u-membre-4', 'u-membre-5', 'u-membre-6'];
const _partenaires = ['u-partenaire-1', 'u-partenaire-2'];

List<Operation> operationsDemo() => [
      Operation(
        id: 'op-demande',
        titre: 'Réassort de médicaments, deuxième lot',
        secteur: 'Santé',
        image: Images.pharmacie,
        statut: StatutVente.soumise,
        entrepriseUid: 'u-ent-pharma',
        clientFinal: 'Réseau de cliniques, Lomé',
        fournisseur: 'Grossiste pharmaceutique agréé, Lomé',
        resume: 'Commande de 9 500 000 FCFA de médicaments génériques pour un réseau de cliniques.',
        montantCommande: 9500000,
        creeLe: _jour(-3),
        garantiesProposees: const [TypeGarantie.reservePropriete, TypeGarantie.cautionnement],
      ),
      Operation(
        id: 'op-analyse',
        titre: 'Ciment pour une école à Tsévié',
        secteur: 'BTP',
        image: Images.livraisonChantier,
        statut: StatutVente.enAnalyse,
        entrepriseUid: 'u-ent-btp',
        clientFinal: 'Entreprise générale de construction',
        fournisseur: 'Cimenterie, Lomé',
        resume: 'Marché de fourniture de 600 tonnes de ciment pour la construction d\'une école.',
        montantCommande: 52000000,
        creeLe: _jour(-8),
        prixAchat: 46000000,
        majoration: 1840000,
        dureeJours: 60,
        garantiesProposees: const [TypeGarantie.reservePropriete, TypeGarantie.nantissementCreance],
      ),
      Operation(
        id: 'op-pharma',
        titre: 'Réassort de médicaments génériques',
        secteur: 'Santé',
        image: Images.opPharmacie,
        statut: StatutVente.proposee,
        entrepriseUid: 'u-ent-pharma',
        clientFinal: 'Grand compte du secteur santé',
        fournisseur: 'Grossiste pharmaceutique agréé, Lomé',
        resume: "Une pharmacie de Lomé a une commande ferme d'un réseau de cliniques. Le partenaire achète le lot au "
            'grossiste et le revend à la pharmacie, payable à 60 jours.',
        montantCommande: 9200000,
        creeLe: _jour(-15),
        prixAchat: 7800000,
        majoration: 234000,
        dureeJours: 60,
        commissionArziki: 100000,
        garanties: const [Garantie(TypeGarantie.reservePropriete, StatutGarantie.aConstituer)],
        partenairesProposes: _membres,
        notaireUid: 'u-notaire',
      ),
      Operation(
        id: 'op-btp',
        titre: 'Ciment et fers pour un chantier à Agoè',
        secteur: 'BTP',
        image: Images.opBtp,
        statut: StatutVente.interetManifeste,
        entrepriseUid: 'u-ent-btp',
        clientFinal: 'Promoteur immobilier, Lomé',
        fournisseur: 'Négoce de matériaux, zone portuaire',
        resume: 'Fourniture de ciment et de fers pour un immeuble de bureaux. Livraison en deux lots.',
        montantCommande: 21500000,
        creeLe: _jour(-20),
        prixAchat: 18000000,
        majoration: 630000,
        dureeJours: 75,
        commissionArziki: 180000,
        garanties: const [
          Garantie(TypeGarantie.reservePropriete, StatutGarantie.aConstituer),
          Garantie(TypeGarantie.cautionnement, StatutGarantie.aConstituer),
        ],
        partenairesProposes: [..._membres, ..._partenaires],
        manifestations: const {'u-membre-1': 3000000, 'u-partenaire-1': 15000000},
        notaireUid: 'u-notaire',
      ),
      Operation(
        id: 'op-mine',
        titre: "Pièces d'usure pour un site minier",
        secteur: 'Mines et industrie',
        image: Images.equipementIndustriel,
        statut: StatutVente.signee,
        entrepriseUid: 'u-ent-mine',
        clientFinal: 'Grand compte du secteur minier',
        fournisseur: 'Équipementier industriel',
        resume: "Fourniture de pièces d'usure pour un exploitant minier. Contrats signés devant notaire ; le "
            'nantissement de créance doit encore être inscrit au RCCM avant le paiement au fournisseur.',
        montantCommande: 78000000,
        creeLe: _jour(-40),
        prixAchat: 65000000,
        majoration: 2100000,
        dureeJours: 90,
        echeance: _jour(80),
        commissionArziki: 650000,
        garanties: const [
          Garantie(TypeGarantie.reservePropriete, StatutGarantie.signee),
          Garantie(TypeGarantie.nantissementCreance, StatutGarantie.aConstituer),
          Garantie(TypeGarantie.cautionnement, StatutGarantie.signee),
        ],
        partenairesProposes: _partenaires,
        manifestations: const {'u-partenaire-1': 45000000, 'u-partenaire-2': 20000000},
        apportsRetenus: const [Apport('u-partenaire-1', 45000000), Apport('u-partenaire-2', 20000000)],
        notaireUid: 'u-notaire',
      ),
      Operation(
        id: 'op-flotte',
        titre: 'Pièces détachées pour une flotte de camions',
        secteur: 'Transport et logistique',
        image: Images.opFlotte,
        statut: StatutVente.fournisseurPaye,
        entrepriseUid: 'u-ent-btp',
        clientFinal: 'Transporteur de la zone portuaire',
        fournisseur: 'Garage poids lourds, port de Lomé',
        resume: 'Pièces détachées pour l\'entretien d\'une flotte de 40 camions. Fournisseur payé, livraison en cours.',
        montantCommande: 9600000,
        creeLe: _jour(-30),
        prixAchat: 8000000,
        majoration: 260000,
        dureeJours: 60,
        echeance: _jour(35),
        commissionArziki: 100000,
        garanties: const [
          Garantie(TypeGarantie.reservePropriete, StatutGarantie.signee),
          Garantie(TypeGarantie.cautionnement, StatutGarantie.signee),
        ],
        partenairesProposes: _membres,
        manifestations: const {'u-membre-1': 1200000, 'u-membre-2': 4000000, 'u-membre-3': 2800000},
        apportsRetenus: const [Apport('u-membre-1', 1200000), Apport('u-membre-2', 4000000), Apport('u-membre-3', 2800000)],
        notaireUid: 'u-notaire',
      ),
      Operation(
        id: 'op-cereales',
        titre: 'Stock de maïs et de riz pour une coopérative',
        secteur: 'Agriculture',
        image: Images.opCereales,
        statut: StatutVente.livree,
        entrepriseUid: 'u-ent-pharma',
        clientFinal: 'Société de transformation, région des Plateaux',
        fournisseur: 'Coopérative agricole des Plateaux',
        resume: 'Marchandise livrée au client final. Paiement du prix de revente attendu à l\'échéance.',
        montantCommande: 14200000,
        creeLe: _jour(-55),
        prixAchat: 12000000,
        majoration: 360000,
        dureeJours: 60,
        echeance: _jour(12),
        commissionArziki: 120000,
        garanties: const [Garantie(TypeGarantie.reservePropriete, StatutGarantie.signee), Garantie(TypeGarantie.cautionnement, StatutGarantie.signee)],
        partenairesProposes: _membres,
        manifestations: const {'u-membre-1': 1500000, 'u-membre-4': 10500000},
        apportsRetenus: const [Apport('u-membre-1', 1500000), Apport('u-membre-4', 10500000)],
        notaireUid: 'u-notaire',
      ),
      Operation(
        id: 'op-intrants',
        titre: 'Engrais et semences de la campagne 2026',
        secteur: 'Agriculture',
        image: Images.opIntrants,
        statut: StatutVente.enRetard,
        entrepriseUid: 'u-ent-pharma',
        clientFinal: 'Union de coopératives, Atakpamé',
        fournisseur: "Distributeur d'intrants agricoles",
        resume: "L'échéance est dépassée de 18 jours : le client final a payé en retard l'entreprise. Suivi rapproché "
            'par ARZIKI ; les garanties peuvent être mises en œuvre.',
        montantCommande: 7400000,
        creeLe: _jour(-110),
        prixAchat: 6000000,
        majoration: 210000,
        dureeJours: 90,
        echeance: _jour(-18),
        commissionArziki: 100000,
        garanties: const [Garantie(TypeGarantie.reservePropriete, StatutGarantie.signee), Garantie(TypeGarantie.cautionnement, StatutGarantie.signee)],
        partenairesProposes: _membres,
        manifestations: const {'u-membre-1': 800000, 'u-membre-5': 5200000},
        apportsRetenus: const [Apport('u-membre-1', 800000), Apport('u-membre-5', 5200000)],
        notaireUid: 'u-notaire',
      ),
      Operation(
        id: 'op-bureau',
        titre: 'Équipements informatiques pour une administration',
        secteur: 'Équipements',
        image: Images.opBureau,
        statut: StatutVente.cloturee,
        entrepriseUid: 'u-ent-btp',
        clientFinal: 'Grand compte du secteur public',
        fournisseur: 'Distributeur informatique, Lomé',
        resume: "Opération clôturée : le prix de revente a été payé à l'échéance et réparti entre les partenaires.",
        montantCommande: 26800000,
        creeLe: _jour(-150),
        prixAchat: 22000000,
        majoration: 770000,
        dureeJours: 75,
        echeance: _jour(-40),
        commissionArziki: 220000,
        garanties: const [Garantie(TypeGarantie.reservePropriete, StatutGarantie.signee), Garantie(TypeGarantie.cautionnement, StatutGarantie.signee)],
        partenairesProposes: _partenaires,
        manifestations: const {'u-partenaire-1': 12000000, 'u-partenaire-2': 10000000},
        apportsRetenus: const [Apport('u-partenaire-1', 12000000), Apport('u-partenaire-2', 10000000)],
        notaireUid: 'u-notaire',
      ),
    ];

// ---------------------------------------------------------------------------
// Notifications de démonstration
// ---------------------------------------------------------------------------

class Avis {
  const Avis(this.titre, this.texte, this.date, {this.lue = false});
  final String titre;
  final String texte;
  final DateTime date;
  final bool lue;
}

List<Avis> notificationsPour(Role role) => switch (role) {
      Role.entreprise => [
          Avis('Pièce demandée', 'Merci de joindre le devis signé du fournisseur pour « Réassort de médicaments, deuxième lot ».', _jour(-1)),
          Avis('Étape franchie', '« Stock de maïs et de riz » : la marchandise est livrée. Échéance dans 12 jours.', _jour(-4)),
          Avis('Compte validé', 'Votre identité a été vérifiée. Bienvenue sur ARZIKI.', _jour(-30), lue: true),
        ],
      Role.membre || Role.partenaire || Role.partenaireStrategique => [
          Avis('Nouvelle opération proposée', '« Ciment et fers pour un chantier à Agoè » vous est proposée.', _jour(-1)),
          Avis('Signature devant notaire', '« Pièces détachées pour une flotte de camions » : contrats signés, fournisseur payé.', _jour(-3)),
          Avis('Retard à l\'échéance', "« Engrais et semences » : l'échéance est dépassée. Suivi en cours.", _jour(-10)),
          Avis('Rapport mensuel disponible', 'Le rapport du mois dernier est disponible dans Documents.', _jour(-16), lue: true),
        ],
      Role.fournisseur => [
          Avis('Nouveau bon de commande', 'Un bon de commande ARZIKI vous attend : pièces détachées, 8 000 000 FCFA.', _jour(-2)),
        ],
      Role.notaire => [
          Avis('Garantie à inscrire', "« Pièces d'usure pour un site minier » : nantissement de créance à inscrire au RCCM.", _jour(-2)),
        ],
      _ => [
          Avis('Bienvenue', 'Votre compte est en cours de vérification. Nous vous prévenons dès qu\'il est activé.', _jour(0)),
        ],
    };

// ---------------------------------------------------------------------------
// Contrôleur (démonstration) : mêmes règles que les Cloud Functions
// ---------------------------------------------------------------------------

class EtatOperations {
  const EtatOperations({required this.operations});
  final List<Operation> operations;

  Operation? parId(String id) => operations.where((o) => o.id == id).firstOrNull;
}

class ControleurOperations extends Notifier<EtatOperations> {
  @override
  EtatOperations build() => EtatOperations(operations: operationsDemo());

  void _remplacer(Operation o) {
    state = EtatOperations(operations: [for (final x in state.operations) x.id == o.id ? o : x]);
  }

  void _auditer(String uid, String action, String cible, {String? avant, String? apres}) =>
      ref.read(baseDemoProvider).auditer(uid, action, cible, avant: avant, apres: apres);

  Operation _op(String id) {
    final o = state.parId(id);
    if (o == null) throw const ErreurVente('Opération introuvable.');
    return o;
  }

  /// Opérations visibles par un partenaire : seulement celles qui lui ont été
  /// proposées, et seulement si son compte est actif et vérifié (R3, R6).
  List<Operation> proposeesA(String uid, {required bool verifie}) {
    if (!verifie) return const [];
    return state.operations.where((o) => o.partenairesProposes.contains(uid)).toList();
  }

  /// Une entreprise soumet une commande à financer.
  Operation soumettre(Operation o) {
    state = EtatOperations(operations: [o, ...state.operations]);
    _auditer(o.entrepriseUid, 'soumettre_demande', 'operations/${o.id}', apres: '${o.montantCommande}');
    return o;
  }

  /// L'administrateur fixe les conditions ; le coût annuel équivalent est calculé.
  void definirConditions(String acteurUid, String id, {required int prixAchat, required int majoration, required int dureeJours, int commission = 0}) {
    final o = _op(id);
    if (o.statut != StatutVente.enAnalyse && o.statut != StatutVente.proposee) {
      throw const ErreurVente("Les conditions se fixent pendant l'analyse, avant toute signature.");
    }
    final c = ConditionsVente(prixAchat: prixAchat, majoration: majoration, dureeJours: dureeJours)..verifier();
    _remplacer(o.copier(
      prixAchat: prixAchat,
      majoration: majoration,
      dureeJours: dureeJours,
      commissionArziki: commission,
      echeance: _jour(dureeJours),
    ));
    _auditer(acteurUid, 'definir_conditions', 'operations/$id', apres: '$prixAchat + $majoration sur $dureeJours j (${c.coutAnnuelEquivalent} %)');
  }

  void proposer(String acteurUid, String id, List<String> partenaires) {
    final o = _op(id);
    if (!o.conditionsFixees) throw const ErreurVente("Fixez d'abord les conditions de la vente à terme.");
    if (partenaires.isEmpty) throw const ErreurVente('Choisissez au moins un partenaire.');
    if (o.statut != StatutVente.proposee) _verifierTransition(o, StatutVente.proposee);
    _remplacer(o.copier(statut: StatutVente.proposee, partenairesProposes: {...o.partenairesProposes, ...partenaires}.toList()));
    _auditer(acteurUid, 'proposer_operation', 'operations/$id', avant: o.statut.code, apres: partenaires.join(', '));
  }

  /// « Je suis intéressé » : non engageant (R4).
  void manifesterInteret({required String uid, required String id, required int montant}) {
    final o = _op(id);
    if (!o.partenairesProposes.contains(uid)) throw const ErreurVente('Cette opération ne vous a pas été proposée.');
    if (!o.ouverteAuxManifestations) throw const ErreurVente("Cette opération n'est plus ouverte aux manifestations d'intérêt.");
    if (montant <= 0 || montant > (o.prixAchat ?? 0)) {
      throw ErreurVente("Indiquez un montant entre 1 FCFA et le prix d'achat (${o.prixAchat} FCFA).");
    }
    _remplacer(o.copier(statut: StatutVente.interetManifeste, manifestations: {...o.manifestations, uid: montant}));
    _auditer(uid, 'manifester_interet', 'operations/$id', apres: '$montant');
  }

  void retenirApports(String acteurUid, String id, List<Apport> apports) {
    final o = _op(id);
    if (o.statut != StatutVente.interetManifeste) {
      throw const ErreurVente('Les apports se retiennent après les manifestations d\'intérêt, avant la signature.');
    }
    for (final a in apports) {
      if (!o.manifestations.containsKey(a.partenaireUid)) throw const ErreurVente("Un partenaire retenu n'a pas manifesté son intérêt.");
    }
    repartir(o.conditions!, apports);
    _remplacer(o.copier(apportsRetenus: apports));
    _auditer(acteurUid, 'retenir_apports', 'operations/$id', apres: apports.map((a) => '${a.partenaireUid}:${a.montant}').join(', '));
  }

  void majGarantie(String acteurUid, String id, TypeGarantie type, StatutGarantie statut) {
    final o = _op(id);
    final liste = [...o.garanties];
    final i = liste.indexWhere((g) => g.type == type);
    final avant = i >= 0 ? liste[i].statut.code : null;
    if (i >= 0) {
      liste[i] = Garantie(type, statut, piece: liste[i].piece);
    } else {
      liste.add(Garantie(type, statut));
    }
    _remplacer(o.copier(garanties: liste));
    _auditer(acteurUid, 'maj_garantie', 'operations/$id', avant: avant, apres: '${type.code}: ${statut.code}');
  }

  void _verifierTransition(Operation o, StatutVente vers) {
    if (!transitionsVente[o.statut]!.contains(vers)) {
      throw ErreurVente('Passage impossible de « ${o.statut.libelle} » à « ${vers.libelle} ».');
    }
    if (vers == StatutVente.interetManifeste && o.manifestations.isEmpty) {
      throw const ErreurVente("Aucune manifestation d'intérêt n'a été reçue.");
    }
    if (vers == StatutVente.signee) {
      final total = o.apportsRetenus.fold<int>(0, (s, a) => s + a.montant);
      if (total != o.prixAchat) throw const ErreurVente("Les apports retenus doivent couvrir exactement le prix d'achat avant la signature.");
      if (o.garanties.isEmpty) throw const ErreurVente('Ajoutez au moins une garantie avant la signature devant notaire.');
    }
    if (vers == StatutVente.fournisseurPaye && !o.garanties.every((g) => g.constituee)) {
      throw const ErreurVente('Toutes les garanties doivent être signées avant le paiement au fournisseur.');
    }
  }

  void changerStatut(String acteurUid, String id, StatutVente vers, {String? motif}) {
    final o = _op(id);
    if ((vers == StatutVente.refusee || vers == StatutVente.annulee || vers == StatutVente.piecesDemandees) &&
        (motif == null || motif.trim().isEmpty)) {
      throw const ErreurVente('Un motif est obligatoire.');
    }
    _verifierTransition(o, vers);
    _remplacer(o.copier(statut: vers, motif: motif));
    _auditer(acteurUid, 'changer_statut_operation', 'operations/$id', avant: o.statut.code, apres: vers.code);
  }
}

final operationsProvider = NotifierProvider<ControleurOperations, EtatOperations>(ControleurOperations.new);
