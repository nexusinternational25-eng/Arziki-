// Composants réutilisés par tous les écrans (système de design ARZIKI).
// Un seul jeu d'icônes : Material, variante arrondie (Icons.xxx_rounded).

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../core/textes_legaux.dart';
import '../theme/arziki_theme.dart';

// ===========================================================================
// Mise en page
// ===========================================================================

/// Bandeau jaune « Démonstration », affiché en haut de chaque écran en mode demo.
class BandeauDemo extends StatelessWidget {
  const BandeauDemo({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.estDemo) return child;
    return Column(
      children: [
        Material(
          color: ArzikiCouleurs.jaune,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Text(
                  'Démonstration : données fictives, aucun paiement réel',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: ArzikiCouleurs.texte),
                ),
              ),
            ),
          ),
        ),
        Expanded(child: MediaQuery.removePadding(context: context, removeTop: true, child: child)),
      ],
    );
  }
}

/// Contenu centré, à largeur limitée (lisible sur téléphone, tablette et web).
class Colonne extends StatelessWidget {
  const Colonne({
    super.key,
    required this.children,
    this.largeurMax = ArzikiEspaces.largeurMax,
    this.padding = const EdgeInsets.all(ArzikiEspaces.l),
  });
  final List<Widget> children;
  final double largeurMax;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: largeurMax),
        child: ListView(padding: padding, children: children),
      ),
    );
  }
}

/// Limite la largeur d'un contenu (sans défilement).
class LargeurMax extends StatelessWidget {
  const LargeurMax({super.key, required this.child, this.largeur = ArzikiEspaces.largeurMax});
  final Widget child;
  final double largeur;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        // heightFactor : la hauteur suit celle du contenu (indispensable dans les barres du bas).
        heightFactor: 1,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: largeur), child: child),
      );
}

/// Logo ARZIKI (version couleur, version blanche pour les fonds verts, ou symbole seul).
class LogoArziki extends StatelessWidget {
  const LogoArziki({super.key, this.hauteur = 56, this.symboleSeul = false, this.blanc = false});
  final double hauteur;
  final bool symboleSeul;
  final bool blanc;

  @override
  Widget build(BuildContext context) {
    final sombre = Theme.of(context).brightness == Brightness.dark;
    final fichier = symboleSeul
        ? 'assets/logo/arziki_symbole.png'
        : blanc || sombre
            ? 'assets/logo/arziki_logo_blanc.png'
            : 'assets/logo/arziki_logo.png';
    return Image.asset(fichier, height: hauteur, fit: BoxFit.contain, semanticLabel: 'ARZIKI');
  }
}

/// Image d'illustration, décodée à la taille affichée (économie de mémoire sur petits téléphones).
class Illustration extends StatelessWidget {
  const Illustration(this.fichier, {super.key, this.hauteur, this.largeur, this.rayon = 0, this.fit = BoxFit.cover});
  final String fichier;
  final double? hauteur;
  final double? largeur;
  final double rayon;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final image = LayoutBuilder(builder: (context, c) {
      final w = (largeur ?? (c.maxWidth.isFinite ? c.maxWidth : 400)) * ratio;
      return Image.asset(
        fichier,
        height: hauteur,
        width: largeur ?? double.infinity,
        fit: fit,
        cacheWidth: w.clamp(200, 1400).round(),
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => Container(color: ArzikiCouleurs.vert.withValues(alpha: 0.12)),
      );
    });
    return rayon == 0 ? image : ClipRRect(borderRadius: BorderRadius.circular(rayon), child: image);
  }
}

/// En-tête avec grande photo et voile dégradé, pour les pages et l'accueil.
class EnTeteImage extends StatelessWidget {
  const EnTeteImage({
    super.key,
    required this.image,
    required this.titre,
    this.sousTitre,
    this.hauteur = 220,
    this.rayon = ArzikiRayons.carte,
    this.enfant,
  });
  final String image;
  final String titre;
  final String? sousTitre;
  final double hauteur;
  final double rayon;
  final Widget? enfant;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(rayon),
      child: SizedBox(
        height: hauteur,
        child: Stack(fit: StackFit.expand, children: [
          Illustration(image),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x10000000), Color(0x5514653A), Color(0xE014653A)],
                stops: [0, 0.45, 1],
              ),
            ),
          ),
          Positioned(
            left: ArzikiEspaces.l,
            right: ArzikiEspaces.l,
            bottom: ArzikiEspaces.l,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(titre, style: t.headlineMedium?.copyWith(color: ArzikiCouleurs.blanc)),
                ),
                if (sousTitre != null) ...[
                  const SizedBox(height: ArzikiEspaces.xs),
                  Text(sousTitre!, style: t.bodyMedium?.copyWith(color: ArzikiCouleurs.blanc.withValues(alpha: 0.92))),
                ],
                if (enfant != null) ...[const SizedBox(height: ArzikiEspaces.m), enfant!],
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

/// Titre de section, avec action facultative à droite (« Tout voir »).
class TitreSection extends StatelessWidget {
  const TitreSection(this.titre, {super.key, this.explication, this.action, this.onAction});
  final String titre;
  final String? explication;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: ArzikiEspaces.l, bottom: ArzikiEspaces.s),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Semantics(header: true, child: Text(titre, style: t.titleLarge))),
          if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
        ]),
        if (explication != null) Text(explication!, style: t.bodySmall),
      ]),
    );
  }
}

/// Titre d'écran et sa phrase d'explication (chaque écran en a une).
class EnTetePage extends StatelessWidget {
  const EnTetePage(this.titre, this.explication, {super.key});
  final String titre;
  final String explication;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: ArzikiEspaces.m),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(header: true, child: Text(titre, style: t.headlineMedium)),
        const SizedBox(height: ArzikiEspaces.s),
        Text(explication, style: t.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}

// ===========================================================================
// Cartes et animations
// ===========================================================================

/// Apparition douce (fondu + léger glissement), décalée selon l'ordre.
class Apparition extends StatelessWidget {
  const Apparition({super.key, required this.child, this.ordre = 0});
  final Widget child;
  final int ordre;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + 50 * ordre.clamp(0, 8)),
      curve: Curves.easeOutCubic,
      builder: (context, v, enfant) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: enfant),
      ),
      child: child,
    );
  }
}

/// Carte ARZIKI : coins arrondis 16, ombre douce, retour visuel au toucher.
class CarteArziki extends StatelessWidget {
  const CarteArziki({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(ArzikiEspaces.m),
    this.couleur,
    this.semantique,
  });
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? couleur;
  final String? semantique;

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    final sombre = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: onTap != null,
      label: semantique,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: ArzikiEspaces.s),
        decoration: BoxDecoration(
          color: couleur ?? schema.surface,
          borderRadius: BorderRadius.circular(ArzikiRayons.carte),
          boxShadow: sombre ? null : ombreDouce,
          border: sombre ? Border.all(color: schema.outlineVariant) : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(ArzikiRayons.carte),
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
        ),
      ),
    );
  }
}

/// Carte avec photo en haut (services, opérations, actualités).
class CarteImage extends StatelessWidget {
  const CarteImage({
    super.key,
    required this.image,
    required this.titre,
    this.texte,
    this.badge,
    this.pied,
    this.onTap,
    this.hauteurImage = 150,
  });
  final String image;
  final String titre;
  final String? texte;
  final Widget? badge;
  final Widget? pied;
  final VoidCallback? onTap;
  final double hauteurImage;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return CarteArziki(
      onTap: onTap,
      padding: EdgeInsets.zero,
      semantique: titre,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          Illustration(image, hauteur: hauteurImage),
          if (badge != null) Positioned(top: 12, left: 12, child: badge!),
        ]),
        Padding(
          padding: const EdgeInsets.all(ArzikiEspaces.m),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titre, style: t.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (texte != null) ...[
              const SizedBox(height: ArzikiEspaces.xs),
              Text(texte!, style: t.bodySmall, maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
            if (pied != null) ...[const SizedBox(height: ArzikiEspaces.m), pied!],
          ]),
        ),
      ]),
    );
  }
}

/// Petite carte chiffrée du tableau de bord.
class CarteChiffre extends StatelessWidget {
  const CarteChiffre({super.key, required this.icone, required this.valeur, required this.libelle, this.couleur = ArzikiCouleurs.vert, this.onTap});
  final IconData icone;
  final String valeur;
  final String libelle;
  final Color couleur;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return CarteArziki(
      onTap: onTap,
      semantique: '$libelle : $valeur',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: couleur.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icone, color: couleur, size: 22),
        ),
        const SizedBox(height: ArzikiEspaces.s),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(valeur, style: t.titleLarge),
        ),
        Text(libelle, style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

// ===========================================================================
// Statuts, progression
// ===========================================================================

enum TonBadge { succes, attente, info, alerte, erreur, neutre }

/// Badge de statut coloré.
class BadgeStatut extends StatelessWidget {
  const BadgeStatut(this.texte, {super.key, this.ton = TonBadge.neutre, this.icone});
  final String texte;
  final TonBadge ton;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final (fond, encre) = switch (ton) {
      TonBadge.succes => (const Color(0xFFDDF2E5), ArzikiCouleurs.vertFonce),
      TonBadge.attente => (const Color(0xFFFDF0D2), const Color(0xFF8A5A00)),
      TonBadge.info => (const Color(0xFFE1ECF8), const Color(0xFF1F4F85)),
      TonBadge.alerte => (const Color(0xFFFDE7D2), const Color(0xFF9A4A00)),
      TonBadge.erreur => (const Color(0xFFF8E0DD), ArzikiCouleurs.erreur),
      TonBadge.neutre => (const Color(0xFFE9ECEB), ArzikiCouleurs.texte),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(ArzikiRayons.badge)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icone != null) ...[Icon(icone, size: 14, color: encre), const SizedBox(width: 4)],
        Flexible(child: Text(texte, style: TextStyle(color: encre, fontSize: 12.5, fontWeight: FontWeight.w700))),
      ]),
    );
  }
}

/// Jauge de financement : montant réuni sur montant à réunir.
class JaugeFinancement extends StatelessWidget {
  const JaugeFinancement({super.key, required this.reuni, required this.objectif, this.compacte = false});
  final int reuni;
  final int objectif;
  final bool compacte;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final part = objectif <= 0 ? 0.0 : (reuni / objectif).clamp(0.0, 1.0);
    return Semantics(
      label: 'Financement réuni : ${(part * 100).round()} pour cent',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: part),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: compacte ? 6 : 10,
              backgroundColor: ArzikiCouleurs.vert.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation(ArzikiCouleurs.vert),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: Text('${fcfa(reuni)} réunis', style: t.labelMedium)),
          Text('${(part * 100).round()} %', style: t.labelMedium?.copyWith(color: ArzikiCouleurs.vert)),
        ]),
      ]),
    );
  }
}

/// Frise d'étapes (cycle d'une opération, suivi d'une commande de service).
class FriseEtapes extends StatelessWidget {
  const FriseEtapes({super.key, required this.etapes, required this.courante, this.details = const {}});
  final List<String> etapes;

  /// Index de l'étape en cours (les précédentes sont terminées).
  final int courante;
  final Map<int, String> details;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final schema = Theme.of(context).colorScheme;
    return Column(children: [
      for (var i = 0; i < etapes.length; i++)
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: 32,
              child: Column(children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < courante
                        ? ArzikiCouleurs.vert
                        : i == courante
                            ? ArzikiCouleurs.orange
                            : schema.surfaceContainerLow,
                    border: i > courante ? Border.all(color: schema.outlineVariant, width: 2) : null,
                  ),
                  child: i < courante
                      ? const Icon(Icons.check_rounded, size: 16, color: ArzikiCouleurs.blanc)
                      : i == courante
                          ? const Icon(Icons.more_horiz_rounded, size: 16, color: ArzikiCouleurs.blanc)
                          : null,
                ),
                if (i < etapes.length - 1)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: i < courante ? ArzikiCouleurs.vert : schema.outlineVariant,
                    ),
                  ),
              ]),
            ),
            const SizedBox(width: ArzikiEspaces.s),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: ArzikiEspaces.m, top: 2),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(etapes[i],
                      style: t.titleSmall?.copyWith(
                        color: i > courante ? schema.onSurfaceVariant : null,
                        fontWeight: i == courante ? FontWeight.w700 : FontWeight.w600,
                      )),
                  if (details[i] != null) Text(details[i]!, style: t.bodySmall),
                ]),
              ),
            ),
          ]),
        ),
    ]);
  }
}

/// Avatar avec initiales (ou photo si fournie).
class AvatarArziki extends StatelessWidget {
  const AvatarArziki({super.key, required this.nom, this.taille = 44, this.photo});
  final String nom;
  final double taille;
  final String? photo;

  @override
  Widget build(BuildContext context) {
    final mots = nom.trim().split(RegExp(r'\s+')).where((m) => m.isNotEmpty).toList();
    final initiales = mots.isEmpty
        ? '?'
        : (mots.first[0] + (mots.length > 1 ? mots.last[0] : '')).toUpperCase();
    return Semantics(
      label: 'Photo de profil de $nom',
      child: CircleAvatar(
        radius: taille / 2,
        backgroundColor: ArzikiCouleurs.vert,
        backgroundImage: photo == null ? null : AssetImage(photo!),
        child: photo == null
            ? Text(initiales,
                style: TextStyle(
                  color: ArzikiCouleurs.blanc,
                  fontFamily: ArzikiPolices.titres,
                  fontWeight: FontWeight.w700,
                  fontSize: taille * 0.38,
                ))
            : null,
      ),
    );
  }
}

// ===========================================================================
// Messages, états vides, chargement
// ===========================================================================

/// Encadré d'information (vert), d'alerte (jaune) ou d'erreur (rouge).
enum TypeEncadre { info, alerte, erreur }

class Encadre extends StatelessWidget {
  const Encadre(this.texte, {super.key, this.type = TypeEncadre.info, this.icone, this.titre});
  final String texte;
  final TypeEncadre type;
  final IconData? icone;
  final String? titre;

  @override
  Widget build(BuildContext context) {
    final sombre = Theme.of(context).brightness == Brightness.dark;
    final (couleur, fond, ic) = switch (type) {
      TypeEncadre.info => (
          sombre ? const Color(0xFF6FD39A) : ArzikiCouleurs.vertFonce,
          ArzikiCouleurs.vert.withValues(alpha: sombre ? 0.18 : 0.08),
          Icons.info_outline_rounded
        ),
      TypeEncadre.alerte => (
          sombre ? ArzikiCouleurs.jaune : const Color(0xFF6B4A00),
          ArzikiCouleurs.jaune.withValues(alpha: sombre ? 0.16 : 0.28),
          Icons.warning_amber_rounded
        ),
      TypeEncadre.erreur => (
          sombre ? const Color(0xFFFF8A7A) : ArzikiCouleurs.erreur,
          ArzikiCouleurs.erreur.withValues(alpha: 0.10),
          Icons.error_outline_rounded
        ),
    };
    return Semantics(
      liveRegion: type == TypeEncadre.erreur,
      child: Container(
        padding: const EdgeInsets.all(ArzikiEspaces.m),
        decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(12)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icone ?? ic, color: couleur),
          const SizedBox(width: ArzikiEspaces.m - 4),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (titre != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(titre!, style: TextStyle(color: couleur, fontWeight: FontWeight.w700)),
                ),
              Text(texte, style: TextStyle(color: couleur, height: 1.45)),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Avertissement de risque obligatoire (CLAUDE.md, section 14).
class AvertissementRisque extends StatelessWidget {
  const AvertissementRisque({super.key});

  @override
  Widget build(BuildContext context) => const Encadre(
        TextesLegaux.avertissementRisque,
        type: TypeEncadre.alerte,
        titre: 'Avertissement sur les risques',
      );
}

/// État vide illustré, toujours avec une action proposée.
class EcranVide extends StatelessWidget {
  const EcranVide({
    super.key,
    required this.titre,
    required this.texte,
    this.icone = Icons.inbox_rounded,
    this.image,
    this.action,
    this.onAction,
  });
  final String titre;
  final String texte;
  final IconData icone;
  final String? image;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ArzikiEspaces.l),
      child: Column(children: [
        if (image != null)
          Illustration(image!, hauteur: 140, rayon: ArzikiRayons.carte)
        else
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(color: ArzikiCouleurs.vert.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icone, size: 40, color: ArzikiCouleurs.vert),
          ),
        const SizedBox(height: ArzikiEspaces.m),
        Text(titre, style: t.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: ArzikiEspaces.xs),
        Text(texte, style: t.bodySmall, textAlign: TextAlign.center),
        if (action != null) ...[
          const SizedBox(height: ArzikiEspaces.m),
          FilledButton(onPressed: onAction, child: Text(action!)),
        ],
      ]),
    );
  }
}

/// État d'erreur compréhensible, avec bouton « Réessayer ».
class EcranErreur extends StatelessWidget {
  const EcranErreur({super.key, this.message, required this.onReessayer});
  final String? message;
  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context) => EcranVide(
        icone: Icons.wifi_off_rounded,
        titre: 'Impossible de charger cette page',
        texte: message ?? 'Vérifiez votre connexion Internet, puis réessayez.',
        action: 'Réessayer',
        onAction: onReessayer,
      );
}

/// Squelette de chargement animé (effet « shimmer »), sans bibliothèque externe.
class Squelette extends StatefulWidget {
  const Squelette({super.key, this.hauteur = 16, this.largeur, this.rayon = 8});
  final double hauteur;
  final double? largeur;
  final double rayon;

  @override
  State<Squelette> createState() => _SqueletteState();
}

class _SqueletteState extends State<Squelette> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerLow;
    final reflet = Theme.of(context).colorScheme.surface;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Container(
        height: widget.hauteur,
        width: widget.largeur,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.rayon),
          gradient: LinearGradient(
            begin: Alignment(-1.5 + 3 * _c.value, 0),
            end: Alignment(-0.5 + 3 * _c.value, 0),
            colors: [base, reflet, base],
          ),
        ),
      ),
    );
  }
}

/// Liste de cartes « squelettes » pendant un chargement.
class ListeSquelettes extends StatelessWidget {
  const ListeSquelettes({super.key, this.nombre = 3});
  final int nombre;

  @override
  Widget build(BuildContext context) => Column(children: [
        for (var i = 0; i < nombre; i++)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: ArzikiEspaces.s),
            child: Row(children: [
              Squelette(hauteur: 56, largeur: 56, rayon: 12),
              SizedBox(width: ArzikiEspaces.m),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Squelette(hauteur: 16),
                  SizedBox(height: 8),
                  Squelette(hauteur: 12, largeur: 160),
                ]),
              ),
            ]),
          ),
      ]);
}

/// Boîte de confirmation. Renvoie true si la personne confirme.
Future<bool> confirmer(
  BuildContext context, {
  required String titre,
  required String message,
  String valider = 'Confirmer',
  String annuler = 'Annuler',
  bool danger = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titre),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(annuler)),
        FilledButton(
          style: danger ? FilledButton.styleFrom(backgroundColor: ArzikiCouleurs.erreur) : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(valider),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Affiche un message court en bas de l'écran.
void annoncer(BuildContext context, String message, {bool erreur = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: erreur ? ArzikiCouleurs.erreur : null,
    ));
}

// ===========================================================================
// Formats
// ===========================================================================

/// Formate un montant en FCFA : 6 000 000 FCFA (espaces fines insécables).
String fcfa(int montant) {
  final s = montant.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return '${montant < 0 ? '-' : ''}$b FCFA';
}

/// Formate une date : 31/10/2026.
String dateCourte(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

const _mois = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

/// Formate une date : 31 octobre 2026 (1er pour le premier jour du mois).
String dateLongue(DateTime d) => '${d.day == 1 ? '1er' : d.day} ${_mois[d.month - 1]} ${d.year}';

/// Formate un numéro : +22890000011 devient +228 90 00 00 11.
String telephoneLisible(String? numero) {
  if (numero == null || numero.isEmpty) return '';
  final m = RegExp(r'^\+(\d{3})(\d{8})$').firstMatch(numero.replaceAll(' ', ''));
  if (m == null) return numero;
  final c = m.group(2)!;
  return '+${m.group(1)} ${c.substring(0, 2)} ${c.substring(2, 4)} ${c.substring(4, 6)} ${c.substring(6, 8)}';
}
