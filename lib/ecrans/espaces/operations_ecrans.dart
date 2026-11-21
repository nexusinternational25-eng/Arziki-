// Écrans liés aux opérations en vente à terme (CLAUDE.md, section 24) :
// fiche d'une opération (entreprise, partenaire, notaire), manifestation
// d'intérêt non engageante, nouvelle demande, notifications.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/session.dart';
import '../../contenu/contenus.dart';
import '../../core/images.dart';
import '../../core/roles.dart';
import '../../core/textes_legaux.dart';
import '../../operations/operations.dart';
import '../../router/garde_roles.dart';
import '../../theme/arziki_theme.dart';
import '../../ui/composants.dart';
import '../navigation/cadre_app.dart';
import 'espaces.dart';

// ---------------------------------------------------------------------------
// Fiche d'une opération
// ---------------------------------------------------------------------------

class FicheOperation extends ConsumerWidget {
  const FicheOperation({super.key, required this.id, required this.vue});
  final String id;
  final VueOperation vue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(operationsProvider);
    final o = etat.parId(id);
    final u = ref.watch(sessionProvider).utilisateur!;
    final t = Theme.of(context).textTheme;

    // Chacun ne voit que ce qui le concerne (R3) : sinon, « introuvable ».
    final autorise = o != null &&
        switch (vue) {
          VueOperation.entreprise => o.entrepriseUid == u.uid,
          VueOperation.partenaire => o.partenairesProposes.contains(u.uid) && u.statut == StatutCompte.actif && u.kycStatut == StatutKyc.valide,
          VueOperation.notaire => o.notaireUid == u.uid,
          VueOperation.equipe => u.role.accesConsole,
        };
    if (!autorise) {
      return Scaffold(
        appBar: AppBar(title: const Text('Opération')),
        body: Colonne(children: [
          EcranVide(
            icone: Icons.search_off_rounded,
            titre: 'Opération introuvable',
            texte: "Elle n'existe pas ou ne vous a pas été proposée.",
            action: 'Retour',
            onAction: () => context.pop(),
          ),
        ]),
      );
    }

    Widget ligne(String libelle, String valeur, IconData icone) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icone, size: 20, color: ArzikiCouleurs.vert),
            const SizedBox(width: ArzikiEspaces.m - 4),
            Expanded(child: Text(libelle, style: t.bodySmall)),
            const SizedBox(width: ArzikiEspaces.s),
            Flexible(child: Text(valeur, style: t.titleSmall, textAlign: TextAlign.right)),
          ]),
        );

    final partenaire = vue == VueOperation.partenaire;
    final monInteret = o.manifestations[u.uid];
    final maPart = o.repartition.where((p) => p.partenaireUid == u.uid).firstOrNull;
    final peutManifester = partenaire && o.ouverteAuxManifestations && maPart == null;

    return Scaffold(
      appBar: barreArziki(context, titre: switch (vue) {
        VueOperation.entreprise => 'Suivi de ma demande',
        VueOperation.notaire => 'Dossier notarial',
        _ => "Fiche de l'opération",
      }),
      bottomNavigationBar: peutManifester
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(ArzikiEspaces.m),
                child: LargeurMax(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    FilledButton.icon(
                      onPressed: () => _manifesterInteret(context, ref, o),
                      icon: const Icon(Icons.thumb_up_alt_rounded),
                      label: Text(monInteret == null ? 'Je suis intéressé' : 'Modifier mon intérêt'),
                    ),
                    const SizedBox(height: 4),
                    Text(TextesLegaux.interetNonEngageant, style: t.labelSmall, textAlign: TextAlign.center),
                  ]),
                ),
              ),
            )
          : null,
      body: Colonne(children: [
        EnTeteImage(image: o.image, titre: o.titre, sousTitre: o.secteur, hauteur: 210),
        const SizedBox(height: ArzikiEspaces.m),
        Wrap(spacing: ArzikiEspaces.s, runSpacing: ArzikiEspaces.s, children: [
          badgeStatutOperation(o.statut),
          if (monInteret != null && maPart == null) BadgeStatut('Intérêt indiqué : ${fcfa(monInteret)}', ton: TonBadge.info),
        ]),
        const SizedBox(height: ArzikiEspaces.m),
        if (partenaire) const AvertissementRisque(),
        if (o.motif != null && (o.statut == StatutVente.piecesDemandees || o.statut == StatutVente.refusee))
          Encadre('Message de l\'équipe ARZIKI : ${o.motif}', type: TypeEncadre.alerte),
        const TitreSection("L'opération en bref"),
        Text(o.resume),
        const TitreSection('Vente à terme'),
        CarteArziki(
          child: Column(children: [
            if (!o.conditionsFixees) ...[
              ligne('Montant de la commande', fcfa(o.montantCommande), Icons.receipt_long_rounded),
              Padding(
                padding: const EdgeInsets.only(top: ArzikiEspaces.s),
                child: Text("Les conditions (prix d'achat, majoration, échéance) seront fixées pendant l'analyse.", style: t.bodySmall),
              ),
            ] else ...[
              ligne("Prix d'achat au fournisseur", fcfa(o.prixAchat!), Icons.shopping_cart_rounded),
              ligne('Majoration fixe', fcfa(o.majoration!), Icons.add_circle_outline_rounded),
              ligne('Prix de revente', fcfa(o.prixRevente!), Icons.sell_rounded),
              ligne('Durée', '${o.dureeJours} jours', Icons.schedule_rounded),
              if (o.echeance != null) ligne('Échéance', dateLongue(o.echeance!), Icons.event_rounded),
            ],
          ]),
        ),
        if (maPart != null) ...[
          const TitreSection('Ma part'),
          CarteArziki(
            couleur: ArzikiCouleurs.vert.withValues(alpha: 0.07),
            child: Column(children: [
              ligne('Mon apport (part du prix d\'achat)', fcfa(maPart.montant), Icons.handshake_rounded),
              ligne('Ma part de la majoration', fcfa(maPart.partMajoration), Icons.add_circle_outline_rounded),
              ligne("À recevoir à l'échéance", fcfa(maPart.aRecevoir), Icons.account_balance_rounded),
            ]),
          ),
        ],
        const TitreSection('Les acteurs'),
        CarteArziki(
          child: Column(children: [
            ligne('Client final', partenaire ? 'Grand compte, secteur ${o.secteur}' : o.clientFinal, Icons.business_rounded),
            ligne('Fournisseur', o.fournisseur, Icons.local_shipping_rounded),
            if (o.notaireUid != null) ligne('Notaire', 'Maître Kafui Atsu, Lomé', Icons.gavel_rounded),
          ]),
        ),
        const TitreSection('Garanties'),
        if (o.garanties.isEmpty)
          CarteArziki(
            child: Text(
              o.garantiesProposees.isEmpty
                  ? 'Les garanties seront fixées pendant l\'analyse.'
                  : 'Proposées par l\'entreprise : ${o.garantiesProposees.map((g) => g.libelle).join(', ')}.',
            ),
          ),
        for (final g in o.garanties) _LigneGarantie(operation: o, garantie: g, modifiable: vue == VueOperation.notaire),
        const TitreSection('Étapes'),
        CarteArziki(child: FriseEtapes(etapes: etapesVente, courante: o.statut.etape)),
        if (vue == VueOperation.notaire) _ActionsNotaire(operation: o),
        const TitreSection('Documents'),
        for (final d in [
          if (vue == VueOperation.entreprise) 'Bon de commande ou marché',
          if (vue == VueOperation.entreprise) 'Devis du fournisseur',
          if (o.conditionsFixees) 'Projet de contrat de vente à terme (à valider par le notaire)',
          if (o.statut.index >= StatutVente.signee.index && o.statut != StatutVente.annulee) 'Actes signés devant notaire',
        ])
          CarteArziki(
            child: Row(children: [
              const Icon(Icons.description_rounded, color: ArzikiCouleurs.vert),
              const SizedBox(width: ArzikiEspaces.m),
              Expanded(child: Text(d)),
              const Icon(Icons.lock_outline_rounded, size: 18),
            ]),
          ),
        if (vue == VueOperation.entreprise) ...[
          const SizedBox(height: ArzikiEspaces.s),
          OutlinedButton.icon(
            onPressed: () => context.push(Chemins.info(PagesId.aide)),
            icon: const Icon(Icons.chat_rounded),
            label: const Text("Écrire à l'équipe ARZIKI"),
          ),
        ],
        if (partenaire) ...[const SizedBox(height: ArzikiEspaces.m), const AvertissementRisque()],
        const SizedBox(height: ArzikiEspaces.l),
      ]),
    );
  }

  Future<void> _manifesterInteret(BuildContext context, WidgetRef ref, Operation o) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FeuilleInteret(operation: o),
    );
    if (ok == true && context.mounted) {
      annoncer(context, "Intérêt enregistré. L'équipe ARZIKI vous contactera avant toute signature devant notaire.");
    }
  }
}

class _LigneGarantie extends ConsumerWidget {
  const _LigneGarantie({required this.operation, required this.garantie, required this.modifiable});
  final Operation operation;
  final Garantie garantie;
  final bool modifiable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = garantie;
    return CarteArziki(
      child: Row(children: [
        Icon(g.constituee ? Icons.verified_rounded : Icons.shield_outlined, color: g.constituee ? ArzikiCouleurs.vert : ArzikiCouleurs.orange),
        const SizedBox(width: ArzikiEspaces.m),
        Expanded(child: Text(g.type.libelle)),
        if (!modifiable)
          BadgeStatut(g.statut.libelle, ton: g.constituee ? TonBadge.succes : TonBadge.attente)
        else
          DropdownButton<StatutGarantie>(
            value: g.statut,
            underline: const SizedBox(),
            items: [for (final s in StatutGarantie.values) DropdownMenuItem(value: s, child: Text(s.libelle))],
            onChanged: (s) {
              if (s == null) return;
              final uid = ref.read(sessionProvider).utilisateur!.uid;
              ref.read(operationsProvider.notifier).majGarantie(uid, operation.id, g.type, s);
              annoncer(context, '${g.type.libelle} : ${s.libelle.toLowerCase()}.');
            },
          ),
      ]),
    );
  }
}

/// Actions du notaire assigné : confirmer la signature, puis le paiement au fournisseur.
class _ActionsNotaire extends ConsumerWidget {
  const _ActionsNotaire({required this.operation});
  final Operation operation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = operation;
    final uid = ref.read(sessionProvider).utilisateur!.uid;
    void faire(StatutVente vers, String message) {
      try {
        ref.read(operationsProvider.notifier).changerStatut(uid, o.id, vers);
        annoncer(context, message);
      } on ErreurVente catch (e) {
        annoncer(context, e.message, erreur: true);
      }
    }

    final actions = <Widget>[
      if (o.statut == StatutVente.interetManifeste)
        FilledButton.icon(
          onPressed: () => faire(StatutVente.signee, 'Signature devant notaire enregistrée.'),
          icon: const Icon(Icons.draw_rounded),
          label: const Text('Confirmer la signature devant notaire'),
        ),
      if (o.statut == StatutVente.signee)
        FilledButton.icon(
          onPressed: () => faire(StatutVente.fournisseurPaye, 'Paiement au fournisseur confirmé.'),
          icon: const Icon(Icons.payments_rounded),
          label: const Text('Confirmer le paiement au fournisseur'),
        ),
    ];
    if (actions.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const TitreSection('À faire'),
      ...actions,
      const SizedBox(height: ArzikiEspaces.s),
      Text(
        'Le paiement au fournisseur n\'est possible que lorsque toutes les garanties sont signées ou inscrites.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ]);
  }
}

/// « Je suis intéressé » : montant indicatif, non engageant (R4).
class _FeuilleInteret extends ConsumerStatefulWidget {
  const _FeuilleInteret({required this.operation});
  final Operation operation;

  @override
  ConsumerState<_FeuilleInteret> createState() => _FeuilleInteretState();
}

class _FeuilleInteretState extends ConsumerState<_FeuilleInteret> {
  final _montant = TextEditingController();
  bool _comprend = false;
  String? _erreur;

  int get _valeur => int.tryParse(_montant.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

  @override
  void initState() {
    super.initState();
    final deja = widget.operation.manifestations[ref.read(sessionProvider).utilisateur!.uid];
    if (deja != null) _montant.text = '$deja';
  }

  void _valider() {
    final o = widget.operation;
    if (!_comprend) {
      setState(() => _erreur = 'Cochez la case pour confirmer que vous avez compris.');
      return;
    }
    try {
      ref.read(operationsProvider.notifier).manifesterInteret(uid: ref.read(sessionProvider).utilisateur!.uid, id: o.id, montant: _valeur);
      Navigator.pop(context, true);
    } on ErreurVente catch (e) {
      setState(() => _erreur = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final o = widget.operation;
    return Padding(
      padding: EdgeInsets.fromLTRB(ArzikiEspaces.l, 0, ArzikiEspaces.l, MediaQuery.viewInsetsOf(context).bottom + ArzikiEspaces.l),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Je suis intéressé', style: t.titleLarge),
          Text(o.titre, style: t.bodySmall),
          const SizedBox(height: ArzikiEspaces.m),
          const Encadre(TextesLegaux.interetNonEngageant, icone: Icons.info_outline_rounded),
          const SizedBox(height: ArzikiEspaces.m),
          TextField(
            controller: _montant,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Montant que vous envisagez (FCFA)',
              helperText: "Indicatif, au plus ${fcfa(o.prixAchat ?? 0)}${_valeur > 0 ? ' · vous saisissez ${fcfa(_valeur)}' : ''}",
            ),
          ),
          const SizedBox(height: ArzikiEspaces.s),
          CheckboxListTile(
            value: _comprend,
            onChanged: (v) => setState(() => _comprend = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text("Je comprends que toute participation comporte un risque de perte et que seule la signature devant notaire m'engage."),
          ),
          if (_erreur != null) ...[const SizedBox(height: ArzikiEspaces.s), Encadre(_erreur!, type: TypeEncadre.erreur)],
          const SizedBox(height: ArzikiEspaces.m),
          FilledButton(onPressed: _valeur > 0 ? _valider : null, child: const Text('Envoyer mon intérêt')),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nouvelle demande : commande à financer (section 24)
// ---------------------------------------------------------------------------

class EcranNouvelleDemande extends ConsumerStatefulWidget {
  const EcranNouvelleDemande({super.key, this.prefill});

  /// Texte préparé (par exemple après un diagnostic : « Avez-vous une commande ferme ? »).
  final String? prefill;

  @override
  ConsumerState<EcranNouvelleDemande> createState() => _EcranNouvelleDemandeState();
}

class _EcranNouvelleDemandeState extends ConsumerState<EcranNouvelleDemande> {
  int _etape = 0;
  final _client = TextEditingController();
  final _rccm = TextEditingController();
  final _contact = TextEditingController();
  String? _secteur;
  final _description = TextEditingController();
  final _montant = TextEditingController();
  final _delai = TextEditingController(text: '60');
  bool _bonCommande = false;
  final _fournisseur = TextEditingController();
  final _contactFournisseur = TextEditingController();
  final _achat = TextEditingController();
  bool _devis = false;
  final _garanties = <TypeGarantie>{};
  bool _engagement = false;
  String? _erreur;

  static const _titres = ['Le client final', 'La commande', 'Le fournisseur', 'Les garanties proposées', 'Récapitulatif'];

  @override
  void initState() {
    super.initState();
    if (widget.prefill != null) _description.text = widget.prefill!;
  }

  int _n(TextEditingController c) => int.tryParse(c.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

  String? _verifier(int etape) {
    switch (etape) {
      case 0:
        if (_client.text.trim().length < 3) return 'Indiquez la raison sociale de votre client.';
        if (_contact.text.trim().length < 8) return 'Indiquez un contact chez votre client (téléphone ou e-mail).';
        if (_secteur == null) return 'Choisissez le secteur.';
      case 1:
        if (_description.text.trim().length < 10) return 'Décrivez la commande en quelques mots.';
        if (_n(_montant) < 1000000) return 'Le montant de la commande doit être d\'au moins 1 000 000 FCFA.';
        if (_n(_delai) < 1 || _n(_delai) > 365) return 'Le délai doit être compris entre 1 et 365 jours.';
        if (!_bonCommande) return 'Joignez le bon de commande ou le marché (PDF, JPG ou PNG).';
      case 2:
        if (_fournisseur.text.trim().length < 3) return 'Indiquez le nom du fournisseur.';
        if (_contactFournisseur.text.trim().length < 8) return 'Indiquez un contact chez le fournisseur.';
        if (_n(_achat) <= 0) return "Indiquez le prix d'achat chez le fournisseur.";
        if (_n(_achat) >= _n(_montant)) return "Le prix d'achat doit être inférieur au montant de votre commande.";
        if (!_devis) return 'Joignez le devis ou la facture pro forma du fournisseur.';
      case 3:
        if (_garanties.isEmpty) return 'Choisissez au moins une garantie que vous pouvez proposer.';
      case 4:
        if (!_engagement) return "Cochez l'engagement sur l'honneur pour envoyer la demande.";
    }
    return null;
  }

  void _suivant() {
    final e = _verifier(_etape);
    setState(() => _erreur = e);
    if (e != null) return;
    if (_etape < 4) {
      setState(() => _etape++);
      return;
    }
    final u = ref.read(sessionProvider).utilisateur!;
    ref.read(operationsProvider.notifier).soumettre(Operation(
          id: 'op-${DateTime.now().millisecondsSinceEpoch}',
          titre: _description.text.trim().split('\n').first,
          secteur: _secteur!,
          image: Images.entrepreneurEntrepot,
          statut: StatutVente.soumise,
          entrepriseUid: u.uid,
          clientFinal: _client.text.trim(),
          fournisseur: _fournisseur.text.trim(),
          resume: _description.text.trim(),
          montantCommande: _n(_montant),
          creeLe: DateTime.now(),
          garantiesProposees: _garanties.toList(),
          pays: u.pays,
        ));
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: ArzikiCouleurs.vert, size: 48),
        title: const Text('Demande envoyée'),
        content: const Text('Notre équipe va contacter directement votre client et votre fournisseur. '
            'Vous suivrez chaque étape dans « Mes opérations ».'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(Chemins.entreprise);
            },
            child: const Text('Retour à mon espace'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    Widget champMontant(TextEditingController c, String libelle) => Padding(
          padding: const EdgeInsets.only(bottom: ArzikiEspaces.m),
          child: TextField(
            controller: c,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: libelle, suffixText: 'FCFA', helperText: _n(c) > 0 ? fcfa(_n(c)) : null),
          ),
        );
    Widget piece(bool ok, String libelle, VoidCallback onTap) => CarteArziki(
          onTap: onTap,
          child: Row(children: [
            Icon(ok ? Icons.check_circle_rounded : Icons.upload_file_rounded, color: ok ? ArzikiCouleurs.vert : ArzikiCouleurs.orange),
            const SizedBox(width: ArzikiEspaces.m),
            Expanded(child: Text(ok ? '$libelle : ajouté' : libelle)),
            Text(ok ? 'Remplacer' : 'Ajouter', style: t.labelLarge?.copyWith(color: ArzikiCouleurs.vert)),
          ]),
        );

    final suggerees = garantiesSuggerees(_n(_achat));
    final contenu = switch (_etape) {
      0 => [
          TextField(controller: _client, decoration: const InputDecoration(labelText: 'Raison sociale de votre client')),
          const SizedBox(height: ArzikiEspaces.m),
          TextField(controller: _rccm, decoration: const InputDecoration(labelText: 'RCCM du client (si connu)')),
          const SizedBox(height: ArzikiEspaces.m),
          TextField(
            controller: _contact,
            decoration: const InputDecoration(labelText: 'Contact chez votre client', helperText: 'ARZIKI appellera directement ce contact.'),
          ),
          const SizedBox(height: ArzikiEspaces.m),
          DropdownButtonFormField<String>(
            initialValue: _secteur,
            decoration: const InputDecoration(labelText: 'Secteur'),
            items: [
              for (final s in const ['Santé', 'BTP', 'Agriculture', 'Mines et industrie', 'Commerce', 'Transport et logistique', 'Équipements', 'Autre'])
                DropdownMenuItem(value: s, child: Text(s)),
            ],
            onChanged: (v) => setState(() => _secteur = v),
          ),
        ],
      1 => [
          TextField(controller: _description, maxLines: 3, decoration: const InputDecoration(labelText: 'Description de la commande', helperText: 'Produits, quantités, date de livraison')),
          const SizedBox(height: ArzikiEspaces.m),
          champMontant(_montant, 'Montant de la commande (ce que votre client paiera)'),
          TextField(
            controller: _delai,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Délai souhaité jusqu\'à l\'échéance', suffixText: 'jours'),
          ),
          const SizedBox(height: ArzikiEspaces.s),
          piece(_bonCommande, 'Bon de commande ou marché (obligatoire)', () => setState(() => _bonCommande = true)),
        ],
      2 => [
          TextField(controller: _fournisseur, decoration: const InputDecoration(labelText: 'Nom du fournisseur')),
          const SizedBox(height: ArzikiEspaces.m),
          TextField(controller: _contactFournisseur, decoration: const InputDecoration(labelText: 'Contact du fournisseur')),
          const SizedBox(height: ArzikiEspaces.m),
          champMontant(_achat, "Prix d'achat chez le fournisseur"),
          piece(_devis, 'Devis ou facture pro forma (obligatoire)', () => setState(() => _devis = true)),
        ],
      3 => [
          Text('Cochez les garanties que vous pouvez proposer. Pour ${fcfa(_n(_achat))}, nous suggérons celles marquées « suggérée ».', style: t.bodyMedium),
          const SizedBox(height: ArzikiEspaces.s),
          for (final g in TypeGarantie.values)
            CheckboxListTile(
              value: _garanties.contains(g),
              onChanged: (v) => setState(() => v == true ? _garanties.add(g) : _garanties.remove(g)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: Text(g.libelle),
              subtitle: suggerees.contains(g) ? const Text('Suggérée pour ce montant') : null,
            ),
          const Encadre('Les garanties sont signées devant notaire et, si besoin, inscrites au RCCM.', icone: Icons.gavel_rounded),
        ],
      _ => [
          CarteArziki(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_description.text, style: t.titleSmall),
              const SizedBox(height: ArzikiEspaces.s),
              Text('Client final : ${_client.text}'),
              Text('Fournisseur : ${_fournisseur.text}'),
              Text('Montant de la commande : ${fcfa(_n(_montant))}'),
              Text("Prix d'achat : ${fcfa(_n(_achat))}"),
              Text('Délai : ${_n(_delai)} jours'),
              Text('Garanties proposées : ${_garanties.map((g) => g.libelle).join(', ')}'),
            ]),
          ),
          const Encadre(
            "La majoration et l'échéance vous seront proposées par écrit après l'analyse. Rien n'est engagé avant la signature devant notaire.",
            icone: Icons.info_outline_rounded,
          ),
          CheckboxListTile(
            value: _engagement,
            onChanged: (v) => setState(() => _engagement = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text("Je certifie sur l'honneur que ces informations et ces documents sont exacts et authentiques."),
          ),
        ],
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle demande')),
      body: Colonne(children: [
        const EnTetePage('Commande à financer', 'Cinq étapes rapides. Votre brouillon reste ouvert tant que vous ne quittez pas cet écran.'),
        Row(children: [
          for (var i = 0; i < 5; i++)
            Expanded(
              child: Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: i <= _etape ? ArzikiCouleurs.orange : Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
        ]),
        const SizedBox(height: ArzikiEspaces.m),
        Text('Étape ${_etape + 1} sur 5 : ${_titres[_etape]}', style: t.titleLarge),
        const SizedBox(height: ArzikiEspaces.m),
        ...contenu,
        if (_erreur != null) ...[const SizedBox(height: ArzikiEspaces.m), Encadre(_erreur!, type: TypeEncadre.erreur)],
        const SizedBox(height: ArzikiEspaces.l),
        Row(children: [
          if (_etape > 0)
            Expanded(child: OutlinedButton(onPressed: () => setState(() { _etape--; _erreur = null; }), child: const Text('Précédent'))),
          if (_etape > 0) const SizedBox(width: ArzikiEspaces.m),
          Expanded(child: FilledButton(onPressed: _suivant, child: Text(_etape == 4 ? 'Envoyer la demande' : 'Suivant'))),
        ]),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifications
// ---------------------------------------------------------------------------

class EcranNotifications extends ConsumerWidget {
  const EcranNotifications({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(sessionProvider).utilisateur!;
    final liste = notificationsPour(u.role);
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(),
      body: Colonne(children: [
        const EnTetePage('Notifications', 'Les étapes de vos dossiers et les informations importantes.'),
        if (liste.isEmpty)
          const EcranVide(icone: Icons.notifications_none_rounded, titre: 'Aucune notification', texte: 'Vous serez prévenu ici de chaque étape importante.'),
        for (var i = 0; i < liste.length; i++)
          Apparition(
            ordre: i,
            child: CarteArziki(
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: liste[i].lue ? Colors.transparent : ArzikiCouleurs.orange, shape: BoxShape.circle),
                ),
                const SizedBox(width: ArzikiEspaces.m - 4),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(liste[i].titre, style: t.titleSmall),
                    const SizedBox(height: 2),
                    Text(liste[i].texte),
                    const SizedBox(height: 4),
                    Text(dateLongue(liste[i].date), style: t.labelSmall),
                  ]),
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}

/// Image de secours pour les écrans d'erreur d'opération.
const imageOperationParDefaut = Images.opBtp;
