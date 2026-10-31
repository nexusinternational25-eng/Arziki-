// Écrans liés au statut du compte : en attente, vérification d'identité,
// candidature au Cercle, compte suspendu, accès refusé.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/session.dart';
import '../../comptes/depot_comptes.dart';
import '../../config/app_config.dart';
import '../../core/kyc.dart';
import '../../core/roles.dart';
import '../../core/textes_legaux.dart';
import '../../models/acces.dart';
import '../../router/garde_roles.dart';
import '../../theme/arziki_theme.dart';
import '../../ui/composants.dart';

/// Bouton de déconnexion pour les barres de titre.
class BoutonDeconnexion extends ConsumerWidget {
  const BoutonDeconnexion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Se déconnecter',
      icon: const Icon(Icons.logout),
      onPressed: () async {
        await ref.read(sessionProvider.notifier).deconnecter();
        if (context.mounted) context.go(Chemins.demarrage);
      },
    );
  }
}

class _Etape extends StatelessWidget {
  const _Etape(this.titre, this.fait, {this.detail, this.action});
  final String titre;
  final bool fait;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(fait ? Icons.check_circle : Icons.radio_button_unchecked,
            color: fait ? ArzikiCouleurs.vert : ArzikiCouleurs.orange),
        title: Text(titre),
        subtitle: detail == null ? null : Text(detail!),
        trailing: action,
      ),
    );
  }
}

class EcranEnAttente extends ConsumerWidget {
  const EcranEnAttente({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(sessionProvider).utilisateur!;
    final candidat = u.role == Role.candidatCercle;
    final kycFait = u.kycStatut == StatutKyc.enCours || u.kycStatut == StatutKyc.valide;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon compte'), actions: const [BoutonDeconnexion()]),
      body: Colonne(children: [
        Text('Votre compte est en cours de vérification', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: ArzikiEspaces.s),
        Text('Profil : ${u.role.libelle}'),
        const SizedBox(height: ArzikiEspaces.l),
        _Etape(
          'Vérification de votre identité',
          u.kycStatut == StatutKyc.valide,
          detail: switch (u.kycStatut) {
            StatutKyc.nonCommence => 'À faire : déposez vos pièces.',
            StatutKyc.enCours => 'Pièces reçues, en cours de contrôle.',
            StatutKyc.aCompleter => 'Des pièces sont à compléter.',
            StatutKyc.valide => 'Identité vérifiée.',
            StatutKyc.refuse => 'Vérification refusée. Contactez ARZIKI.',
          },
          action: kycFait && u.kycStatut != StatutKyc.aCompleter
              ? null
              : TextButton(onPressed: () => context.push(Chemins.identite), child: const Text('Déposer')),
        ),
        if (candidat) _EtapeCandidature(uid: u.uid),
        _Etape(
          candidat ? "Décision d'admission par un administrateur" : 'Validation par un administrateur',
          false,
          detail: 'Vous recevrez une notification dès que votre compte sera activé.',
        ),
        const SizedBox(height: ArzikiEspaces.l),
        OutlinedButton.icon(
          onPressed: () => ref.read(sessionProvider.notifier).rafraichir(),
          icon: const Icon(Icons.refresh),
          label: const Text('Actualiser'),
        ),
      ]),
    );
  }
}

class _EtapeCandidature extends ConsumerWidget {
  const _EtapeCandidature({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Candidature?>(
      future: ref.read(depotComptesProvider).candidatureDe(uid),
      builder: (context, snap) {
        final c = snap.data;
        return _Etape(
          'Candidature au Cercle',
          c != null,
          detail: c == null
              ? 'À faire : présentez votre candidature.'
              : c.statut == StatutCandidature.refusee
                  ? 'Candidature non retenue${c.motif == null ? '' : ' : ${c.motif}'}.'
                  : c.statut.libelle,
          action: c == null
              ? TextButton(onPressed: () => context.push(Chemins.candidature), child: const Text('Remplir'))
              : null,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------

class EcranIdentite extends ConsumerStatefulWidget {
  const EcranIdentite({super.key});

  @override
  ConsumerState<EcranIdentite> createState() => _EcranIdentiteState();
}

class _EcranIdentiteState extends ConsumerState<EcranIdentite> {
  final Map<String, String> _pieces = {};
  String? _origine;
  String? _erreur;
  bool _enCours = false;

  Future<void> _ajouter(PieceKyc p) async {
    // En production : choix d'une photo ou d'un PDF, envoi vers
    // Cloud Storage dans kyc/{uid}/, et l'on garde seulement le chemin.
    final uid = ref.read(sessionProvider).utilisateur!.uid;
    setState(() => _pieces[p.code] = 'kyc/$uid/${p.code}.jpg');
    if (AppConfig.estDemo) annoncer(context, 'Démonstration : pièce simulée ajoutée.');
  }

  Future<void> _envoyer() async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final u = ref.read(sessionProvider).utilisateur!;
      final maj = await ref.read(depotComptesProvider).soumettreKyc(
            utilisateur: u,
            pieces: {..._pieces, if (_origine != null) 'origine_fonds': 'declaration:$_origine'},
            origineFonds: _origine,
          );
      ref.read(sessionProvider.notifier).connecter(maj);
      if (mounted) context.pop();
    } on ErreurAcces catch (e) {
      setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(sessionProvider).utilisateur!.role;
    final pieces = piecesKyc(role);
    return Scaffold(
      appBar: AppBar(title: const Text("Vérification d'identité")),
      body: Colonne(children: [
        const Text(
          'Vos documents sont stockés de façon sécurisée et ne sont visibles que par vous '
          "et l'équipe de vérification ARZIKI.",
        ),
        const SizedBox(height: ArzikiEspaces.l),
        for (final p in pieces)
          if (p.code == 'origine_fonds')
            Padding(
              padding: const EdgeInsets.only(bottom: ArzikiEspaces.s),
              child: DropdownButtonFormField<String>(
                initialValue: _origine,
                decoration: const InputDecoration(labelText: 'Origine de vos fonds'),
                items: [for (final o in originesFonds) DropdownMenuItem(value: o, child: Text(o))],
                onChanged: (v) => setState(() => _origine = v),
              ),
            )
          else
            Card(
              child: ListTile(
                leading: Icon(
                  _pieces.containsKey(p.code) ? Icons.check_circle : Icons.upload_file,
                  color: _pieces.containsKey(p.code) ? ArzikiCouleurs.vert : ArzikiCouleurs.orange,
                ),
                title: Text(p.libelle),
                subtitle: p.obligatoire ? null : const Text('Facultatif'),
                trailing: TextButton(
                  onPressed: () => _ajouter(p),
                  child: Text(_pieces.containsKey(p.code) ? 'Remplacer' : 'Ajouter'),
                ),
              ),
            ),
        if (_erreur != null) ...[
          const SizedBox(height: ArzikiEspaces.m),
          Encadre(_erreur!, type: TypeEncadre.erreur),
        ],
        const SizedBox(height: ArzikiEspaces.l),
        FilledButton(onPressed: _enCours ? null : _envoyer, child: const Text('Envoyer mes pièces')),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------

const tranchesParticipation = [
  '500 000 à 2 000 000 FCFA',
  '2 000 000 à 10 000 000 FCFA',
  '10 000 000 à 50 000 000 FCFA',
  'Plus de 50 000 000 FCFA',
];

const sourcesConnaissance = [
  'Recommandé par un membre',
  'Contact direct avec ARZIKI ou NEXUS International',
  'Événement professionnel',
  'Autre',
];

class EcranCandidature extends ConsumerStatefulWidget {
  const EcranCandidature({super.key});

  @override
  ConsumerState<EcranCandidature> createState() => _EcranCandidatureState();
}

class _EcranCandidatureState extends ConsumerState<EcranCandidature> {
  NiveauCercle _niveau = NiveauCercle.membre;
  String? _tranche;
  String? _source;
  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  bool _comprend = false;
  bool _enCours = false;
  String? _erreur;

  Future<void> _envoyer() async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final u = ref.read(sessionProvider).utilisateur!;
      await ref.read(depotComptesProvider).deposerCandidature(
            candidat: u,
            prenom: _prenom.text,
            nom: _nom.text,
            niveauSouhaite: _niveau,
            trancheEnvisagee: _tranche!,
            commentNousConnu: _source!,
          );
      ref.read(sessionProvider.notifier).connecter(u.copier(prenom: _prenom.text.trim(), nom: _nom.text.trim()));
      if (mounted) context.pop();
    } on ErreurAcces catch (e) {
      setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final complet = _tranche != null && _source != null && _comprend && _prenom.text.isNotEmpty && _nom.text.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Candidature au Cercle')),
      body: Colonne(children: [
        const Encadre(TextesLegaux.cerclePrive, type: TypeEncadre.alerte),
        const SizedBox(height: ArzikiEspaces.l),
        TextField(controller: _prenom, decoration: const InputDecoration(labelText: 'Prénom'), onChanged: (_) => setState(() {})),
        const SizedBox(height: ArzikiEspaces.m),
        TextField(controller: _nom, decoration: const InputDecoration(labelText: 'Nom'), onChanged: (_) => setState(() {})),
        const SizedBox(height: ArzikiEspaces.m),
        DropdownButtonFormField<NiveauCercle>(
          initialValue: _niveau,
          decoration: const InputDecoration(labelText: 'Niveau souhaité'),
          items: [
            for (final n in NiveauCercle.values)
              DropdownMenuItem(value: n, child: Text('${n.libelle} (dès ${fcfa(n.participationMinimale)})')),
          ],
          onChanged: (v) => setState(() => _niveau = v!),
        ),
        const SizedBox(height: ArzikiEspaces.m),
        DropdownButtonFormField<String>(
          initialValue: _tranche,
          decoration: const InputDecoration(labelText: 'Participation envisagée par opération'),
          items: [for (final t in tranchesParticipation) DropdownMenuItem(value: t, child: Text(t))],
          onChanged: (v) => setState(() => _tranche = v),
        ),
        const SizedBox(height: ArzikiEspaces.m),
        DropdownButtonFormField<String>(
          initialValue: _source,
          decoration: const InputDecoration(labelText: 'Comment avez-vous connu ARZIKI ?'),
          items: [for (final s in sourcesConnaissance) DropdownMenuItem(value: s, child: Text(s))],
          onChanged: (v) => setState(() => _source = v),
        ),
        const SizedBox(height: ArzikiEspaces.m),
        CheckboxListTile(
          value: _comprend,
          onChanged: (v) => setState(() => _comprend = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Je comprends que les participations comportent un risque de perte '
            "et que l'admission au Cercle n'est pas automatique.",
          ),
        ),
        if (_erreur != null) ...[
          const SizedBox(height: ArzikiEspaces.m),
          Encadre(_erreur!, type: TypeEncadre.erreur),
        ],
        const SizedBox(height: ArzikiEspaces.l),
        FilledButton(onPressed: _enCours || !complet ? null : _envoyer, child: const Text('Envoyer ma candidature')),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------

class EcranSuspendu extends StatelessWidget {
  const EcranSuspendu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compte suspendu'), actions: const [BoutonDeconnexion()]),
      body: const Colonne(children: [
        Encadre(
          'Votre compte est temporairement suspendu. Contactez ARZIKI pour en connaître la raison.',
          type: TypeEncadre.erreur,
        ),
      ]),
    );
  }
}

class EcranAccesRefuse extends ConsumerStatefulWidget {
  const EcranAccesRefuse({super.key});

  @override
  ConsumerState<EcranAccesRefuse> createState() => _EcranAccesRefuseState();
}

class _EcranAccesRefuseState extends ConsumerState<EcranAccesRefuse> {
  @override
  void initState() {
    super.initState();
    // Toute tentative d'accès refusée est inscrite au journal d'audit.
    final u = ref.read(sessionProvider).utilisateur;
    if (u != null) {
      ref.read(depotComptesProvider).signalerAccesRefuse(utilisateur: u, chemin: 'console');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accès refusé'), actions: const [BoutonDeconnexion()]),
      body: const Colonne(children: [
        Icon(Icons.lock_outline, size: 64, color: ArzikiCouleurs.erreur),
        SizedBox(height: ArzikiEspaces.m),
        Text(
          "Cette console est réservée à l'équipe ARZIKI. Utilisez l'application mobile pour accéder à votre espace. "
          'Cette tentative a été enregistrée.',
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}
