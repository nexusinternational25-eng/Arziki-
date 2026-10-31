// Invitations, candidatures au Cercle et journal d'audit.
// Voir CLAUDE.md, sections 2, 5.6, 13 et 21.

import 'dart:math';

import '../core/roles.dart';

/// Invitation nominative, à usage unique, avec date d'expiration
/// (document invitations/{code}). C'est la porte d'entrée des
/// investisseurs privés que le propriétaire connaît personnellement.
class Invitation {
  const Invitation({
    required this.code,
    required this.pourNom,
    required this.pourTelephone,
    required this.niveau,
    required this.creePar,
    required this.creeLe,
    required this.expireLe,
    this.note,
    this.utiliseLe,
    this.utilisePar,
    this.annuleeLe,
  });

  final String code;
  final String pourNom;

  /// Numéro de téléphone de la personne invitée : seul ce numéro peut utiliser le code.
  final String pourTelephone;
  final NiveauCercle niveau;
  final String creePar;
  final DateTime creeLe;
  final DateTime expireLe;

  /// Note interne (visible des admins uniquement).
  final String? note;
  final DateTime? utiliseLe;
  final String? utilisePar;
  final DateTime? annuleeLe;

  bool get estUtilisee => utiliseLe != null;
  bool get estAnnulee => annuleeLe != null;
  bool estExpiree(DateTime maintenant) => maintenant.isAfter(expireLe);

  /// Statut lisible pour la console.
  String statut(DateTime maintenant) {
    if (estAnnulee) return 'Annulée';
    if (estUtilisee) return 'Utilisée';
    if (estExpiree(maintenant)) return 'Expirée';
    return 'En attente';
  }

  Invitation copier({DateTime? utiliseLe, String? utilisePar, DateTime? annuleeLe}) {
    return Invitation(
      code: code,
      pourNom: pourNom,
      pourTelephone: pourTelephone,
      niveau: niveau,
      creePar: creePar,
      creeLe: creeLe,
      expireLe: expireLe,
      note: note,
      utiliseLe: utiliseLe ?? this.utiliseLe,
      utilisePar: utilisePar ?? this.utilisePar,
      annuleeLe: annuleeLe ?? this.annuleeLe,
    );
  }

  /// Génère un code lisible, sans caractères ambigus (pas de 0/O, 1/I/L).
  /// Exemple : ARZ-7KQM-3XWP.
  static String genererCode([Random? aleatoire]) {
    const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final r = aleatoire ?? Random.secure();
    String bloc() => List.generate(4, (_) => alphabet[r.nextInt(alphabet.length)]).join();
    return 'ARZ-${bloc()}-${bloc()}';
  }
}

/// Statut d'une candidature spontanée au Cercle.
enum StatutCandidature {
  soumise('soumise', 'En attente de décision'),
  admise('admise', 'Admise'),
  refusee('refusee', 'Non retenue');

  const StatutCandidature(this.code, this.libelle);
  final String code;
  final String libelle;
}

/// Candidature d'une personne qui s'est inscrite seule sur la plateforme
/// (document candidatures/{uid}). Elle ne donne accès à aucune opération :
/// seul un administrateur peut admettre la personne dans le Cercle.
class Candidature {
  const Candidature({
    required this.uid,
    required this.nomComplet,
    required this.telephone,
    required this.niveauSouhaite,
    required this.trancheEnvisagee,
    required this.commentNousConnu,
    required this.soumiseLe,
    this.statut = StatutCandidature.soumise,
    this.decidePar,
    this.decideLe,
    this.motif,
  });

  final String uid;
  final String nomComplet;
  final String telephone;
  final NiveauCercle niveauSouhaite;

  /// Tranche indicative de participation envisagée (texte libre choisi dans une liste).
  final String trancheEnvisagee;
  final String commentNousConnu;
  final DateTime soumiseLe;
  final StatutCandidature statut;
  final String? decidePar;
  final DateTime? decideLe;
  final String? motif;

  Candidature decider({
    required StatutCandidature statut,
    required String par,
    required DateTime le,
    String? motif,
  }) {
    return Candidature(
      uid: uid,
      nomComplet: nomComplet,
      telephone: telephone,
      niveauSouhaite: niveauSouhaite,
      trancheEnvisagee: trancheEnvisagee,
      commentNousConnu: commentNousConnu,
      soumiseLe: soumiseLe,
      statut: statut,
      decidePar: par,
      decideLe: le,
      motif: motif,
    );
  }
}

/// Ligne du journal d'audit (document audit/{logId}). Jamais modifiable.
class EntreeAudit {
  const EntreeAudit({
    required this.id,
    required this.date,
    required this.acteurUid,
    required this.action,
    required this.cible,
    this.avant,
    this.apres,
  });

  final String id;
  final DateTime date;
  final String acteurUid;
  final String action;
  final String cible;
  final String? avant;
  final String? apres;
}
