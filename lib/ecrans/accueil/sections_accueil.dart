// Blocs réutilisés par les écrans d'accueil (visiteur et connecté) :
// comment ça marche, carrousel des services, bloc de confiance, actualités,
// et les liens de contact (WhatsApp, appel, e-mail).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../contenu/contenus.dart';
import '../../router/garde_roles.dart';
import '../../services_nexus/services.dart';
import '../../theme/arziki_theme.dart';
import '../../ui/composants.dart';

/// Les 5 étapes de la Commande Financée, en version courte et illustrée.
const etapesCourtes = [
  (Icons.upload_file_rounded, 'Vous déposez votre commande', 'Bon de commande, devis du fournisseur, vos coûts.'),
  (Icons.fact_check_rounded, 'ARZIKI vérifie', 'Acheteur contacté, prix contrôlés, garanties proposées.'),
  (Icons.account_balance_rounded, "L'achat est financé", 'Par le fournisseur ou par le Cercle, via le notaire.'),
  (Icons.local_shipping_rounded, 'Vous livrez', 'Chaque étape est suivie dans l\'application.'),
  (Icons.pie_chart_rounded, 'La marge est partagée', "Après le paiement de l'acheteur, selon le contrat."),
];

/// Section « Comment ça marche », repliable.
class SectionCommentCaMarche extends StatelessWidget {
  const SectionCommentCaMarche({super.key, this.ouverte = false});
  final bool ouverte;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return CarteArziki(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: ouverte,
        tilePadding: const EdgeInsets.symmetric(horizontal: ArzikiEspaces.m, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(ArzikiEspaces.m, 0, ArzikiEspaces.m, ArzikiEspaces.m),
        leading: const Icon(Icons.route_rounded, color: ArzikiCouleurs.vert),
        title: Text('Comment ça marche', style: t.titleMedium),
        subtitle: Text('La Commande Financée en 5 étapes', style: t.bodySmall),
        children: [
          for (var i = 0; i < etapesCourtes.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (i.isEven ? ArzikiCouleurs.vert : ArzikiCouleurs.orange).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(etapesCourtes[i].$1, color: i.isEven ? ArzikiCouleurs.vert : ArzikiCouleurs.orange),
                ),
                const SizedBox(width: ArzikiEspaces.m - 4),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${i + 1}. ${etapesCourtes[i].$2}', style: t.titleSmall),
                    Text(etapesCourtes[i].$3, style: t.bodySmall),
                  ]),
                ),
              ]),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.push(Chemins.info(PagesId.commentCaMarche)),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Tout comprendre en détail'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carrousel « Nos services ».
class CarrouselServices extends ConsumerWidget {
  const CarrouselServices({super.key, this.afficherPrix = true, this.onToutVoir});
  final bool afficherPrix;
  final VoidCallback? onToutVoir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offres = ref.watch(servicesProvider).catalogue;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TitreSection(
        'Nos services',
        explication: 'Opérés par NEXUS International',
        action: 'Tout voir',
        onAction: onToutVoir ?? () => context.push(Chemins.services),
      ),
      SizedBox(
        height: 268,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: offres.length,
          separatorBuilder: (_, _) => const SizedBox(width: ArzikiEspaces.m - 4),
          itemBuilder: (context, i) {
            final o = offres[i];
            return SizedBox(
              width: 240,
              child: CarteImage(
                image: o.image,
                hauteurImage: 120,
                titre: o.titre,
                texte: o.accroche,
                badge: o.bientot
                    ? const BadgeStatut('Bientôt', ton: TonBadge.attente)
                    : BadgeStatut(o.famille.libelle, ton: TonBadge.succes),
                onTap: () => context.push(Chemins.offre(o.id)),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

/// Bloc de confiance.
class BlocConfiance extends StatelessWidget {
  const BlocConfiance({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    const points = [
      (Icons.gavel_rounded, 'Un notaire partenaire', 'Actes signés et fonds reçus en séquestre.'),
      (Icons.fact_check_rounded, 'Acheteurs vérifiés', 'Chaque commande est confirmée auprès de l\'acheteur.'),
      (Icons.shield_rounded, 'Garanties selon le montant', 'Caution, nantissement ou hypothèque selon le cas.'),
      (Icons.account_balance_wallet_rounded, "L'app ne détient jamais l'argent", 'Les fonds vont au fournisseur ou au notaire.'),
    ];
    return CarteArziki(
      couleur: ArzikiCouleurs.vert.withValues(alpha: 0.07),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Pourquoi nous faire confiance', style: t.titleMedium),
        const SizedBox(height: ArzikiEspaces.s),
        for (final p in points)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(p.$1, color: ArzikiCouleurs.vert),
              const SizedBox(width: ArzikiEspaces.m - 4),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.$2, style: t.titleSmall),
                  Text(p.$3, style: t.bodySmall),
                ]),
              ),
            ]),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => context.push(Chemins.info(PagesId.securite)),
            child: const Text('Sécurité et notaire'),
          ),
        ),
      ]),
    );
  }
}

/// Actualités et conseils (modifiables depuis la console).
class SectionActualites extends ConsumerWidget {
  const SectionActualites({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actus = ref.watch(contenusProvider).actualites;
    if (actus.isEmpty) return const SizedBox.shrink();
    final t = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const TitreSection('Actualités et conseils'),
      for (final a in actus.take(3))
        CarteArziki(
          padding: EdgeInsets.zero,
          onTap: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(ArzikiEspaces.l, 0, ArzikiEspaces.l, ArzikiEspaces.l),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Illustration(a.image, hauteur: 180, rayon: ArzikiRayons.carte),
                  const SizedBox(height: ArzikiEspaces.m),
                  Text(a.titre, style: t.titleLarge),
                  Text(dateLongue(a.date), style: t.bodySmall),
                  const SizedBox(height: ArzikiEspaces.s),
                  Text(a.texte),
                ]),
              ),
            ),
          ),
          child: Row(children: [
            Illustration(a.image, largeur: 96, hauteur: 96),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(ArzikiEspaces.m - 4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.titre, style: t.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(a.texte, style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                ]),
              ),
            ),
          ]),
        ),
    ]);
  }
}

/// Ouvre WhatsApp, le téléphone ou la messagerie. Affiche un message si impossible.
Future<void> ouvrirLien(BuildContext context, Uri lien, {required String repli}) async {
  final ok = await launchUrl(lien, mode: LaunchMode.externalApplication).catchError((_) => false);
  if (!ok && context.mounted) annoncer(context, repli);
}

/// Boutons de contact : WhatsApp, appel, e-mail.
class BoutonsContact extends ConsumerWidget {
  const BoutonsContact({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(contenusProvider).contacts;
    final t = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1FA855)),
        onPressed: () => ouvrirLien(
          context,
          Uri.parse('https://wa.me/${c.whatsappChiffres}?text=${Uri.encodeComponent('Bonjour ARZIKI, ')}'),
          repli: 'WhatsApp : ${c.whatsapp}',
        ),
        icon: const Icon(Icons.chat_rounded),
        label: const Text('Discuter sur WhatsApp'),
      ),
      const SizedBox(height: ArzikiEspaces.s),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => ouvrirLien(context, Uri.parse('tel:${c.telephoneChiffres}'), repli: 'Téléphone : ${c.telephone}'),
            icon: const Icon(Icons.call_rounded),
            label: const Text('Appeler'),
          ),
        ),
        const SizedBox(width: ArzikiEspaces.s),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => ouvrirLien(context, Uri.parse('mailto:${c.email}'), repli: 'E-mail : ${c.email}'),
            icon: const Icon(Icons.mail_rounded),
            label: const Text('E-mail'),
          ),
        ),
      ]),
      const SizedBox(height: ArzikiEspaces.m),
      _Ligne(Icons.chat_rounded, 'WhatsApp et téléphone', c.whatsapp, t),
      _Ligne(Icons.mail_rounded, 'E-mail', c.email, t),
      _Ligne(Icons.schedule_rounded, 'Horaires', c.horaires, t),
      _Ligne(Icons.place_rounded, 'Adresse', c.adresse, t),
    ]);
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne(this.icone, this.titre, this.valeur, this.t);
  final IconData icone;
  final String titre;
  final String valeur;
  final TextTheme t;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icone, size: 20, color: ArzikiCouleurs.vert),
          const SizedBox(width: ArzikiEspaces.m - 4),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titre, style: t.labelMedium),
              SelectableText(valeur, style: t.bodyMedium),
            ]),
          ),
        ]),
      );
}
