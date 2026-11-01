// Onglet Services (opéré par NEXUS International) : catalogue par famille,
// fiche détaillée, commande, suivi avec paiements, formations, ARZIKI Carnet.
// Les visiteurs voient le catalogue sans prix détaillés.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/session.dart';
import '../../core/images.dart';
import '../../router/garde_roles.dart';
import '../../services_nexus/services.dart';
import '../../theme/arziki_theme.dart';
import '../../ui/composants.dart';
import '../navigation/cadre_app.dart';

// ---------------------------------------------------------------------------
// Catalogue
// ---------------------------------------------------------------------------

class CatalogueServices extends ConsumerWidget {
  const CatalogueServices({super.key, this.integre = false});

  /// Affiché dans un onglet (sans barre du haut propre).
  final bool integre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(servicesProvider);
    final u = ref.watch(sessionProvider).utilisateur;
    final t = Theme.of(context).textTheme;
    final mesCommandes = u == null ? <CommandeService>[] : etat.commandes.where((c) => c.uid == u.uid).toList();

    final corps = Colonne(children: [
      if (!integre)
        const EnTeteImage(
          image: Images.servicesConseil,
          titre: 'Nos services',
          sousTitre: 'Opérés par NEXUS International',
          hauteur: 180,
        )
      else
        const EnTetePage('Nos services', 'Montage de dossiers, états financiers et formations, opérés par NEXUS International.'),
      if (mesCommandes.isNotEmpty) ...[
        const TitreSection('Mes commandes'),
        for (final c in mesCommandes)
          if (etat.offre(c.offreId) case final o?)
            CarteArziki(
              onTap: () => context.push(Chemins.commandeService(c.id)),
              child: Row(children: [
                Illustration(o.image, largeur: 56, hauteur: 56, rayon: 12),
                const SizedBox(width: ArzikiEspaces.m - 4),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(o.titre, style: t.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    BadgeStatut(c.etape.libelle, ton: c.etape == EtapeCommande.soldeRegle ? TonBadge.neutre : TonBadge.attente),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded),
              ]),
            ),
      ],
      for (final f in FamilleService.values) ...[
        TitreSection(f.libelle, explication: f.resume),
        if (f == FamilleService.formations) ...[
          CarteImage(
            image: Images.equipe,
            hauteurImage: 120,
            titre: 'Sessions de formation à venir',
            texte: '${etat.formations.length} formations au catalogue : dossier de crédit, gestion financière, '
                "états financiers, appels d'offres, garanties.",
            badge: BadgeStatut('${etat.sessions.where((s) => s.date.isAfter(DateTime.now())).length} sessions', ton: TonBadge.succes),
            onTap: () => context.push(Chemins.formations),
          ),
        ],
        for (final o in etat.catalogue.where((x) => x.famille == f))
          CarteArziki(
            padding: EdgeInsets.zero,
            onTap: () => context.push(Chemins.offre(o.id)),
            semantique: o.titre,
            child: Row(children: [
              Illustration(o.image, largeur: 96, hauteur: 108),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(ArzikiEspaces.m - 4),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(o.titre, style: t.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(o.accroche, style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    if (o.bientot)
                      const BadgeStatut('Bientôt disponible', ton: TonBadge.attente)
                    else
                      Text(u == null ? 'Tarif après création du compte' : o.prix,
                          style: t.labelLarge?.copyWith(color: ArzikiCouleurs.vert)),
                  ]),
                ),
              ),
            ]),
          ),
      ],
      const SizedBox(height: ArzikiEspaces.l),
    ]);

    if (integre) return corps;
    return Scaffold(
      appBar: barreArziki(context),
      bottomNavigationBar: const BarreVisiteur(),
      body: corps,
    );
  }
}

// ---------------------------------------------------------------------------
// Fiche d'une offre
// ---------------------------------------------------------------------------

class FicheOffre extends ConsumerWidget {
  const FicheOffre({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(servicesProvider);
    final o = etat.offre(id);
    final u = ref.watch(sessionProvider).utilisateur;
    final t = Theme.of(context).textTheme;
    if (o == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Service')),
        body: Colonne(children: [
          EcranVide(titre: 'Service introuvable', texte: 'Cette offre a été retirée du catalogue.', action: 'Voir les services', onAction: () => context.go(Chemins.services)),
        ]),
      );
    }
    final alerte = u != null && etat.alertesCarnet.contains(u.uid);

    Widget liste(String titre, List<String> elements, IconData icone) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TitreSection(titre),
          for (final e in elements)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icone, size: 18, color: ArzikiCouleurs.vert)),
                const SizedBox(width: ArzikiEspaces.s),
                Expanded(child: Text(e)),
              ]),
            ),
        ]);

    Widget? action;
    if (o.bientot) {
      action = FilledButton.icon(
        onPressed: alerte
            ? null
            : () {
                if (u == null) {
                  context.go(Chemins.choix);
                  return;
                }
                ref.read(servicesProvider.notifier).prevenirCarnet(u.uid);
                annoncer(context, 'C\'est noté : vous serez prévenu dès le lancement d\'ARZIKI Carnet.');
              },
        icon: Icon(alerte ? Icons.check_rounded : Icons.notifications_active_rounded),
        label: Text(alerte ? 'Vous serez prévenu' : 'Me prévenir'),
      );
    } else if (u == null) {
      action = FilledButton(onPressed: () => context.go(Chemins.choix), child: const Text('Créer mon compte pour commander'));
    } else if (o.id == 'formation-entreprise' || o.famille != FamilleService.formations) {
      action = FilledButton(
        onPressed: () => context.push(Chemins.commanderOffre(o.id)),
        child: Text(o.prixMin == null ? 'Demander un devis' : 'Commander ce service'),
      );
    }

    return Scaffold(
      appBar: barreArziki(context, titre: o.famille.libelle),
      bottomNavigationBar: action == null
          ? null
          : SafeArea(child: Padding(padding: const EdgeInsets.all(ArzikiEspaces.m), child: LargeurMax(child: action))),
      body: Colonne(children: [
        EnTeteImage(image: o.image, titre: o.titre, sousTitre: o.accroche, hauteur: 220),
        const SizedBox(height: ArzikiEspaces.m),
        Text(o.description),
        const SizedBox(height: ArzikiEspaces.m),
        CarteArziki(
          child: Column(children: [
            _InfoLigne(Icons.sell_rounded, 'Prix', u == null && !o.bientot ? 'Communiqué après création du compte' : o.prix),
            _InfoLigne(Icons.emoji_events_rounded, 'Commission de succès', o.commission),
            _InfoLigne(Icons.schedule_rounded, 'Délai', o.delai),
          ]),
        ),
        liste('Ce qui est inclus', o.inclus, Icons.check_circle_rounded),
        if (o.livrables.isNotEmpty) liste('Ce que vous recevez', o.livrables, Icons.description_rounded),
        const SizedBox(height: ArzikiEspaces.m),
        if (!o.bientot)
          const Encadre(
            'Paiement : 50 % à la commande, 50 % à la livraison du dossier. $mentionNonRemboursable',
            type: TypeEncadre.alerte,
            icone: Icons.payments_rounded,
          ),
        const SizedBox(height: ArzikiEspaces.s),
        Text('Service opéré par NEXUS International.', style: t.bodySmall),
        const SizedBox(height: ArzikiEspaces.l),
      ]),
    );
  }
}

class _InfoLigne extends StatelessWidget {
  const _InfoLigne(this.icone, this.libelle, this.valeur);
  final IconData icone;
  final String libelle;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icone, size: 20, color: ArzikiCouleurs.vert),
        const SizedBox(width: ArzikiEspaces.m - 4),
        Expanded(child: Text(libelle, style: t.bodySmall)),
        Flexible(flex: 2, child: Text(valeur, style: t.titleSmall, textAlign: TextAlign.right)),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Commander un service
// ---------------------------------------------------------------------------

class CommanderOffre extends ConsumerStatefulWidget {
  const CommanderOffre({super.key, required this.id});
  final String id;

  @override
  ConsumerState<CommanderOffre> createState() => _CommanderOffreState();
}

class _CommanderOffreState extends ConsumerState<CommanderOffre> {
  final _besoin = TextEditingController();
  final _pieces = <String>[];
  String? _erreur;

  @override
  Widget build(BuildContext context) {
    final o = ref.watch(servicesProvider).offre(widget.id)!;
    return Scaffold(
      appBar: AppBar(title: const Text('Ma demande')),
      body: Colonne(children: [
        EnTetePage(o.titre, 'Décrivez votre besoin et joignez vos pièces. Vous recevrez un devis avant tout paiement.'),
        TextField(
          controller: _besoin,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Votre besoin',
            helperText: 'Activité, objectif, montant recherché, échéance.',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: ArzikiEspaces.m),
        for (final p in const ['États financiers récents', 'Statuts et RCCM', 'Autre document utile'])
          CarteArziki(
            onTap: () => setState(() => _pieces.contains(p) ? _pieces.remove(p) : _pieces.add(p)),
            child: Row(children: [
              Icon(_pieces.contains(p) ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                  color: _pieces.contains(p) ? ArzikiCouleurs.vert : ArzikiCouleurs.orange),
              const SizedBox(width: ArzikiEspaces.m),
              Expanded(child: Text(p)),
              Text(_pieces.contains(p) ? 'Ajouté' : 'Ajouter (facultatif)', style: Theme.of(context).textTheme.labelMedium),
            ]),
          ),
        if (_erreur != null) ...[const SizedBox(height: ArzikiEspaces.m), Encadre(_erreur!, type: TypeEncadre.erreur)],
        const SizedBox(height: ArzikiEspaces.l),
        FilledButton(
          onPressed: () {
            try {
              final c = ref.read(servicesProvider.notifier).commander(
                    uid: ref.read(sessionProvider).utilisateur!.uid,
                    offreId: o.id,
                    besoin: _besoin.text,
                    pieces: List.of(_pieces),
                  );
              context.pushReplacement(Chemins.commandeService(c.id));
              annoncer(context, 'Demande envoyée. Vous recevrez votre devis sous 48 heures ouvrées.');
            } on ErreurService catch (e) {
              setState(() => _erreur = e.message);
            }
          },
          child: const Text('Envoyer ma demande'),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Suivi d'une commande
// ---------------------------------------------------------------------------

class SuiviCommande extends ConsumerWidget {
  const SuiviCommande({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(servicesProvider);
    final c = etat.commandes.where((x) => x.id == id).firstOrNull;
    final u = ref.watch(sessionProvider).utilisateur!;
    final t = Theme.of(context).textTheme;
    if (c == null || c.uid != u.uid) {
      return Scaffold(
        appBar: AppBar(title: const Text('Commande')),
        body: Colonne(children: [
          EcranVide(titre: 'Commande introuvable', texte: "Cette commande n'existe pas ou ne vous appartient pas.", action: 'Voir les services', onAction: () => context.go(Chemins.services)),
        ]),
      );
    }
    final o = etat.offre(c.offreId)!;
    final paiementAttendu = c.etape == EtapeCommande.devisEnvoye || c.etape == EtapeCommande.livre;

    return Scaffold(
      appBar: AppBar(title: const Text('Suivi de ma commande')),
      body: Colonne(children: [
        EnTetePage(o.titre, 'Commande du ${dateLongue(c.creeLe)}. Chaque étape vous est notifiée.'),
        CarteArziki(
          child: FriseEtapes(
            etapes: [for (final e in EtapeCommande.values) e.libelle],
            courante: c.etape == EtapeCommande.soldeRegle ? EtapeCommande.values.length : c.etape.index + 1,
            details: {
              if (c.montantDevis != null) 1: 'Montant : ${fcfa(c.montantDevis!)}',
              if (c.montantDevis != null) 2: 'Acompte : ${fcfa(c.acompte)}',
              if (c.livrable != null) 4: c.livrable!,
            },
          ),
        ),
        CarteArziki(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Votre besoin', style: t.titleSmall),
            const SizedBox(height: 4),
            Text(c.besoin),
          ]),
        ),
        if (c.etape == EtapeCommande.besoinEnvoye)
          const Encadre('Notre équipe étudie votre besoin. Vous recevrez le devis sous 48 heures ouvrées.', icone: Icons.hourglass_top_rounded),
        if (paiementAttendu) ...[
          const SizedBox(height: ArzikiEspaces.s),
          const Encadre(mentionNonRemboursable, type: TypeEncadre.alerte),
          const SizedBox(height: ArzikiEspaces.m),
          FilledButton.icon(
            onPressed: () => _payer(context, ref, c),
            icon: const Icon(Icons.lock_rounded),
            label: Text(c.etape == EtapeCommande.devisEnvoye ? "Payer l'acompte de ${fcfa(c.acompte)}" : 'Payer le solde de ${fcfa(c.solde)}'),
          ),
        ],
        if (c.livrable != null) ...[
          const TitreSection('Votre livrable'),
          CarteArziki(
            onTap: () => annoncer(context, 'En production, le livrable PDF se télécharge depuis le stockage sécurisé.'),
            child: Row(children: [
              const Icon(Icons.picture_as_pdf_rounded, color: ArzikiCouleurs.erreur),
              const SizedBox(width: ArzikiEspaces.m),
              Expanded(child: Text(c.livrable!)),
              const Icon(Icons.download_rounded),
            ]),
          ),
        ],
        if (c.etape == EtapeCommande.soldeRegle && o.proposeCommandeFerme) ...[
          const TitreSection('Et maintenant ?'),
          CarteArziki(
            couleur: ArzikiCouleurs.orange.withValues(alpha: 0.08),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Avez-vous une commande ferme ?', style: t.titleMedium),
              const SizedBox(height: 4),
              const Text('ARZIKI peut organiser le financement de son achat. Votre demande sera préremplie.'),
              const SizedBox(height: ArzikiEspaces.m),
              FilledButton(
                onPressed: () => context.push('${Chemins.nouvelleDemande}?depuis=${Uri.encodeComponent(o.titre)}'),
                child: const Text('Oui, créer une demande de Commande Financée'),
              ),
            ]),
          ),
        ],
        const SizedBox(height: ArzikiEspaces.l),
      ]),
    );
  }

  Future<void> _payer(BuildContext context, WidgetRef ref, CommandeService c) async {
    String moyen = 'T-Money';
    final ok = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(ArzikiEspaces.l, 0, ArzikiEspaces.l, ArzikiEspaces.l),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Paiement sécurisé', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: ArzikiEspaces.s),
              const Encadre('Démonstration : paiement simulé. En production, le guichet CinetPay s\'ouvre ici.', type: TypeEncadre.alerte),
              const SizedBox(height: ArzikiEspaces.m),
              Text('Moyen de paiement', style: Theme.of(ctx).textTheme.labelMedium),
              const SizedBox(height: ArzikiEspaces.s),
              Wrap(spacing: ArzikiEspaces.s, children: [
                for (final m in const ['T-Money', 'Flooz', 'Carte bancaire'])
                  ChoiceChip(label: Text(m), selected: moyen == m, onSelected: (_) => setLocal(() => moyen = m)),
              ]),
              const SizedBox(height: ArzikiEspaces.s),
              const SizedBox(height: ArzikiEspaces.s),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Payer')),
            ]),
          ),
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      ref.read(servicesProvider.notifier).payer(uid: ref.read(sessionProvider).utilisateur!.uid, commandeId: c.id);
      annoncer(context, 'Paiement reçu par $moyen. Un reçu est disponible dans vos documents.');
    } on ErreurService catch (e) {
      annoncer(context, e.message, erreur: true);
    }
  }
}

// ---------------------------------------------------------------------------
// Formations
// ---------------------------------------------------------------------------

class EcranFormations extends ConsumerWidget {
  const EcranFormations({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(servicesProvider);
    final u = ref.watch(sessionProvider).utilisateur;
    final t = Theme.of(context).textTheme;
    final aVenir = etat.sessions.where((s) => s.date.isAfter(DateTime.now().subtract(const Duration(days: 1)))).toList();
    final passees = u == null ? <SessionFormation>[] : etat.sessions.where((s) => !aVenir.contains(s) && s.inscrits.contains(u.uid)).toList();

    return Scaffold(
      appBar: barreArziki(context),
      bottomNavigationBar: const BarreVisiteur(),
      body: Colonne(children: [
        const EnTeteImage(image: Images.equipe, titre: 'Formations', sousTitre: 'Sessions de groupe et formations en entreprise', hauteur: 180),
        const SizedBox(height: ArzikiEspaces.m),
        const Text('Des formations courtes et pratiques, animées par les consultants de NEXUS International. '
            'Chaque participant reçoit une attestation.'),
        const TitreSection('Sessions à venir'),
        if (aVenir.isEmpty)
          const EcranVide(icone: Icons.event_busy_rounded, titre: 'Aucune session programmée', texte: 'De nouvelles dates sont publiées chaque mois.'),
        for (final s in aVenir)
          if (etat.formation(s.formationId) case final f?)
            CarteArziki(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.titre, style: t.titleMedium),
                const SizedBox(height: 2),
                Text(f.resume, style: t.bodySmall),
                const SizedBox(height: ArzikiEspaces.s),
                Wrap(spacing: ArzikiEspaces.s, runSpacing: ArzikiEspaces.s, children: [
                  BadgeStatut(dateLongue(s.date), icone: Icons.event_rounded, ton: TonBadge.info),
                  BadgeStatut(s.lieu, icone: Icons.place_rounded),
                  BadgeStatut(f.duree, icone: Icons.schedule_rounded),
                  BadgeStatut('${s.placesRestantes} places restantes', ton: s.placesRestantes > 3 ? TonBadge.succes : TonBadge.alerte),
                ]),
                const SizedBox(height: ArzikiEspaces.m),
                Row(children: [
                  Expanded(child: Text(u == null ? 'Tarif après création du compte' : fcfa(s.prix), style: t.titleSmall)),
                  if (u != null && s.inscrits.contains(u.uid))
                    const BadgeStatut('Inscrit', ton: TonBadge.succes, icone: Icons.check_rounded)
                  else
                    FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                      onPressed: s.placesRestantes <= 0
                          ? null
                          : () async {
                              if (u == null) {
                                context.go(Chemins.choix);
                                return;
                              }
                              if (!await confirmer(context,
                                  titre: "S'inscrire à « ${f.titre} »",
                                  message: 'Montant : ${fcfa(s.prix)}, réglé par mobile money ou carte. $mentionNonRemboursable',
                                  valider: 'Payer et m\'inscrire')) {
                                return;
                              }
                              try {
                                ref.read(servicesProvider.notifier).inscrire(uid: u.uid, sessionId: s.id);
                                if (context.mounted) annoncer(context, 'Inscription confirmée. Vous recevrez un rappel la veille.');
                              } on ErreurService catch (e) {
                                if (context.mounted) annoncer(context, e.message, erreur: true);
                              }
                            },
                      child: Text(u == null ? 'Créer mon compte' : "M'inscrire"),
                    ),
                ]),
              ]),
            ),
        if (passees.isNotEmpty) ...[
          const TitreSection('Mes attestations'),
          for (final s in passees)
            CarteArziki(
              child: Row(children: [
                const Icon(Icons.workspace_premium_rounded, color: ArzikiCouleurs.orange),
                const SizedBox(width: ArzikiEspaces.m),
                Expanded(child: Text('${etat.formation(s.formationId)?.titre ?? 'Formation'} · ${dateLongue(s.date)}')),
                BadgeStatut(s.attestationsDelivrees ? 'Disponible' : 'En préparation', ton: s.attestationsDelivrees ? TonBadge.succes : TonBadge.attente),
              ]),
            ),
        ],
        const TitreSection('Former votre équipe'),
        CarteArziki(
          onTap: () => context.push(Chemins.offre('formation-entreprise')),
          child: const Row(children: [
            Icon(Icons.groups_rounded, color: ArzikiCouleurs.vert),
            SizedBox(width: ArzikiEspaces.m),
            Expanded(child: Text('Formation en entreprise, dans vos locaux, sur devis')),
            Icon(Icons.chevron_right_rounded),
          ]),
        ),
        const SizedBox(height: ArzikiEspaces.l),
      ]),
    );
  }
}
