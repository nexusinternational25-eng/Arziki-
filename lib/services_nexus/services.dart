// Onglet Services, opéré par NEXUS International (CLAUDE.md, section 11).
// Catalogue modifiable depuis la console, commandes avec devis, acompte de 50 %,
// suivi par étapes, livrable et solde ; formations avec sessions et attestations.
// En démonstration, les paiements sont simulés ; en production ils passeront
// par CinetPay et seront confirmés uniquement par le webhook (jalon 7).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session.dart';
import '../core/images.dart';

enum FamilleService {
  montage('Montage de dossiers', 'Diagnostic, business plan, mémorandum, accompagnement bancaire'),
  etatsFinanciers('États financiers', 'Mise en forme, analyse SYSCOHADA, états prévisionnels'),
  formations('Formations', 'Sessions de groupe et formations en entreprise'),
  carnet('ARZIKI Carnet', 'Votre gestion de commerce au quotidien');

  const FamilleService(this.libelle, this.resume);
  final String libelle;
  final String resume;
}

class OffreService {
  const OffreService({
    required this.id,
    required this.famille,
    required this.titre,
    required this.accroche,
    required this.description,
    required this.inclus,
    required this.delai,
    required this.livrables,
    required this.prix,
    required this.image,
    this.prixMin,
    this.commission = 'Aucune',
    this.proposeCommandeFerme = false,
    this.bientot = false,
  });
  final String id;
  final FamilleService famille;
  final String titre;
  final String accroche;
  final String description;
  final List<String> inclus;
  final String delai;
  final List<String> livrables;
  final String image;

  /// Prix affiché (ex. « 150 000 à 500 000 FCFA »).
  final String prix;

  /// Montant de départ en FCFA (sert au devis par défaut), null si sur devis.
  final int? prixMin;
  final String commission;

  /// Après ce service, proposer « Avez-vous une commande ferme ? ».
  final bool proposeCommandeFerme;
  final bool bientot;

  OffreService avecPrix(String prix, int? prixMin) => OffreService(
        id: id,
        famille: famille,
        titre: titre,
        accroche: accroche,
        description: description,
        inclus: inclus,
        delai: delai,
        livrables: livrables,
        prix: prix,
        prixMin: prixMin,
        image: image,
        commission: commission,
        proposeCommandeFerme: proposeCommandeFerme,
        bientot: bientot,
      );
}

const mentionNonRemboursable = 'Frais non remboursables une fois le travail commencé.';
const mentionExpertComptable =
    'Les états financiers certifiés sont établis avec un expert-comptable agréé partenaire.';

const catalogueParDefaut = <OffreService>[
  OffreService(
    id: 'diagnostic',
    famille: FamilleService.montage,
    titre: 'Diagnostic express',
    accroche: 'Savoir en une semaine si votre projet est finançable, et comment.',
    description: 'Un consultant analyse votre activité, vos chiffres et votre besoin, puis vous remet une note '
        'claire : points forts, points à corriger, solutions de financement adaptées.',
    inclus: ['Entretien de 1 h 30', 'Analyse de vos 2 derniers exercices', 'Note de recommandations'],
    delai: '5 jours ouvrés',
    livrables: ['Note de diagnostic (PDF, 6 à 10 pages)'],
    prix: '25 000 FCFA',
    prixMin: 25000,
    image: Images.servicesConseil,
    proposeCommandeFerme: true,
  ),
  OffreService(
    id: 'business-plan',
    famille: FamilleService.montage,
    titre: 'Business plan complet',
    accroche: 'Un dossier solide pour convaincre une banque ou un investisseur.',
    description: 'Étude de marché, stratégie, organisation, projections financières sur 3 à 5 ans et plan de '
        'financement, rédigés avec vous.',
    inclus: ['Ateliers de travail', 'Projections financières', 'Plan de financement', 'Deux relectures'],
    delai: '3 à 5 semaines',
    livrables: ['Business plan (PDF et Word)', 'Modèle financier (tableur)'],
    prix: '150 000 à 500 000 FCFA',
    prixMin: 150000,
    commission: '2 % si le financement est obtenu',
    image: Images.servicesAnalyse,
    proposeCommandeFerme: true,
  ),
  OffreService(
    id: 'projet-structure',
    famille: FamilleService.montage,
    titre: 'Projet structuré : mémorandum et modèle financier',
    accroche: 'Pour les projets qui s\'adressent à des bailleurs et à des fonds.',
    description: "Mémorandum d'information, modèle financier détaillé, structuration du financement et préparation "
        'des échanges avec les bailleurs.',
    inclus: ["Mémorandum d'information", 'Modèle financier détaillé', 'Structuration du financement'],
    delai: '4 à 8 semaines',
    livrables: ['Mémorandum (PDF)', 'Modèle financier (tableur)', 'Présentation investisseurs'],
    prix: '500 000 à 1 500 000 FCFA',
    prixMin: 500000,
    commission: '2 à 3 % si le financement est obtenu',
    image: Images.reunionInvestisseurs,
  ),
  OffreService(
    id: 'grand-projet',
    famille: FamilleService.montage,
    titre: 'Grand projet avec arrangeur',
    accroche: 'Infrastructures et projets industriels, avec un arrangeur financier.',
    description: 'Accompagnement complet des projets de grande taille : structuration, recherche de bailleurs, '
        'coordination des diligences jusqu\'à la signature.',
    inclus: ['Équipe dédiée', 'Recherche de bailleurs', 'Suivi des diligences'],
    delai: 'Selon le projet',
    livrables: ['Dossier de financement complet', 'Rapports d\'avancement'],
    prix: 'Provision de 2 000 000 à 5 000 000 FCFA',
    prixMin: 2000000,
    commission: '1 à 2 % si le financement est obtenu',
    image: Images.port,
  ),
  OffreService(
    id: 'accompagnement-banque',
    famille: FamilleService.montage,
    titre: 'Accompagnement banque, crédit-bail et marché à financer',
    accroche: 'Vous avez un marché ou un équipement à financer ? On vous accompagne.',
    description: 'Préparation et présentation de votre dossier auprès des banques et des sociétés de crédit-bail, '
        'ou accompagnement des entreprises qui ont un marché à financer.',
    inclus: ['Montage du dossier', 'Mise en relation', 'Suivi jusqu\'à la décision'],
    delai: 'Selon le dossier',
    livrables: ['Dossier bancaire', 'Compte rendu des rendez-vous'],
    prix: 'Forfait sur devis',
    image: Images.servicesCamions,
  ),
  OffreService(
    id: 'etats-syscohada',
    famille: FamilleService.etatsFinanciers,
    titre: 'Mise en forme et analyse des états financiers',
    accroche: 'Des comptes présentés selon le SYSCOHADA, et commentés.',
    description: 'Mise en forme de vos états financiers selon le référentiel SYSCOHADA, avec une analyse des '
        'ratios clés et des recommandations. $mentionExpertComptable',
    inclus: ['Bilan et compte de résultat', 'Tableau des flux', 'Analyse des ratios'],
    delai: '2 semaines',
    livrables: ['États financiers mis en forme (PDF)', "Note d'analyse"],
    prix: 'À partir de 100 000 FCFA',
    prixMin: 100000,
    image: Images.servicesAnalyse,
  ),
  OffreService(
    id: 'etats-previsionnels',
    famille: FamilleService.etatsFinanciers,
    titre: 'États financiers prévisionnels',
    accroche: 'Vos comptes des 3 prochaines années, pour préparer une demande de financement.',
    description: 'Compte de résultat, bilan et trésorerie prévisionnels, construits à partir de vos chiffres et de '
        'vos hypothèses. $mentionExpertComptable',
    inclus: ['Hypothèses validées avec vous', 'Prévisionnel sur 3 ans', 'Plan de trésorerie'],
    delai: '2 à 3 semaines',
    livrables: ['États prévisionnels (PDF et tableur)'],
    prix: 'À partir de 100 000 FCFA',
    prixMin: 100000,
    image: Images.dirigeanteSignature,
  ),
  OffreService(
    id: 'formation-entreprise',
    famille: FamilleService.formations,
    titre: 'Formation en entreprise',
    accroche: 'Nos formations, adaptées à votre équipe et dans vos locaux.',
    description: 'Programme construit à partir de vos besoins, animé dans vos locaux, avec attestation de '
        'participation pour chaque stagiaire.',
    inclus: ['Programme sur mesure', 'Supports de cours', 'Attestations'],
    delai: 'Selon votre calendrier',
    livrables: ['Attestations de participation (PDF)'],
    prix: 'Sur devis',
    image: Images.equipe,
  ),
  OffreService(
    id: 'carnet',
    famille: FamilleService.carnet,
    titre: 'ARZIKI Carnet',
    accroche: 'Ventes, stock et crédit client dans votre téléphone.',
    description: 'Un petit outil de gestion par abonnement pour les commerçants : ventes du jour, stock, dettes '
        'des clients et rappels. Bientôt disponible.',
    inclus: ['Ventes et stock', 'Suivi des clients', 'Rapports simples'],
    delai: 'Bientôt disponible',
    livrables: [],
    prix: 'Abonnement mensuel',
    image: Images.commercante,
    bientot: true,
  ),
];

/// Formations du catalogue (modifiables depuis la console).
class Formation {
  const Formation(this.id, this.titre, this.resume, this.duree);
  final String id;
  final String titre;
  final String resume;
  final String duree;
}

const formationsParDefaut = <Formation>[
  Formation('dossier-credit', 'Préparer son dossier de crédit', 'Les pièces, les chiffres et les arguments qui rassurent une banque.', '1 jour'),
  Formation('gestion-pme', 'Gestion financière de la PME', 'Trésorerie, marges, prix de revient : piloter avec des chiffres simples.', '2 jours'),
  Formation('lire-etats', 'Lire ses états financiers', 'Comprendre son bilan et son compte de résultat, repérer les signaux.', '1 jour'),
  Formation('appel-offres', "Répondre à un appel d'offres", 'Constituer un dossier conforme et présenter une offre compétitive.', '1 jour'),
  Formation('garanties', 'Constituer ses garanties', 'Caution, nantissement, hypothèque : ce qui est demandé et comment le préparer.', '1 jour'),
];

class SessionFormation {
  const SessionFormation({
    required this.id,
    required this.formationId,
    required this.date,
    required this.lieu,
    required this.places,
    required this.prix,
    this.inscrits = const [],
    this.attestationsDelivrees = false,
  });
  final String id;
  final String formationId;
  final DateTime date;
  final String lieu;
  final int places;
  final int prix;
  final List<String> inscrits;
  final bool attestationsDelivrees;

  int get placesRestantes => places - inscrits.length;

  SessionFormation copier({List<String>? inscrits, bool? attestationsDelivrees}) => SessionFormation(
        id: id,
        formationId: formationId,
        date: date,
        lieu: lieu,
        places: places,
        prix: prix,
        inscrits: inscrits ?? this.inscrits,
        attestationsDelivrees: attestationsDelivrees ?? this.attestationsDelivrees,
      );
}

final sessionsParDefaut = <SessionFormation>[
  SessionFormation(id: 's1', formationId: 'dossier-credit', date: DateTime(2026, 11, 21), lieu: 'Lomé, Tokoin Wuiti', places: 20, prix: 45000, inscrits: const ['u-ent-btp', 'u-ent-mine']),
  SessionFormation(id: 's2', formationId: 'gestion-pme', date: DateTime(2026, 12, 3), lieu: 'Lomé, Tokoin Wuiti', places: 16, prix: 75000),
  SessionFormation(id: 's3', formationId: 'appel-offres', date: DateTime(2026, 12, 10), lieu: 'Kara', places: 15, prix: 45000),
  SessionFormation(id: 's4', formationId: 'lire-etats', date: DateTime(2026, 10, 15), lieu: 'Lomé, Tokoin Wuiti', places: 20, prix: 40000, inscrits: const ['u-ent-pharma']),
];

/// Étapes d'une commande de service.
enum EtapeCommande {
  besoinEnvoye('Besoin envoyé'),
  devisEnvoye('Devis reçu'),
  acompteRegle('Acompte de 50 % réglé'),
  enCours('Travail en cours'),
  livre('Livrable disponible'),
  soldeRegle('Solde réglé, commande terminée');

  const EtapeCommande(this.libelle);
  final String libelle;
}

class CommandeService {
  const CommandeService({
    required this.id,
    required this.uid,
    required this.offreId,
    required this.besoin,
    required this.creeLe,
    this.pieces = const [],
    this.etape = EtapeCommande.besoinEnvoye,
    this.montantDevis,
    this.livrable,
    this.paiements = const [],
  });
  final String id;
  final String uid;
  final String offreId;
  final String besoin;
  final DateTime creeLe;
  final List<String> pieces;
  final EtapeCommande etape;
  final int? montantDevis;
  final String? livrable;

  /// Paiements simulés : (date, montant).
  final List<(DateTime, int)> paiements;

  int get acompte => ((montantDevis ?? 0) / 2).floor();
  int get solde => (montantDevis ?? 0) - acompte;

  CommandeService avec({EtapeCommande? etape, int? montantDevis, String? livrable, List<(DateTime, int)>? paiements}) =>
      CommandeService(
        id: id,
        uid: uid,
        offreId: offreId,
        besoin: besoin,
        creeLe: creeLe,
        pieces: pieces,
        etape: etape ?? this.etape,
        montantDevis: montantDevis ?? this.montantDevis,
        livrable: livrable ?? this.livrable,
        paiements: paiements ?? this.paiements,
      );
}

class EtatServices {
  const EtatServices({
    required this.catalogue,
    required this.formations,
    required this.sessions,
    required this.commandes,
    required this.alertesCarnet,
    required this.inscriptionsFormation,
  });
  final List<OffreService> catalogue;
  final List<Formation> formations;
  final List<SessionFormation> sessions;
  final List<CommandeService> commandes;
  final Set<String> alertesCarnet;

  /// Paiements des inscriptions aux formations : (date, montant).
  final List<(DateTime, int)> inscriptionsFormation;

  OffreService? offre(String id) => catalogue.where((o) => o.id == id).firstOrNull;
  Formation? formation(String id) => formations.where((f) => f.id == id).firstOrNull;

  EtatServices avec({
    List<OffreService>? catalogue,
    List<SessionFormation>? sessions,
    List<CommandeService>? commandes,
    Set<String>? alertesCarnet,
    List<(DateTime, int)>? inscriptionsFormation,
  }) =>
      EtatServices(
        catalogue: catalogue ?? this.catalogue,
        formations: formations,
        sessions: sessions ?? this.sessions,
        commandes: commandes ?? this.commandes,
        alertesCarnet: alertesCarnet ?? this.alertesCarnet,
        inscriptionsFormation: inscriptionsFormation ?? this.inscriptionsFormation,
      );

  /// Chiffre d'affaires encaissé sur un mois (acomptes, soldes et inscriptions).
  int chiffreAffairesDuMois(DateTime mois) {
    bool memeMois(DateTime d) => d.year == mois.year && d.month == mois.month;
    var total = 0;
    for (final c in commandes) {
      for (final p in c.paiements) {
        if (memeMois(p.$1)) total += p.$2;
      }
    }
    for (final p in inscriptionsFormation) {
      if (memeMois(p.$1)) total += p.$2;
    }
    return total;
  }
}

class ErreurService implements Exception {
  const ErreurService(this.message);
  final String message;
  @override
  String toString() => message;
}

class ControleurServices extends Notifier<EtatServices> {
  DateTime Function() maintenant = DateTime.now;

  @override
  EtatServices build() => EtatServices(
        catalogue: List.of(catalogueParDefaut),
        formations: List.of(formationsParDefaut),
        sessions: List.of(sessionsParDefaut),
        commandes: [
          CommandeService(
            id: 'c1',
            uid: 'u-ent-pharma',
            offreId: 'business-plan',
            besoin: "Business plan pour l'ouverture d'une deuxième officine à Kara.",
            creeLe: DateTime(2026, 10, 12),
            etape: EtapeCommande.enCours,
            montantDevis: 300000,
            paiements: [(DateTime(2026, 10, 14), 150000)],
          ),
          CommandeService(
            id: 'c2',
            uid: 'u-ent-btp',
            offreId: 'diagnostic',
            besoin: 'Savoir si mon entreprise peut financer un nouveau camion-benne.',
            creeLe: DateTime(2026, 10, 29),
          ),
        ],
        alertesCarnet: {'u-ent-mine'},
        inscriptionsFormation: [(DateTime(2026, 10, 5), 40000), (DateTime(2026, 10, 20), 45000), (DateTime(2026, 10, 24), 45000)],
      );

  void _auditer(String acteur, String action, String cible, {String? apres}) =>
      ref.read(baseDemoProvider).auditer(acteur, action, cible, apres: apres);

  void _remplacer(CommandeService c) =>
      state = state.avec(commandes: [for (final x in state.commandes) x.id == c.id ? c : x]);

  CommandeService commande(String id) {
    final c = state.commandes.where((x) => x.id == id).firstOrNull;
    if (c == null) throw const ErreurService('Commande introuvable.');
    return c;
  }

  // ----- Côté client -----

  CommandeService commander({required String uid, required String offreId, required String besoin, List<String> pieces = const []}) {
    if (besoin.trim().length < 10) throw const ErreurService('Décrivez votre besoin en quelques phrases.');
    final c = CommandeService(
      id: 'c${state.commandes.length + 1}',
      uid: uid,
      offreId: offreId,
      besoin: besoin.trim(),
      pieces: pieces,
      creeLe: maintenant(),
    );
    state = state.avec(commandes: [c, ...state.commandes]);
    _auditer(uid, 'commander_service', 'commandes_services/${c.id}', apres: offreId);
    return c;
  }

  /// Paiement simulé de l'acompte (50 %) puis du solde.
  void payer({required String uid, required String commandeId}) {
    final c = commande(commandeId);
    if (c.uid != uid) throw const ErreurService('Cette commande ne vous appartient pas.');
    if (c.etape == EtapeCommande.devisEnvoye) {
      _remplacer(c.avec(etape: EtapeCommande.acompteRegle, paiements: [...c.paiements, (maintenant(), c.acompte)]));
      _auditer(uid, 'payer_acompte_service', 'commandes_services/${c.id}', apres: '${c.acompte}');
    } else if (c.etape == EtapeCommande.livre) {
      _remplacer(c.avec(etape: EtapeCommande.soldeRegle, paiements: [...c.paiements, (maintenant(), c.solde)]));
      _auditer(uid, 'payer_solde_service', 'commandes_services/${c.id}', apres: '${c.solde}');
    } else {
      throw const ErreurService("Aucun paiement n'est attendu à cette étape.");
    }
  }

  void inscrire({required String uid, required String sessionId}) {
    final s = state.sessions.firstWhere((x) => x.id == sessionId);
    if (s.inscrits.contains(uid)) throw const ErreurService('Vous êtes déjà inscrit à cette session.');
    if (s.placesRestantes <= 0) throw const ErreurService('Cette session est complète.');
    state = state.avec(
      sessions: [for (final x in state.sessions) x.id == s.id ? x.copier(inscrits: [...x.inscrits, uid]) : x],
      inscriptionsFormation: [...state.inscriptionsFormation, (maintenant(), s.prix)],
    );
    _auditer(uid, 'inscrire_formation', 'sessions/${s.id}', apres: '${s.prix}');
  }

  void prevenirCarnet(String uid) {
    state = state.avec(alertesCarnet: {...state.alertesCarnet, uid});
  }

  // ----- Côté console (administrateurs) -----

  void envoyerDevis({required String acteur, required String commandeId, required int montant}) {
    final c = commande(commandeId);
    if (c.etape != EtapeCommande.besoinEnvoye) throw const ErreurService('Le devis a déjà été envoyé.');
    if (montant <= 0) throw const ErreurService('Indiquez un montant.');
    _remplacer(c.avec(etape: EtapeCommande.devisEnvoye, montantDevis: montant));
    _auditer(acteur, 'envoyer_devis_service', 'commandes_services/${c.id}', apres: '$montant');
  }

  void demarrer({required String acteur, required String commandeId}) {
    final c = commande(commandeId);
    if (c.etape != EtapeCommande.acompteRegle) throw const ErreurService("L'acompte n'est pas encore réglé.");
    _remplacer(c.avec(etape: EtapeCommande.enCours));
    _auditer(acteur, 'demarrer_service', 'commandes_services/${c.id}');
  }

  void livrer({required String acteur, required String commandeId, required String livrable}) {
    final c = commande(commandeId);
    if (c.etape != EtapeCommande.enCours) throw const ErreurService("Le travail n'est pas en cours.");
    _remplacer(c.avec(etape: EtapeCommande.livre, livrable: livrable));
    _auditer(acteur, 'livrer_service', 'commandes_services/${c.id}', apres: livrable);
  }

  void modifierPrix({required String acteur, required String offreId, required String prix, int? prixMin}) {
    state = state.avec(catalogue: [for (final o in state.catalogue) o.id == offreId ? o.avecPrix(prix, prixMin) : o]);
    _auditer(acteur, 'modifier_tarif_service', 'services_catalogue/$offreId', apres: prix);
  }

  void ajouterSession({required String acteur, required SessionFormation s}) {
    state = state.avec(sessions: [...state.sessions, s]..sort((a, b) => a.date.compareTo(b.date)));
    _auditer(acteur, 'ajouter_session_formation', 'sessions/${s.id}');
  }

  void delivrerAttestations({required String acteur, required String sessionId}) {
    state = state.avec(sessions: [
      for (final s in state.sessions) s.id == sessionId ? s.copier(attestationsDelivrees: true) : s,
    ]);
    _auditer(acteur, 'delivrer_attestations', 'sessions/$sessionId');
  }
}

final servicesProvider = NotifierProvider<ControleurServices, EtatServices>(ControleurServices.new);
