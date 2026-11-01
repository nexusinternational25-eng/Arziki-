// Premier lancement : démarrage animé, présentation en 4 écrans,
// choix du profil (dont le mode visiteur « Je veux juste découvrir »).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/depot_auth.dart';
import '../../auth/session.dart';
import '../../config/app_config.dart';
import '../../core/images.dart';
import '../../router/garde_roles.dart';
import '../../theme/arziki_theme.dart';
import '../../ui/composants.dart';

// ---------------------------------------------------------------------------
// Démarrage animé
// ---------------------------------------------------------------------------

class EcranDemarrage extends StatefulWidget {
  const EcranDemarrage({super.key});

  @override
  State<EcranDemarrage> createState() => _EcranDemarrageState();
}

class _EcranDemarrageState extends State<EcranDemarrage> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
    ..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (!mounted) return;
      context.go(AppConfig.estConsole ? Chemins.connexionAdmin : Chemins.presentation);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final echelle = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
    final fondu = CurvedAnimation(parent: _c, curve: const Interval(0.35, 1, curve: Curves.easeOut));
    return Scaffold(
      backgroundColor: ArzikiCouleurs.blanc,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ScaleTransition(
            scale: Tween(begin: 0.7, end: 1.0).animate(echelle),
            child: FadeTransition(opacity: _c, child: const LogoArziki(hauteur: 96)),
          ),
          const SizedBox(height: ArzikiEspaces.l),
          FadeTransition(
            opacity: fondu,
            child: Text(
              AppConfig.estConsole ? "Console d'administration" : 'Ta commande. Notre financement.',
              style: t.titleMedium?.copyWith(color: ArzikiCouleurs.vert),
            ),
          ),
          const SizedBox(height: ArzikiEspaces.xl),
          FadeTransition(
            opacity: fondu,
            child: const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5)),
          ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Présentation en 4 écrans
// ---------------------------------------------------------------------------

class _PagePresentation {
  const _PagePresentation(this.image, this.titre, this.texte, this.icone);
  final String image;
  final String titre;
  final String texte;
  final IconData icone;
}

const _pages = [
  _PagePresentation(
    Images.commercante,
    'Votre commande, financée',
    'Une commande ferme mais pas la trésorerie pour acheter la marchandise ? ARZIKI vérifie votre commande '
        "et organise le financement de l'achat.",
    Icons.shopping_cart_checkout_rounded,
  ),
  _PagePresentation(
    Images.cercleApplication,
    "Un Cercle privé d'investisseurs",
    'Des membres et des partenaires choisissent les opérations auxquelles ils participent. '
        "L'argent ne transite jamais par l'application.",
    Icons.groups_rounded,
  ),
  _PagePresentation(
    Images.cercleNotaire,
    'Chaque opération encadrée par notaire',
    'Actes signés, fonds en séquestre, garanties proportionnées au montant : un cadre clair à chaque étape.',
    Icons.gavel_rounded,
  ),
  _PagePresentation(
    Images.dirigeanteSignature,
    'Des experts pour vos dossiers',
    'Business plan, états financiers, formations : les équipes de NEXUS International vous accompagnent.',
    Icons.workspace_premium_rounded,
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
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: ArzikiCouleurs.vertFonce,
      body: Stack(children: [
        PageView.builder(
          controller: _controleur,
          itemCount: _pages.length,
          onPageChanged: (p) => setState(() => _page = p),
          itemBuilder: (context, i) {
            final p = _pages[i];
            return Stack(fit: StackFit.expand, children: [
              Illustration(p.image),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x33000000), Color(0x00000000), Color(0xCC0E3F25), Color(0xF20E3F25)],
                    stops: [0, 0.3, 0.62, 1],
                  ),
                ),
              ),
              SafeArea(
                child: LargeurMax(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(ArzikiEspaces.l, 0, ArzikiEspaces.l, 150),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: ArzikiCouleurs.orange, borderRadius: BorderRadius.circular(14)),
                        child: Icon(p.icone, color: ArzikiCouleurs.blanc),
                      ),
                      const SizedBox(height: ArzikiEspaces.m),
                      Semantics(
                        header: true,
                        child: Text(p.titre, style: t.displaySmall?.copyWith(color: ArzikiCouleurs.blanc)),
                      ),
                      const SizedBox(height: ArzikiEspaces.s),
                      Text(p.texte, style: t.bodyLarge?.copyWith(color: ArzikiCouleurs.blanc.withValues(alpha: 0.92))),
                    ]),
                  ),
                ),
              ),
            ]);
          },
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ArzikiEspaces.s),
            child: Row(children: [
              const Padding(padding: EdgeInsets.all(ArzikiEspaces.s), child: _PastilleLogo()),
              const Spacer(),
              TextButton(
                onPressed: _terminer,
                style: TextButton.styleFrom(foregroundColor: ArzikiCouleurs.blanc),
                child: const Text('Passer'),
              ),
            ]),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            child: LargeurMax(
              child: Padding(
                padding: const EdgeInsets.all(ArzikiEspaces.l),
                child: Row(children: [
                  Semantics(
                    label: 'Écran ${_page + 1} sur ${_pages.length}',
                    child: Row(
                      children: List.generate(
                        _pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(right: 6),
                          width: i == _page ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page ? ArzikiCouleurs.jaune : ArzikiCouleurs.blanc.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: derniere
                        ? _terminer
                        : () => _controleur.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic),
                    icon: Icon(derniere ? Icons.check_rounded : Icons.arrow_forward_rounded),
                    label: Text(derniere ? 'Commencer' : 'Suivant'),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Logo dans une pastille blanche (lisible sur photo).
class _PastilleLogo extends StatelessWidget {
  const _PastilleLogo();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: ArzikiCouleurs.blanc, borderRadius: BorderRadius.circular(12)),
        child: const LogoArziki(hauteur: 26),
      );
}

// ---------------------------------------------------------------------------
// Choix du profil
// ---------------------------------------------------------------------------

class _Profil {
  const _Profil(this.image, this.titre, this.texte, this.icone, this.action);
  final String image;
  final String titre;
  final String texte;
  final IconData icone;
  final void Function(BuildContext) action;
}

class EcranChoix extends ConsumerWidget {
  const EcranChoix({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    void inscription(BuildContext c, Parcours p) => c.push('${Chemins.inscription}?parcours=${p.code}');

    final profils = [
      _Profil(Images.entrepreneurEntrepot, 'Entreprise', "Faire financer l'achat d'une commande ferme.",
          Icons.storefront_rounded, (c) => inscription(c, Parcours.entreprise)),
      _Profil(Images.cercleApplication, 'Membre du Cercle', "J'ai reçu un code d'invitation personnel.",
          Icons.vpn_key_rounded, (c) => c.push(Chemins.invitation)),
      _Profil(Images.cercleDiaspora, 'Rejoindre le Cercle', 'Créer mon compte et présenter ma candidature.',
          Icons.group_add_rounded, (c) => inscription(c, Parcours.candidature)),
      _Profil(Images.fournisseurPme, 'Fournisseur', 'Recevoir les bons de commande ARZIKI.',
          Icons.local_shipping_rounded, (c) => inscription(c, Parcours.fournisseur)),
      _Profil(Images.cercleDossier, 'Notaire', 'Suivre les opérations qui me sont confiées.',
          Icons.gavel_rounded, (c) => inscription(c, Parcours.notaire)),
      _Profil(Images.marche, 'Je veux juste découvrir', 'Visiter ARZIKI sans créer de compte.',
          Icons.explore_rounded, (c) {
        ref.read(sessionProvider.notifier).presentationTerminee();
        c.go(Chemins.decouvrir);
      }),
    ];

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(builder: (context, c) {
          final colonnes = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 560 ? 2 : 1);
          return CustomScrollView(slivers: [
            const SliverToBoxAdapter(
              child: LargeurMax(
                largeur: 1000,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(ArzikiEspaces.l, ArzikiEspaces.l, ArzikiEspaces.l, ArzikiEspaces.s),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    LogoArziki(hauteur: 48),
                    SizedBox(height: ArzikiEspaces.l),
                    EnTetePage('Bienvenue sur ARZIKI', 'Choisissez votre profil pour commencer.'),
                  ]),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: LargeurMax(
                largeur: 1000,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ArzikiEspaces.l),
                  child: Wrap(spacing: ArzikiEspaces.m, children: [
                    for (var i = 0; i < profils.length; i++)
                      SizedBox(
                        width: colonnes == 1
                            ? double.infinity
                            : (c.maxWidth.clamp(0, 1000) - ArzikiEspaces.l * 2 - ArzikiEspaces.m * (colonnes - 1)) / colonnes,
                        child: Apparition(ordre: i, child: _CarteProfil(profils[i])),
                      ),
                  ]),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: LargeurMax(
                largeur: 1000,
                child: Padding(
                  padding: const EdgeInsets.all(ArzikiEspaces.l),
                  child: Column(children: [
                    OutlinedButton.icon(
                      onPressed: () => context.push(Chemins.connexion),
                      icon: const Icon(Icons.login_rounded),
                      label: const Text("J'ai déjà un compte : me connecter"),
                    ),
                    const SizedBox(height: ArzikiEspaces.s),
                    TextButton.icon(
                      onPressed: () => context.push(Chemins.connexionAdmin),
                      icon: const Icon(Icons.admin_panel_settings_rounded),
                      label: const Text('Accès administrateur'),
                    ),
                    const SizedBox(height: ArzikiEspaces.s),
                    Text('Une offre de NEXUS International', style: t.labelMedium),
                  ]),
                ),
              ),
            ),
          ]);
        }),
      ),
    );
  }
}

class _CarteProfil extends StatelessWidget {
  const _CarteProfil(this.p);
  final _Profil p;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return CarteArziki(
      padding: EdgeInsets.zero,
      onTap: () => p.action(context),
      semantique: '${p.titre}. ${p.texte}',
      child: Row(children: [
        Illustration(p.image, largeur: 104, hauteur: 104),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ArzikiEspaces.m),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(p.icone, color: ArzikiCouleurs.vert, size: 20),
                const SizedBox(width: 6),
                Expanded(child: Text(p.titre, style: t.titleMedium, maxLines: 2)),
              ]),
              const SizedBox(height: 4),
              Text(p.texte, style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(right: ArzikiEspaces.s),
          child: Icon(Icons.chevron_right_rounded),
        ),
      ]),
    );
  }
}
