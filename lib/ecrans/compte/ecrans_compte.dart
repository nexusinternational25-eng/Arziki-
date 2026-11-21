// Écrans liés au statut du compte : en attente, vérification d'identité,
// compte suspendu, accès refusé.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/session.dart';
import '../../comptes/depot_comptes.dart';
import '../../config/app_config.dart';
import '../../core/images.dart';
import '../../core/kyc.dart';
import '../../core/roles.dart';
import '../../router/garde_roles.dart';
import '../../theme/arziki_theme.dart';
import '../../ui/composants.dart';
import '../accueil/sections_accueil.dart';
import '../navigation/cadre_app.dart';

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
    return CarteArziki(
      padding: const EdgeInsets.symmetric(horizontal: ArzikiEspaces.s, vertical: 2),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: ArzikiEspaces.s),
        leading: Icon(fait ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
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
    final kycFait = u.kycStatut == StatutKyc.enCours || u.kycStatut == StatutKyc.valide;

    final t = Theme.of(context).textTheme;
    return Scaffold(
      drawer: const MenuLateral(),
      appBar: barreArziki(context, logo: true),
      body: Colonne(children: [
        Apparition(
          child: EnTeteImage(
            image: Images.dirigeanteSignature,
            hauteur: 190,
            titre: u.prenom.isEmpty ? 'Bienvenue sur ARZIKI' : 'Bienvenue, ${u.prenom}',
            sousTitre: '${u.role.libelle} · compte en cours de vérification',
          ),
        ),
        const SizedBox(height: ArzikiEspaces.m),
        Text('Plus que quelques étapes', style: t.titleLarge),
        const SizedBox(height: ArzikiEspaces.xs),
        Text(
          'Notre équipe vérifie votre identité. Vous recevrez une notification dès que votre compte sera activé.',
          style: t.bodySmall,
        ),
        const SizedBox(height: ArzikiEspaces.s),
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
        const _Etape(
          'Validation par un administrateur',
          false,
          detail: 'Vous recevrez une notification dès que votre compte sera activé.',
        ),
        const SizedBox(height: ArzikiEspaces.m),
        OutlinedButton.icon(
          onPressed: () => ref.read(sessionProvider.notifier).rafraichir(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Actualiser'),
        ),
        const TitreSection('En attendant, découvrez ARZIKI'),
        const SectionCommentCaMarche(),
        const CarrouselServices(),
        const BlocConfiance(),
      ]),
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
