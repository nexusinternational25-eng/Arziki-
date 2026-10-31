// Gestion des comptes et des accès : invitations, candidatures au Cercle,
// validation, rôles, équipe interne.
//
// Chaque méthode correspond à une Cloud Function (CLAUDE.md, section 13) :
// creerInvitation, annulerInvitation, verifierInvitation, deposerCandidature,
// deciderCandidature, validerKyc, changerStatutCompte, attribuerRole,
// creerCompteEquipe, signalerAccesRefuse.
// En production, c'est le serveur qui vérifie les droits ; ici, la version
// de démonstration applique exactement les mêmes règles.

import '../core/roles.dart';
import '../models/acces.dart';
import '../models/utilisateur.dart';

class ErreurAcces implements Exception {
  const ErreurAcces(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Seuil d'alerte sur la taille du Cercle. Au-delà de 100 personnes sans lien
/// juridique entre elles, une offre peut être qualifiée d'appel public à l'épargne
/// dans l'UMOA (visa de l'AMF-UMOA). Valeur à confirmer par l'avocat.
const int seuilAlerteTailleCercle = 90;
const int limiteTailleCercle = 100;

abstract class DepotComptes {
  // ----- Lecture (console) -----
  Future<List<Utilisateur>> listerComptes();
  Future<List<Invitation>> listerInvitations();
  Future<List<Candidature>> listerCandidatures();
  Future<List<EntreeAudit>> lireJournal();
  Future<Candidature?> candidatureDe(String uid);
  Future<int> tailleDuCercle();

  // ----- Investisseurs privés : invitation par l'administrateur -----
  Future<Invitation> creerInvitation({
    required Utilisateur acteur,
    required String pourNom,
    required String pourTelephone,
    required NiveauCercle niveau,
    int joursValidite = 30,
    String? note,
  });
  Future<void> annulerInvitation({required Utilisateur acteur, required String code});

  /// Vérifie qu'un code est utilisable par ce numéro (avant l'inscription).
  Future<Invitation> verifierInvitation({required String code, required String telephone});

  // ----- Investisseurs inscrits seuls : candidature -----
  /// Enregistre aussi le prénom et le nom dans le profil du candidat.
  Future<Candidature> deposerCandidature({
    required Utilisateur candidat,
    required String prenom,
    required String nom,
    required NiveauCercle niveauSouhaite,
    required String trancheEnvisagee,
    required String commentNousConnu,
  });
  Future<void> admettreCandidat({
    required Utilisateur acteur,
    required String uid,
    required NiveauCercle niveau,
  });
  Future<void> refuserCandidat({
    required Utilisateur acteur,
    required String uid,
    required String motif,
  });

  // ----- Vérification d'identité (côté utilisateur) -----
  /// Enregistre les pièces déposées (chemins Cloud Storage) et passe le KYC à en_cours.
  Future<Utilisateur> soumettreKyc({
    required Utilisateur utilisateur,
    required Map<String, String> pieces,
    String? origineFonds,
  });

  // ----- Validation et statut des comptes -----
  Future<void> validerKyc({required Utilisateur acteur, required String uid});
  Future<void> demanderComplementKyc({required Utilisateur acteur, required String uid, required String motif});
  Future<void> suspendre({required Utilisateur acteur, required String uid, required String motif});
  Future<void> reactiver({required Utilisateur acteur, required String uid});

  // ----- Rôles et équipe interne -----
  Future<void> attribuerRole({required Utilisateur acteur, required String uid, required Role role});
  Future<Utilisateur> creerCompteEquipe({
    required Utilisateur acteur,
    required String prenom,
    required String nom,
    required String email,
    required Role role,
  });

  /// Trace une tentative d'accès à la console par un rôle non autorisé.
  Future<void> signalerAccesRefuse({required Utilisateur utilisateur, required String chemin});
}

/// Règles de droits, partagées par la démonstration et décrites à l'identique
/// dans functions/src/acces.ts.
class ReglesAcces {
  ReglesAcces._();

  static void exigerValidateur(Utilisateur acteur) {
    if (!acteur.estActif || !acteur.role.peutValiderComptes) {
      throw const ErreurAcces('Action réservée aux administrateurs.');
    }
  }

  /// Qui peut donner quel rôle :
  /// - personne ne change son propre rôle ;
  /// - seuls les super_admin donnent ou retirent un rôle d'administration ;
  /// - un admin gère les rôles clients et les niveaux du Cercle.
  static void exigerDroitAttribution(Utilisateur acteur, Utilisateur cible, Role nouveauRole) {
    exigerValidateur(acteur);
    if (acteur.uid == cible.uid) {
      throw const ErreurAcces('Vous ne pouvez pas modifier votre propre rôle.');
    }
    final toucheAdministration = nouveauRole.estAdministration || cible.role.estAdministration;
    if (toucheAdministration && !acteur.role.peutGererAdmins) {
      throw const ErreurAcces("Seul le super administrateur gère les comptes d'administration.");
    }
    if (nouveauRole == Role.superAdmin) {
      throw const ErreurAcces(
          'Le rôle de super administrateur ne se donne pas depuis l\'application.');
    }
  }

  /// Format attendu : +228 suivi de 8 chiffres (ou autre indicatif UEMOA).
  static String normaliserTelephone(String brut) {
    final chiffres = brut.replaceAll(RegExp(r'[^0-9+]'), '');
    if (chiffres.startsWith('+')) return chiffres;
    if (chiffres.startsWith('00')) return '+${chiffres.substring(2)}';
    return '+228$chiffres';
  }
}
