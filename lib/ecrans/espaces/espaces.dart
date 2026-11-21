// Espaces connectés de chaque rôle client, avec barre du bas :
// - entreprise : Accueil, Mes opérations, Nouvelle demande, Services, Profil ;
// - partenaire financier (membre, partenaire, stratégique) : Accueil, Proposées,
//   Mes opérations, Documents, Profil ;
// - fournisseur : Accueil, Bons de commande, Livraisons, Profil ;
// - notaire : Accueil, Dossiers, Profil.
// Modèle : vente à terme (CLAUDE.md, section 24).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/session.dart';
import '../../core/images.dart';
import '../../core/roles.dart';
import '../../core/textes_legaux.dart';
import '../../models/utilisateur.dart';
import '../../operations/operations.dart';
import '../../router/garde_roles.dart';
import '../../theme/arziki_theme.dart';
import '../../ui/composants.dart';
import '../accueil/sections_accueil.dart';
import '../navigation/cadre_app.dart';
import '../profil/profil.dart';
import '../services/ecrans_services.dart';

// ===========================================================================
// Accueil commun, adapté au rôle
// ===========================================================================

class Raccourci {
  const Raccourci(this.icone, this.libelle, this.action);
  final IconData icone;
  final String libelle;
  final void Function(BuildContext) action;
}

class AccueilRole extends ConsumerWidget {
  const AccueilRole({super.key, required this.synthese, required this.raccourcis, this.image = Images.marche, this.avantSynthese});
  final List<Widget> synthese;
  final List<Raccourci> raccourcis;
  final String image;
  final Widget? avantSynthese;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(sessionProvider).utilisateur!;
    final t = Theme.of(context).textTheme;
    final prenom = u.prenom.isEmpty ? '' : ', ${u.prenom}';
    return Colonne(padding: const EdgeInsets.fromLTRB(ArzikiEspaces.m, ArzikiEspaces.s, ArzikiEspaces.m, ArzikiEspaces.l), children: [
      Apparition(
        child: EnTeteImage(
          image: image,
          hauteur: 190,
          titre: 'Bonjour$prenom',
          sousTitre: '${u.role.libelle} · ${dateLongue(DateTime.now())}',
        ),
      ),
      if (avantSynthese != null) ...[const SizedBox(height: ArzikiEspaces.m), avantSynthese!],
      const SizedBox(height: ArzikiEspaces.s),
      LayoutBuilder(builder: (context, c) {
        final largeur = (c.maxWidth - ArzikiEspaces.m) / 2;
        return Wrap(spacing: ArzikiEspaces.m, children: [
          for (var i = 0; i < synthese.length; i++)
            SizedBox(width: i == synthese.length - 1 && synthese.length.isOdd ? c.maxWidth : largeur, child: Apparition(ordre: i, child: synthese[i])),
        ]);
      }),
      const TitreSection('Raccourcis'),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final r in raccourcis)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(ArzikiRayons.carte),
                onTap: () => r.action(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: ArzikiEspaces.s),
                  child: Column(children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: ArzikiCouleurs.vert.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(r.icone, color: ArzikiCouleurs.vert),
                    ),
                    const SizedBox(height: 6),
                    Text(r.libelle, style: t.labelMedium, textAlign: TextAlign.center, maxLines: 2),
                  ]),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: ArzikiEspaces.s),
      const SectionCommentCaMarche(),
      CarrouselServices(onToutVoir: () => context.push(Chemins.services)),
      const SizedBox(height: ArzikiEspaces.s),
      const BlocConfiance(),
      const SectionActualites(),
    ]);
  }
}

/// Prochaine échéance parmi des opérations (dates futures seulement).
String _prochaine(Iterable<Operation> ops) {
  final aujourdhui = DateTime.now();
  final dates = ops.map((o) => o.echeance).whereType<DateTime>().where((d) => d.isAfter(aujourdhui)).toList()..sort();
  return dates.isEmpty ? 'Aucune' : dateLongue(dates.first);
}

/// Qui regarde une opération : chacun voit ce qui le concerne.
enum VueOperation { entreprise, partenaire, notaire, equipe }

// ===========================================================================
// Entreprise
// ===========================================================================

class EspaceEntreprise extends ConsumerStatefulWidget {
  const EspaceEntreprise({super.key});

  @override
  ConsumerState<EspaceEntreprise> createState() => _EspaceEntrepriseState();
}

class _EspaceEntrepriseState extends ConsumerState<EspaceEntreprise> {
  final cadre = GlobalKey<CadreOngletsState>();

  @override
  Widget build(BuildContext context) {
    final u = ref.watch(sessionProvider).utilisateur!;
    final etat = ref.watch(operationsProvider);
    final mesOps = etat.operations.where((o) => o.entrepriseUid == u.uid).toList();
    final enCours = mesOps.where((o) => !o.terminee).toList();
    final aRegler = enCours
        .where((o) => o.statut.index >= StatutVente.signee.index && o.prixRevente != null)
        .fold<int>(0, (s, o) => s + o.prixRevente!);

    return CadreOnglets(
      key: cadre,
      libelleCentral: 'Demande',
      boutonCentral: () => context.push(Chemins.nouvelleDemande),
      onglets: [
        Onglet(
          icone: Icons.home_outlined,
          iconeActive: Icons.home_rounded,
          libelle: 'Accueil',
          page: AccueilRole(
            image: Images.entrepreneurEntrepot,
            synthese: [
              CarteChiffre(icone: Icons.timeline_rounded, valeur: '${enCours.length}', libelle: 'Demandes et opérations en cours',
                  onTap: () => cadre.currentState?.allerA(1)),
              CarteChiffre(icone: Icons.payments_rounded, valeur: fcfa(aRegler), libelle: 'À régler aux échéances', couleur: ArzikiCouleurs.orange),
              CarteChiffre(icone: Icons.event_rounded, valeur: _prochaine(enCours), libelle: 'Prochaine échéance', couleur: ArzikiCouleurs.info),
            ],
            raccourcis: [
              Raccourci(Icons.add_circle_rounded, 'Nouvelle demande', (c) => c.push(Chemins.nouvelleDemande)),
              Raccourci(Icons.timeline_rounded, 'Mes opérations', (_) => cadre.currentState?.allerA(1)),
              Raccourci(Icons.work_rounded, 'Services', (_) => cadre.currentState?.allerA(2)),
              Raccourci(Icons.support_agent_rounded, 'Aide', (c) => c.push(Chemins.info('aide'))),
            ],
          ),
        ),
        Onglet(
          icone: Icons.timeline_outlined,
          iconeActive: Icons.timeline_rounded,
          libelle: 'Opérations',
          titre: 'Mes opérations',
          page: _MesOperationsEntreprise(operations: mesOps),
        ),
        const Onglet(icone: Icons.work_outline_rounded, iconeActive: Icons.work_rounded, libelle: 'Services', titre: 'Services', page: CatalogueServices(integre: true)),
        const Onglet(icone: Icons.person_outline_rounded, iconeActive: Icons.person_rounded, libelle: 'Profil', titre: 'Mon profil', page: EcranProfil(integre: true)),
      ],
    );
  }
}

class _MesOperationsEntreprise extends StatelessWidget {
  const _MesOperationsEntreprise({required this.operations});
  final List<Operation> operations;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final demandes = operations.where((o) => o.statut.index <= StatutVente.refusee.index).toList();
    final suivies = operations.where((o) => o.statut.index > StatutVente.refusee.index).toList();
    return Colonne(children: [
      const EnTetePage('Mes opérations', 'Vos demandes en analyse et vos commandes financées, étape par étape.'),
      if (operations.isEmpty)
        EcranVide(
          image: Images.entrepreneurEntrepot,
          titre: 'Aucune demande pour le moment',
          texte: 'Soumettez votre première commande ferme : ARZIKI l\'analyse et cherche un partenaire.',
          action: 'Nouvelle demande',
          onAction: () => context.push(Chemins.nouvelleDemande),
        ),
      if (demandes.isNotEmpty) ...[
        Text('Demandes en analyse', style: t.titleMedium),
        for (var i = 0; i < demandes.length; i++)
          Apparition(
            ordre: i,
            child: CarteOperation(operation: demandes[i], vue: VueOperation.entreprise, onTap: () => context.push(Chemins.operationEntreprise(demandes[i].id))),
          ),
        const SizedBox(height: ArzikiEspaces.m),
      ],
      if (suivies.isNotEmpty) ...[
        Text('Opérations en cours et terminées', style: t.titleMedium),
        for (var i = 0; i < suivies.length; i++)
          Apparition(
            ordre: i,
            child: CarteOperation(operation: suivies[i], vue: VueOperation.entreprise, onTap: () => context.push(Chemins.operationEntreprise(suivies[i].id))),
          ),
      ],
    ]);
  }
}

/// Carte résumée d'une opération, adaptée à celui qui la regarde.
class CarteOperation extends StatelessWidget {
  const CarteOperation({super.key, required this.operation, required this.onTap, required this.vue, this.monApport});
  final Operation operation;
  final VoidCallback onTap;
  final VueOperation vue;

  /// Montant retenu pour ce partenaire, s'il y en a un.
  final int? monApport;

  @override
  Widget build(BuildContext context) {
    final o = operation;
    final t = Theme.of(context).textTheme;
    final duree = o.dureeJours != null ? ' · ${o.dureeJours} jours' : '';
    final String ligne;
    switch (vue) {
      case VueOperation.entreprise:
        ligne = o.prixRevente != null ? 'Prix de revente : ${fcfa(o.prixRevente!)}' : 'Commande : ${fcfa(o.montantCommande)}';
      case VueOperation.partenaire:
        ligne = monApport != null
            ? 'Votre apport : ${fcfa(monApport!)}'
            : "Prix d'achat : ${fcfa(o.prixAchat ?? 0)} · majoration ${fcfa(o.majoration ?? 0)}";
      case VueOperation.notaire || VueOperation.equipe:
        ligne = o.prixAchat != null ? "Prix d'achat : ${fcfa(o.prixAchat!)}" : 'Commande : ${fcfa(o.montantCommande)}';
    }
    return CarteImage(
      image: o.image,
      hauteurImage: 130,
      titre: o.titre,
      texte: '${o.secteur}$duree${o.echeance != null ? ' · échéance le ${dateLongue(o.echeance!)}' : ''}',
      badge: badgeStatutOperation(o.statut),
      onTap: onTap,
      pied: Text(ligne, style: t.labelLarge),
    );
  }
}

BadgeStatut badgeStatutOperation(StatutVente s) => BadgeStatut(
      s.libelle,
      ton: switch (s) {
        StatutVente.proposee || StatutVente.interetManifeste => TonBadge.succes,
        StatutVente.enRetard || StatutVente.enRecouvrement || StatutVente.refusee => TonBadge.erreur,
        StatutVente.cloturee || StatutVente.annulee => TonBadge.neutre,
        StatutVente.livree || StatutVente.echeancePayee || StatutVente.fournisseurPaye || StatutVente.signee => TonBadge.info,
        _ => TonBadge.attente,
      },
    );

// ===========================================================================
// Partenaires financiers (sur invitation, section 24.2)
// ===========================================================================

class EspaceCercle extends ConsumerStatefulWidget {
  const EspaceCercle({super.key});

  @override
  ConsumerState<EspaceCercle> createState() => _EspaceCercleState();
}

class _EspaceCercleState extends ConsumerState<EspaceCercle> {
  final cadre = GlobalKey<CadreOngletsState>();

  @override
  Widget build(BuildContext context) {
    final u = ref.watch(sessionProvider).utilisateur!;
    ref.watch(operationsProvider);
    final verifie = u.statut == StatutCompte.actif && u.kycStatut == StatutKyc.valide;
    final proposees = ref.read(operationsProvider.notifier).proposeesA(u.uid, verifie: verifie);
    final ouvertes = proposees.where((o) => o.ouverteAuxManifestations).toList();
    final miennes = proposees.where((o) => o.apportsRetenus.any((a) => a.partenaireUid == u.uid)).toList();
    final enCours = miennes.where((o) => !o.terminee);
    final engage = enCours.fold<int>(0, (s, o) => s + o.apportsRetenus.firstWhere((a) => a.partenaireUid == u.uid).montant);

    return CadreOnglets(
      key: cadre,
      onglets: [
        Onglet(
          icone: Icons.home_outlined,
          iconeActive: Icons.home_rounded,
          libelle: 'Accueil',
          page: AccueilRole(
            image: Images.reunionInvestisseurs,
            avantSynthese: const Encadre(
              'Espace privé, sur invitation. Vous ne voyez que les opérations qui vous sont proposées. '
              "« Je suis intéressé » n'engage pas : seule la signature devant notaire engage.",
              icone: Icons.lock_rounded,
            ),
            synthese: [
              CarteChiffre(icone: Icons.storefront_rounded, valeur: '${ouvertes.length}', libelle: 'Opérations proposées',
                  couleur: ArzikiCouleurs.vert, onTap: () => cadre.currentState?.allerA(1)),
              CarteChiffre(icone: Icons.timeline_rounded, valeur: '${enCours.length}', libelle: 'Mes opérations en cours',
                  onTap: () => cadre.currentState?.allerA(2)),
              CarteChiffre(icone: Icons.handshake_rounded, valeur: fcfa(engage), libelle: 'Apports signés en cours', couleur: ArzikiCouleurs.orange),
              CarteChiffre(icone: Icons.event_rounded, valeur: _prochaine(enCours), libelle: 'Prochaine échéance', couleur: ArzikiCouleurs.info),
            ],
            raccourcis: [
              Raccourci(Icons.storefront_rounded, 'Proposées', (_) => cadre.currentState?.allerA(1)),
              Raccourci(Icons.receipt_long_rounded, 'Mes opérations', (_) => cadre.currentState?.allerA(2)),
              Raccourci(Icons.folder_rounded, 'Documents', (_) => cadre.currentState?.allerA(3)),
              Raccourci(Icons.person_add_alt_rounded, 'Recommander', (c) => _recommander(c)),
            ],
          ),
        ),
        Onglet(
          icone: Icons.storefront_outlined,
          iconeActive: Icons.storefront_rounded,
          libelle: 'Proposées',
          titre: 'Opérations proposées',
          page: _OperationsProposees(operations: ouvertes, verifie: verifie),
        ),
        Onglet(
          icone: Icons.receipt_long_outlined,
          iconeActive: Icons.receipt_long_rounded,
          libelle: 'Mes opérations',
          titre: 'Mes opérations',
          page: _MesOperationsPartenaire(uid: u.uid, proposees: proposees, onDecouvrir: () => cadre.currentState?.allerA(1)),
        ),
        const Onglet(icone: Icons.folder_outlined, iconeActive: Icons.folder_rounded, libelle: 'Documents', titre: 'Documents', page: _Documents()),
        const Onglet(icone: Icons.person_outline_rounded, iconeActive: Icons.person_rounded, libelle: 'Profil', titre: 'Mon profil', page: EcranProfil(integre: true)),
      ],
    );
  }

  /// Recommander une personne : l'administrateur décide seul d'envoyer une invitation.
  static void _recommander(BuildContext context) {
    final nom = TextEditingController();
    final tel = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(ArzikiEspaces.l, 0, ArzikiEspaces.l, MediaQuery.viewInsetsOf(ctx).bottom + ArzikiEspaces.l),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Recommander une personne', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: ArzikiEspaces.s),
          const Text("Votre recommandation est transmise à l'administrateur, qui décide seul d'envoyer une invitation."),
          const SizedBox(height: ArzikiEspaces.m),
          TextField(controller: nom, decoration: const InputDecoration(labelText: 'Nom complet')),
          const SizedBox(height: ArzikiEspaces.m),
          TextField(controller: tel, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Téléphone')),
          const SizedBox(height: ArzikiEspaces.l),
          FilledButton(
            onPressed: () {
              if (nom.text.trim().length < 3 || tel.text.trim().length < 8) {
                annoncer(ctx, 'Indiquez le nom et le numéro de la personne.', erreur: true);
                return;
              }
              Navigator.pop(ctx);
              annoncer(context, "Recommandation envoyée. L'administrateur vous répondra par notification.");
            },
            child: const Text('Envoyer'),
          ),
        ]),
      ),
    );
  }
}

class _OperationsProposees extends StatelessWidget {
  const _OperationsProposees({required this.operations, required this.verifie});
  final List<Operation> operations;
  final bool verifie;

  @override
  Widget build(BuildContext context) {
    return Colonne(children: [
      const EnTetePage('Opérations proposées', 'Les opérations vérifiées par ARZIKI qui vous ont été proposées personnellement.'),
      const AvertissementRisque(),
      const SizedBox(height: ArzikiEspaces.m),
      if (!verifie)
        const EcranVide(
          icone: Icons.lock_rounded,
          titre: 'Identité en cours de vérification',
          texte: "Aucune opération n'est visible tant que votre identité et l'origine de vos fonds ne sont pas validées.",
        )
      else if (operations.isEmpty)
        const EcranVide(
          icone: Icons.storefront_rounded,
          titre: 'Aucune opération proposée',
          texte: "Vous recevrez une notification dès qu'une opération vous sera proposée.",
        ),
      for (var i = 0; i < operations.length; i++)
        Apparition(
          ordre: i,
          child: CarteOperation(
            operation: operations[i],
            vue: VueOperation.partenaire,
            onTap: () => context.push(Chemins.operationCercle(operations[i].id)),
          ),
        ),
    ]);
  }
}

class _MesOperationsPartenaire extends StatelessWidget {
  const _MesOperationsPartenaire({required this.uid, required this.proposees, required this.onDecouvrir});
  final String uid;
  final List<Operation> proposees;
  final VoidCallback onDecouvrir;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final manifestations = proposees.where((o) => o.manifestations.containsKey(uid) && !o.apportsRetenus.any((a) => a.partenaireUid == uid)).toList();
    final signees = proposees.where((o) => o.apportsRetenus.any((a) => a.partenaireUid == uid)).toList();
    return Colonne(children: [
      const EnTetePage('Mes opérations', "Vos manifestations d'intérêt, puis vos opérations signées devant notaire, avec ce que vous recevrez à l'échéance."),
      if (manifestations.isEmpty && signees.isEmpty)
        EcranVide(
          image: Images.cercleApplication,
          titre: 'Aucune opération pour le moment',
          texte: 'Parcourez les opérations proposées et indiquez celles qui vous intéressent.',
          action: 'Voir les opérations proposées',
          onAction: onDecouvrir,
        ),
      if (manifestations.isNotEmpty) ...[
        Text('Intérêt manifesté (non engageant)', style: t.titleMedium),
        for (final o in manifestations)
          CarteArziki(
            onTap: () => context.push(Chemins.operationCercle(o.id)),
            child: Row(children: [
              Illustration(o.image, largeur: 56, hauteur: 56, rayon: 12),
              const SizedBox(width: ArzikiEspaces.m - 4),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(o.titre, style: t.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text('Montant indiqué : ${fcfa(o.manifestations[uid]!)}', style: t.bodySmall),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded),
            ]),
          ),
        const SizedBox(height: ArzikiEspaces.m),
      ],
      if (signees.isNotEmpty) ...[
        Text('Signées devant notaire', style: t.titleMedium),
        for (final o in signees)
          if (o.repartition.where((p) => p.partenaireUid == uid).firstOrNull case final part?)
            CarteArziki(
              onTap: () => context.push(Chemins.operationCercle(o.id)),
              child: Row(children: [
                Illustration(o.image, largeur: 56, hauteur: 56, rayon: 12),
                const SizedBox(width: ArzikiEspaces.m - 4),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(o.titre, style: t.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text('Apport ${fcfa(part.montant)} · à recevoir ${fcfa(part.aRecevoir)}', style: t.bodySmall),
                    const SizedBox(height: 4),
                    badgeStatutOperation(o.statut),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded),
              ]),
            ),
      ],
    ]);
  }
}

class _Documents extends StatelessWidget {
  const _Documents();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final maintenant = DateTime.now();
    final mois = [for (var i = 1; i <= 3; i++) DateTime(maintenant.year, maintenant.month - i, 1)];
    const noms = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    return Colonne(children: [
      const EnTetePage('Documents', 'Rapports mensuels, projets de contrats et actes signés de vos opérations.'),
      for (final m in mois)
        CarteArziki(
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: ArzikiCouleurs.erreur.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.picture_as_pdf_rounded, color: ArzikiCouleurs.erreur),
            ),
            const SizedBox(width: ArzikiEspaces.m),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Rapport mensuel, ${noms[m.month - 1]} ${m.year}', style: t.titleSmall),
                Text('Opérations en cours, échéances, retards. Sans données personnelles des autres partenaires.', style: t.bodySmall),
              ]),
            ),
          ]),
        ),
      const SizedBox(height: ArzikiEspaces.m),
      const Encadre(
        'En production, chaque document est produit par le serveur et ouvert par un lien temporaire de 15 minutes.',
        icone: Icons.info_outline_rounded,
      ),
      const SizedBox(height: ArzikiEspaces.s),
      const Encadre(TextesLegaux.regleEspeces, icone: Icons.payments_rounded),
    ]);
  }
}

// ===========================================================================
// Fournisseur
// ===========================================================================

class EspaceFournisseur extends ConsumerStatefulWidget {
  const EspaceFournisseur({super.key});

  @override
  ConsumerState<EspaceFournisseur> createState() => _EspaceFournisseurState();
}

class _EspaceFournisseurState extends ConsumerState<EspaceFournisseur> {
  final cadre = GlobalKey<CadreOngletsState>();

  @override
  Widget build(BuildContext context) {
    return CadreOnglets(
      key: cadre,
      onglets: [
        Onglet(
          icone: Icons.home_outlined,
          iconeActive: Icons.home_rounded,
          libelle: 'Accueil',
          page: AccueilRole(
            image: Images.fournisseurPme,
            synthese: [
              CarteChiffre(icone: Icons.receipt_long_rounded, valeur: '1', libelle: 'Bon de commande à traiter', onTap: () => cadre.currentState?.allerA(1)),
              CarteChiffre(icone: Icons.local_shipping_rounded, valeur: '1', libelle: 'Livraison à déclarer', couleur: ArzikiCouleurs.orange, onTap: () => cadre.currentState?.allerA(2)),
              CarteChiffre(icone: Icons.payments_rounded, valeur: fcfa(8000000), libelle: 'Paiements reçus ce mois', couleur: ArzikiCouleurs.info),
            ],
            raccourcis: [
              Raccourci(Icons.receipt_long_rounded, 'Bons de commande', (_) => cadre.currentState?.allerA(1)),
              Raccourci(Icons.local_shipping_rounded, 'Livraisons', (_) => cadre.currentState?.allerA(2)),
              Raccourci(Icons.work_rounded, 'Services', (c) => c.push(Chemins.services)),
              Raccourci(Icons.support_agent_rounded, 'Aide', (c) => c.push(Chemins.info('aide'))),
            ],
          ),
        ),
        const Onglet(icone: Icons.receipt_long_outlined, iconeActive: Icons.receipt_long_rounded, libelle: 'Bons', titre: 'Bons de commande', page: _BonsFournisseur()),
        const Onglet(icone: Icons.local_shipping_outlined, iconeActive: Icons.local_shipping_rounded, libelle: 'Livraisons', titre: 'Livraisons', page: _LivraisonsFournisseur()),
        const Onglet(icone: Icons.person_outline_rounded, iconeActive: Icons.person_rounded, libelle: 'Profil', titre: 'Mon profil', page: EcranProfil(integre: true)),
      ],
    );
  }
}

class _BonsFournisseur extends StatefulWidget {
  const _BonsFournisseur();

  @override
  State<_BonsFournisseur> createState() => _BonsFournisseurState();
}

class _BonsFournisseurState extends State<_BonsFournisseur> {
  String? _reponse;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Colonne(children: [
      const EnTetePage('Bons de commande', 'Les bons de commande ARZIKI qui vous concernent. Vous êtes payé directement par le partenaire acheteur ou par le séquestre du notaire.'),
      CarteImage(
        image: Images.opFlotte,
        titre: 'Pièces détachées pour une flotte de camions',
        texte: 'Bon n° ARZ-BC-0042 · 8 000 000 FCFA · livraison avant le ${dateLongue(DateTime.now().add(const Duration(days: 20)))}',
        badge: BadgeStatut(_reponse ?? 'À traiter', ton: _reponse == null ? TonBadge.attente : TonBadge.succes),
        pied: _reponse != null
            ? Text('Votre réponse a été transmise à ARZIKI.', style: t.bodySmall)
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Le paiement intervient après la signature des contrats devant notaire.', style: t.bodySmall),
                const SizedBox(height: ArzikiEspaces.m),
                FilledButton(onPressed: () => setState(() => _reponse = 'Bon accepté'), child: const Text('Accepter le bon de commande')),
                TextButton(
                  onPressed: () async {
                    if (await confirmer(context, titre: 'Refuser ce bon ?', message: 'ARZIKI cherchera un autre fournisseur.', valider: 'Refuser', danger: true)) {
                      setState(() => _reponse = 'Refusé');
                    }
                  },
                  child: const Text('Refuser'),
                ),
              ]),
      ),
    ]);
  }
}

class _LivraisonsFournisseur extends StatefulWidget {
  const _LivraisonsFournisseur();

  @override
  State<_LivraisonsFournisseur> createState() => _LivraisonsFournisseurState();
}

class _LivraisonsFournisseurState extends State<_LivraisonsFournisseur> {
  int _photos = 0;
  bool _bordereau = false;
  bool _declaree = false;

  @override
  Widget build(BuildContext context) {
    return Colonne(children: [
      const EnTetePage('Livraisons', 'Déclarez vos livraisons avec photos et bordereau signé.'),
      CarteArziki(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Pièces détachées pour une flotte de camions', style: Theme.of(context).textTheme.titleMedium),
          Text('Fournisseur payé · livraison à déclarer', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: ArzikiEspaces.m),
          if (_declaree)
            const Encadre('Livraison déclarée. ARZIKI vérifie les pièces.', icone: Icons.check_circle_rounded)
          else ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_photos > 0 ? Icons.check_circle_rounded : Icons.add_a_photo_rounded),
              title: Text(_photos == 0 ? 'Ajouter des photos' : '$_photos photo(s) ajoutée(s)'),
              onTap: () => setState(() => _photos++),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_bordereau ? Icons.check_circle_rounded : Icons.upload_file_rounded),
              title: Text(_bordereau ? 'Bordereau signé ajouté' : 'Ajouter le bordereau signé'),
              onTap: () => setState(() => _bordereau = true),
            ),
            FilledButton(
              onPressed: _photos > 0 && _bordereau ? () => setState(() => _declaree = true) : null,
              child: const Text('Déclarer la livraison'),
            ),
          ],
        ]),
      ),
    ]);
  }
}

// ===========================================================================
// Notaire
// ===========================================================================

class EspaceNotaire extends ConsumerStatefulWidget {
  const EspaceNotaire({super.key});

  @override
  ConsumerState<EspaceNotaire> createState() => _EspaceNotaireState();
}

class _EspaceNotaireState extends ConsumerState<EspaceNotaire> {
  final cadre = GlobalKey<CadreOngletsState>();

  @override
  Widget build(BuildContext context) {
    final u = ref.watch(sessionProvider).utilisateur!;
    final ops = ref.watch(operationsProvider).operations.where((o) => o.notaireUid == u.uid && !o.terminee).toList();
    final aInscrire = ops.expand((o) => o.garanties).where((g) => !g.constituee).length;
    final aSigner = ops.where((o) => o.statut == StatutVente.interetManifeste && o.apportsRetenus.isNotEmpty).length;
    return CadreOnglets(
      key: cadre,
      onglets: [
        Onglet(
          icone: Icons.home_outlined,
          iconeActive: Icons.home_rounded,
          libelle: 'Accueil',
          page: AccueilRole(
            image: Images.cercleNotaire,
            synthese: [
              CarteChiffre(icone: Icons.folder_shared_rounded, valeur: '${ops.length}', libelle: 'Dossiers assignés', onTap: () => cadre.currentState?.allerA(1)),
              CarteChiffre(icone: Icons.draw_rounded, valeur: '$aSigner', libelle: 'Signatures à recevoir', couleur: ArzikiCouleurs.orange, onTap: () => cadre.currentState?.allerA(1)),
              CarteChiffre(icone: Icons.shield_rounded, valeur: '$aInscrire', libelle: 'Garanties à constituer', couleur: ArzikiCouleurs.info, onTap: () => cadre.currentState?.allerA(1)),
            ],
            raccourcis: [
              Raccourci(Icons.folder_shared_rounded, 'Dossiers', (_) => cadre.currentState?.allerA(1)),
              Raccourci(Icons.verified_user_rounded, 'Garanties', (c) => c.push(Chemins.info('securite'))),
              Raccourci(Icons.support_agent_rounded, 'Aide', (c) => c.push(Chemins.info('aide'))),
            ],
          ),
        ),
        Onglet(
          icone: Icons.folder_shared_outlined,
          iconeActive: Icons.folder_shared_rounded,
          libelle: 'Dossiers',
          titre: 'Dossiers assignés',
          page: Colonne(children: [
            const EnTetePage('Dossiers assignés', 'Les opérations qui vous sont confiées : actes, garanties et paiement au fournisseur.'),
            if (ops.isEmpty) const EcranVide(icone: Icons.folder_off_rounded, titre: 'Aucun dossier', texte: 'Les opérations qui vous sont assignées apparaîtront ici.'),
            for (final o in ops) CarteOperation(operation: o, vue: VueOperation.notaire, onTap: () => context.push(Chemins.operationNotaire(o.id))),
          ]),
        ),
        const Onglet(icone: Icons.person_outline_rounded, iconeActive: Icons.person_rounded, libelle: 'Profil', titre: 'Mon profil', page: EcranProfil(integre: true)),
      ],
    );
  }
}

/// Utilisé par les écrans qui ont besoin de l'utilisateur courant.
Utilisateur utilisateurCourant(WidgetRef ref) => ref.read(sessionProvider).utilisateur!;
