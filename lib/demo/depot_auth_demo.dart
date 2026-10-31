// Authentification de démonstration : SMS simulé (code 123456),
// connexion admin par e-mail + mot de passe + double facteur simulé.

import '../auth/depot_auth.dart';
import '../comptes/depot_comptes.dart';
import '../config/app_config.dart';
import '../core/roles.dart';
import '../models/utilisateur.dart';
import 'base_demo.dart';
import 'depot_comptes_demo.dart';

class DepotAuthDemo implements DepotAuth {
  DepotAuthDemo(this.base, this.comptes);

  final BaseDemo base;
  final DepotComptesDemo comptes;

  // Limitation des tentatives (CLAUDE.md, section 14).
  static const int maxSmsParHeure = 5;
  static const int maxEchecs = 5;
  final Map<String, List<DateTime>> _envoisSms = {};
  final Map<String, int> _echecs = {};

  String? _adminEnAttente2fa;

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

  @override
  Future<void> envoyerCodeSms(String telephone) async {
    final t = ReglesAcces.normaliserTelephone(telephone);
    final ilYaUneHeure = base.maintenant().subtract(const Duration(hours: 1));
    final envois = (_envoisSms[t] ?? [])..removeWhere((d) => d.isBefore(ilYaUneHeure));
    if (envois.length >= maxSmsParHeure) {
      throw const ErreurAuth('Trop de codes demandés pour ce numéro. Réessayez dans une heure.');
    }
    envois.add(base.maintenant());
    _envoisSms[t] = envois;
  }

  @override
  Future<Utilisateur?> connecterParTelephone(String telephone, String code) async {
    final t = ReglesAcces.normaliserTelephone(telephone);
    _verifierCode(t, code);
    final u = base.parTelephone(t);
    if (u != null && u.role.estAdministration) {
      throw const ErreurAuth('Les administrateurs se connectent avec leur adresse e-mail.');
    }
    return u;
  }

  @override
  Future<Utilisateur> inscrireParTelephone(DemandeInscription demande, String code) async {
    final t = ReglesAcces.normaliserTelephone(demande.telephone);
    _verifierCode(t, code);
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

  @override
  Future<void> connecterAdmin(String email, String motDePasse) async {
    final e = email.trim().toLowerCase();
    if ((_echecs[e] ?? 0) >= maxEchecs) {
      throw const ErreurAuth('Trop de tentatives. Réessayez dans 15 minutes.');
    }
    final compte = base.comptesAdmin.where((c) => c.email == e && c.motDePasse == motDePasse);
    if (compte.isEmpty) {
      _echecs[e] = (_echecs[e] ?? 0) + 1;
      throw const ErreurAuth('Adresse e-mail ou mot de passe incorrect.');
    }
    _echecs.remove(e);
    _adminEnAttente2fa = compte.first.uid;
  }

  @override
  Future<Utilisateur> verifierDoubleFacteur(String code) async {
    final uid = _adminEnAttente2fa;
    if (uid == null) throw const ErreurAuth('Reprenez la connexion depuis le début.');
    _verifierCode('2fa-$uid', code);
    _adminEnAttente2fa = null;
    final u = base.utilisateurs[uid]!;
    if (u.statut == StatutCompte.suspendu) throw const ErreurAuth('Ce compte est suspendu.');
    base.auditer(uid, 'connexion_admin', 'users/$uid');
    return u;
  }

  @override
  Future<void> deconnecter() async {
    _adminEnAttente2fa = null;
  }
}
