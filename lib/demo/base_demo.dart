// Base de données fictive, en mémoire, pour le mode démonstration
// (CLAUDE.md, section 17). Rien n'est envoyé sur Internet.
// Elle joue le rôle de Firestore et des Cloud Functions tant que
// le projet Firebase n'est pas fourni.

import '../core/roles.dart';
import '../models/acces.dart';
import '../models/utilisateur.dart';

/// Compte d'équipe créé pendant la démonstration par le super administrateur
/// (mot de passe provisoire généré au hasard, gardé en mémoire seulement).
class CompteAdminDemo {
  const CompteAdminDemo(this.identifiant, this.motDePasse, this.uid);
  final String identifiant;
  final String motDePasse;
  final String uid;
}

class BaseDemo {
  BaseDemo({DateTime Function()? horloge}) : maintenant = horloge ?? DateTime.now {
    _remplir();
  }

  /// Horloge injectable (pratique pour les tests sur l'expiration des invitations).
  final DateTime Function() maintenant;

  final Map<String, Utilisateur> utilisateurs = {};
  final Map<String, Invitation> invitations = {};
  final Map<String, Candidature> candidatures = {};
  final List<EntreeAudit> journal = [];

  /// Pièces KYC déposées : uid -> (code de la pièce -> chemin du fichier).
  /// Comme en production, on ne garde que le chemin, jamais l'image elle-même.
  final Map<String, Map<String, String>> piecesKyc = {};
  final List<CompteAdminDemo> comptesAdmin = [];

  int _compteur = 0;
  String nouvelId(String prefixe) => '$prefixe-${++_compteur}';

  /// Écrit une ligne au journal d'audit. Le journal ne fait que grandir.
  void auditer(String acteurUid, String action, String cible, {String? avant, String? apres}) {
    journal.add(EntreeAudit(
      id: nouvelId('audit'),
      date: maintenant(),
      acteurUid: acteurUid,
      action: action,
      cible: cible,
      avant: avant,
      apres: apres,
    ));
  }

  Utilisateur? parTelephone(String telephone) {
    for (final u in utilisateurs.values) {
      if (u.telephone == telephone) return u;
    }
    return null;
  }

  void _ajouter(
    String uid,
    Role role,
    String prenom,
    String nom, {
    String? telephone,
    String? email,
    StatutCompte statut = StatutCompte.actif,
    StatutKyc kyc = StatutKyc.valide,
    String ville = 'Lomé',
  }) {
    utilisateurs[uid] = Utilisateur(
      uid: uid,
      role: role,
      statut: statut,
      kycStatut: kyc,
      prenom: prenom,
      nom: nom,
      telephone: telephone,
      email: email,
      ville: ville,
      cgVersionAcceptee: '1.0',
      cgAccepteeLe: DateTime(2026, 10, 1),
      creeLe: DateTime(2026, 10, 1),
    );
  }

  void _remplir() {
    // Administration. Seul le super administrateur peut se connecter : identifiant
    // personnel, mot de passe et code à 6 chiffres (voir lib/auth/acces_admin.dart).
    // Les deux collaborateurs fictifs servent à remplir la page « Équipe » ;
    // ils n'ont pas de mot de passe et ne peuvent pas se connecter.
    _ajouter('u-super-admin', Role.superAdmin, 'CEO', 'NEXUS International',
        email: 'oumara', telephone: '+22890000001');
    _ajouter('u-admin', Role.admin, 'Afi', 'Mensah', email: 'afi.mensah');
    _ajouter('u-analyste', Role.analyste, 'Kossi', 'Agbeko', email: 'kossi.agbeko');

    // Entreprises (pharmacie, BTP, fournisseur d'une mine).
    _ajouter('u-ent-pharma', Role.entreprise, 'Ama', 'Kpodar', telephone: '+22890000011');
    _ajouter('u-ent-btp', Role.entreprise, 'Yao', 'Akakpo', telephone: '+22890000012', ville: 'Kara');
    _ajouter('u-ent-mine', Role.entreprise, 'Komla', 'Dossou', telephone: '+22890000013');

    // Cercle : 6 membres, 2 partenaires.
    const membres = [
      ['Essi', 'Lawson'], ['Kodjo', 'Amouzou'], ['Abla', 'Gbeasor'],
      ['Mawuli', 'Tchalla'], ['Sena', 'Adjovi'], ['Fati', 'Issa'],
    ];
    for (var i = 0; i < membres.length; i++) {
      _ajouter('u-membre-${i + 1}', Role.membre, membres[i][0], membres[i][1],
          telephone: '+2289000002${i + 1}');
    }
    _ajouter('u-partenaire-1', Role.partenaire, 'Edem', 'Kouassi', telephone: '+22890000031');
    _ajouter('u-partenaire-2', Role.partenaire, 'Nadia', 'Bawa', telephone: '+22890000032');

    // Fournisseurs et notaire.
    _ajouter('u-fourn-1', Role.fournisseur, 'Komi', 'Ayivi', telephone: '+22890000041');
    _ajouter('u-fourn-2', Role.fournisseur, 'Akouvi', 'Ahadji', telephone: '+22890000042');
    _ajouter('u-notaire', Role.notaire, 'Maître Kafui', 'Atsu', telephone: '+22890000051');

    // Un candidat au Cercle inscrit seul, en attente de décision.
    _ajouter('u-candidat-1', Role.candidatCercle, 'Rachid', 'Ouro', telephone: '+22890000061',
        statut: StatutCompte.enAttente, kyc: StatutKyc.enCours);
    candidatures['u-candidat-1'] = Candidature(
      uid: 'u-candidat-1',
      nomComplet: 'Rachid Ouro',
      telephone: '+22890000061',
      niveauSouhaite: NiveauCercle.membre,
      trancheEnvisagee: '500 000 à 2 000 000 FCFA',
      commentNousConnu: 'Recommandé par un membre',
      soumiseLe: DateTime(2026, 10, 28),
    );

    // Une entreprise en attente de validation.
    _ajouter('u-ent-attente', Role.entreprise, 'Delali', 'Kumako', telephone: '+22890000014',
        statut: StatutCompte.enAttente, kyc: StatutKyc.aCompleter);

    // Une invitation nominative prête à l'emploi pour un investisseur privé.
    invitations['ARZ-DEMO-2026'] = Invitation(
      code: 'ARZ-DEMO-2026',
      pourNom: 'Ibrahim Salifou',
      pourTelephone: '+22890000071',
      niveau: NiveauCercle.partenaire,
      creePar: 'u-super-admin',
      creeLe: DateTime(2026, 10, 30),
      expireLe: DateTime(2027, 1, 31),
      note: 'Contact personnel du fondateur',
    );
  }
}
