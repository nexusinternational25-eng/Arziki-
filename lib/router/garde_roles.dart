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

  // Entrée
  static const demarrage = '/';
  static const presentation = '/presentation';
  static const choix = '/choix';
  static const decouvrir = '/decouvrir';
  static const invitation = '/invitation';
  static const inscription = '/inscription';
  static const connexion = '/connexion';
  static const connexionAdmin = '/connexion-admin';
  static const doubleFacteur = '/connexion-admin/code';

  // Compte
  static const enAttente = '/en-attente';
  static const identite = '/verification-identite';
  static const candidature = '/candidature';
  static const suspendu = '/compte-suspendu';
  static const accesRefuse = '/acces-refuse';
  static const notifications = '/notifications';
  static const profil = '/profil';
  static const parametres = '/profil/parametres';
  static const documents = '/profil/documents';

  // Pages d'information (publiques)
  static const infos = '/infos';
  static String info(String id) => '/infos/$id';
  static const faq = '/infos/faq';

  // Services (catalogue public, commande avec compte)
  static const services = '/services';
  static const formations = '/services/formations';
  static String offre(String id) => '/services/offre/$id';
  static String commanderOffre(String id) => '/services/offre/$id/commander';
  static String commandeService(String id) => '/services/commande/$id';

  // Espaces
  static const entreprise = '/entreprise';
  static const nouvelleDemande = '/entreprise/demande';
  static String operationEntreprise(String id) => '/entreprise/operation/$id';
  static const cercle = '/cercle';
  static String operationCercle(String id) => '/cercle/operation/$id';
  static const fournisseur = '/fournisseur';
  static const notaire = '/notaire';

  // Console
  static const admin = '/admin';
  static const adminComptes = '/admin/comptes';
  static const adminInvitations = '/admin/invitations';
  static const adminCandidatures = '/admin/candidatures';
  static const adminServices = '/admin/services';
  static const adminContenus = '/admin/contenus';
  static const adminEquipe = '/admin/equipe';
  static const adminJournal = '/admin/journal';

  /// Écrans d'entrée (sans compte). Une personne connectée qui les ouvre retourne à son accueil.
  static const entreeMobile = {
    demarrage, presentation, choix, decouvrir, invitation, inscription, connexion,
    connexionAdmin, doubleFacteur,
  };

  /// Écrans accessibles sans être connecté (console web).
  static const publicsConsole = {demarrage, connexionAdmin, doubleFacteur};

  /// Écrans autorisés à un compte en attente de validation.
  static const autorisesEnAttente = {enAttente, identite, candidature, notifications, profil, parametres, documents};
}

bool _commencePar(String chemin, String prefixe) => chemin == prefixe || chemin.startsWith('$prefixe/');

/// Contenu public : pages d'information et catalogue des Services (sans commande).
bool estContenuPublic(String chemin) {
  if (_commencePar(chemin, Chemins.infos)) return true;
  if (chemin == Chemins.services || chemin == Chemins.formations) return true;
  return chemin.startsWith('/services/offre/') && !chemin.endsWith('/commander');
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

/// Le rôle a-t-il le droit d'ouvrir cet écran (compte actif) ?
bool roleAutorise(Role role, String chemin) {
  if (_commencePar(chemin, Chemins.admin)) {
    if (!role.accesConsole) return false;
    if (_commencePar(chemin, Chemins.adminEquipe)) return role.peutGererAdmins;
    if (_commencePar(chemin, Chemins.adminInvitations) ||
        _commencePar(chemin, Chemins.adminCandidatures) ||
        _commencePar(chemin, Chemins.adminJournal) ||
        _commencePar(chemin, Chemins.adminServices) ||
        _commencePar(chemin, Chemins.adminContenus)) {
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

  // --- Personne non connectée (ou visiteur) ---
  if (u == null) {
    if (console) {
      return Chemins.publicsConsole.contains(chemin) ? null : Chemins.connexionAdmin;
    }
    if (chemin == Chemins.presentation && etat.presentationVue) return Chemins.choix;
    if (Chemins.entreeMobile.contains(chemin) || estContenuPublic(chemin)) return null;
    return etat.presentationVue ? Chemins.choix : Chemins.presentation;
  }

  // --- Console web réservée à l'administration ---
  if (console && !u.role.accesConsole) return Chemins.accesRefuse;

  // --- Compte suspendu ---
  if (u.statut == StatutCompte.suspendu) {
    if (chemin == Chemins.suspendu || _commencePar(chemin, Chemins.infos)) return null;
    return Chemins.suspendu;
  }

  // --- Compte en attente de validation ---
  if (u.statut == StatutCompte.enAttente) {
    if (Chemins.autorisesEnAttente.contains(chemin) && roleAutorise(u.role, chemin)) return null;
    if (estContenuPublic(chemin)) return null;
    return Chemins.enAttente;
  }

  // --- Compte actif ---
  final accueil = accueilDe(u.role);
  if (Chemins.entreeMobile.contains(chemin) || chemin == Chemins.enAttente || chemin == Chemins.suspendu) {
    return accueil;
  }
  if (!roleAutorise(u.role, chemin)) return accueil;
  return null;
}
