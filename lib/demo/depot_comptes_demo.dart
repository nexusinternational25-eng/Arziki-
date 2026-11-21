// Mise en oeuvre de démonstration de DepotComptes, sur la BaseDemo.

import '../comptes/depot_comptes.dart';
import '../core/kyc.dart';
import '../core/roles.dart';
import '../models/acces.dart';
import '../models/utilisateur.dart';
import '../operations/vente_a_terme.dart';
import 'base_demo.dart';

class DepotComptesDemo implements DepotComptes {
  DepotComptesDemo(this.base);

  final BaseDemo base;

  /// Mots de passe provisoires des comptes d'équipe créés pendant la démonstration.
  final Map<String, String> motsDePasseProvisoires = {};

  Utilisateur _compte(String uid) {
    final u = base.utilisateurs[uid];
    if (u == null) throw const ErreurAcces('Compte introuvable.');
    return u;
  }

  void _enregistrer(Utilisateur u) => base.utilisateurs[u.uid] = u;

  // ----- Lecture -----

  @override
  Future<Utilisateur?> lireProfil(String uid) async => base.utilisateurs[uid];

  @override
  Future<List<Utilisateur>> listerComptes() async =>
      base.utilisateurs.values.toList()..sort((a, b) => a.nomComplet.compareTo(b.nomComplet));

  @override
  Future<List<Invitation>> listerInvitations() async =>
      base.invitations.values.toList()..sort((a, b) => b.creeLe.compareTo(a.creeLe));

  @override
  Future<List<EntreeAudit>> lireJournal() async => base.journal.reversed.toList();

  @override
  Future<int> placesOccupees() async {
    final maintenant = base.maintenant();
    final comptes = base.utilisateurs.values.where((u) => u.role.estMembreDuCercle && u.statut != StatutCompte.suspendu).length;
    final invitations = base.invitations.values.where((i) => i.statut(maintenant) == 'En attente').length;
    return comptes + invitations;
  }

  @override
  Future<int> plafondPartenaires() async => base.plafondPartenaires;

  // ----- Invitations -----

  @override
  Future<Invitation> creerInvitation({
    required Utilisateur acteur,
    required String pourNom,
    required String pourTelephone,
    required NiveauCercle niveau,
    int joursValidite = 30,
    String? note,
  }) async {
    ReglesAcces.exigerValidateur(acteur);
    if (pourNom.trim().length < 3) throw const ErreurAcces('Indiquez le nom complet de la personne invitée.');
    if (joursValidite < 1 || joursValidite > 90) {
      throw const ErreurAcces('La durée de validité doit être comprise entre 1 et 90 jours.');
    }
    final telephone = ReglesAcces.normaliserTelephone(pourTelephone);
    ReglesAcces.exigerTelephoneAccepte(telephone);
    if (telephone.length < 10) throw const ErreurAcces('Numéro de téléphone invalide.');
    if (base.parTelephone(telephone) != null) {
      throw const ErreurAcces('Ce numéro a déjà un compte ARZIKI.');
    }
    // Plafond de partenaires (section 24.2).
    try {
      verifierPlaceDisponible(await placesOccupees(), base.plafondPartenaires);
    } on ErreurVente catch (e) {
      throw ErreurAcces(e.message);
    }
    String code;
    do {
      code = Invitation.genererCode();
    } while (base.invitations.containsKey(code));

    final maintenant = base.maintenant();
    final invitation = Invitation(
      code: code,
      pourNom: pourNom.trim(),
      pourTelephone: telephone,
      niveau: niveau,
      creePar: acteur.uid,
      creeLe: maintenant,
      expireLe: maintenant.add(Duration(days: joursValidite)),
      note: note,
    );
    base.invitations[code] = invitation;
    base.auditer(acteur.uid, 'creer_invitation', 'invitations/$code',
        apres: '${invitation.pourNom}, ${niveau.libelle}');
    return invitation;
  }

  @override
  Future<void> annulerInvitation({required Utilisateur acteur, required String code}) async {
    ReglesAcces.exigerValidateur(acteur);
    final inv = base.invitations[code];
    if (inv == null) throw const ErreurAcces('Invitation introuvable.');
    if (inv.estUtilisee) throw const ErreurAcces('Cette invitation a déjà été utilisée.');
    base.invitations[code] = inv.copier(annuleeLe: base.maintenant());
    base.auditer(acteur.uid, 'annuler_invitation', 'invitations/$code');
  }

  @override
  Future<Invitation> verifierInvitation({required String code, required String telephone}) async {
    final inv = base.invitations[code.trim().toUpperCase()];
    // Message volontairement identique dans tous les cas d'échec :
    // on ne révèle pas si un code existe.
    const refus = ErreurAcces(
        "Ce code d'invitation n'est pas valable pour ce numéro. Vérifiez-le ou contactez la personne qui vous a invité.");
    if (inv == null || inv.estUtilisee || inv.estAnnulee || inv.estExpiree(base.maintenant())) throw refus;
    if (inv.pourTelephone != ReglesAcces.normaliserTelephone(telephone)) throw refus;
    return inv;
  }

  /// Appelée par l'inscription : marque l'invitation comme utilisée.
  Invitation consommerInvitation(String code, String telephone, String uid) {
    final inv = base.invitations[code.trim().toUpperCase()]!;
    final utilisee = inv.copier(utiliseLe: base.maintenant(), utilisePar: uid);
    base.invitations[inv.code] = utilisee;
    base.auditer(uid, 'utiliser_invitation', 'invitations/${inv.code}');
    return utilisee;
  }

  // ----- Vérification d'identité -----

  @override
  Future<Utilisateur> soumettreKyc({
    required Utilisateur utilisateur,
    required Map<String, String> pieces,
    String? origineFonds,
  }) async {
    final manquantes = piecesKyc(utilisateur.role)
        .where((p) => p.obligatoire && !pieces.containsKey(p.code))
        .map((p) => p.libelle);
    if (manquantes.isNotEmpty) {
      throw ErreurAcces('Pièces manquantes : ${manquantes.join(', ')}.');
    }
    final u = _compte(utilisateur.uid).copier(kycStatut: StatutKyc.enCours);
    _enregistrer(u);
    base.piecesKyc[u.uid] = Map.of(pieces);
    base.auditer(u.uid, 'soumettre_kyc', 'users/${u.uid}', apres: '${pieces.length} pièce(s)');
    return u;
  }

  // ----- Validation et statut -----

  @override
  Future<void> validerKyc({required Utilisateur acteur, required String uid}) async {
    ReglesAcces.exigerValidateur(acteur);
    final u = _compte(uid);
    // Un compte sans rôle d'accès (ancien candidat) reste en attente.
    final statut = u.role == Role.candidatCercle ? StatutCompte.enAttente : StatutCompte.actif;
    _enregistrer(u.copier(kycStatut: StatutKyc.valide, statut: statut));
    base.auditer(acteur.uid, 'valider_kyc', 'users/$uid', avant: u.kycStatut.code, apres: StatutKyc.valide.code);
  }

  @override
  Future<void> demanderComplementKyc({required Utilisateur acteur, required String uid, required String motif}) async {
    ReglesAcces.exigerValidateur(acteur);
    final u = _compte(uid);
    _enregistrer(u.copier(kycStatut: StatutKyc.aCompleter));
    base.auditer(acteur.uid, 'demander_complement_kyc', 'users/$uid', apres: motif);
  }

  @override
  Future<void> suspendre({required Utilisateur acteur, required String uid, required String motif}) async {
    ReglesAcces.exigerValidateur(acteur);
    final u = _compte(uid);
    if (u.uid == acteur.uid) throw const ErreurAcces('Vous ne pouvez pas suspendre votre propre compte.');
    if (u.role.estAdministration && !acteur.role.peutGererAdmins) {
      throw const ErreurAcces('Seul le super administrateur peut suspendre un administrateur.');
    }
    _enregistrer(u.copier(statut: StatutCompte.suspendu));
    base.auditer(acteur.uid, 'suspendre_compte', 'users/$uid', avant: u.statut.code, apres: motif);
  }

  @override
  Future<void> reactiver({required Utilisateur acteur, required String uid}) async {
    ReglesAcces.exigerValidateur(acteur);
    final u = _compte(uid);
    if (u.role.estAdministration && !acteur.role.peutGererAdmins) {
      throw const ErreurAcces('Seul le super administrateur peut réactiver un administrateur.');
    }
    final statut = u.kycStatut == StatutKyc.valide && u.role != Role.candidatCercle
        ? StatutCompte.actif
        : StatutCompte.enAttente;
    _enregistrer(u.copier(statut: statut));
    base.auditer(acteur.uid, 'reactiver_compte', 'users/$uid', avant: u.statut.code, apres: statut.code);
  }

  // ----- Rôles -----

  @override
  Future<void> attribuerRole({required Utilisateur acteur, required String uid, required Role role}) async {
    final cible = _compte(uid);
    ReglesAcces.exigerDroitAttribution(acteur, cible, role);
    _enregistrer(cible.copier(role: role));
    base.auditer(acteur.uid, 'attribuer_role', 'users/$uid', avant: cible.role.code, apres: role.code);
  }

  @override
  Future<Utilisateur> creerCompteEquipe({
    required Utilisateur acteur,
    required String prenom,
    required String nom,
    required String email,
    required Role role,
  }) async {
    if (!acteur.role.peutGererAdmins) {
      throw const ErreurAcces("Seul le super administrateur crée les comptes de l'équipe.");
    }
    if (role != Role.admin && role != Role.analyste) {
      throw const ErreurAcces("Un compte d'équipe est soit administrateur, soit analyste.");
    }
    final e = email.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) {
      throw const ErreurAcces('Adresse e-mail invalide.');
    }
    if (base.comptesAdmin.any((c) => c.identifiant == e)) {
      throw const ErreurAcces('Cette adresse e-mail est déjà utilisée.');
    }
    final uid = base.nouvelId('u-equipe');
    final u = Utilisateur(
      uid: uid,
      role: role,
      statut: StatutCompte.actif,
      kycStatut: StatutKyc.valide,
      prenom: prenom.trim(),
      nom: nom.trim(),
      email: e,
      creeLe: base.maintenant(),
    );
    _enregistrer(u);
    // En démonstration, mot de passe provisoire tiré au hasard, affiché une seule fois
    // au super administrateur. En production, la personne reçoit un lien pour choisir
    // son mot de passe et activer le double facteur.
    final provisoire = Invitation.genererCode().replaceFirst('ARZ-', '');
    base.comptesAdmin.add(CompteAdminDemo(e, provisoire, uid));
    motsDePasseProvisoires[uid] = provisoire;
    base.auditer(acteur.uid, 'creer_compte_equipe', 'users/$uid', apres: role.code);
    return u;
  }

  @override
  Future<void> signalerAccesRefuse({required Utilisateur utilisateur, required String chemin}) async {
    base.auditer(utilisateur.uid, 'acces_console_refuse', chemin, avant: utilisateur.role.code);
  }
}
