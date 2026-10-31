// Profil d'un utilisateur (document users/{uid}, CLAUDE.md section 13).

import '../core/roles.dart';

class Utilisateur {
  const Utilisateur({
    required this.uid,
    required this.role,
    required this.statut,
    required this.kycStatut,
    this.nom = '',
    this.prenom = '',
    this.telephone,
    this.email,
    this.pays = 'TG',
    this.ville,
    this.invitationCode,
    this.cgVersionAcceptee,
    this.cgAccepteeLe,
    this.creeLe,
  });

  final String uid;
  final Role role;
  final StatutCompte statut;
  final StatutKyc kycStatut;
  final String nom;
  final String prenom;
  final String? telephone;
  final String? email;
  final String pays;
  final String? ville;

  /// Code d'invitation utilisé à l'inscription (investisseurs privés invités).
  final String? invitationCode;

  /// Version des conditions d'utilisation acceptée et date d'acceptation.
  final String? cgVersionAcceptee;
  final DateTime? cgAccepteeLe;
  final DateTime? creeLe;

  String get nomComplet {
    final complet = '$prenom $nom'.trim();
    return complet.isEmpty ? (telephone ?? email ?? 'Utilisateur') : complet;
  }

  bool get estActif => statut == StatutCompte.actif;

  /// Niveau dans le Cercle, déduit du rôle (null si la personne n'est pas investisseur).
  NiveauCercle? get niveau => switch (role) {
        Role.membre => NiveauCercle.membre,
        Role.partenaire => NiveauCercle.partenaire,
        Role.partenaireStrategique => NiveauCercle.partenaireStrategique,
        _ => null,
      };

  Utilisateur copier({
    Role? role,
    StatutCompte? statut,
    StatutKyc? kycStatut,
    String? nom,
    String? prenom,
    String? ville,
  }) {
    return Utilisateur(
      uid: uid,
      role: role ?? this.role,
      statut: statut ?? this.statut,
      kycStatut: kycStatut ?? this.kycStatut,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      telephone: telephone,
      email: email,
      pays: pays,
      ville: ville ?? this.ville,
      invitationCode: invitationCode,
      cgVersionAcceptee: cgVersionAcceptee,
      cgAccepteeLe: cgAccepteeLe,
      creeLe: creeLe,
    );
  }
}
