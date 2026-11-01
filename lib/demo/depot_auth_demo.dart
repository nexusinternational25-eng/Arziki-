// Authentification de démonstration : vérification du numéro simulée pour les clients
// (message WhatsApp confirmé automatiquement, code 123456 par WhatsApp ou SMS) ;
// pour l'administration, vrai contrôle du mot de passe et du code à 6 chiffres.

import '../auth/acces_admin.dart';
import '../auth/depot_auth.dart';
import '../comptes/depot_comptes.dart';
import '../config/app_config.dart';
import '../core/roles.dart';
import '../models/utilisateur.dart';
import 'base_demo.dart';
import 'depot_comptes_demo.dart';

class DepotAuthDemo implements DepotAuth {
  DepotAuthDemo(this.base, this.comptes, {this.proprietaire = ParametresAccesAdmin.proprietaire});

  final BaseDemo base;
  final DepotComptesDemo comptes;

  /// Paramètres du compte du super administrateur (remplaçables dans les tests).
  final ParametresAccesAdmin proprietaire;

  // Limitation des tentatives (CLAUDE.md, section 14).
  static const int maxSmsParHeure = 5;
  static const int maxEchecs = 5;
  final Map<String, List<DateTime>> _envoisSms = {};
  final Map<String, int> _echecs = {};

  void _verifierCode(String cle, String code) {
    if ((_echecs[cle] ?? 0) >= maxEchecs) {
      throw const ErreurAuth('Trop de tentatives. Réessayez dans 15 minutes.');
    }
    if (code.trim() != AppConfig.codeSmsDemo) {
      _echecs[cle] = (_echecs[cle] ?? 0) + 1;
      throw const ErreurAuth('Code incorrect.');
    }
    _echecs.remove(cle);
  }

  /// Limite commune à tous les moyens de vérification : 5 demandes par heure.
  void _compterDemande(String t) {
    final ilYaUneHeure = base.maintenant().subtract(const Duration(hours: 1));
    final envois = (_envoisSms[t] ?? [])..removeWhere((d) => d.isBefore(ilYaUneHeure));
    if (envois.length >= maxSmsParHeure) {
      throw const ErreurAuth('Trop de codes demandés pour ce numéro. Réessayez dans une heure.');
    }
    envois.add(base.maintenant());
    _envoisSms[t] = envois;
  }

  // Vérifications par message WhatsApp en cours : identifiant -> numéro, nombre de consultations.
  final Map<String, ({String telephone, int consultations, bool utilisee})> _messages = {};
  int _compteurMessages = 0;

  @override
  Future<VerificationParMessage> demarrerVerificationParMessage(String telephone) async {
    final t = ReglesAcces.normaliserTelephone(telephone);
    _compterDemande(t);
    final id = 'demo-${++_compteurMessages}';
    _messages[id] = (telephone: t, consultations: 0, utilisee: false);
    const message = 'Bonjour ARZIKI, voici mon code de vérification : 482915';
    return VerificationParMessage(
      id: id,
      message: message,
      lien: Uri.parse('https://wa.me/22891978080?text=${Uri.encodeComponent(message)}'),
    );
  }

  /// En démonstration, le message est « reçu » à la deuxième consultation (environ 3 secondes).
  @override
  Future<bool> verificationConfirmee(String id) async {
    final v = _messages[id];
    if (v == null) throw const ErreurAuth('Vérification introuvable. Recommencez.');
    final n = v.consultations + 1;
    _messages[id] = (telephone: v.telephone, consultations: n, utilisee: v.utilisee);
    return n >= 2;
  }

  @override
  Future<void> envoyerCode(String telephone, CanalCode canal) async {
    _compterDemande(ReglesAcces.normaliserTelephone(telephone));
  }

  void _verifierPreuve(String t, PreuveTelephone preuve) {
    switch (preuve) {
      case PreuveCode(:final code):
        _verifierCode(t, code);
      case PreuveMessage(:final id):
        final v = _messages[id];
        if (v == null || v.telephone != t || v.consultations < 2) {
          throw const ErreurAuth("Votre message WhatsApp n'est pas encore arrivé.");
        }
        if (v.utilisee) throw const ErreurAuth('Cette vérification a déjà été utilisée. Recommencez.');
        _messages[id] = (telephone: v.telephone, consultations: v.consultations, utilisee: true);
    }
  }

  @override
  Future<Utilisateur?> connecterParTelephone(String telephone, PreuveTelephone preuve) async {
    final t = ReglesAcces.normaliserTelephone(telephone);
    _verifierPreuve(t, preuve);
    final u = base.parTelephone(t);
    if (u != null && u.role.estAdministration) {
      throw const ErreurAuth('Les administrateurs se connectent avec leur adresse e-mail.');
    }
    return u;
  }

  @override
  Future<Utilisateur> inscrireParTelephone(DemandeInscription demande, PreuveTelephone preuve) async {
    final t = ReglesAcces.normaliserTelephone(demande.telephone);
    _verifierPreuve(t, preuve);
    if (base.parTelephone(t) != null) {
      throw const ErreurAuth('Ce numéro a déjà un compte. Utilisez « Se connecter ».');
    }

    Role role;
    String? codeInvitation;
    if (demande.parcours == Parcours.invitation) {
      // Cercle fermé : le code doit être nominatif, valable et lié à ce numéro.
      final inv = await comptes.verifierInvitation(code: demande.codeInvitation ?? '', telephone: t);
      role = inv.niveau.role;
      codeInvitation = inv.code;
    } else {
      role = demande.parcours.roleInitial!;
    }

    final uid = base.nouvelId('u-nouveau');
    final u = Utilisateur(
      uid: uid,
      role: role,
      statut: StatutCompte.enAttente,
      kycStatut: StatutKyc.nonCommence,
      telephone: t,
      invitationCode: codeInvitation,
      cgVersionAcceptee: demande.cgVersion,
      cgAccepteeLe: base.maintenant(),
      creeLe: base.maintenant(),
    );
    base.utilisateurs[uid] = u;
    if (codeInvitation != null) comptes.consommerInvitation(codeInvitation, t, uid);
    base.auditer(uid, 'inscription', 'users/$uid', apres: '${role.code} (${demande.parcours.code})');
    return u;
  }

  // ----- Administration -----
  // Super administrateur : identifiant + mot de passe (empreinte PBKDF2) + code
  // à 6 chiffres de son application d'authentification (TOTP).
  // Après 5 erreurs, l'identifiant est bloqué 15 minutes.

  final Map<String, DateTime> _bloqueJusquA = {};
  String? _adminEnAttente;
  List<int>? _cleTotpEnAttente;

  void _verifierBlocage(String cle) {
    final fin = _bloqueJusquA[cle];
    if (fin != null && base.maintenant().isBefore(fin)) {
      throw const ErreurAuth('Trop de tentatives. Accès bloqué pendant 15 minutes.');
    }
  }

  void _echec(String cle) {
    final n = (_echecs[cle] ?? 0) + 1;
    _echecs[cle] = n;
    if (n >= maxEchecs) {
      _bloqueJusquA[cle] = base.maintenant().add(const Duration(minutes: 15));
      _echecs.remove(cle);
    }
  }

  @override
  Future<void> connecterAdmin(String identifiant, String motDePasse) async {
    final id = identifiant.trim().toLowerCase();
    _verifierBlocage(id);
    _adminEnAttente = null;
    _cleTotpEnAttente = null;

    if (id == proprietaire.identifiant) {
      final cle = verifierMotDePasse(proprietaire, motDePasse);
      if (cle != null) {
        _adminEnAttente = proprietaire.uid;
        _cleTotpEnAttente = cle;
        return;
      }
    } else {
      final compte = base.comptesAdmin.where((c) => c.identifiant == id && c.motDePasse == motDePasse);
      if (compte.isNotEmpty) {
        _adminEnAttente = compte.first.uid;
        return;
      }
    }
    _echec(id);
    base.auditer('inconnu', 'connexion_admin_refusee', id);
    // Même message dans tous les cas : on ne dit pas si l'identifiant existe.
    throw const ErreurAuth('Identifiant ou mot de passe incorrect.');
  }

  @override
  Future<Utilisateur> verifierDoubleFacteur(String code) async {
    final uid = _adminEnAttente;
    if (uid == null) throw const ErreurAuth('Reprenez la connexion depuis le début.');
    final cleBlocage = '2fa-$uid';
    _verifierBlocage(cleBlocage);

    final cle = _cleTotpEnAttente;
    final bon = cle != null
        ? verifierCodeTotp(cle, code, base.maintenant())
        // Comptes d'équipe créés pendant la démonstration : code simulé.
        : code.trim() == AppConfig.codeSmsDemo;
    if (!bon) {
      _echec(cleBlocage);
      throw const ErreurAuth('Code incorrect. Saisissez le code affiché dans votre application d\'authentification.');
    }
    _echecs.remove(cleBlocage);
    _adminEnAttente = null;
    _cleTotpEnAttente = null;
    final u = base.utilisateurs[uid]!;
    if (u.statut == StatutCompte.suspendu) throw const ErreurAuth('Ce compte est suspendu.');
    base.auditer(uid, 'connexion_admin', 'users/$uid');
    return u;
  }

  @override
  Future<void> deconnecter() async {
    _adminEnAttente = null;
    _cleTotpEnAttente = null;
  }
}
