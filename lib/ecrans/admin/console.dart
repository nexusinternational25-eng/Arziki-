// Console d'administration : tableau de bord, comptes, investisseurs privés
// (invitations), candidatures au Cercle, équipe, journal d'audit.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/session.dart';
import '../../comptes/depot_comptes.dart';
import '../../core/roles.dart';
import '../../demo/depot_comptes_demo.dart';
import '../../models/acces.dart';
import '../../models/utilisateur.dart';
import '../../router/garde_roles.dart';
import '../../theme/arziki_theme.dart';
import '../../ui/composants.dart';
import '../compte/ecrans_compte.dart';

class _Entree {
  const _Entree(this.chemin, this.icone, this.libelle);
  final String chemin;
  final IconData icone;
  final String libelle;
}

/// Cadre commun de la console : menu latéral sur grand écran, tiroir sur téléphone.
class CadreConsole extends ConsumerWidget {
  const CadreConsole({super.key, required this.chemin, required this.titre, required this.corps, this.action});

  final String chemin;
  final String titre;
  final Widget corps;
  final Widget? action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(sessionProvider).utilisateur!;
    final entrees = [
      const _Entree(Chemins.admin, Icons.dashboard_outlined, 'Tableau de bord'),
      const _Entree(Chemins.adminComptes, Icons.people_outline, 'Comptes'),
      const _Entree(Chemins.adminInvitations, Icons.vpn_key_outlined, 'Investisseurs privés'),
      const _Entree(Chemins.adminCandidatures, Icons.how_to_reg_outlined, 'Candidatures au Cercle'),
      const _Entree(Chemins.adminEquipe, Icons.admin_panel_settings_outlined, 'Équipe'),
      const _Entree(Chemins.adminJournal, Icons.history, "Journal d'audit"),
    ].where((e) => roleAutorise(u.role, e.chemin)).toList();
    final index = entrees.indexWhere((e) => e.chemin == chemin).clamp(0, entrees.length - 1);
    final large = MediaQuery.sizeOf(context).width >= 900;

    final menu = NavigationRail(
      extended: true,
      selectedIndex: index,
      onDestinationSelected: (i) => context.go(entrees[i].chemin),
      leading: const Padding(
        padding: EdgeInsets.symmetric(vertical: ArzikiEspaces.m),
        child: LogoArziki(hauteur: 48),
      ),
      destinations: [
        for (final e in entrees) NavigationRailDestination(icon: Icon(e.icone), label: Text(e.libelle)),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(titre),
        actions: [
          ?action,
          Center(child: Text(u.nomComplet, style: const TextStyle(color: ArzikiCouleurs.blanc))),
          const SizedBox(width: ArzikiEspaces.s),
          const BoutonDeconnexion(),
        ],
      ),
      drawer: large
          ? null
          : Drawer(
              child: ListView(children: [
                const DrawerHeader(child: LogoArziki(hauteur: 56)),
                for (final e in entrees)
                  ListTile(
                    leading: Icon(e.icone),
                    title: Text(e.libelle),
                    selected: e.chemin == chemin,
                    onTap: () => context.go(e.chemin),
                  ),
              ]),
            ),
      body: large ? Row(children: [menu, const VerticalDivider(width: 1), Expanded(child: corps)]) : corps,
    );
  }
}

/// Charge une donnée et la recharge après chaque action.
mixin _Rechargeable<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  int version = 0;
  void recharger() => setState(() => version++);

  Future<void> executer(Future<void> Function() action, String succes) async {
    try {
      await action();
      if (mounted) annoncer(context, succes);
      recharger();
    } on ErreurAcces catch (e) {
      if (mounted) annoncer(context, e.message, erreur: true);
    }
  }
}

Widget _chargement<T>(AsyncSnapshot<T> snap, Widget Function(T data) construire) {
  if (snap.hasError) return Center(child: Text('Erreur : ${snap.error}'));
  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
  return construire(snap.data as T);
}

// ---------------------------------------------------------------------------
// Tableau de bord
// ---------------------------------------------------------------------------

class TableauDeBordAdmin extends ConsumerWidget {
  const TableauDeBordAdmin({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depot = ref.watch(depotComptesProvider);
    final role = ref.watch(sessionProvider).utilisateur!.role;
    final donnees = Future.wait([
      depot.listerComptes(),
      depot.listerCandidatures(),
      depot.listerInvitations(),
      depot.tailleDuCercle(),
    ]);

    return CadreConsole(
      chemin: Chemins.admin,
      titre: 'Tableau de bord',
      corps: FutureBuilder(
        future: donnees,
        builder: (context, snap) => _chargement(snap, (d) {
          final comptes = d[0] as List<Utilisateur>;
          final candidatures = d[1] as List<Candidature>;
          final invitations = d[2] as List<Invitation>;
          final taille = d[3] as int;
          final aValider = comptes.where((u) => u.statut == StatutCompte.enAttente).length;
          final candEnAttente = candidatures.where((c) => c.statut == StatutCandidature.soumise).length;
          final invActives = invitations.where((i) => i.statut(DateTime.now()) == 'En attente').length;

          Widget tuile(String titre, String valeur, IconData icone, String? chemin) => SizedBox(
                width: 260,
                child: Card(
                  child: InkWell(
                    onTap: chemin == null || !roleAutorise(role, chemin) ? null : () => context.go(chemin),
                    child: Padding(
                      padding: const EdgeInsets.all(ArzikiEspaces.m),
                      child: Row(children: [
                        Icon(icone, color: ArzikiCouleurs.vert, size: 36),
                        const SizedBox(width: ArzikiEspaces.m),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(valeur, style: Theme.of(context).textTheme.headlineMedium),
                            Text(titre),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                ),
              );

          return ListView(padding: const EdgeInsets.all(ArzikiEspaces.l), children: [
            if (taille >= seuilAlerteTailleCercle)
              Padding(
                padding: const EdgeInsets.only(bottom: ArzikiEspaces.m),
                child: Encadre(
                  'Alerte : le Cercle compte $taille personnes. Au-delà de $limiteTailleCercle personnes sans lien '
                  "juridique entre elles, l'offre risque d'être qualifiée d'appel public à l'épargne (AMF-UMOA). "
                  'Consultez votre avocat.',
                  type: TypeEncadre.erreur,
                ),
              ),
            Wrap(spacing: ArzikiEspaces.m, runSpacing: ArzikiEspaces.m, children: [
              tuile('Comptes à valider', '$aValider', Icons.pending_actions, Chemins.adminComptes),
              tuile('Candidatures au Cercle', '$candEnAttente', Icons.how_to_reg, Chemins.adminCandidatures),
              tuile('Invitations en attente', '$invActives', Icons.vpn_key, Chemins.adminInvitations),
              tuile('Personnes dans le Cercle', '$taille / $limiteTailleCercle', Icons.groups, null),
              tuile('Comptes au total', '${comptes.length}', Icons.people, Chemins.adminComptes),
            ]),
            const SizedBox(height: ArzikiEspaces.l),
            const Encadre(
              'Les indicateurs des opérations (volume financé, retards, marges, frais de dossier) '
              'arrivent avec les jalons 3 à 9.',
            ),
          ]);
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Comptes
// ---------------------------------------------------------------------------

class PageComptes extends ConsumerStatefulWidget {
  const PageComptes({super.key});

  @override
  ConsumerState<PageComptes> createState() => _PageComptesState();
}

class _PageComptesState extends ConsumerState<PageComptes> with _Rechargeable {
  String _filtre = 'en_attente';
  String _recherche = '';

  @override
  Widget build(BuildContext context) {
    final acteur = ref.watch(sessionProvider).utilisateur!;
    final depot = ref.watch(depotComptesProvider);
    return CadreConsole(
      chemin: Chemins.adminComptes,
      titre: 'Comptes',
      corps: FutureBuilder(
        key: ValueKey(version),
        future: depot.listerComptes(),
        builder: (context, snap) => _chargement(snap, (comptes) {
          final liste = comptes.where((u) {
            if (_filtre != 'tous' && u.statut.code != _filtre) return false;
            final q = _recherche.toLowerCase();
            return q.isEmpty ||
                u.nomComplet.toLowerCase().contains(q) ||
                (u.telephone ?? '').contains(q) ||
                (u.email ?? '').contains(q);
          }).toList();
          return Column(children: [
            Padding(
              padding: const EdgeInsets.all(ArzikiEspaces.m),
              child: Wrap(spacing: ArzikiEspaces.s, runSpacing: ArzikiEspaces.s, crossAxisAlignment: WrapCrossAlignment.center, children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Rechercher'),
                    onChanged: (v) => setState(() => _recherche = v),
                  ),
                ),
                for (final f in const [('en_attente', 'À valider'), ('actif', 'Actifs'), ('suspendu', 'Suspendus'), ('tous', 'Tous')])
                  ChoiceChip(
                    label: Text(f.$2),
                    selected: _filtre == f.$1,
                    onSelected: (_) => setState(() => _filtre = f.$1),
                  ),
              ]),
            ),
            Expanded(
              child: liste.isEmpty
                  ? const Center(child: Text('Aucun compte.'))
                  : ListView.builder(
                      itemCount: liste.length,
                      itemBuilder: (context, i) {
                        final u = liste[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: u.statut == StatutCompte.actif
                                ? ArzikiCouleurs.vert
                                : u.statut == StatutCompte.suspendu
                                    ? ArzikiCouleurs.erreur
                                    : ArzikiCouleurs.jaune,
                            child: Text(u.nomComplet.characters.first.toUpperCase(),
                                style: const TextStyle(color: ArzikiCouleurs.blanc)),
                          ),
                          title: Text(u.nomComplet),
                          subtitle: Text('${u.role.libelle} · ${u.telephone ?? u.email ?? ''} · '
                              'Identité : ${u.kycStatut.libelle}'),
                          trailing: Text(u.statut.libelle),
                          onTap: () => _ouvrir(acteur, u),
                        );
                      },
                    ),
            ),
          ]);
        }),
      ),
    );
  }

  void _ouvrir(Utilisateur acteur, Utilisateur u) {
    final depot = ref.read(depotComptesProvider);
    final peutAgir = acteur.role.peutValiderComptes && acteur.uid != u.uid;
    // Rôles proposés selon les droits de l'acteur (vérifiés à nouveau côté serveur).
    final rolesPossibles = Role.values.where((r) {
      if (r == Role.superAdmin) return false;
      if ((r.estAdministration || u.role.estAdministration) && !acteur.role.peutGererAdmins) return false;
      return true;
    }).toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        Role roleChoisi = u.role;
        return StatefulBuilder(builder: (context, setLocal) {
          Future<void> agir(Future<void> Function() f, String ok) async {
            Navigator.pop(context);
            await executer(f, ok);
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(ArzikiEspaces.l),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(u.nomComplet, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: ArzikiEspaces.s),
                Text('${u.role.libelle} · ${u.statut.libelle}'),
                Text('Identité : ${u.kycStatut.libelle}'),
                if (u.invitationCode != null) Text('Entré avec l\'invitation ${u.invitationCode}'),
                if (u.cgVersionAcceptee != null)
                  Text('Conditions acceptées : version ${u.cgVersionAcceptee}'
                      '${u.cgAccepteeLe == null ? '' : ' le ${dateCourte(u.cgAccepteeLe!)}'}'),
                const SizedBox(height: ArzikiEspaces.l),
                if (!peutAgir)
                  const Encadre('Lecture seule.')
                else ...[
                  if (u.kycStatut != StatutKyc.valide) ...[
                    FilledButton(
                      onPressed: () => agir(() => depot.validerKyc(acteur: acteur, uid: u.uid), 'Identité validée.'),
                      child: const Text("Valider l'identité et le compte"),
                    ),
                    const SizedBox(height: ArzikiEspaces.s),
                    OutlinedButton(
                      onPressed: () => agir(
                        () => depot.demanderComplementKyc(acteur: acteur, uid: u.uid, motif: 'Pièces à compléter'),
                        'Demande de pièces envoyée.',
                      ),
                      child: const Text('Demander des pièces'),
                    ),
                    const SizedBox(height: ArzikiEspaces.m),
                  ],
                  if (u.role != Role.candidatCercle)
                    Row(children: [
                      Expanded(
                        child: DropdownButtonFormField<Role>(
                          initialValue: rolesPossibles.contains(roleChoisi) ? roleChoisi : null,
                          decoration: const InputDecoration(labelText: 'Rôle'),
                          items: [for (final r in rolesPossibles) DropdownMenuItem(value: r, child: Text(r.libelle))],
                          onChanged: (r) => setLocal(() => roleChoisi = r!),
                        ),
                      ),
                      const SizedBox(width: ArzikiEspaces.s),
                      TextButton(
                        onPressed: roleChoisi == u.role
                            ? null
                            : () => agir(() => depot.attribuerRole(acteur: acteur, uid: u.uid, role: roleChoisi),
                                'Rôle modifié.'),
                        child: const Text('Appliquer'),
                      ),
                    ]),
                  const SizedBox(height: ArzikiEspaces.m),
                  if (u.statut == StatutCompte.suspendu)
                    OutlinedButton(
                      onPressed: () => agir(() => depot.reactiver(acteur: acteur, uid: u.uid), 'Compte réactivé.'),
                      child: const Text('Réactiver'),
                    )
                  else
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: ArzikiCouleurs.erreur),
                      onPressed: () => agir(
                          () => depot.suspendre(acteur: acteur, uid: u.uid, motif: 'Suspension administrative'),
                          'Compte suspendu.'),
                      child: const Text('Suspendre le compte'),
                    ),
                ],
              ]),
            ),
          );
        });
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Investisseurs privés : invitations nominatives
// ---------------------------------------------------------------------------

class PageInvitations extends ConsumerStatefulWidget {
  const PageInvitations({super.key});

  @override
  ConsumerState<PageInvitations> createState() => _PageInvitationsState();
}

class _PageInvitationsState extends ConsumerState<PageInvitations> with _Rechargeable {
  @override
  Widget build(BuildContext context) {
    final acteur = ref.watch(sessionProvider).utilisateur!;
    final depot = ref.watch(depotComptesProvider);
    final maintenant = DateTime.now();
    return CadreConsole(
      chemin: Chemins.adminInvitations,
      titre: 'Investisseurs privés',
      corps: FutureBuilder(
        key: ValueKey(version),
        future: depot.listerInvitations(),
        builder: (context, snap) => _chargement(snap, (invitations) {
          return ListView(padding: const EdgeInsets.all(ArzikiEspaces.l), children: [
            const Encadre(
              'Ajoutez ici les investisseurs que vous connaissez personnellement. Chacun reçoit un code nominatif, '
              "à usage unique, lié à son numéro de téléphone. Il crée ensuite lui-même son compte dans l'application "
              'et dispose de son propre espace. Son niveau est fixé par vous.',
            ),
            const SizedBox(height: ArzikiEspaces.m),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 320,
                child: FilledButton.icon(
                  onPressed: () => _nouvelle(acteur),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Inviter un investisseur'),
                ),
              ),
            ),
            const SizedBox(height: ArzikiEspaces.l),
            if (invitations.isEmpty) const Text('Aucune invitation pour le moment.'),
            for (final inv in invitations)
              Card(
                child: ListTile(
                  title: Text('${inv.pourNom} · ${inv.niveau.libelle}'),
                  subtitle: Text('${inv.code} · ${inv.pourTelephone}\n'
                      'Valable jusqu\'au ${dateCourte(inv.expireLe)}'
                      '${inv.note == null ? '' : ' · ${inv.note}'}'),
                  isThreeLine: true,
                  trailing: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 4, children: [
                    Chip(label: Text(inv.statut(maintenant))),
                    if (inv.statut(maintenant) == 'En attente') ...[
                      IconButton(
                        tooltip: 'Copier le message',
                        icon: const Icon(Icons.copy),
                        onPressed: () => _copierMessage(inv),
                      ),
                      IconButton(
                        tooltip: 'Annuler',
                        icon: const Icon(Icons.block, color: ArzikiCouleurs.erreur),
                        onPressed: () => executer(
                            () => depot.annulerInvitation(acteur: acteur, code: inv.code), 'Invitation annulée.'),
                      ),
                    ],
                  ]),
                ),
              ),
          ]);
        }),
      ),
    );
  }

  /// Message prêt à envoyer par WhatsApp ou SMS à la personne invitée.
  String _message(Invitation inv) =>
      'Bonjour ${inv.pourNom}, vous êtes invité(e) à rejoindre le Cercle Arziki au niveau ${inv.niveau.libelle}. '
      "Installez l'application ARZIKI, choisissez « J'ai un code d'invitation au Cercle » et saisissez le code "
      '${inv.code} avec votre numéro ${inv.pourTelephone}. Ce code est personnel et valable jusqu\'au '
      '${dateCourte(inv.expireLe)}.';

  Future<void> _copierMessage(Invitation inv) async {
    await Clipboard.setData(ClipboardData(text: _message(inv)));
    if (mounted) annoncer(context, 'Message copié.');
  }

  Future<void> _nouvelle(Utilisateur acteur) async {
    final nom = TextEditingController();
    final tel = TextEditingController();
    final note = TextEditingController();
    var niveau = NiveauCercle.membre;
    var jours = 30;

    final creee = await showDialog<Invitation>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setLocal) {
        return AlertDialog(
          title: const Text('Inviter un investisseur privé'),
          content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nom, decoration: const InputDecoration(labelText: 'Nom complet')),
              const SizedBox(height: ArzikiEspaces.m),
              TextField(
                controller: tel,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Téléphone', hintText: '+228 90 00 00 00'),
              ),
              const SizedBox(height: ArzikiEspaces.m),
              DropdownButtonFormField<NiveauCercle>(
                initialValue: niveau,
                decoration: const InputDecoration(labelText: 'Niveau'),
                items: [for (final n in NiveauCercle.values) DropdownMenuItem(value: n, child: Text(n.libelle))],
                onChanged: (v) => setLocal(() => niveau = v!),
              ),
              const SizedBox(height: ArzikiEspaces.m),
              DropdownButtonFormField<int>(
                initialValue: jours,
                decoration: const InputDecoration(labelText: 'Validité du code'),
                items: const [
                  DropdownMenuItem(value: 7, child: Text('7 jours')),
                  DropdownMenuItem(value: 30, child: Text('30 jours')),
                  DropdownMenuItem(value: 90, child: Text('90 jours')),
                ],
                onChanged: (v) => setLocal(() => jours = v!),
              ),
              const SizedBox(height: ArzikiEspaces.m),
              TextField(controller: note, decoration: const InputDecoration(labelText: 'Note interne (facultatif)')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
              onPressed: () async {
                try {
                  final inv = await ref.read(depotComptesProvider).creerInvitation(
                        acteur: acteur,
                        pourNom: nom.text,
                        pourTelephone: tel.text,
                        niveau: niveau,
                        joursValidite: jours,
                        note: note.text.trim().isEmpty ? null : note.text.trim(),
                      );
                  if (context.mounted) Navigator.pop(context, inv);
                } on ErreurAcces catch (e) {
                  if (context.mounted) annoncer(context, e.message, erreur: true);
                }
              },
              child: const Text('Créer le code'),
            ),
          ],
        );
      }),
    );
    if (creee == null || !mounted) return;
    recharger();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invitation créée'),
        content: SizedBox(
          width: 420,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            SelectableText(creee.code, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: ArzikiEspaces.m),
            SelectableText(_message(creee)),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _copierMessage(creee);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Copier le message'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Candidatures au Cercle (investisseurs inscrits seuls)
// ---------------------------------------------------------------------------

class PageCandidatures extends ConsumerStatefulWidget {
  const PageCandidatures({super.key});

  @override
  ConsumerState<PageCandidatures> createState() => _PageCandidaturesState();
}

class _PageCandidaturesState extends ConsumerState<PageCandidatures> with _Rechargeable {
  @override
  Widget build(BuildContext context) {
    final acteur = ref.watch(sessionProvider).utilisateur!;
    final depot = ref.watch(depotComptesProvider);
    return CadreConsole(
      chemin: Chemins.adminCandidatures,
      titre: 'Candidatures au Cercle',
      corps: FutureBuilder(
        key: ValueKey(version),
        future: Future.wait([depot.listerCandidatures(), depot.listerComptes()]),
        builder: (context, snap) => _chargement(snap, (d) {
          final candidatures = d[0] as List<Candidature>;
          final comptes = {for (final u in d[1] as List<Utilisateur>) u.uid: u};
          return ListView(padding: const EdgeInsets.all(ArzikiEspaces.l), children: [
            const Encadre(
              'Personnes qui se sont inscrites seules et demandent à rejoindre le Cercle. Elles ne voient aucune '
              "opération tant que vous ne les avez pas admises. Vérifiez d'abord leur identité dans « Comptes ».",
            ),
            const SizedBox(height: ArzikiEspaces.l),
            if (candidatures.isEmpty) const Text('Aucune candidature.'),
            for (final c in candidatures)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(ArzikiEspaces.m),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(c.nomComplet, style: Theme.of(context).textTheme.titleMedium)),
                      Chip(label: Text(c.statut.libelle)),
                    ]),
                    Text('${c.telephone} · déposée le ${dateCourte(c.soumiseLe)}'),
                    Text('Niveau souhaité : ${c.niveauSouhaite.libelle} · ${c.trancheEnvisagee}'),
                    Text('Source : ${c.commentNousConnu}'),
                    Text('Identité : ${comptes[c.uid]?.kycStatut.libelle ?? 'inconnue'}'),
                    if (c.motif != null) Text('Motif : ${c.motif}'),
                    if (c.statut == StatutCandidature.soumise) ...[
                      const SizedBox(height: ArzikiEspaces.m),
                      Wrap(spacing: ArzikiEspaces.s, runSpacing: ArzikiEspaces.s, children: [
                        for (final n in NiveauCercle.values)
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                            onPressed: () => executer(
                              () => depot.admettreCandidat(acteur: acteur, uid: c.uid, niveau: n),
                              '${c.nomComplet} est admis(e) au niveau ${n.libelle}.',
                            ),
                            child: Text('Admettre : ${n.libelle}'),
                          ),
                        TextButton(
                          style: TextButton.styleFrom(foregroundColor: ArzikiCouleurs.erreur),
                          onPressed: () => _refuser(acteur, c),
                          child: const Text('Ne pas retenir'),
                        ),
                      ]),
                    ],
                  ]),
                ),
              ),
          ]);
        }),
      ),
    );
  }

  Future<void> _refuser(Utilisateur acteur, Candidature c) async {
    final motif = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ne pas retenir la candidature'),
        content: TextField(controller: motif, decoration: const InputDecoration(labelText: 'Motif (communiqué au candidat)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmer')),
        ],
      ),
    );
    if (ok == true) {
      await executer(
        () => ref.read(depotComptesProvider).refuserCandidat(acteur: acteur, uid: c.uid, motif: motif.text),
        'Candidature non retenue.',
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Équipe interne (super administrateur uniquement)
// ---------------------------------------------------------------------------

class PageEquipe extends ConsumerStatefulWidget {
  const PageEquipe({super.key});

  @override
  ConsumerState<PageEquipe> createState() => _PageEquipeState();
}

class _PageEquipeState extends ConsumerState<PageEquipe> with _Rechargeable {
  @override
  Widget build(BuildContext context) {
    final acteur = ref.watch(sessionProvider).utilisateur!;
    final depot = ref.watch(depotComptesProvider);
    return CadreConsole(
      chemin: Chemins.adminEquipe,
      titre: 'Équipe',
      corps: FutureBuilder(
        key: ValueKey(version),
        future: depot.listerComptes(),
        builder: (context, snap) => _chargement(snap, (comptes) {
          final equipe = comptes.where((u) => u.role.estAdministration).toList();
          return ListView(padding: const EdgeInsets.all(ArzikiEspaces.l), children: [
            const Encadre(
              'Chaque collaborateur a son propre compte, avec e-mail, mot de passe et double facteur obligatoire. '
              'Un administrateur gère les comptes et les opérations ; un analyste vérifie les dossiers sans pouvoir '
              'publier ni valider de paiement. Vous seul pouvez créer ou retirer ces accès.',
            ),
            const SizedBox(height: ArzikiEspaces.m),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 320,
                child: FilledButton.icon(
                  onPressed: () => _nouveau(acteur),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Ajouter un collaborateur'),
                ),
              ),
            ),
            const SizedBox(height: ArzikiEspaces.l),
            for (final u in equipe)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.badge_outlined, color: ArzikiCouleurs.vert),
                  title: Text(u.nomComplet),
                  subtitle: Text('${u.role.libelle} · ${u.email ?? ''}'),
                  trailing: Text(u.statut.libelle),
                ),
              ),
          ]);
        }),
      ),
    );
  }

  Future<void> _nouveau(Utilisateur acteur) async {
    final prenom = TextEditingController();
    final nom = TextEditingController();
    final email = TextEditingController();
    var role = Role.analyste;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Nouveau collaborateur'),
          content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: prenom, decoration: const InputDecoration(labelText: 'Prénom')),
              const SizedBox(height: ArzikiEspaces.m),
              TextField(controller: nom, decoration: const InputDecoration(labelText: 'Nom')),
              const SizedBox(height: ArzikiEspaces.m),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail professionnel'),
              ),
              const SizedBox(height: ArzikiEspaces.m),
              DropdownButtonFormField<Role>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Rôle'),
                items: const [
                  DropdownMenuItem(value: Role.analyste, child: Text('Analyste')),
                  DropdownMenuItem(value: Role.admin, child: Text('Administrateur')),
                ],
                onChanged: (v) => setLocal(() => role = v!),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Créer le compte')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final depot = ref.read(depotComptesProvider);
    Utilisateur? cree;
    await executer(() async {
      cree = await depot.creerCompteEquipe(
        acteur: acteur,
        prenom: prenom.text,
        nom: nom.text,
        email: email.text,
        role: role,
      );
    }, 'Compte créé.');
    // Démonstration : le mot de passe provisoire est montré une seule fois.
    // Production : la personne reçoit un lien pour choisir son mot de passe.
    final provisoire = cree == null || depot is! DepotComptesDemo ? null : depot.motsDePasseProvisoires[cree!.uid];
    if (provisoire == null || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accès du collaborateur'),
        content: SelectableText(
          'Identifiant : ${cree!.email}\nMot de passe provisoire : $provisoire\n\n'
          "Transmettez-le en main propre. Il n'apparaîtra plus.",
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Journal d'audit (lecture seule, jamais modifiable)
// ---------------------------------------------------------------------------

class PageJournal extends ConsumerWidget {
  const PageJournal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CadreConsole(
      chemin: Chemins.adminJournal,
      titre: "Journal d'audit",
      corps: FutureBuilder(
        future: ref.watch(depotComptesProvider).lireJournal(),
        builder: (context, snap) => _chargement(snap, (journal) {
          if (journal.isEmpty) return const Center(child: Text('Aucune action enregistrée pour le moment.'));
          return ListView.separated(
            padding: const EdgeInsets.all(ArzikiEspaces.m),
            itemCount: journal.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final e = journal[i];
              final h = '${e.date.hour.toString().padLeft(2, '0')}:${e.date.minute.toString().padLeft(2, '0')}';
              return ListTile(
                dense: true,
                title: Text('${e.action} · ${e.cible}'),
                subtitle: Text('${dateCourte(e.date)} $h · par ${e.acteurUid}'
                    '${e.avant == null ? '' : ' · avant : ${e.avant}'}'
                    '${e.apres == null ? '' : ' · après : ${e.apres}'}'),
              );
            },
          );
        }),
      ),
    );
  }
}
