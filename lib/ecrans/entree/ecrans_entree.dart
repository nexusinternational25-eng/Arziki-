// Premier lancement : démarrage, présentation en 3 écrans, choix du parcours.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/depot_auth.dart';
import '../../auth/session.dart';
import '../../config/app_config.dart';
import '../../router/garde_roles.dart';
import '../../theme/arziki_theme.dart';
import '../../ui/composants.dart';

class EcranDemarrage extends StatefulWidget {
  const EcranDemarrage({super.key});

  @override
  State<EcranDemarrage> createState() => _EcranDemarrageState();
}

class _EcranDemarrageState extends State<EcranDemarrage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      context.go(AppConfig.estConsole ? Chemins.connexionAdmin : Chemins.presentation);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LogoArziki(hauteur: 110),
            const SizedBox(height: ArzikiEspaces.l),
            Text(
              AppConfig.estConsole ? "Console d'administration" : '',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PagePresentation {
  const _PagePresentation(this.image, this.titre, this.texte);
  final String image;
  final String titre;
  final String texte;
}

const _pages = [
  _PagePresentation(
    'assets/images/presentation_commande.jpg',
    'La Commande Financée',
    "Vous avez une commande ferme d'un acheteur identifié, mais pas la trésorerie pour acheter "
        "la marchandise ? ARZIKI vérifie la commande et organise le financement de l'achat.",
  ),
  _PagePresentation(
    'assets/images/presentation_cercle.jpg',
    'Le Cercle Arziki',
    'Un cercle privé de membres et de partenaires qui choisissent les opérations auxquelles '
        "ils participent. L'argent ne transite jamais par l'application.",
  ),
  _PagePresentation(
    'assets/images/presentation_notaire.jpg',
    'Un notaire à chaque étape',
    'Chaque opération est encadrée par un notaire, avec des garanties proportionnées au montant. '
        'Les fonds passent par un compte désigné, jamais par un compte personnel.',
  ),
];

class EcranPresentation extends ConsumerStatefulWidget {
  const EcranPresentation({super.key});

  @override
  ConsumerState<EcranPresentation> createState() => _EcranPresentationState();
}

class _EcranPresentationState extends ConsumerState<EcranPresentation> {
  final _controleur = PageController();
  int _page = 0;

  void _terminer() {
    ref.read(sessionProvider.notifier).presentationTerminee();
    context.go(Chemins.choix);
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final derniere = _page == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _terminer, child: const Text('Passer')),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controleur,
                itemCount: _pages.length,
                onPageChanged: (p) => setState(() => _page = p),
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: ArzikiEspaces.l),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const LogoArziki(hauteur: 64),
                            const SizedBox(height: ArzikiEspaces.l),
                            // Photo affichée entière (pas de zoom).
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(p.image, fit: BoxFit.fitWidth, width: double.infinity),
                            ),
                            const SizedBox(height: ArzikiEspaces.l),
                            Text(p.titre,
                                style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                            const SizedBox(height: ArzikiEspaces.m),
                            Text(p.texte, textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => Container(
                  margin: const EdgeInsets.all(4),
                  width: i == _page ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page ? ArzikiCouleurs.orange : ArzikiCouleurs.bordure,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ArzikiEspaces.l),
              child: FilledButton(
                onPressed: derniere
                    ? _terminer
                    : () => _controleur.nextPage(
                          duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                child: Text(derniere ? 'Commencer' : 'Suivant'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Choix de la porte d'entrée.
class EcranChoix extends StatelessWidget {
  const EcranChoix({super.key});

  @override
  Widget build(BuildContext context) {
    Widget option(Parcours p, IconData icone, String detail) {
      return Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: ArzikiEspaces.m, vertical: ArzikiEspaces.s),
          leading: Icon(icone, color: ArzikiCouleurs.vert, size: 32),
          title: Text(p.libelle, style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text(detail),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => p == Parcours.invitation
              ? context.push(Chemins.invitation)
              : context.push('${Chemins.inscription}?parcours=${p.code}'),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Colonne(children: [
          const SizedBox(height: ArzikiEspaces.m),
          const Center(child: LogoArziki(hauteur: 64)),
          const SizedBox(height: ArzikiEspaces.l),
          Text('Bienvenue', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: ArzikiEspaces.s),
          const Text('Choisissez ce qui vous correspond.'),
          const SizedBox(height: ArzikiEspaces.l),
          option(Parcours.entreprise, Icons.storefront, "Faire financer l'achat d'une commande ferme."),
          option(Parcours.invitation, Icons.vpn_key_outlined,
              "Vous avez reçu un code personnel d'un administrateur ARZIKI."),
          option(Parcours.candidature, Icons.group_add_outlined,
              'Créer votre compte et présenter votre candidature au Cercle.'),
          option(Parcours.fournisseur, Icons.local_shipping_outlined, 'Recevoir les bons de commande ARZIKI.'),
          option(Parcours.notaire, Icons.gavel, 'Suivre les opérations qui vous sont confiées.'),
          const SizedBox(height: ArzikiEspaces.l),
          OutlinedButton(
            onPressed: () => context.push(Chemins.connexion),
            child: const Text("J'ai déjà un compte : se connecter"),
          ),
          TextButton(
            onPressed: () => context.push(Chemins.connexionAdmin),
            child: const Text('Accès administrateur'),
          ),
        ]),
      ),
    );
  }
}
