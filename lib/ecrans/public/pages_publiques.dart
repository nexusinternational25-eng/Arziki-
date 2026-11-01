// Pages accessibles à tous, y compris aux visiteurs sans compte :
// accueil visiteur, pages d'information, questions fréquentes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/session.dart';
import '../../contenu/contenus.dart';
import '../../core/images.dart';
import '../../core/roles.dart';
import '../../operations/operations.dart';
import '../../router/garde_roles.dart';
import '../../theme/arziki_theme.dart';
import '../../ui/composants.dart';
import '../accueil/sections_accueil.dart';
import '../navigation/cadre_app.dart';

// ---------------------------------------------------------------------------
// Accueil du visiteur
// ---------------------------------------------------------------------------

class EcranDecouvrir extends StatelessWidget {
  const EcranDecouvrir({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      drawer: const MenuLateral(),
      appBar: barreArziki(context, logo: true),
      bottomNavigationBar: const BarreVisiteur(),
      body: Colonne(children: [
        const Apparition(
          child: EnTeteImage(
            image: Images.marche,
            hauteur: 260,
            titre: 'Ta commande. Notre financement.',
            sousTitre: 'La Commande Financée au Togo : une commande ferme, un financement encadré par notaire.',
          ),
        ),
        const SizedBox(height: ArzikiEspaces.m),
        const Encadre(
          'Vous visitez ARZIKI sans compte. Les opérations du Cercle sont réservées aux membres admis et vérifiés.',
          icone: Icons.visibility_rounded,
        ),
        const SizedBox(height: ArzikiEspaces.s),
        const Apparition(ordre: 1, child: SectionCommentCaMarche(ouverte: true)),
        const CarrouselServices(afficherPrix: false),
        const TitreSection('Le Cercle Arziki', explication: 'Un cercle privé, sur invitation ou après admission.'),
        CarteImage(
          image: Images.reunionInvestisseurs,
          titre: 'Trois niveaux : Membre, Partenaire, Partenaire stratégique',
          texte: 'Des membres et des partenaires choisissent les opérations commerciales auxquelles ils participent, '
              'avec un avertissement clair sur les risques.',
          onTap: () => context.push(Chemins.info(PagesId.cercle)),
          pied: Text('Découvrir le Cercle', style: t.labelLarge?.copyWith(color: ArzikiCouleurs.vert)),
        ),
        const SizedBox(height: ArzikiEspaces.s),
        const BlocConfiance(),
        const TitreSection("À propos d'ARZIKI"),
        CarteArziki(
          onTap: () => context.push(Chemins.info(PagesId.aPropos)),
          child: Row(children: [
            const AvatarArziki(nom: 'Moussa Oumara', taille: 52),
            const SizedBox(width: ArzikiEspaces.m),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Une initiative de NEXUS International', style: t.titleSmall),
                Text('Fondée par MOUSSA SALEY ZOUZOU OUMARA, conseiller en investissement certifié USAID.', style: t.bodySmall),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded),
          ]),
        ),
        CarteArziki(
          onTap: () => context.push(Chemins.faq),
          child: Row(children: [
            const Icon(Icons.quiz_rounded, color: ArzikiCouleurs.vert),
            const SizedBox(width: ArzikiEspaces.m),
            Expanded(child: Text('Questions fréquentes', style: t.titleSmall)),
            const Icon(Icons.chevron_right_rounded),
          ]),
        ),
        const TitreSection('Nous contacter'),
        const CarteArziki(child: BoutonsContact()),
        const SizedBox(height: ArzikiEspaces.l),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Page d'information générique (contenu modifiable)
// ---------------------------------------------------------------------------

class PageInfo extends ConsumerWidget {
  const PageInfo({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(contenusProvider).pages[id];
    final t = Theme.of(context).textTheme;
    if (page == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Page introuvable')),
        body: Colonne(children: [
          EcranVide(
            icone: Icons.search_off_rounded,
            titre: 'Cette page n\'existe pas',
            texte: 'Elle a peut-être été déplacée. Revenez à l\'accueil.',
            action: "Retour à l'accueil",
            onAction: () => context.go(Chemins.demarrage),
          ),
        ]),
      );
    }
    final legale = page.version != null;
    return Scaffold(
      // Le titre est déjà sur la photo d'en-tête : la barre du haut reste sobre.
      appBar: barreArziki(context, titre: page.image == null ? page.titre : null),
      bottomNavigationBar: const BarreVisiteur(),
      body: Colonne(children: [
        if (page.image != null)
          Apparition(child: EnTeteImage(image: page.image!, titre: page.titre, hauteur: 200))
        else
          Semantics(header: true, child: Text(page.titre, style: t.headlineMedium)),
        const SizedBox(height: ArzikiEspaces.m),
        if (legale)
          Padding(
            padding: const EdgeInsets.only(bottom: ArzikiEspaces.s),
            child: Wrap(spacing: ArzikiEspaces.s, runSpacing: ArzikiEspaces.s, children: [
              BadgeStatut('Version ${page.version}', ton: TonBadge.info),
              if (page.majLe != null) BadgeStatut('Mise à jour le ${dateLongue(page.majLe!)}'),
            ]),
          ),
        Text(page.intro, style: t.bodyLarge),
        ..._complements(context, ref, id),
        for (var i = 0; i < page.sections.length; i++)
          Apparition(
            ordre: i,
            child: CarteArziki(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(page.sections[i].titre, style: t.titleMedium),
                const SizedBox(height: ArzikiEspaces.s),
                Text(page.sections[i].texte),
              ]),
            ),
          ),
        ..._apres(context, ref, id),
        const SizedBox(height: ArzikiEspaces.l),
      ]),
    );
  }

  /// Éléments propres à certaines pages, placés avant les sections.
  List<Widget> _complements(BuildContext context, WidgetRef ref, String id) {
    switch (id) {
      case PagesId.commentCaMarche:
        return const [SizedBox(height: ArzikiEspaces.m), SchemaCommandeFinancee()];
      case PagesId.cercle:
        return const [SizedBox(height: ArzikiEspaces.m), NiveauxCercle(), SizedBox(height: ArzikiEspaces.s), AvertissementRisque()];
      case PagesId.securite:
        return const [SizedBox(height: ArzikiEspaces.m), TableauGaranties()];
      case PagesId.aPropos:
        return const [SizedBox(height: ArzikiEspaces.m), CarteFondateur()];
      case PagesId.aide:
        return [
          const TitreSection('Nous contacter', explication: 'Notre équipe vous répond pendant les horaires indiqués.'),
          const CarteArziki(child: BoutonsContact()),
          const TitreSection('Guides pas à pas'),
        ];
      default:
        return const [SizedBox(height: ArzikiEspaces.s)];
    }
  }

  /// Éléments propres à certaines pages, placés après les sections.
  List<Widget> _apres(BuildContext context, WidgetRef ref, String id) {
    final u = ref.watch(sessionProvider).utilisateur;
    switch (id) {
      case PagesId.cercle:
        if (u != null && u.role.estMembreDuCercle) return const [];
        return [
          const SizedBox(height: ArzikiEspaces.s),
          FilledButton.icon(
            onPressed: () => context.push(Chemins.invitation),
            icon: const Icon(Icons.vpn_key_rounded),
            label: const Text("J'ai un code d'invitation"),
          ),
          const SizedBox(height: ArzikiEspaces.s),
          OutlinedButton(
            onPressed: () => context.push('${Chemins.inscription}?parcours=candidature'),
            child: const Text('Présenter ma candidature'),
          ),
        ];
      case PagesId.aide:
        return [
          const SizedBox(height: ArzikiEspaces.s),
          OutlinedButton.icon(
            onPressed: () => context.push(Chemins.faq),
            icon: const Icon(Icons.quiz_rounded),
            label: const Text('Voir les questions fréquentes'),
          ),
        ];
      default:
        return const [];
    }
  }
}

/// Schéma de la Commande Financée : qui fait quoi.
class SchemaCommandeFinancee extends StatelessWidget {
  const SchemaCommandeFinancee({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    const acteurs = [
      (Icons.storefront_rounded, 'Entreprise', 'Dépose sa commande ferme'),
      (Icons.fact_check_rounded, 'ARZIKI', 'Vérifie et coordonne'),
      (Icons.groups_rounded, 'Cercle ou fournisseur', "Finance l'achat"),
      (Icons.local_shipping_rounded, 'Fournisseur', 'Livre la marchandise'),
      (Icons.business_rounded, 'Acheteur final', 'Paie sur le compte désigné'),
      (Icons.gavel_rounded, 'Notaire', 'Contrôle les fonds et le partage'),
    ];
    return CarteArziki(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Le schéma en un coup d\'œil', style: t.titleMedium),
        const SizedBox(height: ArzikiEspaces.m),
        for (var i = 0; i < acteurs.length; i++) ...[
          Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: i == 1 ? ArzikiCouleurs.orange : ArzikiCouleurs.vert,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(acteurs[i].$1, color: ArzikiCouleurs.blanc),
            ),
            const SizedBox(width: ArzikiEspaces.m - 4),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(acteurs[i].$2, style: t.titleSmall),
                Text(acteurs[i].$3, style: t.bodySmall),
              ]),
            ),
          ]),
          if (i < acteurs.length - 1)
            const Padding(
              padding: EdgeInsets.only(left: 12, top: 2, bottom: 2),
              child: Icon(Icons.arrow_downward_rounded, color: ArzikiCouleurs.jaune),
            ),
        ],
      ]),
    );
  }
}

/// Les trois niveaux du Cercle.
class NiveauxCercle extends StatelessWidget {
  const NiveauxCercle({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final niveaux = [
      (NiveauCercle.membre, 'Opérations PME', '50 000 FCFA par an', ArzikiCouleurs.vert),
      (NiveauCercle.partenaire, 'PME et Entreprises', '250 000 FCFA par an', ArzikiCouleurs.orange),
      (NiveauCercle.partenaireStrategique, 'Toutes, chef de file possible', 'Selon convention', ArzikiCouleurs.vertFonce),
    ];
    return Column(children: [
      for (final n in niveaux)
        CarteArziki(
          child: Row(children: [
            Container(width: 6, height: 64, decoration: BoxDecoration(color: n.$4, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: ArzikiEspaces.m),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n.$1.libelle, style: t.titleMedium),
                Text('Opérations : ${n.$2}', style: t.bodySmall),
                Text('Participation minimale : ${fcfa(n.$1.participationMinimale)}', style: t.bodySmall),
                Text('Cotisation : ${n.$3}', style: t.bodySmall),
              ]),
            ),
          ]),
        ),
    ]);
  }
}

/// Tableau des garanties selon le montant (CLAUDE.md, section 8).
class TableauGaranties extends StatelessWidget {
  const TableauGaranties({super.key});

  static const paliers = [
    ('Moins de 5 M FCFA', 4000000, [
      'Bon de commande écrit',
      'Paiement sur compte désigné',
      "Caution du dirigeant si l'historique est faible",
    ]),
    ('De 5 à 30 M FCFA', 10000000, [
      'Caution solidaire du dirigeant',
      'Gage ou nantissement du stock ou du matériel',
    ]),
    ('De 30 à 100 M FCFA', 50000000, [
      "Cession de créance sur l'acheteur ou délégation de paiement",
      "Nantissement du fonds de commerce ou d'un compte",
      "Caution solidaire d'un tiers solvable",
    ]),
    ('Plus de 100 M FCFA', 150000000, [
      "Garantie foncière (hypothèque sur titre foncier, éventuellement d'un tiers garant)",
      'Assurance de la marchandise',
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Garanties selon le montant', style: t.titleLarge),
      const SizedBox(height: ArzikiEspaces.xs),
      Text('Chaque palier ajoute des garanties au précédent. Le notaire ajuste au cas par cas.', style: t.bodySmall),
      for (var i = 0; i < paliers.length; i++)
        CarteArziki(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            BadgeStatut(paliers[i].$1, ton: i < 2 ? TonBadge.succes : TonBadge.alerte),
            const SizedBox(height: ArzikiEspaces.s),
            for (final g in paliers[i].$3)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(Icons.check_circle_rounded, size: 18, color: ArzikiCouleurs.vert),
                  ),
                  const SizedBox(width: ArzikiEspaces.s),
                  Expanded(child: Text(i == 0 ? g : 'En plus : $g')),
                ]),
              ),
            const SizedBox(height: ArzikiEspaces.s),
            Text("Forme de l'acte : ${formeActePour(paliers[i].$2)}", style: t.bodySmall),
          ]),
        ),
    ]);
  }
}

/// Présentation du fondateur.
class CarteFondateur extends StatelessWidget {
  const CarteFondateur({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    const chiffres = [
      ('30 M USD', 'financement validé'),
      ('160 M USD', 'financement validé'),
      ('100+', 'entreprises accompagnées'),
    ];
    return CarteArziki(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const AvatarArziki(nom: 'Moussa Oumara', taille: 64),
          const SizedBox(width: ArzikiEspaces.m),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('MOUSSA SALEY ZOUZOU OUMARA', style: t.titleMedium),
              Text('Fondateur de NEXUS International', style: t.bodySmall),
              const SizedBox(height: 4),
              const BadgeStatut('Conseiller en investissement certifié USAID', ton: TonBadge.succes, icone: Icons.verified_rounded),
            ]),
          ),
        ]),
        const SizedBox(height: ArzikiEspaces.m),
        Row(children: [
          for (final c in chiffres)
            Expanded(
              child: Column(children: [
                Text(c.$1, style: t.titleLarge?.copyWith(color: ArzikiCouleurs.vert)),
                Text(c.$2, style: t.labelSmall, textAlign: TextAlign.center),
              ]),
            ),
        ]),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Questions fréquentes
// ---------------------------------------------------------------------------

class EcranFaq extends ConsumerStatefulWidget {
  const EcranFaq({super.key});

  @override
  ConsumerState<EcranFaq> createState() => _EcranFaqState();
}

class _EcranFaqState extends ConsumerState<EcranFaq> {
  String _recherche = '';
  CategorieFaq? _categorie;

  String _sansAccents(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[àâä]'), 'a')
      .replaceAll(RegExp('[îï]'), 'i')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[ùûü]'), 'u')
      .replaceAll('ç', 'c');

  @override
  Widget build(BuildContext context) {
    final faq = ref.watch(contenusProvider).faq;
    final q = _sansAccents(_recherche.trim());
    final liste = faq.where((x) {
      if (_categorie != null && x.categorie != _categorie) return false;
      return q.isEmpty || _sansAccents('${x.question} ${x.reponse}').contains(q);
    }).toList();

    return Scaffold(
      appBar: barreArziki(context),
      bottomNavigationBar: const BarreVisiteur(),
      body: Colonne(children: [
        const EnTetePage('Questions fréquentes', 'Les réponses aux questions les plus courantes, classées par sujet.'),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            labelText: 'Rechercher une question',
            helperText: 'Par exemple : garanties, versement, notaire',
          ),
          onChanged: (v) => setState(() => _recherche = v),
        ),
        const SizedBox(height: ArzikiEspaces.m),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            Padding(
              padding: const EdgeInsets.only(right: ArzikiEspaces.s),
              child: ChoiceChip(label: const Text('Toutes'), selected: _categorie == null, onSelected: (_) => setState(() => _categorie = null)),
            ),
            for (final c in CategorieFaq.values)
              Padding(
                padding: const EdgeInsets.only(right: ArzikiEspaces.s),
                child: ChoiceChip(label: Text(c.libelle), selected: _categorie == c, onSelected: (_) => setState(() => _categorie = c)),
              ),
          ]),
        ),
        const SizedBox(height: ArzikiEspaces.s),
        if (liste.isEmpty)
          EcranVide(
            icone: Icons.search_off_rounded,
            titre: 'Aucune réponse trouvée',
            texte: 'Essayez un autre mot, ou posez directement votre question à notre équipe.',
            action: 'Contacter ARZIKI',
            onAction: () => context.push(Chemins.info(PagesId.aide)),
          ),
        for (final x in liste)
          CarteArziki(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: ArzikiEspaces.m, vertical: 2),
              childrenPadding: const EdgeInsets.fromLTRB(ArzikiEspaces.m, 0, ArzikiEspaces.m, ArzikiEspaces.m),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              title: Text(x.question, style: Theme.of(context).textTheme.titleSmall),
              subtitle: Text(x.categorie.libelle, style: Theme.of(context).textTheme.labelSmall),
              children: [Text(x.reponse)],
            ),
          ),
        const SizedBox(height: ArzikiEspaces.l),
      ]),
    );
  }
}
