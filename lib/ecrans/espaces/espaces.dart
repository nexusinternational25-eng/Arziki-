// Espaces connectés de chaque rôle client, avec barre du bas :
// - entreprise : Accueil, Mes opérations, Nouvelle demande, Services, Profil ;
// - membre / partenaire : Accueil, Opérations ouvertes, Mes participations, Rapports, Profil ;
// - fournisseur : Accueil, Bons de commande, Livraisons, Profil ;
// - notaire : Accueil, Dossiers, Actes, Profil.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/session.dart';
import '../../core/images.dart';
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

/// Prochaine échéance de paiement estimée d'une opération.
DateTime echeance(Operation o) => o.dateLimite.add(Duration(days: o.dureeJours));

String _prochaine(Iterable<Operation> ops) {
  final dates = ops.where((o) => o.statut != StatutOperation.cloturee).map(echeance).toList()..sort();
  return dates.isEmpty ? 'Aucune' : dateLongue(dates.first);
}

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
    final enCours = mesOps.where((o) => o.statut != StatutOperation.cloturee).toList();
    final engage = enCours.fold<int>(0, (s, o) => s + o.montantAReunir);

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
              CarteChiffre(icone: Icons.timeline_rounded, valeur: '${enCours.length}', libelle: 'Opérations en cours',
                  onTap: () => cadre.currentState?.allerA(1)),
              CarteChiffre(icone: Icons.payments_rounded, valeur: fcfa(engage), libelle: 'Montant engagé', couleur: ArzikiCouleurs.orange),
              CarteChiffre(icone: Icons.event_rounded, valeur: _prochaine(enCours), libelle: 'Prochaine échéance de paiement', couleur: ArzikiCouleurs.info),
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
          page: _MesOperationsEntreprise(operations: mesOps, demandes: etat.demandes.where((d) => d.uid == u.uid).toList()),
        ),
        const Onglet(icone: Icons.work_outline_rounded, iconeActive: Icons.work_rounded, libelle: 'Services', titre: 'Services', page: CatalogueServices(integre: true)),
        const Onglet(icone: Icons.person_outline_rounded, iconeActive: Icons.person_rounded, libelle: 'Profil', titre: 'Mon profil', page: EcranProfil(integre: true)),
      ],
    );
  }
}

class _MesOperationsEntreprise extends StatelessWidget {
  const _MesOperationsEntreprise({required this.operations, required this.demandes});
  final List<Operation> operations;
  final List<Demande> demandes;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Colonne(children: [
      const EnTetePage('Mes opérations', 'Vos demandes en cours de vérification et vos opérations financées, étape par étape.'),
      if (demandes.isNotEmpty) ...[
        Text('Demandes en vérification', style: t.titleMedium),
        for (final d in demandes)
          CarteArziki(
            child: Row(children: [
              const Icon(Icons.hourglass_top_rounded, color: ArzikiCouleurs.orange),
              const SizedBox(width: ArzikiEspaces.m),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.titre, style: t.titleSmall),
                  Text('${fcfa(d.montantVente)} · déposée le ${dateLongue(d.creeLe)}', style: t.bodySmall),
                ]),
              ),
              BadgeStatut(d.statut, ton: TonBadge.attente),
            ]),
          ),
        const SizedBox(height: ArzikiEspaces.m),
      ],
      Text('Opérations', style: t.titleMedium),
      if (operations.isEmpty)
        EcranVide(
          image: Images.entrepreneurEntrepot,
          titre: 'Aucune opération pour le moment',
          texte: 'Déposez votre première commande ferme : ARZIKI la vérifie et organise son financement.',
          action: 'Nouvelle demande',
          onAction: () => context.push(Chemins.nouvelleDemande),
        ),
      for (var i = 0; i < operations.length; i++)
        Apparition(ordre: i, child: CarteOperation(operation: operations[i], onTap: () => context.push(Chemins.operationEntreprise(operations[i].id)))),
    ]);
  }
}

/// Carte résumée d'une opération.
class CarteOperation extends StatelessWidget {
  const CarteOperation({super.key, required this.operation, required this.onTap, this.montantPersonnel});
  final Operation operation;
  final VoidCallback onTap;
  final int? montantPersonnel;

  @override
  Widget build(BuildContext context) {
    final o = operation;
    final t = Theme.of(context).textTheme;
    return CarteImage(
      image: o.image,
      hauteurImage: 130,
      titre: o.titre,
      texte: '${o.secteur} · ${o.estEntreprises ? 'Format Entreprises' : 'Format PME'} · ${o.dureeJours} jours',
      badge: badgeStatutOperation(o.statut),
      onTap: onTap,
      pied: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (o.estOuverte) JaugeFinancement(reuni: o.montantReuni, objectif: o.montantAReunir, compacte: true),
        if (!o.estOuverte)
          Text(montantPersonnel != null ? 'Votre participation : ${fcfa(montantPersonnel!)}' : 'Montant : ${fcfa(o.montantAReunir)}',
              style: t.labelLarge),
        if (o.resultatPct != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Résultat final : ${o.resultatPct! >= 0 ? '+' : ''}${o.resultatPct!.toStringAsFixed(1).replaceAll('.', ',')} % de la mise',
              style: t.labelMedium?.copyWith(color: o.resultatPct! >= 0 ? ArzikiCouleurs.vert : ArzikiCouleurs.erreur),
            ),
          ),
      ]),
    );
  }
}

BadgeStatut badgeStatutOperation(StatutOperation s) => BadgeStatut(
      s.libelle,
      ton: switch (s) {
        StatutOperation.financementOuvert => TonBadge.succes,
        StatutOperation.enRetard => TonBadge.erreur,
        StatutOperation.cloturee => TonBadge.neutre,
        StatutOperation.livree => TonBadge.info,
        _ => TonBadge.attente,
      },
    );

// ===========================================================================
// Membre et partenaire du Cercle
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
    final etat = ref.watch(operationsProvider);
    final ouvertes = ref.read(operationsProvider.notifier).ouvertesPour(u.role);
    final mesParts = etat.participations.where((p) => p.uid == u.uid).toList();
    final opsMiennes = [for (final p in mesParts) etat.parId(p.operationId)].whereType<Operation>().toList();
    final enCours = opsMiennes.where((o) => o.statut != StatutOperation.cloturee);
    final engage = mesParts
        .where((p) => etat.parId(p.operationId)?.statut != StatutOperation.cloturee)
        .fold<int>(0, (s, p) => s + p.montant);

    return CadreOnglets(
      key: cadre,
      onglets: [
        Onglet(
          icone: Icons.home_outlined,
          iconeActive: Icons.home_rounded,
          libelle: 'Accueil',
          page: AccueilRole(
            image: Images.reunionInvestisseurs,
            avantSynthese: Encadre(
              'Niveau ${u.niveau!.libelle} : participation minimale de ${fcfa(u.niveau!.participationMinimale)}. '
              '${u.role.voitOperationsEntreprises ? 'Vous voyez les opérations PME et Entreprises.' : 'Vous voyez les opérations PME.'}',
              icone: Icons.workspace_premium_rounded,
            ),
            synthese: [
              CarteChiffre(icone: Icons.timeline_rounded, valeur: '${enCours.length}', libelle: 'Opérations en cours',
                  onTap: () => cadre.currentState?.allerA(2)),
              CarteChiffre(icone: Icons.savings_rounded, valeur: fcfa(engage), libelle: 'Montant engagé', couleur: ArzikiCouleurs.orange),
              CarteChiffre(icone: Icons.storefront_rounded, valeur: '${ouvertes.length}', libelle: 'Opérations ouvertes',
                  couleur: ArzikiCouleurs.vert, onTap: () => cadre.currentState?.allerA(1)),
              CarteChiffre(icone: Icons.event_rounded, valeur: _prochaine(enCours), libelle: 'Prochaine échéance', couleur: ArzikiCouleurs.info),
            ],
            raccourcis: [
              Raccourci(Icons.storefront_rounded, 'Opérations ouvertes', (_) => cadre.currentState?.allerA(1)),
              Raccourci(Icons.receipt_long_rounded, 'Mes participations', (_) => cadre.currentState?.allerA(2)),
              Raccourci(Icons.bar_chart_rounded, 'Rapports', (_) => cadre.currentState?.allerA(3)),
              Raccourci(Icons.person_add_alt_rounded, 'Parrainer', (c) => _parrainer(c)),
            ],
          ),
        ),
        Onglet(
          icone: Icons.storefront_outlined,
          iconeActive: Icons.storefront_rounded,
          libelle: 'Ouvertes',
          titre: 'Opérations ouvertes',
          page: _OperationsOuvertes(operations: ouvertes),
        ),
        Onglet(
          icone: Icons.receipt_long_outlined,
          iconeActive: Icons.receipt_long_rounded,
          libelle: 'Participations',
          titre: 'Mes participations',
          page: _MesParticipations(participations: mesParts, etat: etat, onDecouvrir: () => cadre.currentState?.allerA(1)),
        ),
        const Onglet(icone: Icons.bar_chart_outlined, iconeActive: Icons.bar_chart_rounded, libelle: 'Rapports', titre: 'Rapports', page: _Rapports()),
        const Onglet(icone: Icons.person_outline_rounded, iconeActive: Icons.person_rounded, libelle: 'Profil', titre: 'Mon profil', page: EcranProfil(integre: true)),
      ],
    );
  }

  static void _parrainer(BuildContext context) {
    final nom = TextEditingController();
    final tel = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(ArzikiEspaces.l, 0, ArzikiEspaces.l, MediaQuery.viewInsetsOf(ctx).bottom + ArzikiEspaces.l),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Parrainer une personne', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: ArzikiEspaces.s),
          const Text("Votre demande est transmise à l'administrateur, qui décide seul de l'envoi d'un code d'invitation."),
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
              annoncer(context, "Demande envoyée. L'administrateur vous répondra par notification.");
            },
            child: const Text('Envoyer la demande'),
          ),
        ]),
      ),
    );
  }
}

class _OperationsOuvertes extends StatefulWidget {
  const _OperationsOuvertes({required this.operations});
  final List<Operation> operations;

  @override
  State<_OperationsOuvertes> createState() => _OperationsOuvertesState();
}

class _OperationsOuvertesState extends State<_OperationsOuvertes> {
  String? _secteur;
  String _tri = 'date';

  @override
  Widget build(BuildContext context) {
    final secteurs = widget.operations.map((o) => o.secteur).toSet().toList()..sort();
    var liste = widget.operations.where((o) => _secteur == null || o.secteur == _secteur).toList();
    liste.sort((a, b) => switch (_tri) {
          'montant' => b.montantAReunir.compareTo(a.montantAReunir),
          'duree' => a.dureeJours.compareTo(b.dureeJours),
          _ => a.dateLimite.compareTo(b.dateLimite),
        });
    return Colonne(children: [
      const EnTetePage('Opérations ouvertes', 'Les opérations commerciales vérifiées par ARZIKI, ouvertes à votre niveau.'),
      const AvertissementRisque(),
      const SizedBox(height: ArzikiEspaces.m),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          Padding(
            padding: const EdgeInsets.only(right: ArzikiEspaces.s),
            child: ChoiceChip(label: const Text('Tous les secteurs'), selected: _secteur == null, onSelected: (_) => setState(() => _secteur = null)),
          ),
          for (final s in secteurs)
            Padding(
              padding: const EdgeInsets.only(right: ArzikiEspaces.s),
              child: ChoiceChip(label: Text(s), selected: _secteur == s, onSelected: (_) => setState(() => _secteur = s)),
            ),
        ]),
      ),
      const SizedBox(height: ArzikiEspaces.s),
      Row(children: [
        Text('Trier par :', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(width: ArzikiEspaces.s),
        DropdownButton<String>(
          value: _tri,
          underline: const SizedBox(),
          items: const [
            DropdownMenuItem(value: 'date', child: Text('Date limite')),
            DropdownMenuItem(value: 'montant', child: Text('Montant')),
            DropdownMenuItem(value: 'duree', child: Text('Durée')),
          ],
          onChanged: (v) => setState(() => _tri = v!),
        ),
      ]),
      if (liste.isEmpty)
        const EcranVide(
          icone: Icons.storefront_rounded,
          titre: 'Aucune opération ouverte',
          texte: 'Vous recevrez une notification dès qu\'une nouvelle opération correspondant à votre niveau sera publiée.',
        ),
      for (var i = 0; i < liste.length; i++)
        Apparition(ordre: i, child: CarteOperation(operation: liste[i], onTap: () => context.push(Chemins.operationCercle(liste[i].id)))),
    ]);
  }
}

class _MesParticipations extends StatelessWidget {
  const _MesParticipations({required this.participations, required this.etat, required this.onDecouvrir});
  final List<Participation> participations;
  final EtatOperations etat;
  final VoidCallback onDecouvrir;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final total = participations.fold<int>(0, (s, p) => s + p.montant);
    return Colonne(children: [
      const EnTetePage('Mes participations', 'Ce que vous avez versé, ce qui est attendu et ce qui a été reçu, opération par opération.'),
      if (participations.isNotEmpty)
        CarteArziki(
          couleur: ArzikiCouleurs.vert.withValues(alpha: 0.07),
          child: Row(children: [
            const Icon(Icons.account_balance_rounded, color: ArzikiCouleurs.vert),
            const SizedBox(width: ArzikiEspaces.m),
            Expanded(child: Text('Total de vos participations', style: t.titleSmall)),
            Text(fcfa(total), style: t.titleMedium),
          ]),
        ),
      if (participations.isEmpty)
        EcranVide(
          image: Images.cercleApplication,
          titre: 'Aucune participation pour le moment',
          texte: 'Parcourez les opérations ouvertes et choisissez celles qui vous intéressent.',
          action: 'Voir les opérations ouvertes',
          onAction: onDecouvrir,
        ),
      for (final p in participations)
        if (etat.parId(p.operationId) case final o?)
          CarteArziki(
            onTap: () => context.push(Chemins.operationCercle(o.id)),
            child: Row(children: [
              Illustration(o.image, largeur: 64, hauteur: 64, rayon: 12),
              const SizedBox(width: ArzikiEspaces.m - 4),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(o.titre, style: t.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text('${fcfa(p.montant)} · ${o.statut.libelle}', style: t.bodySmall),
                  const SizedBox(height: 4),
                  BadgeStatut(
                    p.statut.libelle,
                    ton: switch (p.statut) {
                      StatutParticipation.attenteVersement => TonBadge.attente,
                      StatutParticipation.versementDeclare => TonBadge.info,
                      StatutParticipation.versementConfirme => TonBadge.succes,
                      StatutParticipation.paye => TonBadge.neutre,
                    },
                  ),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded),
            ]),
          ),
    ]);
  }
}

class _Rapports extends StatelessWidget {
  const _Rapports();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final rapports = [
      (DateTime(2026, 10, 5), 'Septembre 2026', '5 opérations en cours, 1 clôturée, 1 en retard de paiement.'),
      (DateTime(2026, 9, 5), 'Août 2026', '4 opérations en cours, 2 clôturées, aucune en retard.'),
      (DateTime(2026, 8, 5), 'Juillet 2026', '3 opérations en cours, 1 clôturée avec perte de 4,2 %.'),
    ];
    return Colonne(children: [
      const EnTetePage('Rapports', 'Chaque 5 du mois, un rapport sur les opérations du Cercle, sans données personnelles des autres membres.'),
      for (final r in rapports)
        CarteArziki(
          onTap: () => showModalBottomSheet<void>(
            context: context,
            builder: (ctx) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(ArzikiEspaces.l, 0, ArzikiEspaces.l, ArzikiEspaces.l),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Rapport de ${r.$2.toLowerCase()}', style: t.titleLarge),
                  Text('Publié le ${dateLongue(r.$1)}', style: t.bodySmall),
                  const SizedBox(height: ArzikiEspaces.m),
                  Text(r.$3),
                  const SizedBox(height: ArzikiEspaces.m),
                  const Encadre('En production, le rapport complet est généré en PDF par le serveur et téléchargeable ici.'),
                ]),
              ),
            ),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: ArzikiCouleurs.erreur.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.picture_as_pdf_rounded, color: ArzikiCouleurs.erreur),
            ),
            const SizedBox(width: ArzikiEspaces.m),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Rapport mensuel, ${r.$2}', style: t.titleSmall),
                Text(r.$3, style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded),
          ]),
        ),
      const SizedBox(height: ArzikiEspaces.m),
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
              CarteChiffre(icone: Icons.payments_rounded, valeur: fcfa(6200000), libelle: 'Règlements attendus', couleur: ArzikiCouleurs.info),
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
  int _delai = 45;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Colonne(children: [
      const EnTetePage('Bons de commande', 'Les bons de commande ARZIKI qui vous concernent. Indiquez vos conditions de paiement.'),
      CarteImage(
        image: Images.opFlotte,
        titre: 'Pièces détachées pour une flotte de camions',
        texte: 'Bon n° ARZ-BC-0042 · 8 000 000 FCFA · livraison avant le 30 novembre 2026',
        badge: BadgeStatut(_reponse ?? 'À traiter', ton: _reponse == null ? TonBadge.attente : TonBadge.succes),
        pied: _reponse != null
            ? Text('Votre réponse a été transmise à ARZIKI.', style: t.bodySmall)
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Paiement différé proposé', style: t.labelMedium),
                const SizedBox(height: 6),
                Wrap(spacing: ArzikiEspaces.s, children: [
                  for (final j in const [30, 45, 60, 90])
                    ChoiceChip(label: Text('$j jours'), selected: _delai == j, onSelected: (_) => setState(() => _delai = j)),
                ]),
                const SizedBox(height: ArzikiEspaces.m),
                FilledButton(
                  onPressed: () => setState(() => _reponse = 'Accepté, paiement à $_delai jours'),
                  child: Text('Accepter avec paiement à $_delai jours'),
                ),
                const SizedBox(height: ArzikiEspaces.s),
                OutlinedButton(onPressed: () => setState(() => _reponse = 'Paiement comptant demandé'), child: const Text('Demander un paiement comptant')),
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
      const EnTetePage('Livraisons', 'Déclarez vos livraisons avec photos et bordereau signé ; suivez vos règlements.'),
      CarteArziki(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Stock de maïs et de riz', style: Theme.of(context).textTheme.titleMedium),
          Text('Livraison 2 sur 3 · règlement prévu le 15 décembre 2026', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: ArzikiEspaces.m),
          if (_declaree)
            const Encadre('Livraison déclarée. ARZIKI et le notaire vérifient les pièces.', icone: Icons.check_circle_rounded)
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
    final ops = ref.watch(operationsProvider).operations.where((o) => o.statut != StatutOperation.cloturee).toList();
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
              CarteChiffre(icone: Icons.draw_rounded, valeur: '2', libelle: 'Actes à déposer', couleur: ArzikiCouleurs.orange, onTap: () => cadre.currentState?.allerA(2)),
              CarteChiffre(icone: Icons.account_balance_rounded, valeur: fcfa(68400000), libelle: 'Fonds en séquestre', couleur: ArzikiCouleurs.info),
            ],
            raccourcis: [
              Raccourci(Icons.folder_shared_rounded, 'Dossiers', (_) => cadre.currentState?.allerA(1)),
              Raccourci(Icons.draw_rounded, 'Actes', (_) => cadre.currentState?.allerA(2)),
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
            const EnTetePage('Dossiers assignés', 'Lecture seule des opérations qui vous sont confiées.'),
            for (final o in ops) CarteOperation(operation: o, onTap: () => _ficheNotaire(context, o)),
          ]),
        ),
        const Onglet(icone: Icons.draw_outlined, iconeActive: Icons.draw_rounded, libelle: 'Actes', titre: 'Actes et séquestre', page: _ActesNotaire()),
        const Onglet(icone: Icons.person_outline_rounded, iconeActive: Icons.person_rounded, libelle: 'Profil', titre: 'Mon profil', page: EcranProfil(integre: true)),
      ],
    );
  }

  static void _ficheNotaire(BuildContext context, Operation o) {
    final t = Theme.of(context).textTheme;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(ArzikiEspaces.l, 0, ArzikiEspaces.l, ArzikiEspaces.l),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(o.titre, style: t.titleLarge),
            const SizedBox(height: ArzikiEspaces.s),
            Text('Garanties : ${o.niveauGaranties}'),
            Text("Forme de l'acte : ${formeActePour(o.montantAReunir)}", style: t.bodySmall),
            const SizedBox(height: ArzikiEspaces.m),
            FriseEtapes(etapes: etapesOperation, courante: o.statut.etape),
          ]),
        ),
      ),
    );
  }
}

class _ActesNotaire extends StatefulWidget {
  const _ActesNotaire();

  @override
  State<_ActesNotaire> createState() => _ActesNotaireState();
}

class _ActesNotaireState extends State<_ActesNotaire> {
  final _deposes = <String>{};
  bool _fondsConfirmes = false;

  @override
  Widget build(BuildContext context) {
    const actes = [
      'Convention-cadre : Ciment et fers pour un chantier à Agoè',
      "Acte de cession de créance : Pièces d'usure pour un site minier",
    ];
    return Colonne(children: [
      const EnTetePage('Actes et séquestre', 'Déposez les actes signés et confirmez les fonds reçus sur votre compte séquestre.'),
      for (final a in actes)
        CarteArziki(
          child: Row(children: [
            Icon(_deposes.contains(a) ? Icons.check_circle_rounded : Icons.draw_rounded,
                color: _deposes.contains(a) ? ArzikiCouleurs.vert : ArzikiCouleurs.orange),
            const SizedBox(width: ArzikiEspaces.m),
            Expanded(child: Text(a)),
            if (!_deposes.contains(a))
              TextButton(onPressed: () => setState(() => _deposes.add(a)), child: const Text('Déposer')),
          ]),
        ),
      const TitreSection('Fonds reçus en séquestre'),
      CarteArziki(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Réassort de médicaments génériques : 7 800 000 FCFA déclarés par 9 participants.'),
          const SizedBox(height: ArzikiEspaces.m),
          if (_fondsConfirmes)
            const Encadre('Réception confirmée. Les participants sont notifiés.', icone: Icons.check_circle_rounded)
          else
            FilledButton(onPressed: () => setState(() => _fondsConfirmes = true), child: const Text('Confirmer la réception des fonds')),
        ]),
      ),
    ]);
  }
}

/// Utilisé par les écrans qui ont besoin de l'utilisateur courant.
Utilisateur utilisateurCourant(WidgetRef ref) => ref.read(sessionProvider).utilisateur!;
