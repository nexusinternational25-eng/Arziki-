// Console : opérations en vente à terme (CLAUDE.md, section 24) et paramètres.
//
// L'équipe analyse une demande, fixe les conditions (prix d'achat, majoration,
// durée), voit le coût annuel équivalent avec une alerte au-delà du seuil,
// propose l'opération à des partenaires choisis, retient les apports, suit les
// garanties et fait avancer chaque étape jusqu'à la clôture.
// L'analyste prépare (analyse, pièces, conditions) ; seuls super_admin et admin décident.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/session.dart';
import '../../core/roles.dart';
import '../../models/utilisateur.dart';
import '../../operations/operations.dart';
import '../../router/garde_roles.dart';
import '../../theme/arziki_theme.dart';
import '../../ui/composants.dart';
import '../espaces/espaces.dart';
import 'console.dart';

// ---------------------------------------------------------------------------
// Liste des opérations
// ---------------------------------------------------------------------------

class PageOperationsAdmin extends ConsumerStatefulWidget {
  const PageOperationsAdmin({super.key});

  @override
  ConsumerState<PageOperationsAdmin> createState() => _PageOperationsAdminState();
}

class _PageOperationsAdminState extends ConsumerState<PageOperationsAdmin> {
  String _filtre = 'a_traiter';

  static const _filtres = {
    'a_traiter': 'À traiter',
    'proposees': 'Proposées',
    'en_cours': 'En cours',
    'incidents': 'Retards',
    'terminees': 'Terminées',
    'toutes': 'Toutes',
  };

  bool _garder(Operation o) => switch (_filtre) {
        'a_traiter' => o.statut == StatutVente.soumise || o.statut == StatutVente.enAnalyse || o.statut == StatutVente.piecesDemandees,
        'proposees' => o.ouverteAuxManifestations,
        'en_cours' => const [StatutVente.signee, StatutVente.fournisseurPaye, StatutVente.livree, StatutVente.echeancePayee].contains(o.statut),
        'incidents' => o.statut == StatutVente.enRetard || o.statut == StatutVente.enRecouvrement,
        'terminees' => o.terminee,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    final ops = ref.watch(operationsProvider).operations;
    final liste = ops.where(_garder).toList();
    return CadreConsole(
      chemin: Chemins.adminOperations,
      titre: 'Opérations',
      corps: ListView(padding: const EdgeInsets.all(ArzikiEspaces.l), children: [
        const EnTetePage('Opérations', 'Des demandes des entreprises jusqu\'à la clôture, en vente à terme.'),
        Wrap(spacing: ArzikiEspaces.s, runSpacing: ArzikiEspaces.s, children: [
          for (final e in _filtres.entries)
            ChoiceChip(
              label: Text('${e.value} (${ops.where((o) {
                final avant = _filtre;
                _filtre = e.key;
                final r = _garder(o);
                _filtre = avant;
                return r;
              }).length})'),
              selected: _filtre == e.key,
              onSelected: (_) => setState(() => _filtre = e.key),
            ),
        ]),
        const SizedBox(height: ArzikiEspaces.m),
        if (liste.isEmpty) const EcranVide(icone: Icons.inbox_rounded, titre: 'Rien ici', texte: 'Aucune opération dans cette catégorie.'),
        for (final o in liste)
          CarteArziki(
            onTap: () => context.go(Chemins.adminOperation(o.id)),
            child: Row(children: [
              Illustration(o.image, largeur: 64, hauteur: 64, rayon: 12),
              const SizedBox(width: ArzikiEspaces.m),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(o.titre, style: Theme.of(context).textTheme.titleSmall),
                  Text(
                    o.conditionsFixees
                        ? '${o.secteur} · achat ${fcfa(o.prixAchat!)} · majoration ${fcfa(o.majoration!)} · ${o.dureeJours} j'
                        : '${o.secteur} · commande ${fcfa(o.montantCommande)} · reçue le ${dateLongue(o.creeLe)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Wrap(spacing: ArzikiEspaces.s, children: [
                    badgeStatutOperation(o.statut),
                    if (o.conditions?.alerte() ?? false)
                      BadgeStatut('Coût annuel ${_pct(o.coutAnnuelEquivalent!)}', ton: TonBadge.erreur),
                  ]),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded),
            ]),
          ),
      ]),
    );
  }
}

String _pct(double v) => '${v.toStringAsFixed(2).replaceAll('.', ',')} %';

// ---------------------------------------------------------------------------
// Détail d'une opération
// ---------------------------------------------------------------------------

class PageOperationAdmin extends ConsumerStatefulWidget {
  const PageOperationAdmin({super.key, required this.id});
  final String id;

  @override
  ConsumerState<PageOperationAdmin> createState() => _PageOperationAdminState();
}

class _PageOperationAdminState extends ConsumerState<PageOperationAdmin> {
  final _achat = TextEditingController();
  final _majoration = TextEditingController();
  final _duree = TextEditingController();
  final _commission = TextEditingController();
  String? _initialise;

  int _n(TextEditingController c) => int.tryParse(c.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

  void _remplir(Operation o) {
    if (_initialise == o.id) return;
    _initialise = o.id;
    _achat.text = '${o.prixAchat ?? ''}';
    _majoration.text = '${o.majoration ?? ''}';
    _duree.text = '${o.dureeJours ?? 60}';
    _commission.text = '${o.commissionArziki}';
  }

  ControleurOperations get _ctrl => ref.read(operationsProvider.notifier);
  String get _moi => ref.read(sessionProvider).utilisateur!.uid;

  void _faire(void Function() action, String succes) {
    try {
      action();
      annoncer(context, succes);
    } on ErreurVente catch (e) {
      annoncer(context, e.message, erreur: true);
    }
  }

  Future<String?> _demanderMotif(String titre) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titre),
        content: TextField(controller: c, maxLines: 3, decoration: const InputDecoration(labelText: "Motif (communiqué à l'entreprise)")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Valider')),
        ],
      ),
    );
    return ok == true && c.text.trim().isNotEmpty ? c.text.trim() : null;
  }

  Future<void> _changer(Operation o, StatutVente vers, String succes, {bool motif = false}) async {
    String? m;
    if (motif) {
      m = await _demanderMotif(vers.libelle);
      if (m == null) return;
    }
    _faire(() => _ctrl.changerStatut(_moi, o.id, vers, motif: m), succes);
  }

  Future<void> _proposer(Operation o, List<Utilisateur> partenaires) async {
    final choisis = <String>{...o.partenairesProposes};
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Proposer à des partenaires'),
          content: SizedBox(
            width: 420,
            child: ListView(shrinkWrap: true, children: [
              const Text('Seuls les partenaires actifs, dont l\'identité est validée, peuvent recevoir une proposition.'),
              for (final p in partenaires)
                CheckboxListTile(
                  value: choisis.contains(p.uid),
                  onChanged: (v) => setLocal(() => v == true ? choisis.add(p.uid) : choisis.remove(p.uid)),
                  title: Text(p.nomComplet),
                  subtitle: Text(p.role.libelle),
                ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Proposer')),
          ],
        ),
      ),
    );
    if (ok == true) _faire(() => _ctrl.proposer(_moi, o.id, choisis.toList()), 'Opération proposée.');
  }

  Future<void> _retenir(Operation o, Map<String, String> noms) async {
    final champs = {for (final e in o.manifestations.entries) e.key: TextEditingController(text: '${e.value}')};
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retenir les apports'),
        content: SizedBox(
          width: 420,
          child: ListView(shrinkWrap: true, children: [
            Text("Le total doit être exactement égal au prix d'achat : ${fcfa(o.prixAchat ?? 0)}. Mettez 0 pour ne pas retenir un partenaire."),
            const SizedBox(height: ArzikiEspaces.m),
            for (final e in champs.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: ArzikiEspaces.s),
                child: TextField(
                  controller: e.value,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: noms[e.key] ?? e.key, suffixText: 'FCFA'),
                ),
              ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Retenir')),
        ],
      ),
    );
    if (ok != true) return;
    final apports = [
      for (final e in champs.entries)
        if (_n(e.value) > 0) Apport(e.key, _n(e.value)),
    ];
    _faire(() => _ctrl.retenirApports(_moi, o.id, apports), 'Apports retenus. Le notaire peut recevoir la signature.');
  }

  @override
  Widget build(BuildContext context) {
    final o = ref.watch(operationsProvider).parId(widget.id);
    final role = ref.watch(sessionProvider).utilisateur!.role;
    final decide = role.peutValiderComptes;
    final t = Theme.of(context).textTheme;
    if (o == null) {
      return const CadreConsole(
        chemin: Chemins.adminOperations,
        titre: 'Opération',
        corps: Colonne(children: [EcranVide(icone: Icons.search_off_rounded, titre: 'Opération introuvable', texte: 'Elle a peut-être été supprimée de la démonstration.')]),
      );
    }
    _remplir(o);
    final seuil = ref.watch(baseDemoProvider).seuilAlerteCoutAnnuel;
    final apercu = _n(_achat) > 0 && _n(_duree) > 0
        ? ConditionsVente(prixAchat: _n(_achat), majoration: _n(_majoration), dureeJours: _n(_duree).clamp(1, 365))
        : null;

    return CadreConsole(
      chemin: Chemins.adminOperations,
      titre: 'Opération',
      action: TextButton.icon(onPressed: () => context.go(Chemins.adminOperations), icon: const Icon(Icons.arrow_back_rounded), label: const Text('Liste')),
      corps: FutureBuilder<List<Utilisateur>>(
        future: ref.read(depotComptesProvider).listerComptes(),
        builder: (context, snap) {
          final comptes = snap.data ?? const <Utilisateur>[];
          final noms = {for (final c in comptes) c.uid: c.nomComplet};
          final partenaires = comptes
              .where((c) => c.role.estMembreDuCercle && c.statut == StatutCompte.actif && c.kycStatut == StatutKyc.valide)
              .toList();
          return ListView(padding: const EdgeInsets.all(ArzikiEspaces.l), children: [
            EnTetePage(o.titre, '${o.secteur} · demande de ${noms[o.entrepriseUid] ?? 'l\'entreprise'} · reçue le ${dateLongue(o.creeLe)}'),
            Wrap(spacing: ArzikiEspaces.s, children: [badgeStatutOperation(o.statut), BadgeStatut('Pays : ${o.pays}', ton: TonBadge.info)]),
            const SizedBox(height: ArzikiEspaces.m),
            CarteArziki(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(o.resume),
                const SizedBox(height: ArzikiEspaces.s),
                Text('Client final : ${o.clientFinal}', style: t.bodySmall),
                Text('Fournisseur : ${o.fournisseur}', style: t.bodySmall),
                Text('Montant de la commande : ${fcfa(o.montantCommande)}', style: t.bodySmall),
                if (o.garantiesProposees.isNotEmpty)
                  Text('Garanties proposées : ${o.garantiesProposees.map((g) => g.libelle).join(', ')}', style: t.bodySmall),
                if (o.motif != null) Text('Dernier motif : ${o.motif}', style: t.bodySmall),
              ]),
            ),

            // ----- Étape suivante -----
            const TitreSection('Faire avancer'),
            Wrap(spacing: ArzikiEspaces.s, runSpacing: ArzikiEspaces.s, children: [
              if (o.statut == StatutVente.soumise)
                FilledButton(onPressed: () => _changer(o, StatutVente.enAnalyse, 'Demande en analyse.'), child: const Text('Passer en analyse')),
              if (o.statut == StatutVente.enAnalyse)
                OutlinedButton(onPressed: () => _changer(o, StatutVente.piecesDemandees, "Pièces demandées à l'entreprise.", motif: true), child: const Text('Demander des pièces')),
              if (o.statut == StatutVente.piecesDemandees)
                FilledButton(onPressed: () => _changer(o, StatutVente.enAnalyse, 'Analyse reprise.'), child: const Text("Reprendre l'analyse")),
              if (decide && o.statut == StatutVente.enAnalyse)
                OutlinedButton(onPressed: () => _changer(o, StatutVente.refusee, 'Demande non retenue.', motif: true), child: const Text('Ne pas retenir')),
              if (decide && (o.statut == StatutVente.enAnalyse || o.ouverteAuxManifestations))
                FilledButton.icon(onPressed: () => _proposer(o, partenaires), icon: const Icon(Icons.send_rounded), label: const Text('Proposer à des partenaires')),
              if (decide && o.statut == StatutVente.interetManifeste)
                FilledButton.icon(onPressed: () => _retenir(o, noms), icon: const Icon(Icons.handshake_rounded), label: const Text('Retenir les apports')),
              if (decide && o.statut == StatutVente.interetManifeste && o.apportsRetenus.isNotEmpty)
                FilledButton(onPressed: () => _changer(o, StatutVente.signee, 'Signature devant notaire enregistrée.'), child: const Text('Signature devant notaire faite')),
              if (decide && o.statut == StatutVente.signee)
                FilledButton(onPressed: () => _changer(o, StatutVente.fournisseurPaye, 'Paiement au fournisseur enregistré.'), child: const Text('Fournisseur payé')),
              if (decide && o.statut == StatutVente.fournisseurPaye)
                FilledButton(onPressed: () => _changer(o, StatutVente.livree, 'Livraison enregistrée.'), child: const Text('Marchandise livrée')),
              if (decide && const [StatutVente.livree, StatutVente.enRetard, StatutVente.enRecouvrement].contains(o.statut))
                FilledButton(onPressed: () => _changer(o, StatutVente.echeancePayee, "Paiement à l'échéance enregistré."), child: const Text('Échéance payée')),
              if (decide && (o.statut == StatutVente.livree || o.statut == StatutVente.fournisseurPaye))
                OutlinedButton(onPressed: () => _changer(o, StatutVente.enRetard, 'Opération en retard.'), child: const Text('Passer en retard')),
              if (decide && o.statut == StatutVente.enRetard)
                OutlinedButton(onPressed: () => _changer(o, StatutVente.enRecouvrement, 'Opération en recouvrement.'), child: const Text('Passer en recouvrement')),
              if (decide && (o.statut == StatutVente.echeancePayee || o.statut == StatutVente.enRecouvrement))
                FilledButton(onPressed: () => _changer(o, StatutVente.cloturee, 'Opération clôturée.'), child: const Text('Clôturer')),
              if (decide && transitionsVente[o.statut]!.contains(StatutVente.annulee))
                TextButton(onPressed: () => _changer(o, StatutVente.annulee, 'Opération annulée.', motif: true), child: const Text('Annuler l\'opération')),
              if (o.terminee) const Text('Opération terminée : plus aucune action possible.'),
            ]),
            if (!decide)
              Padding(
                padding: const EdgeInsets.only(top: ArzikiEspaces.s),
                child: Text('Analyste : vous préparez le dossier ; un administrateur décide.', style: t.bodySmall),
              ),

            // ----- Conditions de la vente à terme -----
            const TitreSection('Conditions de la vente à terme'),
            CarteArziki(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Wrap(spacing: ArzikiEspaces.m, runSpacing: ArzikiEspaces.m, children: [
                  for (final (c, l, s) in [
                    (_achat, "Prix d'achat", 'FCFA'),
                    (_majoration, 'Majoration fixe', 'FCFA'),
                    (_duree, 'Durée', 'jours'),
                    (_commission, 'Commission ARZIKI', 'FCFA'),
                  ])
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: c,
                        enabled: o.statut == StatutVente.enAnalyse || o.statut == StatutVente.proposee,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(labelText: l, suffixText: s),
                      ),
                    ),
                ]),
                const SizedBox(height: ArzikiEspaces.m),
                if (apercu != null) ...[
                  Text('Prix de revente : ${fcfa(apercu.prixRevente)}', style: t.titleSmall),
                  Text(
                    'Coût annuel équivalent : ${_pct(apercu.coutAnnuelEquivalent)} (seuil d\'alerte ${_pct(seuil)})',
                    style: t.bodyMedium?.copyWith(color: apercu.alerte(seuil) ? ArzikiCouleurs.erreur : null, fontWeight: FontWeight.w600),
                  ),
                  if (apercu.alerte(seuil))
                    const Padding(
                      padding: EdgeInsets.only(top: ArzikiEspaces.s),
                      child: Encadre(
                        'Alerte : le coût annuel équivalent dépasse le seuil. Réduisez la majoration ou allongez la durée, '
                        'ou justifiez la décision par écrit.',
                        type: TypeEncadre.erreur,
                      ),
                    ),
                  Text('Indicateur réservé à l\'équipe : il n\'est jamais affiché aux entreprises ni aux partenaires.', style: t.labelSmall),
                ],
                const SizedBox(height: ArzikiEspaces.m),
                if (o.statut == StatutVente.enAnalyse || o.statut == StatutVente.proposee)
                  FilledButton(
                    onPressed: () => _faire(
                      () => _ctrl.definirConditions(_moi, o.id,
                          prixAchat: _n(_achat), majoration: _n(_majoration), dureeJours: _n(_duree), commission: _n(_commission)),
                      'Conditions enregistrées.',
                    ),
                    child: const Text('Enregistrer les conditions'),
                  ),
              ]),
            ),

            // ----- Partenaires -----
            if (o.partenairesProposes.isNotEmpty) ...[
              const TitreSection('Partenaires'),
              CarteArziki(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Proposée à ${o.partenairesProposes.length} partenaire(s).', style: t.bodySmall),
                  const SizedBox(height: ArzikiEspaces.s),
                  if (o.manifestations.isEmpty) const Text("Aucune manifestation d'intérêt pour le moment."),
                  for (final e in o.manifestations.entries)
                    Text('Intérêt (non engageant) : ${noms[e.key] ?? e.key}, ${fcfa(e.value)}'),
                  if (o.repartition.isNotEmpty) ...[
                    const Divider(),
                    Text('Apports retenus et montants à recevoir à l\'échéance', style: t.titleSmall),
                    for (final p in o.repartition)
                      Text('${noms[p.partenaireUid] ?? p.partenaireUid} : apport ${fcfa(p.montant)}, part de majoration ${fcfa(p.partMajoration)}, total ${fcfa(p.aRecevoir)}'),
                  ],
                ]),
              ),
            ],

            // ----- Garanties -----
            const TitreSection('Garanties'),
            for (final g in o.garanties)
              CarteArziki(
                child: Row(children: [
                  Icon(g.constituee ? Icons.verified_rounded : Icons.shield_outlined, color: g.constituee ? ArzikiCouleurs.vert : ArzikiCouleurs.orange),
                  const SizedBox(width: ArzikiEspaces.m),
                  Expanded(child: Text(g.type.libelle)),
                  DropdownButton<StatutGarantie>(
                    value: g.statut,
                    underline: const SizedBox(),
                    items: [for (final s in StatutGarantie.values) DropdownMenuItem(value: s, child: Text(s.libelle))],
                    onChanged: decide ? (s) => _faire(() => _ctrl.majGarantie(_moi, o.id, g.type, s!), 'Garantie mise à jour.') : null,
                  ),
                ]),
              ),
            if (decide && !o.terminee)
              Wrap(spacing: ArzikiEspaces.s, children: [
                for (final type in TypeGarantie.values.where((t) => !o.garanties.any((g) => g.type == t)))
                  ActionChip(
                    avatar: const Icon(Icons.add_rounded, size: 18),
                    label: Text(type.libelle),
                    onPressed: () => _faire(() => _ctrl.majGarantie(_moi, o.id, type, StatutGarantie.aConstituer), 'Garantie ajoutée.'),
                  ),
              ]),

            // ----- Projets de contrats -----
            const TitreSection('Projets de contrats'),
            const Encadre(
              'Projets à faire valider par le notaire, produits en PDF par le serveur avec le filigrane '
              '« PROJET À VALIDER PAR LE NOTAIRE » : vente à terme avec réserve de propriété, nantissement de créance, '
              'acte de cautionnement, convention de séquestre, contrat de courtage ARZIKI.',
              icone: Icons.picture_as_pdf_rounded,
            ),
            const SizedBox(height: ArzikiEspaces.l),
          ]);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Paramètres (super administrateur)
// ---------------------------------------------------------------------------

class PageParametresAdmin extends ConsumerStatefulWidget {
  const PageParametresAdmin({super.key});

  @override
  ConsumerState<PageParametresAdmin> createState() => _PageParametresAdminState();
}

class _PageParametresAdminState extends ConsumerState<PageParametresAdmin> {
  late final _plafond = TextEditingController(text: '${ref.read(baseDemoProvider).plafondPartenaires}');
  late final _seuil = TextEditingController(text: ref.read(baseDemoProvider).seuilAlerteCoutAnnuel.toStringAsFixed(0));
  late final _tva = TextEditingController(text: ref.read(baseDemoProvider).tauxTva.toStringAsFixed(0));
  late final _ipdcp = TextEditingController(text: ref.read(baseDemoProvider).numeroIpdcp);
  String? _erreur;

  void _enregistrer() {
    final base = ref.read(baseDemoProvider);
    final plafond = int.tryParse(_plafond.text) ?? 0;
    final seuil = double.tryParse(_seuil.text.replaceAll(',', '.')) ?? 0;
    final tva = double.tryParse(_tva.text.replaceAll(',', '.')) ?? -1;
    if (plafond < 1 || plafond > plafondPartenairesMaximum) {
      setState(() => _erreur = 'Le plafond de partenaires doit être compris entre 1 et $plafondPartenairesMaximum.');
      return;
    }
    if (seuil <= 0 || seuil > 100) {
      setState(() => _erreur = "Le seuil d'alerte doit être compris entre 0 et 100 %.");
      return;
    }
    if (tva < 0 || tva > 50) {
      setState(() => _erreur = 'Le taux de TVA doit être compris entre 0 et 50 %.');
      return;
    }
    final avant = 'plafond ${base.plafondPartenaires}, seuil ${base.seuilAlerteCoutAnnuel}, TVA ${base.tauxTva}, IPDCP ${base.numeroIpdcp}';
    base
      ..plafondPartenaires = plafond
      ..seuilAlerteCoutAnnuel = seuil
      ..tauxTva = tva
      ..numeroIpdcp = _ipdcp.text.trim();
    base.auditer(ref.read(sessionProvider).utilisateur!.uid, 'modifier_parametres', 'parametres/global',
        avant: avant, apres: 'plafond $plafond, seuil $seuil, TVA $tva, IPDCP ${_ipdcp.text.trim()}');
    setState(() => _erreur = null);
    annoncer(context, 'Paramètres enregistrés.');
  }

  @override
  Widget build(BuildContext context) {
    Widget champ(TextEditingController c, String libelle, String aide, {bool nombre = true}) => Padding(
          padding: const EdgeInsets.only(bottom: ArzikiEspaces.m),
          child: TextField(
            controller: c,
            keyboardType: nombre ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(labelText: libelle, helperText: aide, helperMaxLines: 2),
          ),
        );
    return CadreConsole(
      chemin: Chemins.adminParametres,
      titre: 'Paramètres',
      corps: Colonne(children: [
        const EnTetePage('Paramètres', 'Réservés au super administrateur. Chaque modification est inscrite au journal.'),
        champ(_plafond, 'Plafond de partenaires financiers', '50 par défaut ; blocage dur à 99 (le cercle doit rester privé). Les invitations en cours comptent.'),
        champ(_seuil, 'Seuil d\'alerte du coût annuel équivalent (%)', '24 % par défaut. Au-delà, l\'opération est signalée en rouge dans la console.'),
        champ(_tva, 'Taux de TVA des factures (%)', '18 % par défaut.'),
        champ(_ipdcp, 'Numéro de déclaration IPDCP', 'Attribué par l\'autorité de protection des données. Affiché dans les mentions légales.', nombre: false),
        if (_erreur != null) Encadre(_erreur!, type: TypeEncadre.erreur),
        const SizedBox(height: ArzikiEspaces.m),
        FilledButton(onPressed: _enregistrer, child: const Text('Enregistrer')),
      ]),
    );
  }
}
