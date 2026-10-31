// Espace personnel de chaque rôle client. Le contenu métier arrive
// jalon après jalon (CLAUDE.md, section 15) ; ici, la structure et les accès.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/session.dart';
import '../../core/textes_legaux.dart';
import '../../theme/arziki_theme.dart';
import '../../ui/composants.dart';
import '../compte/ecrans_compte.dart';

class _Rubrique {
  const _Rubrique(this.icone, this.titre, this.detail);
  final IconData icone;
  final String titre;
  final String detail;
}

class _Espace extends ConsumerWidget {
  const _Espace({required this.titre, required this.rubriques, this.avant = const [], this.apres = const []});

  final String titre;
  final List<_Rubrique> rubriques;
  final List<Widget> avant;
  final List<Widget> apres;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(sessionProvider).utilisateur!;
    return Scaffold(
      appBar: AppBar(title: Text(titre), actions: const [BoutonDeconnexion()]),
      body: Colonne(children: [
        Text('Bonjour ${u.prenom.isEmpty ? '' : u.prenom}'.trim(), style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: ArzikiEspaces.xs),
        Chip(label: Text(u.role.libelle)),
        const SizedBox(height: ArzikiEspaces.m),
        ...avant,
        for (final r in rubriques)
          Card(
            child: ListTile(
              leading: Icon(r.icone, color: ArzikiCouleurs.vert),
              title: Text(r.titre),
              subtitle: Text(r.detail),
            ),
          ),
        ...apres,
      ]),
    );
  }
}

class EspaceEntreprise extends StatelessWidget {
  const EspaceEntreprise({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Espace(
      titre: 'Mon espace entreprise',
      rubriques: [
        _Rubrique(Icons.add_shopping_cart, 'Nouvelle demande de Commande Financée', 'Disponible au jalon 3.'),
        _Rubrique(Icons.timeline, 'Mes opérations', 'Suivi étape par étape.'),
        _Rubrique(Icons.business, 'Mon entreprise', 'RCCM, NIF, statuts, dirigeants.'),
        _Rubrique(Icons.design_services, 'Services', 'Opéré par NEXUS International.'),
      ],
    );
  }
}

class EspaceCercle extends ConsumerWidget {
  const EspaceCercle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(sessionProvider).utilisateur!;
    final niveau = u.niveau!;
    return _Espace(
      titre: 'Cercle Arziki',
      avant: [
        const AvertissementRisque(),
        const SizedBox(height: ArzikiEspaces.m),
        Encadre(
          'Niveau ${niveau.libelle} : participation minimale de ${fcfa(niveau.participationMinimale)}. '
          '${u.role.voitOperationsEntreprises ? 'Vous voyez les opérations PME et Entreprises.' : 'Vous voyez les opérations PME.'}',
        ),
        const SizedBox(height: ArzikiEspaces.m),
      ],
      rubriques: const [
        _Rubrique(Icons.storefront, 'Opérations ouvertes', 'Aucune opération ouverte pour le moment.'),
        _Rubrique(Icons.assignment_turned_in_outlined, 'Mes opérations', 'Versements, échéances, résultats.'),
        _Rubrique(Icons.folder_outlined, 'Mes documents', 'Contrats, rapports mensuels, attestations.'),
        _Rubrique(Icons.card_membership, 'Ma cotisation', 'Statut et paiement de la cotisation annuelle.'),
        _Rubrique(Icons.person_add_alt, 'Parrainer', "Demander à l'administrateur un code d'invitation pour un proche."),
      ],
      apres: const [
        SizedBox(height: ArzikiEspaces.m),
        Encadre(TextesLegaux.regleEspeces),
        SizedBox(height: ArzikiEspaces.m),
        AvertissementRisque(),
      ],
    );
  }
}

class EspaceFournisseur extends StatelessWidget {
  const EspaceFournisseur({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Espace(
      titre: 'Espace fournisseur',
      rubriques: [
        _Rubrique(Icons.receipt_long, 'Bons de commande ARZIKI', 'Accepter, refuser, proposer un paiement différé.'),
        _Rubrique(Icons.local_shipping, 'Livraisons', 'Déclarer une livraison avec photos et bordereau.'),
        _Rubrique(Icons.payments_outlined, 'Règlements', 'Quand et combien vous serez réglé.'),
      ],
    );
  }
}

class EspaceNotaire extends StatelessWidget {
  const EspaceNotaire({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Espace(
      titre: 'Espace notaire',
      rubriques: [
        _Rubrique(Icons.folder_shared, 'Opérations assignées', 'Lecture seule des dossiers qui vous sont confiés.'),
        _Rubrique(Icons.upload_file, 'Actes signés', 'Convention-cadre, contrats de participation, garanties.'),
        _Rubrique(Icons.account_balance, 'Fonds en séquestre', 'Confirmer les fonds reçus et les décaissements.'),
      ],
    );
  }
}
