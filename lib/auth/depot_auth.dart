// Contrat d'authentification. Deux mises en oeuvre :
// - DepotAuthDemo : données fictives en mémoire, code 123456, WhatsApp simulé ;
// - DepotAuthFirebase : production.
// Vérification du numéro (décision du 1er novembre 2026) : WhatsApp d'abord,
// SMS en secours. Voir CLAUDE.md, section 22.3.
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

/// Données nécessaires pour créer un compte après la vérification du numéro.
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

/// Moyen de recevoir un code à 6 chiffres.
enum CanalCode {
  whatsapp('WhatsApp'),
  sms('SMS');

  const CanalCode(this.libelle);
  final String libelle;
}

/// Vérification où le client envoie lui-même un message WhatsApp à ARZIKI.
class VerificationParMessage {
  const VerificationParMessage({required this.id, required this.message, required this.lien});
  final String id;

  /// Texte déjà rédigé, avec le code.
  final String message;

  /// Lien qui ouvre WhatsApp avec ce message, adressé au numéro d'ARZIKI.
  final Uri lien;
}

/// Ce qui prouve que la personne possède bien ce numéro.
sealed class PreuveTelephone {
  const PreuveTelephone();
}

/// Code à 6 chiffres reçu par WhatsApp ou par SMS.
class PreuveCode extends PreuveTelephone {
  const PreuveCode(this.code);
  final String code;
}

/// Message WhatsApp envoyé par le client et reçu par ARZIKI.
class PreuveMessage extends PreuveTelephone {
  const PreuveMessage(this.id);
  final String id;
}

abstract class DepotAuth {
  /// Voie principale : prépare le message WhatsApp que le client va envoyer.
  Future<VerificationParMessage> demarrerVerificationParMessage(String telephone);

  /// Vrai quand ARZIKI a bien reçu le message du client.
  Future<bool> verificationConfirmee(String id);

  /// Voies de secours : envoie un code par WhatsApp ou par SMS.
  /// Lève ErreurAuth si trop de tentatives.
  Future<void> envoyerCode(String telephone, CanalCode canal);

  /// Vérifie la preuve et connecte un compte existant.
  /// Renvoie null si aucun compte n'existe pour ce numéro.
  Future<Utilisateur?> connecterParTelephone(String telephone, PreuveTelephone preuve);

  /// Vérifie la preuve et crée un nouveau compte (statut en_attente).
  Future<Utilisateur> inscrireParTelephone(DemandeInscription demande, PreuveTelephone preuve);

  /// Première étape de connexion administrateur (e-mail + mot de passe).
  Future<void> connecterAdmin(String email, String motDePasse);

  /// Deuxième étape obligatoire : code du double facteur.
  Future<Utilisateur> verifierDoubleFacteur(String code);

  Future<void> deconnecter();
}
