// Contrat d'authentification. Deux mises en oeuvre :
// - DepotAuthDemo : données fictives en mémoire, code SMS 123456 ;
// - DepotAuthFirebase (jalon 2, quand le projet Firebase sera fourni).
// Les écrans ne connaissent que ce contrat, jamais Firebase directement.

import '../core/roles.dart';
import '../models/utilisateur.dart';

/// Porte d'entrée choisie au premier lancement (CLAUDE.md, section 5.1).
enum Parcours {
  entreprise('entreprise', 'Je suis une entreprise'),
  invitation('invitation', "J'ai un code d'invitation au Cercle"),
  candidature('candidature', 'Je souhaite rejoindre le Cercle'),
  fournisseur('fournisseur', 'Je suis fournisseur'),
  notaire('notaire', 'Je suis notaire');

  const Parcours(this.code, this.libelle);
  final String code;
  final String libelle;

  static Parcours? depuisCode(String? code) {
    for (final p in Parcours.values) {
      if (p.code == code) return p;
    }
    return null;
  }

  /// Rôle provisoire donné au compte créé par ce parcours.
  /// Pour une invitation, le rôle vient du niveau inscrit sur l'invitation.
  Role? get roleInitial => switch (this) {
        Parcours.entreprise => Role.entreprise,
        Parcours.candidature => Role.candidatCercle,
        Parcours.fournisseur => Role.fournisseur,
        Parcours.notaire => Role.notaire,
        Parcours.invitation => null,
      };
}

/// Données nécessaires pour créer un compte après le code SMS.
class DemandeInscription {
  const DemandeInscription({
    required this.parcours,
    required this.telephone,
    required this.cgVersion,
    this.codeInvitation,
  });

  final Parcours parcours;
  final String telephone;
  final String cgVersion;
  final String? codeInvitation;
}

class ErreurAuth implements Exception {
  const ErreurAuth(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class DepotAuth {
  /// Envoie le code SMS. Lève ErreurAuth si trop de tentatives.
  Future<void> envoyerCodeSms(String telephone);

  /// Vérifie le code et connecte un compte existant.
  /// Renvoie null si aucun compte n'existe pour ce numéro.
  Future<Utilisateur?> connecterParTelephone(String telephone, String code);

  /// Vérifie le code et crée un nouveau compte (statut en_attente).
  Future<Utilisateur> inscrireParTelephone(DemandeInscription demande, String code);

  /// Première étape de connexion administrateur (e-mail + mot de passe).
  Future<void> connecterAdmin(String email, String motDePasse);

  /// Deuxième étape obligatoire : code du double facteur.
  Future<Utilisateur> verifierDoubleFacteur(String code);

  Future<void> deconnecter();
}
