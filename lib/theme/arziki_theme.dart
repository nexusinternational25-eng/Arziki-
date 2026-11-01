// Thème ARZIKI : toutes les couleurs, tailles et styles de l'application.
// Règle : aucune couleur ne doit être écrite ailleurs que dans ce fichier.

import 'package:flutter/material.dart';

/// Couleurs de la charte ARZIKI (CLAUDE.md, section 4).
class ArzikiCouleurs {
  ArzikiCouleurs._();

  /// Orange : actions principales (boutons).
  static const Color orange = Color(0xFFF28C28);

  /// Vert : succès, confiance, en-têtes.
  static const Color vert = Color(0xFF1E8E4E);

  /// Vert foncé : dégradés des en-têtes.
  static const Color vertFonce = Color(0xFF14653A);

  /// Jaune : mises en avant, badges, bandeau de démonstration.
  static const Color jaune = Color(0xFFF7C51E);

  /// Blanc : fonds.
  static const Color blanc = Color(0xFFFFFFFF);

  /// Gris clair : fonds de page et de cartes secondaires.
  static const Color grisClair = Color(0xFFF5F7F6);

  /// Gris foncé : textes.
  static const Color texte = Color(0xFF1D2733);

  /// Rouge : erreurs.
  static const Color erreur = Color(0xFFC0392B);

  /// Bleu discret : informations neutres (statuts « en cours »).
  static const Color info = Color(0xFF2F6FB5);

  /// Teintes dérivées.
  static const Color bordure = Color(0x1F1D2733);
  static const Color fondCarte = grisClair;
  static const Color texteSecondaire = Color(0xB31D2733);
  static const Color ombre = Color(0x141D2733);

  /// Mode sombre.
  static const Color fondSombre = Color(0xFF111815);
  static const Color carteSombre = Color(0xFF1B2420);
  static const Color texteSombre = Color(0xFFE9EEEB);
}

/// Espacements standards (multiples de 8), pour des écrans réguliers.
class ArzikiEspaces {
  ArzikiEspaces._();

  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Largeur maximale du contenu sur grand écran (tablette, web).
  static const double largeurMax = 640;

  /// Zone tactile minimale (accessibilité).
  static const double toucheMin = 48;
}

/// Rayons des coins arrondis.
class ArzikiRayons {
  ArzikiRayons._();

  static const double carte = 16;
  static const double bouton = 12;
  static const double badge = 20;
}

/// Polices intégrées à l'application (assets/fonts, déclarées dans pubspec.yaml) :
/// aucune police n'est téléchargée au démarrage, ce qui compte en 3G.
class ArzikiPolices {
  ArzikiPolices._();

  static const String titres = 'Poppins';
  static const String texte = 'Inter';
}

/// Ombre douce des cartes.
const List<BoxShadow> ombreDouce = [
  BoxShadow(color: ArzikiCouleurs.ombre, blurRadius: 16, offset: Offset(0, 4)),
];

class ArzikiTheme {
  ArzikiTheme._();

  /// Échelle typographique : titre, sous-titre, corps (16), légende.
  static TextTheme _textes(Color couleur, Color secondaire) => TextTheme(
        displaySmall: TextStyle(
            fontFamily: ArzikiPolices.titres, fontSize: 30, fontWeight: FontWeight.w700, color: couleur, height: 1.2),
        headlineMedium: TextStyle(
            fontFamily: ArzikiPolices.titres, fontSize: 24, fontWeight: FontWeight.w700, color: couleur, height: 1.25),
        headlineSmall: TextStyle(
            fontFamily: ArzikiPolices.titres, fontSize: 21, fontWeight: FontWeight.w600, color: couleur, height: 1.3),
        titleLarge: TextStyle(
            fontFamily: ArzikiPolices.titres, fontSize: 19, fontWeight: FontWeight.w600, color: couleur, height: 1.3),
        titleMedium: TextStyle(
            fontFamily: ArzikiPolices.titres, fontSize: 16, fontWeight: FontWeight.w600, color: couleur, height: 1.35),
        titleSmall: TextStyle(fontFamily: ArzikiPolices.texte, fontSize: 15, fontWeight: FontWeight.w600, color: couleur),
        bodyLarge: TextStyle(fontFamily: ArzikiPolices.texte, fontSize: 16, height: 1.5, color: couleur),
        bodyMedium: TextStyle(fontFamily: ArzikiPolices.texte, fontSize: 16, height: 1.5, color: couleur),
        bodySmall: TextStyle(fontFamily: ArzikiPolices.texte, fontSize: 14, height: 1.45, color: secondaire),
        labelLarge: const TextStyle(fontFamily: ArzikiPolices.texte, fontSize: 16, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontFamily: ArzikiPolices.texte, fontSize: 13, fontWeight: FontWeight.w600, color: secondaire),
        labelSmall: TextStyle(fontFamily: ArzikiPolices.texte, fontSize: 12, fontWeight: FontWeight.w600, color: secondaire),
      );

  static ThemeData get clair => _construire(Brightness.light);
  static ThemeData get sombre => _construire(Brightness.dark);

  static ThemeData _construire(Brightness luminosite) {
    final sombre = luminosite == Brightness.dark;
    final fond = sombre ? ArzikiCouleurs.fondSombre : ArzikiCouleurs.blanc;
    final carte = sombre ? ArzikiCouleurs.carteSombre : ArzikiCouleurs.blanc;
    final texte = sombre ? ArzikiCouleurs.texteSombre : ArzikiCouleurs.texte;
    final secondaire = sombre ? const Color(0xB3E9EEEB) : ArzikiCouleurs.texteSecondaire;
    final grisFond = sombre ? const Color(0xFF16201C) : ArzikiCouleurs.grisClair;

    final schema = ColorScheme.fromSeed(
      seedColor: ArzikiCouleurs.vert,
      brightness: luminosite,
      primary: ArzikiCouleurs.orange,
      onPrimary: ArzikiCouleurs.blanc,
      secondary: ArzikiCouleurs.vert,
      onSecondary: ArzikiCouleurs.blanc,
      tertiary: ArzikiCouleurs.jaune,
      onTertiary: ArzikiCouleurs.texte,
      error: ArzikiCouleurs.erreur,
      onError: ArzikiCouleurs.blanc,
      surface: carte,
      onSurface: texte,
      onSurfaceVariant: secondaire,
      surfaceContainerLowest: fond,
      surfaceContainerLow: grisFond,
      surfaceContainer: grisFond,
      outlineVariant: sombre ? const Color(0x33E9EEEB) : ArzikiCouleurs.bordure,
    );
    final textes = _textes(texte, secondaire);
    final formeBouton = RoundedRectangleBorder(borderRadius: BorderRadius.circular(ArzikiRayons.bouton));

    return ThemeData(
      useMaterial3: true,
      brightness: luminosite,
      colorScheme: schema,
      fontFamily: ArzikiPolices.texte,
      scaffoldBackgroundColor: fond,
      textTheme: textes,
      // Transitions de pages sobres, identiques sur Android et sur le web.
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
      }),
      appBarTheme: AppBarTheme(
        backgroundColor: fond,
        foregroundColor: texte,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: textes.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ArzikiCouleurs.orange,
          foregroundColor: ArzikiCouleurs.blanc,
          minimumSize: const Size(ArzikiEspaces.toucheMin, 52),
          padding: const EdgeInsets.symmetric(horizontal: ArzikiEspaces.l),
          shape: formeBouton,
          textStyle: textes.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ArzikiCouleurs.vert,
          side: const BorderSide(color: ArzikiCouleurs.vert, width: 1.5),
          minimumSize: const Size(ArzikiEspaces.toucheMin, 52),
          padding: const EdgeInsets.symmetric(horizontal: ArzikiEspaces.l),
          shape: formeBouton,
          textStyle: textes.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: sombre ? const Color(0xFF6FD39A) : ArzikiCouleurs.vert,
          minimumSize: const Size(ArzikiEspaces.toucheMin, ArzikiEspaces.toucheMin),
          textStyle: textes.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: grisFond,
        contentPadding: const EdgeInsets.symmetric(horizontal: ArzikiEspaces.m, vertical: 16),
        helperMaxLines: 3,
        errorMaxLines: 3,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(ArzikiRayons.bouton)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ArzikiRayons.bouton),
          borderSide: BorderSide(color: schema.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ArzikiRayons.bouton),
          borderSide: const BorderSide(color: ArzikiCouleurs.vert, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ArzikiRayons.bouton),
          borderSide: const BorderSide(color: ArzikiCouleurs.erreur, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: carte,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: ArzikiEspaces.s),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ArzikiRayons.carte),
          side: BorderSide(color: schema.outlineVariant),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: grisFond,
        selectedColor: ArzikiCouleurs.vert.withValues(alpha: 0.15),
        labelStyle: TextStyle(fontFamily: ArzikiPolices.texte, color: texte, fontWeight: FontWeight.w600),
        side: BorderSide(color: schema.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ArzikiRayons.badge)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: carte,
        surfaceTintColor: Colors.transparent,
        indicatorColor: ArzikiCouleurs.vert.withValues(alpha: 0.14),
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((etats) => TextStyle(
              fontFamily: ArzikiPolices.texte,
              fontSize: 12,
              fontWeight: etats.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: etats.contains(WidgetState.selected) ? (sombre ? const Color(0xFF6FD39A) : ArzikiCouleurs.vert) : secondaire,
            )),
        iconTheme: WidgetStateProperty.resolveWith((etats) => IconThemeData(
              color: etats.contains(WidgetState.selected) ? (sombre ? const Color(0xFF6FD39A) : ArzikiCouleurs.vert) : secondaire,
            )),
      ),
      drawerTheme: DrawerThemeData(backgroundColor: carte, surfaceTintColor: Colors.transparent),
      dividerTheme: DividerThemeData(color: schema.outlineVariant, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: sombre ? const Color(0xFF6FD39A) : ArzikiCouleurs.vert,
        titleTextStyle: textes.titleSmall,
        subtitleTextStyle: textes.bodySmall,
        minVerticalPadding: 12,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: ArzikiCouleurs.vert,
        collapsedIconColor: secondaire,
        shape: const Border(),
        collapsedShape: const Border(),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      dialogTheme: DialogThemeData(
        backgroundColor: carte,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ArzikiRayons.carte)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: carte,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: ArzikiCouleurs.vert),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (e) => e.contains(WidgetState.selected) ? ArzikiCouleurs.blanc : null),
        trackColor: WidgetStateProperty.resolveWith(
            (e) => e.contains(WidgetState.selected) ? ArzikiCouleurs.vert : null),
      ),
    );
  }
}
