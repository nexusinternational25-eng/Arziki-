// Garde de navigation : décide, pour chaque écran demandé, si l'utilisateur
// peut l'ouvrir ou vers quel écran le renvoyer.
//
// C'est une simple fonction, sans Flutter, pour pouvoir la tester facilement.
// Attention : cette garde protège l'interface. La vraie protection des données
// est faite par les règles Firestore et les Cloud Functions.

import '../config/app_config.dart';
import '../core/roles.dart';
import '../auth/session.dart';

class Chemins {
  Chemins._();

  static const demarrage = '/';
  static const presentation = '/presentation';
  static const choix = '/choix';
  static const invitation = '/invitation';
  static const inscription = '/inscription';
  static const connexion = '/connexion';
  static const connexionAdmin = '/connexion-admin';
  static const doubleFacteur = '/connexion-admin/code';

  static const enAttente = '/en-attente';
  static const identite = '/verification-identite';
  static const candidature = '/candidature';
  static const suspendu = '/compte-suspendu';
  static const accesRefuse = '/acces-refuse';

  static const entreprise = '/entreprise';
  static const cercle = '/cercle';
  static const fournisseur = '/fournisseur';
  static const notaire = '/notaire';

  static const admin = '/admin';
  static const adminComptes = '/admin/comptes';
  static const adminInvitations = '/admin/invitations';
  static const adminCandidatures = '/admin/candidatures';
  static const adminEquipe = '/admin/equipe';
  static const adminJournal = '/admin/journal';

  /// Écrans accessibles sans être connecté (application mobile).
  static const publicsMobile = {
    demarrage, presentation, choix, invitation, inscription, connexion,
    connexionAdmin, doubleFacteur,
  };

  /// Écrans accessibles sans être connecté (console web).
  static const publicsConsole = {demarrage, connexionAdmin, doubleFacteur};

  /// Écrans autorisés à un compte en attente de validation.
  static const autorisesEnAttente = {enAttente, identite, candidature};
}

/// Écran d'accueil de chaque rôle.
String accueilDe(Role role) => switch (role) {
      Role.superAdmin || Role.admin || Role.analyste => Chemins.admin,
      Role.entreprise => Chemins.entreprise,
      Role.membre || Role.partenaire || Role.partenaireStrategique => Chemins.cercle,
      Role.fournisseur => Chemins.fournisseur,
      Role.notaire => Chemins.notaire,
      Role.candidatCercle => Chemins.enAttente,
    };

bool _commencePar(String chemin, String prefixe) =>
    chemin == prefixe || chemin.startsWith('$prefixe/');

/// Le rôle a-t-il le droit d'ouvrir cet écran (compte actif) ?
bool roleAutorise(Role role, String chemin) {
  if (_commencePar(chemin, Chemins.admin)) {
    if (!role.accesConsole) return false;
    if (_commencePar(chemin, Chemins.adminEquipe)) return role.peutGererAdmins;
    if (_commencePar(chemin, Chemins.adminInvitations) ||
        _commencePar(chemin, Chemins.adminCandidatures) ||
        _commencePar(chemin, Chemins.adminJournal)) {
      return role.peutValiderComptes;
    }
    return true; // tableau de bord et liste des comptes (lecture pour l'analyste)
  }
  if (_commencePar(chemin, Chemins.cercle)) return role.estMembreDuCercle;
  if (_commencePar(chemin, Chemins.entreprise)) return role == Role.entreprise;
  if (_commencePar(chemin, Chemins.fournisseur)) return role == Role.fournisseur;
  if (_commencePar(chemin, Chemins.notaire)) return role == Role.notaire;
  if (_commencePar(chemin, Chemins.candidature)) return role == Role.candidatCercle;
  return true;
}

/// Renvoie le chemin de redirection, ou null si l'écran demandé peut s'afficher.
String? redirection(EtatSession etat, String chemin, CibleApp cible) {
  if (chemin == Chemins.accesRefuse) return null;
  final console = cible == CibleApp.console;
  final u = etat.utilisateur;

  // --- Personne connectée ---
  if (u == null) {
    if (console) {
      return Chemins.publicsConsole.contains(chemin) ? null : Chemins.connexionAdmin;
    }
    if (chemin == Chemins.presentation && etat.presentationVue) return Chemins.choix;
    return Chemins.publicsMobile.contains(chemin) ? null : Chemins.presentation;
  }

  // --- Console web réservée à l'administration ---
  if (console && !u.role.accesConsole) return Chemins.accesRefuse;

  // --- Compte suspendu ---
  if (u.statut == StatutCompte.suspendu) {
    return chemin == Chemins.suspendu ? null : Chemins.suspendu;
  }

  // --- Compte en attente de validation ---
  if (u.statut == StatutCompte.enAttente) {
    if (Chemins.autorisesEnAttente.contains(chemin) && roleAutorise(u.role, chemin)) return null;
    return Chemins.enAttente;
  }

  // --- Compte actif ---
  final accueil = accueilDe(u.role);
  final ecransDEntree = {
    ...Chemins.publicsMobile,
    Chemins.enAttente,
    Chemins.suspendu,
  };
  if (ecransDEntree.contains(chemin)) return accueil;
  if (!roleAutorise(u.role, chemin)) return accueil;
  return null;
}
