// Petits composants réutilisés par tous les écrans.

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../core/textes_legaux.dart';
import '../theme/arziki_theme.dart';

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
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Démonstration : données fictives, aucun paiement réel',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ArzikiCouleurs.texte,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(context: context, removeTop: true, child: child),
        ),
      ],
    );
  }
}

/// Contenu centré, à largeur limitée (lisible sur la console web comme sur téléphone).
class Colonne extends StatelessWidget {
  const Colonne({super.key, required this.children, this.largeurMax = ArzikiEspaces.largeurMax});
  final List<Widget> children;
  final double largeurMax;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: largeurMax),
        child: ListView(
          padding: const EdgeInsets.all(ArzikiEspaces.l),
          children: children,
        ),
      ),
    );
  }
}

/// Logo ARZIKI.
class LogoArziki extends StatelessWidget {
  const LogoArziki({super.key, this.hauteur = 72, this.symboleSeul = false});
  final double hauteur;
  final bool symboleSeul;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      symboleSeul ? 'assets/logo/arziki_symbole.png' : 'assets/logo/arziki_logo.png',
      height: hauteur,
      fit: BoxFit.contain,
      semanticLabel: 'ARZIKI',
    );
  }
}

/// Encadré d'information (vert), d'alerte (jaune) ou d'erreur (rouge).
enum TypeEncadre { info, alerte, erreur }

class Encadre extends StatelessWidget {
  const Encadre(this.texte, {super.key, this.type = TypeEncadre.info, this.icone});
  final String texte;
  final TypeEncadre type;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final (couleur, fond, ic) = switch (type) {
      TypeEncadre.info => (ArzikiCouleurs.vert, ArzikiCouleurs.vert.withValues(alpha: 0.08), Icons.info_outline),
      TypeEncadre.alerte => (ArzikiCouleurs.texte, ArzikiCouleurs.jaune.withValues(alpha: 0.35), Icons.warning_amber),
      TypeEncadre.erreur => (ArzikiCouleurs.erreur, ArzikiCouleurs.erreur.withValues(alpha: 0.08), Icons.error_outline),
    };
    return Container(
      padding: const EdgeInsets.all(ArzikiEspaces.m),
      decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone ?? ic, color: couleur),
          const SizedBox(width: ArzikiEspaces.s),
          Expanded(child: Text(texte, style: TextStyle(color: couleur == ArzikiCouleurs.texte ? null : couleur))),
        ],
      ),
    );
  }
}

/// Avertissement de risque obligatoire (CLAUDE.md, section 14).
class AvertissementRisque extends StatelessWidget {
  const AvertissementRisque({super.key});

  @override
  Widget build(BuildContext context) =>
      const Encadre(TextesLegaux.avertissementRisque, type: TypeEncadre.alerte);
}

/// Affiche un message court en bas de l'écran.
void annoncer(BuildContext context, String message, {bool erreur = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: erreur ? ArzikiCouleurs.erreur : null,
  ));
}

/// Formate un montant en FCFA : 1 500 000 FCFA (espaces insécables).
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
