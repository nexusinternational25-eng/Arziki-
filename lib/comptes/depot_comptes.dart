// Gestion des comptes et des accès : invitations (seule porte d'entrée des
// partenaires financiers, section 24.2), validation, rôles, équipe interne.
//
// Chaque méthode correspond à une Cloud Function (CLAUDE.md, section 13) :
// creerInvitation, annulerInvitation, verifierInvitation, validerKyc, changerStatutCompte, attribuerRole,
// creerCompteEquipe, signalerAccesRefuse.
// En production, c'est le serveur qui vérifie les droits ; ici, la version
// de démonstration applique exactement les mêmes règles.

import '../core/pays.dart';
import '../core/roles.dart';
import '../models/acces.dart';
import '../models/utilisateur.dart';

class ErreurAcces implements Exception {
  const ErreurAcces(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Plafond de partenaires financiers (section 24.2) : réglé par le super
/// administrateur, 50 par défaut, jamais plus de 99 (voir vente_a_terme.dart).
/// On compte les partenaires actifs ou en attente et les invitations encore valables.

abstract class DepotComptes {
  /// Profil d'une personne (la sienne, ou n'importe laquelle pour l'équipe).
  Future<Utilisateur?> lireProfil(String uid);

  // ----- Lecture (console) -----
  Future<List<Utilisateur>> listerComptes();
  Future<List<Invitation>> listerInvitations();
  Future<List<EntreeAudit>> lireJournal();
  /// Places occupées : partenaires actifs ou en attente, et invitations encore valables.
  Future<int> placesOccupees();

  /// Plafond réglé par le super administrateur (50 par défaut, 99 au maximum).
  Future<int> plafondPartenaires();

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

  /// Format international. Sans indicatif, on suppose le pays par défaut (section 23).
  /// Refuse un numéro mal formé ou d'un pays qui n'est pas encore ouvert.
  static void exigerTelephoneAccepte(String telephone) {
    final refus = PaysConfig.erreurTelephone(normaliserTelephone(telephone));
    if (refus != null) throw ErreurAcces(refus);
  }

  static String normaliserTelephone(String brut) {
    final chiffres = brut.replaceAll(RegExp(r'[^0-9+]'), '');
    if (chiffres.startsWith('+')) return chiffres;
    if (chiffres.startsWith('00')) return '+${chiffres.substring(2)}';
    return '${PaysConfig.parDefaut.indicatif}$chiffres';
  }
}
