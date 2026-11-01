// Ossature de navigation commune : menu latéral, barre du haut avec
// notifications, barre du bas selon le rôle, bouton « Créer mon compte »
// pour les visiteurs.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/session.dart';
import '../../config/app_config.dart';
import '../../contenu/contenus.dart';
import '../../operations/operations.dart';
import '../../router/garde_roles.dart';
import '../../theme/arziki_theme.dart';
import '../../ui/composants.dart';

// ---------------------------------------------------------------------------
// Menu latéral
// ---------------------------------------------------------------------------

class _EntreeMenu {
  const _EntreeMenu(this.icone, this.libelle, this.chemin);
  final IconData icone;
  final String libelle;
  final String chemin;
}

class MenuLateral extends ConsumerWidget {
  const MenuLateral({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(sessionProvider).utilisateur;
    final t = Theme.of(context).textTheme;
    final accueil = u == null ? Chemins.decouvrir : accueilDe(u.role);

    final principales = [
      _EntreeMenu(Icons.home_rounded, 'Accueil', accueil),
      _EntreeMenu(Icons.route_rounded, 'Comment ça marche', Chemins.info(PagesId.commentCaMarche)),
      _EntreeMenu(Icons.info_rounded, "À propos d'ARZIKI", Chemins.info(PagesId.aPropos)),
      const _EntreeMenu(Icons.work_rounded, 'Nos services', Chemins.services),
      _EntreeMenu(Icons.groups_rounded, 'Le Cercle Arziki', Chemins.info(PagesId.cercle)),
      _EntreeMenu(Icons.verified_user_rounded, 'Sécurité et notaire', Chemins.info(PagesId.securite)),
      const _EntreeMenu(Icons.quiz_rounded, 'Questions fréquentes', Chemins.faq),
      _EntreeMenu(Icons.support_agent_rounded, "Centre d'aide", Chemins.info(PagesId.aide)),
      _EntreeMenu(Icons.mail_rounded, 'Nous contacter', '${Chemins.info(PagesId.aide)}#contact'),
    ];
    final legales = [
      _EntreeMenu(Icons.description_rounded, "Conditions d'utilisation", Chemins.info(PagesId.cgu)),
      _EntreeMenu(Icons.privacy_tip_rounded, 'Politique de confidentialité', Chemins.info(PagesId.confidentialite)),
      _EntreeMenu(Icons.warning_amber_rounded, 'Avertissement sur les risques', Chemins.info(PagesId.risques)),
    ];

    void aller(String chemin) {
      Navigator.of(context).pop();
      final route = chemin.split('#').first;
      if (route == accueil) {
        context.go(route);
      } else {
        context.push(route);
      }
    }

    Widget ligne(_EntreeMenu e) => ListTile(
          leading: Icon(e.icone),
          title: Text(e.libelle),
          dense: false,
          visualDensity: VisualDensity.compact,
          onTap: () => aller(e.chemin),
        );

    return Drawer(
      child: SafeArea(
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(ArzikiEspaces.l, ArzikiEspaces.l, ArzikiEspaces.l, ArzikiEspaces.m),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [ArzikiCouleurs.vertFonce, ArzikiCouleurs.vert]),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const LogoArziki(hauteur: 44, blanc: true),
              const SizedBox(height: ArzikiEspaces.m),
              if (u == null)
                Text('Bienvenue sur ARZIKI', style: t.titleMedium?.copyWith(color: ArzikiCouleurs.blanc))
              else
                Row(children: [
                  AvatarArziki(nom: u.nomComplet, taille: 40),
                  const SizedBox(width: ArzikiEspaces.m - 4),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(u.nomComplet,
                          style: t.titleSmall?.copyWith(color: ArzikiCouleurs.blanc), overflow: TextOverflow.ellipsis),
                      Text(u.role.libelle, style: t.bodySmall?.copyWith(color: ArzikiCouleurs.blanc.withValues(alpha: 0.85))),
                    ]),
                  ),
                ]),
            ]),
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.symmetric(vertical: ArzikiEspaces.s), children: [
              ...principales.map(ligne),
              const Divider(height: ArzikiEspaces.m),
              ...legales.map(ligne),
              const Divider(height: ArzikiEspaces.m),
              if (u != null) ...[
                ListTile(
                  leading: const Icon(Icons.settings_rounded),
                  title: const Text('Paramètres'),
                  visualDensity: VisualDensity.compact,
                  onTap: () => aller(Chemins.parametres),
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: ArzikiCouleurs.erreur),
                  title: const Text('Déconnexion', style: TextStyle(color: ArzikiCouleurs.erreur)),
                  visualDensity: VisualDensity.compact,
                  onTap: () async {
                    Navigator.of(context).pop();
                    if (await confirmer(context,
                        titre: 'Se déconnecter ?',
                        message: 'Vous devrez saisir à nouveau votre code pour vous reconnecter.',
                        valider: 'Me déconnecter')) {
                      await ref.read(sessionProvider.notifier).deconnecter();
                      if (context.mounted) context.go(Chemins.choix);
                    }
                  },
                ),
              ] else
                ListTile(
                  leading: const Icon(Icons.person_add_alt_1_rounded, color: ArzikiCouleurs.orange),
                  title: const Text('Créer mon compte'),
                  visualDensity: VisualDensity.compact,
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go(Chemins.choix);
                  },
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(ArzikiEspaces.m),
            child: Column(children: [
              Text('Version ${AppConfig.version}', style: t.labelSmall),
              const SizedBox(height: 2),
              Text('Une offre de NEXUS International', style: t.labelMedium?.copyWith(color: ArzikiCouleurs.vert)),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Barre du haut
// ---------------------------------------------------------------------------

/// Cloche de notifications avec pastille du nombre de non lues.
class BoutonNotifications extends ConsumerWidget {
  const BoutonNotifications({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(sessionProvider).utilisateur;
    if (u == null) return const SizedBox.shrink();
    final nonLues = notificationsPour(u.role).where((n) => !n.lue).length;
    return IconButton(
      tooltip: nonLues == 0 ? 'Notifications' : 'Notifications, $nonLues non lues',
      onPressed: () => context.push(Chemins.notifications),
      icon: Badge(
        isLabelVisible: nonLues > 0,
        backgroundColor: ArzikiCouleurs.orange,
        label: Text('$nonLues'),
        child: const Icon(Icons.notifications_rounded),
      ),
    );
  }
}

/// Barre du haut ARZIKI : menu à gauche (ou retour), titre, notifications à droite.
PreferredSizeWidget barreArziki(BuildContext context, {String? titre, bool logo = false, List<Widget> actions = const []}) {
  return AppBar(
    title: logo ? const LogoArziki(hauteur: 34) : (titre == null ? null : Text(titre)),
    actions: [...actions, const BoutonNotifications(), const SizedBox(width: 4)],
  );
}

/// Bouton « Créer mon compte » toujours visible pour un visiteur.
class BarreVisiteur extends ConsumerWidget {
  const BarreVisiteur({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(sessionProvider).estConnecte) return const SizedBox.shrink();
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(ArzikiEspaces.m, ArzikiEspaces.s, ArzikiEspaces.m, ArzikiEspaces.s),
          child: LargeurMax(
            child: Row(children: [
              Expanded(
                child: OutlinedButton(onPressed: () => context.push(Chemins.connexion), child: const Text('Se connecter')),
              ),
              const SizedBox(width: ArzikiEspaces.m - 4),
              Expanded(
                child: FilledButton(onPressed: () => context.go(Chemins.choix), child: const Text('Créer mon compte')),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cadre avec onglets (barre du bas selon le rôle)
// ---------------------------------------------------------------------------

class Onglet {
  const Onglet({required this.icone, required this.iconeActive, required this.libelle, required this.page, this.titre});
  final IconData icone;
  final IconData iconeActive;
  final String libelle;
  final Widget page;

  /// Titre de la barre du haut (sinon le logo).
  final String? titre;
}

class CadreOnglets extends StatefulWidget {
  const CadreOnglets({super.key, required this.onglets, this.boutonCentral, this.libelleCentral});
  final List<Onglet> onglets;

  /// Action du bouton central orange (ex. « Nouvelle demande »), placé au milieu.
  final VoidCallback? boutonCentral;
  final String? libelleCentral;

  @override
  State<CadreOnglets> createState() => CadreOngletsState();
}

class CadreOngletsState extends State<CadreOnglets> {
  int _index = 0;

  /// Permet aux pages de changer d'onglet (ex. « Tout voir »).
  void allerA(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final central = widget.boutonCentral != null;
    final milieu = widget.onglets.length ~/ 2;
    final destinations = <Widget>[];
    for (var i = 0; i < widget.onglets.length; i++) {
      if (central && i == milieu) {
        destinations.add(NavigationDestination(
          icon: Container(
            width: 52,
            height: 40,
            decoration: BoxDecoration(color: ArzikiCouleurs.orange, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.add_rounded, color: ArzikiCouleurs.blanc, size: 28),
          ),
          label: widget.libelleCentral ?? 'Nouveau',
        ));
      }
      final o = widget.onglets[i];
      destinations.add(NavigationDestination(icon: Icon(o.icone), selectedIcon: Icon(o.iconeActive), label: o.libelle));
    }
    int versDestination(int index) => central && index >= milieu ? index + 1 : index;
    int versOnglet(int dest) => central && dest > milieu ? dest - 1 : dest;

    final onglet = widget.onglets[_index];
    return Scaffold(
      drawer: const MenuLateral(),
      appBar: barreArziki(context, titre: onglet.titre, logo: onglet.titre == null),
      body: IndexedStack(index: _index, children: [for (final o in widget.onglets) o.page]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: versDestination(_index),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (d) {
          if (central && d == milieu) {
            widget.boutonCentral!();
            return;
          }
          setState(() => _index = versOnglet(d));
        },
        destinations: destinations,
      ),
    );
  }
}
