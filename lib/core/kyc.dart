// Pièces demandées pour la vérification d'identité (CLAUDE.md, section 7).

import 'roles.dart';

class PieceKyc {
  const PieceKyc(this.code, this.libelle, {this.obligatoire = true});
  final String code;
  final String libelle;
  final bool obligatoire;
}

const _personnePhysique = [
  PieceKyc('identite_recto', "Pièce d'identité (recto) : CNI, passeport ou carte consulaire"),
  PieceKyc('identite_verso', "Pièce d'identité (verso)"),
  PieceKyc('selfie', 'Selfie de contrôle'),
  PieceKyc('justificatif_adresse', "Justificatif d'adresse"),
];

const _origineFonds = PieceKyc('origine_fonds', "Déclaration d'origine des fonds");
const _justificatifBancaire = PieceKyc('justificatif_bancaire', 'Justificatif bancaire récent');

/// Liste des pièces attendues selon le rôle.
List<PieceKyc> piecesKyc(Role role) => switch (role) {
      Role.entreprise || Role.fournisseur => const [
          PieceKyc('rccm', 'RCCM'),
          PieceKyc('nif', 'NIF'),
          PieceKyc('statuts', 'Statuts'),
          PieceKyc('identite_dirigeant', "Pièce d'identité du dirigeant"),
          PieceKyc('pouvoir_signataire', 'Pouvoir du signataire (si ce n\'est pas le gérant)', obligatoire: false),
        ],
      Role.membre || Role.candidatCercle => const [..._personnePhysique, _origineFonds],
      Role.partenaire || Role.partenaireStrategique => const [
          ..._personnePhysique,
          _origineFonds,
          _justificatifBancaire,
        ],
      Role.notaire => const [
          ..._personnePhysique,
          PieceKyc('attestation_chambre', "Attestation d'inscription à la Chambre des notaires"),
        ],
      Role.superAdmin || Role.admin || Role.analyste => const [],
    };

/// Origines des fonds proposées dans la déclaration.
const originesFonds = [
  'Salaire',
  'Activité commerciale',
  'Épargne',
  "Vente d'un bien",
  'Héritage ou donation',
  'Autre (à préciser)',
];
