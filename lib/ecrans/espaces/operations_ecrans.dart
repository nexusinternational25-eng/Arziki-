// Écrans liés aux opérations : fiche d'une opération (Cercle), participation,
// suivi par l'entreprise, nouvelle demande de Commande Financée, notifications.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/session.dart';
import '../../contenu/contenus.dart';
import '../../core/images.dart';
import '../../core/textes_legaux.dart';
import '../../operations/operations.dart';
import '../../preferences/preferences.dart';
import '../../router/garde_roles.dart';
import '../../theme/arziki_theme.dart';
import '../../ui/composants.dart';
import '../navigation/cadre_app.dart';
import 'espaces.dart';

// ---------------------------------------------------------------------------
// Fiche d'une opération
// ---------------------------------------------------------------------------

class FicheOperation extends ConsumerWidget {
  const FicheOperation({super.key, required this.id, this.vueEntreprise = false});
  final String id;
  final bool vueEntreprise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(operationsProvider);
    final o = etat.parId(id);
    final u = ref.watch(sessionProvider).utilisateur!;
    final t = Theme.of(context).textTheme;
    if (o == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Opération')),
        body: Colonne(children: [
          EcranVide(
            icone: Icons.search_off_rounded,
            titre: 'Opération introuvable',
            texte: "Elle n'est plus disponible ou n'est pas ouverte à votre niveau.",
            action: 'Retour',
            onAction: () => context.pop(),
          ),
        ]),
      );
    }
    // Règle légale n° 3 : un membre ne voit que les opérations de son niveau.
    if (!vueEntreprise && o.estEntreprises && !u.role.voitOperationsEntreprises) {
      return Scaffold(
        appBar: AppBar(title: const Text('Opération')),
        body: Colonne(children: [
          EcranVide(
            icone: Icons.lock_rounded,
            titre: 'Réservée au niveau Partenaire',
            texte: 'Cette opération du format Entreprises est ouverte aux partenaires du Cercle.',
            action: 'Retour',
            onAction: () => context.pop(),
          ),
        ]),
      );
    }
    final maPart = etat.participations.where((p) => p.uid == u.uid && p.operationId == o.id).firstOrNull;

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

    return Scaffold(
      appBar: barreArziki(context, titre: vueEntreprise ? 'Suivi de mon opération' : "Fiche de l'opération"),
      bottomNavigationBar: !vueEntreprise && o.estOuverte && maPart == null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(ArzikiEspaces.m),
                child: LargeurMax(
                  child: FilledButton.icon(
                    onPressed: () => _participer(context, ref, o),
                    icon: const Icon(Icons.handshake_rounded),
                    label: const Text('Je participe'),
                  ),
                ),
              ),
            )
          : null,
      body: Colonne(children: [
        EnTeteImage(image: o.image, titre: o.titre, sousTitre: '${o.secteur} · ${o.estEntreprises ? 'Format Entreprises' : 'Format PME'}', hauteur: 210),
        const SizedBox(height: ArzikiEspaces.m),
        Wrap(spacing: ArzikiEspaces.s, runSpacing: ArzikiEspaces.s, children: [
          badgeStatutOperation(o.statut),
          if (o.estOuverte) BadgeStatut('${o.placesRestantes} places restantes', ton: TonBadge.info),
        ]),
        const SizedBox(height: ArzikiEspaces.m),
        if (!vueEntreprise) const AvertissementRisque(),
        const TitreSection("L'opération en bref"),
        Text(o.resume),
        if (o.estOuverte) ...[
          const SizedBox(height: ArzikiEspaces.m),
          CarteArziki(child: JaugeFinancement(reuni: o.montantReuni, objectif: o.montantAReunir)),
        ],
        CarteArziki(
          child: Column(children: [
            ligne('Montant à réunir', fcfa(o.montantAReunir), Icons.payments_rounded),
            ligne('Durée prévue', '${o.dureeJours} jours', Icons.schedule_rounded),
            ligne('Marge visée (objectif)', '${o.margeViseePct.toStringAsFixed(0)} %', Icons.trending_up_rounded),
            ligne('Part prévue pour les investisseurs', '${o.partInvestisseursPct} % de la marge nette', Icons.pie_chart_rounded),
            if (o.estOuverte) ligne('Date limite', dateLongue(o.dateLimite), Icons.event_rounded),
            if (o.estOuverte) ligne('Participation', '${fcfa(o.minParticipant)} à ${fcfa(o.maxParticipant)}', Icons.account_balance_wallet_rounded),
          ]),
        ),
        const TitreSection('Les acteurs'),
        CarteArziki(
          child: Column(children: [
            ligne('Acheteur final', o.acheteur, Icons.business_rounded),
            ligne('Fournisseur', o.fournisseur, Icons.local_shipping_rounded),
            ligne('Notaire', 'Maître Kafui Atsu, Lomé', Icons.gavel_rounded),
            ligne('Garanties prises', o.niveauGaranties, Icons.shield_rounded),
          ]),
        ),
        const TitreSection('Calendrier'),
        CarteArziki(child: FriseEtapes(etapes: etapesOperation, courante: o.statut.etape)),
        if (maPart != null) ...[
          const TitreSection('Ma participation'),
          CarteArziki(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(fcfa(maPart.montant), style: t.headlineSmall),
              const SizedBox(height: 4),
              BadgeStatut(maPart.statut.libelle, ton: TonBadge.succes),
              if (maPart.reference != null) ...[
                const SizedBox(height: ArzikiEspaces.s),
                Text('Référence de versement : ${maPart.reference}', style: t.bodySmall),
              ],
            ]),
          ),
        ],
        if (vueEntreprise) ...[
          const TitreSection('Documents'),
          for (final d in const ['Bon de commande signé', 'Devis du fournisseur', 'Convention-cadre (notaire)'])
            CarteArziki(
              child: Row(children: [
                const Icon(Icons.description_rounded, color: ArzikiCouleurs.vert),
                const SizedBox(width: ArzikiEspaces.m),
                Expanded(child: Text(d)),
                const BadgeStatut('Reçu', ton: TonBadge.succes),
              ]),
            ),
          const SizedBox(height: ArzikiEspaces.s),
          OutlinedButton.icon(
            onPressed: () => context.push(Chemins.info(PagesId.aide)),
            icon: const Icon(Icons.chat_rounded),
            label: const Text("Écrire à l'équipe ARZIKI"),
          ),
        ],
        if (!vueEntreprise) ...[const SizedBox(height: ArzikiEspaces.m), const AvertissementRisque()],
        const SizedBox(height: ArzikiEspaces.l),
      ]),
    );
  }

  Future<void> _participer(BuildContext context, WidgetRef ref, Operation o) async {
    final u = ref.read(sessionProvider).utilisateur!;
    final minimum = o.minParticipant > u.niveau!.participationMinimale ? o.minParticipant : u.niveau!.participationMinimale;
    final p = await showModalBottomSheet<Participation>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FeuilleParticipation(operation: o, minimum: minimum),
    );
    if (p == null || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: ArzikiCouleurs.vert, size: 48),
        title: const Text('Intention enregistrée'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Versez ${fcfa(p.montant)} par virement ou mobile money sur le compte séquestre du notaire :'),
          const SizedBox(height: ArzikiEspaces.s),
          const SelectableText('Maître Kafui Atsu, compte séquestre ARZIKI\nBanque partenaire, Lomé'),
          const SizedBox(height: ArzikiEspaces.s),
          SelectableText('Référence à indiquer : ${p.reference}', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: ArzikiEspaces.s),
          const Text('Déposez ensuite votre preuve de versement depuis « Mes participations ».'),
        ]),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text("J'ai compris"))],
      ),
    );
  }
}

class _FeuilleParticipation extends ConsumerStatefulWidget {
  const _FeuilleParticipation({required this.operation, required this.minimum});
  final Operation operation;
  final int minimum;

  @override
  ConsumerState<_FeuilleParticipation> createState() => _FeuilleParticipationState();
}

class _FeuilleParticipationState extends ConsumerState<_FeuilleParticipation> {
  final _montant = TextEditingController();
  final _pin = TextEditingController();
  bool _comprend = false;
  String? _erreur;

  int get _valeur => int.tryParse(_montant.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

  void _valider() {
    final o = widget.operation;
    final pinAttendu = ref.read(preferencesProvider).codePin;
    setState(() => _erreur = null);
    if (_valeur < widget.minimum || _valeur > o.maxParticipant) {
      setState(() => _erreur = 'Le montant doit être compris entre ${fcfa(widget.minimum)} et ${fcfa(o.maxParticipant)}.');
      return;
    }
    if (!_comprend) {
      setState(() => _erreur = 'Cochez la case pour confirmer que vous comprenez le risque de perte.');
      return;
    }
    if (_pin.text.length != 4 || (pinAttendu != null && _pin.text != pinAttendu)) {
      setState(() => _erreur = pinAttendu == null ? 'Saisissez un code PIN à 4 chiffres.' : 'Code PIN incorrect.');
      return;
    }
    if (pinAttendu == null) ref.read(preferencesProvider.notifier).definirPin(_pin.text);
    final p = ref.read(operationsProvider.notifier).participer(uid: ref.read(sessionProvider).utilisateur!.uid, op: o, montant: _valeur);
    Navigator.pop(context, p);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pinDefini = ref.watch(preferencesProvider).codePin != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(ArzikiEspaces.l, 0, ArzikiEspaces.l, MediaQuery.viewInsetsOf(context).bottom + ArzikiEspaces.l),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Je participe', style: t.titleLarge),
          Text(widget.operation.titre, style: t.bodySmall),
          const SizedBox(height: ArzikiEspaces.m),
          TextField(
            controller: _montant,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Montant de ma participation (FCFA)',
              helperText: 'De ${fcfa(widget.minimum)} à ${fcfa(widget.operation.maxParticipant)}'
                  '${_valeur > 0 ? ' · vous saisissez ${fcfa(_valeur)}' : ''}',
            ),
          ),
          const SizedBox(height: ArzikiEspaces.m),
          const Encadre(TextesLegaux.regleEspeces, icone: Icons.payments_rounded),
          const SizedBox(height: ArzikiEspaces.s),
          OutlinedButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Contrat de participation'),
                content: const SingleChildScrollView(
                  child: Text(
                    'Objet : le participant engage une somme dans l\'opération commerciale décrite dans la fiche, '
                    'aux côtés des autres participants.\n\n'
                    'Versement : la somme est versée par virement ou mobile money sur le compte séquestre du notaire, '
                    'avec la référence indiquée. La participation est confirmée après vérification de la preuve.\n\n'
                    'Rémunération : à la clôture, le participant reçoit sa part de la marge nette réelle, au prorata '
                    'de son versement confirmé, selon la répartition prévue dans la fiche et les actes notariés.\n\n'
                    'Durée : la somme est immobilisée jusqu\'à la clôture de l\'opération.\n\n'
                    'Annulation : si le financement n\'est pas réuni à la date limite, la somme est restituée par le notaire.\n\n'
                    'Risque : le participant supporte sa part d\'une éventuelle perte, selon le contrat. ${TextesLegaux.avertissementRisque}',
                  ),
                ),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))],
              ),
            ),
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('Lire le contrat de participation'),
          ),
          CheckboxListTile(
            value: _comprend,
            onChanged: (v) => setState(() => _comprend = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text("J'ai lu et je comprends que je peux perdre tout ou partie de ma mise."),
          ),
          TextField(
            controller: _pin,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: pinDefini ? 'Mon code PIN' : 'Créer mon code PIN (4 chiffres)',
              helperText: 'Le code PIN valide votre participation, comme une signature.',
            ),
          ),
          if (_erreur != null) ...[const SizedBox(height: ArzikiEspaces.s), Encadre(_erreur!, type: TypeEncadre.erreur)],
          const SizedBox(height: ArzikiEspaces.m),
          FilledButton(onPressed: _valider, child: const Text('Valider ma participation')),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nouvelle demande de Commande Financée
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
  final _acheteur = TextEditingController();
  final _rccm = TextEditingController();
  final _contact = TextEditingController();
  String? _secteur;
  final _description = TextEditingController();
  final _vente = TextEditingController();
  final _delaiPaiement = TextEditingController(text: '45');
  bool _bonCommande = false;
  final _fournisseur = TextEditingController();
  bool _devis = false;
  final _achat = TextEditingController();
  final _transport = TextEditingController();
  final _autres = TextEditingController();
  bool _engagement = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    if (widget.prefill != null) _description.text = widget.prefill!;
  }

  int _n(TextEditingController c) => int.tryParse(c.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

  String? _verifier(int etape) {
    switch (etape) {
      case 0:
        if (_acheteur.text.trim().length < 3) return "Indiquez la raison sociale de l'acheteur.";
        if (_contact.text.trim().length < 8) return "Indiquez un contact de l'acheteur (téléphone ou e-mail).";
        if (_secteur == null) return 'Choisissez le secteur.';
      case 1:
        if (_description.text.trim().length < 10) return 'Décrivez la commande en quelques mots.';
        if (_n(_vente) < 2000000) return 'Le prix de vente total doit être d\'au moins 2 000 000 FCFA.';
        if (!_bonCommande) return 'Joignez le bon de commande ou le contrat (photo ou PDF).';
      case 2:
        if (_fournisseur.text.trim().length < 3) return 'Indiquez le nom du fournisseur.';
        if (!_devis) return 'Joignez le devis ou la facture pro forma du fournisseur.';
      case 3:
        if (_n(_achat) <= 0) return "Indiquez le prix d'achat.";
        if (_n(_achat) >= _n(_vente)) return "Le prix d'achat doit être inférieur au prix de vente.";
      case 5:
        if (!_engagement) return "Cochez l'engagement sur l'honneur pour envoyer la demande.";
    }
    return null;
  }

  void _suivant() {
    final e = _verifier(_etape);
    setState(() => _erreur = e);
    if (e != null) return;
    if (_etape < 5) {
      setState(() => _etape++);
    } else {
      final u = ref.read(sessionProvider).utilisateur!;
      final d = Demande(
        id: 'd${DateTime.now().millisecondsSinceEpoch}',
        uid: u.uid,
        titre: _description.text.trim().split('\n').first,
        acheteur: _acheteur.text.trim(),
        montantVente: _n(_vente),
        prixAchat: _n(_achat),
        frais: _n(_transport) + _n(_autres),
        creeLe: DateTime.now(),
      );
      ref.read(operationsProvider.notifier).soumettreDemande(d);
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded, color: ArzikiCouleurs.vert, size: 48),
          title: const Text('Demande envoyée'),
          content: const Text('Notre équipe va contacter directement votre acheteur et votre fournisseur. '
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
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final marge = calculerMarge(vente: _n(_vente), achat: _n(_achat), transport: _n(_transport), autres: _n(_autres));
    const titres = ["L'acheteur", 'La commande', 'Le fournisseur', 'Les coûts', 'Les garanties', 'Récapitulatif'];

    Widget champMontant(TextEditingController c, String libelle, {String? aide}) => Padding(
          padding: const EdgeInsets.only(bottom: ArzikiEspaces.m),
          child: TextField(
            controller: c,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: libelle, suffixText: 'FCFA', helperText: aide ?? (_n(c) > 0 ? fcfa(_n(c)) : null)),
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

    final contenu = switch (_etape) {
      0 => [
          TextField(controller: _acheteur, decoration: const InputDecoration(labelText: "Raison sociale de l'acheteur")),
          const SizedBox(height: ArzikiEspaces.m),
          TextField(controller: _rccm, decoration: const InputDecoration(labelText: 'RCCM (si connu)')),
          const SizedBox(height: ArzikiEspaces.m),
          TextField(
            controller: _contact,
            decoration: const InputDecoration(labelText: 'Contact chez l\'acheteur', helperText: 'ARZIKI appellera directement ce contact.'),
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
          champMontant(_vente, 'Prix de vente total'),
          TextField(
            controller: _delaiPaiement,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: "Délai de paiement promis par l'acheteur", suffixText: 'jours'),
          ),
          const SizedBox(height: ArzikiEspaces.s),
          piece(_bonCommande, 'Bon de commande ou contrat (obligatoire)', () => setState(() => _bonCommande = true)),
        ],
      2 => [
          TextField(controller: _fournisseur, decoration: const InputDecoration(labelText: 'Nom et contact du fournisseur')),
          const SizedBox(height: ArzikiEspaces.s),
          piece(_devis, 'Devis ou facture pro forma (obligatoire)', () => setState(() => _devis = true)),
        ],
      3 => [
          champMontant(_achat, "Prix d'achat chez le fournisseur"),
          champMontant(_transport, 'Transport'),
          champMontant(_autres, 'Autres frais (douane, manutention, assurance)'),
          CarteArziki(
            couleur: (marge.nettePct >= 8 ? ArzikiCouleurs.vert : ArzikiCouleurs.erreur).withValues(alpha: 0.07),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Marge prévisionnelle', style: t.titleMedium),
              const SizedBox(height: ArzikiEspaces.s),
              Text('Marge brute : ${fcfa(marge.brute)}'),
              Text('Marge nette : ${fcfa(marge.nette)} (${marge.nettePct.toStringAsFixed(1).replaceAll('.', ',')} %)'),
            ]),
          ),
          if (_n(_vente) > 0 && marge.nettePct < 8)
            const Padding(
              padding: EdgeInsets.only(top: ArzikiEspaces.s),
              child: Encadre('La marge nette est inférieure à 8 % : la demande risque d\'être refusée. Vérifiez vos prix et vos frais.', type: TypeEncadre.alerte),
            ),
        ],
      4 => [
          Text('Pour un achat de ${fcfa(_n(_achat))}, les garanties suivantes seront demandées :', style: t.bodyMedium),
          const SizedBox(height: ArzikiEspaces.s),
          for (final g in garantiesPour(_n(_achat)))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                const Icon(Icons.shield_rounded, size: 20, color: ArzikiCouleurs.vert),
                const SizedBox(width: ArzikiEspaces.s),
                Expanded(child: Text(g)),
              ]),
            ),
          const SizedBox(height: ArzikiEspaces.s),
          Text("Forme de l'acte : ${formeActePour(_n(_achat))}", style: t.bodySmall),
        ],
      _ => [
          CarteArziki(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_description.text, style: t.titleSmall),
              const SizedBox(height: ArzikiEspaces.s),
              Text('Acheteur : ${_acheteur.text}'),
              Text('Fournisseur : ${_fournisseur.text}'),
              Text('Prix de vente : ${fcfa(_n(_vente))}'),
              Text("Prix d'achat : ${fcfa(_n(_achat))}"),
              Text('Marge nette prévue : ${fcfa(marge.nette)} (${marge.nettePct.toStringAsFixed(1).replaceAll('.', ',')} %)'),
            ]),
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
        const EnTetePage('Commande Financée', 'Six étapes rapides. Votre brouillon reste ouvert tant que vous ne quittez pas cet écran.'),
        Row(children: [
          for (var i = 0; i < 6; i++)
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
        Text('Étape ${_etape + 1} sur 6 : ${titres[_etape]}', style: t.titleLarge),
        const SizedBox(height: ArzikiEspaces.m),
        ...contenu,
        if (_erreur != null) ...[const SizedBox(height: ArzikiEspaces.m), Encadre(_erreur!, type: TypeEncadre.erreur)],
        const SizedBox(height: ArzikiEspaces.l),
        Row(children: [
          if (_etape > 0)
            Expanded(child: OutlinedButton(onPressed: () => setState(() { _etape--; _erreur = null; }), child: const Text('Précédent'))),
          if (_etape > 0) const SizedBox(width: ArzikiEspaces.m),
          Expanded(child: FilledButton(onPressed: _suivant, child: Text(_etape == 5 ? 'Envoyer la demande' : 'Suivant'))),
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
