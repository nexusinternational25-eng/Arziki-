// Console : pages « Services » (commandes, devis, étapes, livrables, catalogue,
// sessions de formation, inscrits, attestations, chiffre d'affaires) et
// « Contenus » (pages d'information, actualités, FAQ, coordonnées).
// Toute action est inscrite au journal d'audit.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/session.dart';
import '../../contenu/contenus.dart';
import '../../core/images.dart';
import '../../router/garde_roles.dart';
import '../../services_nexus/services.dart';
import '../../theme/arziki_theme.dart';
import '../../ui/composants.dart';
import 'console.dart';

// ===========================================================================
// Services
// ===========================================================================

class PageServicesAdmin extends ConsumerStatefulWidget {
  const PageServicesAdmin({super.key});

  @override
  ConsumerState<PageServicesAdmin> createState() => _PageServicesAdminState();
}

class _PageServicesAdminState extends ConsumerState<PageServicesAdmin> {
  int _onglet = 0;

  void _agir(void Function() action, String succes) {
    try {
      action();
      annoncer(context, succes);
    } on ErreurService catch (e) {
      annoncer(context, e.message, erreur: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(servicesProvider);
    final acteur = ref.watch(sessionProvider).utilisateur!;
    final ctrl = ref.read(servicesProvider.notifier);
    final base = ref.read(baseDemoProvider);
    final t = Theme.of(context).textTheme;
    final ca = etat.chiffreAffairesDuMois(DateTime.now());

    String nomClient(String uid) => base.utilisateurs[uid]?.nomComplet ?? uid;

    Widget commandes() => Column(children: [
          if (etat.commandes.isEmpty)
            const EcranVide(icone: Icons.inbox_rounded, titre: 'Aucune commande', texte: 'Les demandes de service des clients apparaîtront ici.'),
          for (final c in etat.commandes)
            if (etat.offre(c.offreId) case final o?)
              CarteArziki(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(o.titre, style: t.titleSmall)),
                    BadgeStatut(c.etape.libelle, ton: c.etape == EtapeCommande.soldeRegle ? TonBadge.neutre : TonBadge.attente),
                  ]),
                  Text('${nomClient(c.uid)} · ${dateLongue(c.creeLe)}${c.montantDevis == null ? '' : ' · devis ${fcfa(c.montantDevis!)}'}', style: t.bodySmall),
                  const SizedBox(height: 4),
                  Text(c.besoin),
                  if (c.pieces.isNotEmpty) Text('Pièces : ${c.pieces.join(', ')}', style: t.bodySmall),
                  const SizedBox(height: ArzikiEspaces.s),
                  Wrap(spacing: ArzikiEspaces.s, runSpacing: ArzikiEspaces.s, children: [
                    if (c.etape == EtapeCommande.besoinEnvoye)
                      FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                        onPressed: () => _devis(c, o),
                        child: const Text('Envoyer le devis'),
                      ),
                    if (c.etape == EtapeCommande.acompteRegle)
                      FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                        onPressed: () => _agir(() => ctrl.demarrer(acteur: acteur.uid, commandeId: c.id), 'Travail démarré, client notifié.'),
                        child: const Text('Démarrer le travail'),
                      ),
                    if (c.etape == EtapeCommande.enCours)
                      FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                        onPressed: () => _agir(
                          () => ctrl.livrer(acteur: acteur.uid, commandeId: c.id, livrable: '${o.livrables.isEmpty ? 'Livrable' : o.livrables.first} (PDF)'),
                          'Livrable déposé, solde demandé au client.',
                        ),
                        child: const Text('Déposer le livrable'),
                      ),
                    if (c.etape == EtapeCommande.devisEnvoye) const BadgeStatut('En attente de l\'acompte', ton: TonBadge.info),
                    if (c.etape == EtapeCommande.livre) const BadgeStatut('En attente du solde', ton: TonBadge.info),
                  ]),
                ]),
              ),
        ]);

    Widget catalogue() => Column(children: [
          for (final o in etat.catalogue)
            CarteArziki(
              child: Row(children: [
                Illustration(o.image, largeur: 56, hauteur: 56, rayon: 12),
                const SizedBox(width: ArzikiEspaces.m - 4),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(o.titre, style: t.titleSmall),
                    Text('${o.famille.libelle} · ${o.prix} · commission : ${o.commission}', style: t.bodySmall),
                  ]),
                ),
                IconButton(tooltip: 'Modifier le tarif', icon: const Icon(Icons.edit_rounded), onPressed: () => _tarif(o)),
              ]),
            ),
        ]);

    Widget formations() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: _nouvelleSession,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Programmer une session'),
            ),
          ),
          for (final s in etat.sessions)
            CarteArziki(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(etat.formation(s.formationId)?.titre ?? 'Formation', style: t.titleSmall),
                Text('${dateLongue(s.date)} · ${s.lieu} · ${fcfa(s.prix)} · ${s.inscrits.length} inscrit(s) sur ${s.places}', style: t.bodySmall),
                if (s.inscrits.isNotEmpty) Text('Inscrits : ${s.inscrits.map(nomClient).join(', ')}', style: t.bodySmall),
                const SizedBox(height: ArzikiEspaces.s),
                if (s.attestationsDelivrees)
                  const BadgeStatut('Attestations délivrées', ton: TonBadge.succes)
                else if (s.date.isBefore(DateTime.now()) && s.inscrits.isNotEmpty)
                  OutlinedButton(
                    onPressed: () => _agir(() => ctrl.delivrerAttestations(acteur: acteur.uid, sessionId: s.id), 'Attestations PDF délivrées aux participants.'),
                    child: const Text('Délivrer les attestations'),
                  )
                else
                  const BadgeStatut('Session à venir', ton: TonBadge.info),
              ]),
            ),
          const SizedBox(height: ArzikiEspaces.s),
          Text('ARZIKI Carnet : ${etat.alertesCarnet.length} personne(s) à prévenir au lancement.', style: t.bodySmall),
        ]);

    return CadreConsole(
      chemin: Chemins.adminServices,
      titre: 'Services',
      corps: ListView(padding: const EdgeInsets.all(ArzikiEspaces.l), children: [
        const EnTetePage('Services NEXUS International', 'Commandes, devis, livrables, catalogue et formations.'),
        Wrap(spacing: ArzikiEspaces.m, children: [
          SizedBox(width: 230, child: CarteChiffre(icone: Icons.account_balance_wallet_rounded, valeur: fcfa(ca), libelle: 'Encaissé ce mois', couleur: ArzikiCouleurs.info)),
          SizedBox(width: 230, child: CarteChiffre(icone: Icons.request_quote_rounded, valeur: '${etat.commandes.where((c) => c.etape == EtapeCommande.besoinEnvoye).length}', libelle: 'Devis à envoyer', couleur: ArzikiCouleurs.orange)),
          SizedBox(width: 230, child: CarteChiffre(icone: Icons.school_rounded, valeur: '${etat.sessions.fold<int>(0, (s, x) => s + x.inscrits.length)}', libelle: 'Inscrits aux formations')),
        ]),
        const SizedBox(height: ArzikiEspaces.m),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 0, label: Text('Commandes'), icon: Icon(Icons.inbox_rounded)),
            ButtonSegment(value: 1, label: Text('Catalogue'), icon: Icon(Icons.sell_rounded)),
            ButtonSegment(value: 2, label: Text('Formations'), icon: Icon(Icons.school_rounded)),
          ],
          selected: {_onglet},
          onSelectionChanged: (s) => setState(() => _onglet = s.first),
        ),
        const SizedBox(height: ArzikiEspaces.m),
        switch (_onglet) { 0 => commandes(), 1 => catalogue(), _ => formations() },
      ]),
    );
  }

  Future<void> _devis(CommandeService c, OffreService o) async {
    final montant = TextEditingController(text: '${o.prixMin ?? ''}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Envoyer le devis'),
        content: TextField(
          controller: montant,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: 'Montant total (FCFA)', helperText: 'Tarif du catalogue : ${o.prix}'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Envoyer')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    _agir(
      () => ref.read(servicesProvider.notifier).envoyerDevis(
            acteur: ref.read(sessionProvider).utilisateur!.uid,
            commandeId: c.id,
            montant: int.tryParse(montant.text) ?? 0,
          ),
      'Devis envoyé au client.',
    );
  }

  Future<void> _tarif(OffreService o) async {
    final prix = TextEditingController(text: o.prix);
    final min = TextEditingController(text: o.prixMin?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(o.titre),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: prix, decoration: const InputDecoration(labelText: 'Prix affiché')),
          const SizedBox(height: ArzikiEspaces.m),
          TextField(
            controller: min,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Montant de départ du devis (FCFA)', helperText: 'Laisser vide pour « sur devis »'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enregistrer')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    _agir(
      () => ref.read(servicesProvider.notifier).modifierPrix(
            acteur: ref.read(sessionProvider).utilisateur!.uid,
            offreId: o.id,
            prix: prix.text.trim(),
            prixMin: int.tryParse(min.text),
          ),
      'Tarif mis à jour.',
    );
  }

  Future<void> _nouvelleSession() async {
    final etat = ref.read(servicesProvider);
    var formation = etat.formations.first.id;
    final lieu = TextEditingController(text: 'Lomé, Tokoin Wuiti');
    final places = TextEditingController(text: '20');
    final prix = TextEditingController(text: '45000');
    var date = DateTime.now().add(const Duration(days: 30));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Programmer une session'),
          content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                initialValue: formation,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Formation'),
                items: [for (final f in etat.formations) DropdownMenuItem(value: f.id, child: Text(f.titre))],
                onChanged: (v) => setLocal(() => formation = v!),
              ),
              const SizedBox(height: ArzikiEspaces.m),
              OutlinedButton.icon(
                onPressed: () async {
                  final d = await showDatePicker(context: ctx, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: date);
                  if (d != null) setLocal(() => date = d);
                },
                icon: const Icon(Icons.event_rounded),
                label: Text(dateLongue(date)),
              ),
              const SizedBox(height: ArzikiEspaces.m),
              TextField(controller: lieu, decoration: const InputDecoration(labelText: 'Lieu')),
              const SizedBox(height: ArzikiEspaces.m),
              Row(children: [
                Expanded(child: TextField(controller: places, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Places'))),
                const SizedBox(width: ArzikiEspaces.m),
                Expanded(child: TextField(controller: prix, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prix (FCFA)'))),
              ]),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Programmer')),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    _agir(
      () => ref.read(servicesProvider.notifier).ajouterSession(
            acteur: ref.read(sessionProvider).utilisateur!.uid,
            s: SessionFormation(
              id: 's${DateTime.now().millisecondsSinceEpoch}',
              formationId: formation,
              date: date,
              lieu: lieu.text.trim(),
              places: int.tryParse(places.text) ?? 20,
              prix: int.tryParse(prix.text) ?? 0,
            ),
          ),
      'Session programmée et visible dans l\'application.',
    );
  }
}

// ===========================================================================
// Contenus
// ===========================================================================

class PageContenusAdmin extends ConsumerStatefulWidget {
  const PageContenusAdmin({super.key});

  @override
  ConsumerState<PageContenusAdmin> createState() => _PageContenusAdminState();
}

class _PageContenusAdminState extends ConsumerState<PageContenusAdmin> {
  int _onglet = 0;

  String get _acteur => ref.read(sessionProvider).utilisateur!.uid;

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(contenusProvider);
    final t = Theme.of(context).textTheme;

    Widget pages() => Column(children: [
          for (final p in etat.pages.values)
            CarteArziki(
              onTap: () => _modifierPage(p),
              child: Row(children: [
                const Icon(Icons.article_rounded, color: ArzikiCouleurs.vert),
                const SizedBox(width: ArzikiEspaces.m),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.titre, style: t.titleSmall),
                    Text('${p.sections.length} section(s)${p.majLe == null ? '' : ' · mise à jour le ${dateLongue(p.majLe!)}'}', style: t.bodySmall),
                  ]),
                ),
                const Icon(Icons.edit_rounded),
              ]),
            ),
        ]);

    Widget actualites() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => _modifierActualite(null),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Publier une actualité'),
            ),
          ),
          for (final a in etat.actualites)
            CarteArziki(
              child: Row(children: [
                Illustration(a.image, largeur: 64, hauteur: 64, rayon: 12),
                const SizedBox(width: ArzikiEspaces.m - 4),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a.titre, style: t.titleSmall),
                    Text(dateLongue(a.date), style: t.bodySmall),
                  ]),
                ),
                IconButton(tooltip: 'Modifier', icon: const Icon(Icons.edit_rounded), onPressed: () => _modifierActualite(a)),
                IconButton(
                  tooltip: 'Retirer',
                  icon: const Icon(Icons.delete_outline_rounded, color: ArzikiCouleurs.erreur),
                  onPressed: () async {
                    if (await confirmer(context, titre: 'Retirer cette actualité ?', message: a.titre, valider: 'Retirer', danger: true)) {
                      ref.read(contenusProvider.notifier).supprimerActualite(_acteur, a.id);
                    }
                  },
                ),
              ]),
            ),
        ]);

    Widget faq() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => _modifierQuestion(null, null),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajouter une question'),
            ),
          ),
          for (var i = 0; i < etat.faq.length; i++)
            CarteArziki(
              onTap: () => _modifierQuestion(i, etat.faq[i]),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(etat.faq[i].question, style: t.titleSmall),
                    Text(etat.faq[i].categorie.libelle, style: t.bodySmall),
                  ]),
                ),
                const Icon(Icons.edit_rounded),
              ]),
            ),
        ]);

    Widget contacts() {
      final c = etat.contacts;
      return CarteArziki(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('WhatsApp : ${c.whatsapp}'),
          Text('Téléphone : ${c.telephone}'),
          Text('E-mail : ${c.email}'),
          Text('Adresse : ${c.adresse}'),
          Text('Horaires : ${c.horaires}'),
          const SizedBox(height: ArzikiEspaces.s),
          OutlinedButton.icon(onPressed: _modifierContacts, icon: const Icon(Icons.edit_rounded), label: const Text('Modifier les coordonnées')),
        ]),
      );
    }

    return CadreConsole(
      chemin: Chemins.adminContenus,
      titre: 'Contenus',
      corps: ListView(padding: const EdgeInsets.all(ArzikiEspaces.l), children: [
        const EnTetePage('Contenus de l\'application', 'Modifiez les textes visibles par les clients. Chaque modification est tracée.'),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 0, label: Text('Pages')),
            ButtonSegment(value: 1, label: Text('Actualités')),
            ButtonSegment(value: 2, label: Text('FAQ')),
            ButtonSegment(value: 3, label: Text('Contacts')),
          ],
          selected: {_onglet},
          onSelectionChanged: (s) => setState(() => _onglet = s.first),
        ),
        const SizedBox(height: ArzikiEspaces.m),
        switch (_onglet) { 0 => pages(), 1 => actualites(), 2 => faq(), _ => contacts() },
      ]),
    );
  }

  Future<void> _modifierPage(PageContenu p) async {
    final titre = TextEditingController(text: p.titre);
    final intro = TextEditingController(text: p.intro);
    final sections = [for (final s in p.sections) (TextEditingController(text: s.titre), TextEditingController(text: s.texte))];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Modifier « ${p.titre} »'),
        content: SizedBox(
          width: 640,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: titre, decoration: const InputDecoration(labelText: 'Titre')),
              const SizedBox(height: ArzikiEspaces.m),
              TextField(controller: intro, maxLines: 4, decoration: const InputDecoration(labelText: 'Introduction')),
              for (final s in sections) ...[
                const Divider(height: ArzikiEspaces.xl),
                TextField(controller: s.$1, decoration: const InputDecoration(labelText: 'Titre de la section')),
                const SizedBox(height: ArzikiEspaces.s),
                TextField(controller: s.$2, maxLines: 5, decoration: const InputDecoration(labelText: 'Texte')),
              ],
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enregistrer')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    ref.read(contenusProvider.notifier).modifierPage(
          _acteur,
          p.id,
          titre: titre.text.trim(),
          intro: intro.text.trim(),
          sections: [for (final s in sections) SectionContenu(s.$1.text.trim(), s.$2.text.trim())],
        );
    annoncer(context, 'Page mise à jour.');
  }

  Future<void> _modifierActualite(Actualite? a) async {
    final titre = TextEditingController(text: a?.titre ?? '');
    final texte = TextEditingController(text: a?.texte ?? '');
    var image = a?.image ?? Images.toutes.first;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(a == null ? 'Nouvelle actualité' : 'Modifier l\'actualité'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextField(controller: titre, decoration: const InputDecoration(labelText: 'Titre')),
                const SizedBox(height: ArzikiEspaces.m),
                TextField(controller: texte, maxLines: 4, decoration: const InputDecoration(labelText: 'Texte')),
                const SizedBox(height: ArzikiEspaces.m),
                const Text('Image'),
                const SizedBox(height: ArzikiEspaces.s),
                SizedBox(
                  height: 72,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    for (final img in Images.toutes)
                      GestureDetector(
                        onTap: () => setLocal(() => image = img),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: image == img ? ArzikiCouleurs.orange : Colors.transparent, width: 3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Illustration(img, largeur: 72, hauteur: 66, rayon: 8),
                        ),
                      ),
                  ]),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Publier')),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    if (titre.text.trim().length < 3) {
      annoncer(context, 'Indiquez un titre.', erreur: true);
      return;
    }
    ref.read(contenusProvider.notifier).enregistrerActualite(
          _acteur,
          Actualite(id: a?.id ?? 'a${DateTime.now().millisecondsSinceEpoch}', titre: titre.text.trim(), texte: texte.text.trim(), image: image, date: a?.date ?? DateTime.now()),
        );
    annoncer(context, 'Actualité publiée.');
  }

  Future<void> _modifierQuestion(int? index, QuestionFaq? q) async {
    final question = TextEditingController(text: q?.question ?? '');
    final reponse = TextEditingController(text: q?.reponse ?? '');
    var categorie = q?.categorie ?? CategorieFaq.entreprises;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(q == null ? 'Nouvelle question' : 'Modifier la question'),
          content: SizedBox(
            width: 520,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<CategorieFaq>(
                initialValue: categorie,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: [for (final c in CategorieFaq.values) DropdownMenuItem(value: c, child: Text(c.libelle))],
                onChanged: (v) => setLocal(() => categorie = v!),
              ),
              const SizedBox(height: ArzikiEspaces.m),
              TextField(controller: question, decoration: const InputDecoration(labelText: 'Question')),
              const SizedBox(height: ArzikiEspaces.m),
              TextField(controller: reponse, maxLines: 5, decoration: const InputDecoration(labelText: 'Réponse')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enregistrer')),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    ref.read(contenusProvider.notifier).enregistrerQuestion(_acteur, index, QuestionFaq(categorie, question.text.trim(), reponse.text.trim()));
    annoncer(context, 'Question enregistrée.');
  }

  Future<void> _modifierContacts() async {
    final c = ref.read(contenusProvider).contacts;
    final champs = {
      'WhatsApp': TextEditingController(text: c.whatsapp),
      'Téléphone': TextEditingController(text: c.telephone),
      'E-mail': TextEditingController(text: c.email),
      'Adresse': TextEditingController(text: c.adresse),
      'Horaires': TextEditingController(text: c.horaires),
    };
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Coordonnées'),
        content: SizedBox(
          width: 480,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final e in champs.entries)
              Padding(padding: const EdgeInsets.only(bottom: ArzikiEspaces.m), child: TextField(controller: e.value, decoration: InputDecoration(labelText: e.key))),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enregistrer')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    ref.read(contenusProvider.notifier).modifierContacts(
          _acteur,
          Contacts(
            whatsapp: champs['WhatsApp']!.text.trim(),
            telephone: champs['Téléphone']!.text.trim(),
            email: champs['E-mail']!.text.trim(),
            adresse: champs['Adresse']!.text.trim(),
            horaires: champs['Horaires']!.text.trim(),
          ),
        );
    annoncer(context, 'Coordonnées mises à jour.');
  }
}
