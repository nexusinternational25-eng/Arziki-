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

  /// Jaune : mises en avant, badges, bandeau de démonstration.
  static const Color jaune = Color(0xFFF7C51E);

  /// Blanc : fonds.
  static const Color blanc = Color(0xFFFFFFFF);

  /// Gris foncé : textes.
  static const Color texte = Color(0xFF1D2733);

  /// Rouge : erreurs.
  static const Color erreur = Color(0xFFC0392B);

  /// Gris clair pour les bordures et les fonds de cartes (dérivé du texte).
  static const Color bordure = Color(0x221D2733);
  static const Color fondCarte = Color(0xFFF6F7F8);
  static const Color texteSecondaire = Color(0xB31D2733);
}

/// Espacements standards, pour garder des écrans réguliers.
class ArzikiEspaces {
  ArzikiEspaces._();

  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;

  /// Largeur maximale du contenu sur grand écran (console web).
  static const double largeurMax = 560;
}

/// Polices intégrées à l'application (assets/fonts, déclarées dans pubspec.yaml) :
/// aucune police n'est téléchargée au démarrage, ce qui compte en 3G.
class ArzikiPolices {
  ArzikiPolices._();

  static const String titres = 'Poppins';
  static const String texte = 'Inter';
}

class ArzikiTheme {
  ArzikiTheme._();

  static const double _rayon = 12;

  static ThemeData get clair {
    final schema = ColorScheme.fromSeed(
      seedColor: ArzikiCouleurs.vert,
      primary: ArzikiCouleurs.orange,
      onPrimary: ArzikiCouleurs.blanc,
      secondary: ArzikiCouleurs.vert,
      onSecondary: ArzikiCouleurs.blanc,
      tertiary: ArzikiCouleurs.jaune,
      onTertiary: ArzikiCouleurs.texte,
      error: ArzikiCouleurs.erreur,
      onError: ArzikiCouleurs.blanc,
      surface: ArzikiCouleurs.blanc,
      onSurface: ArzikiCouleurs.texte,
    );

    // Tailles généreuses : texte de base à 16.
    const textes = TextTheme(
      headlineMedium: TextStyle(
        fontFamily: ArzikiPolices.titres,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: ArzikiCouleurs.texte,
      ),
      titleLarge: TextStyle(
        fontFamily: ArzikiPolices.titres,
        fontSize: 21,
        fontWeight: FontWeight.w600,
        color: ArzikiCouleurs.texte,
      ),
      titleMedium: TextStyle(
        fontFamily: ArzikiPolices.titres,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: ArzikiCouleurs.texte,
      ),
      bodyLarge: TextStyle(fontFamily: ArzikiPolices.texte, fontSize: 16, height: 1.4),
      bodyMedium: TextStyle(fontFamily: ArzikiPolices.texte, fontSize: 16, height: 1.4),
      bodySmall: TextStyle(fontFamily: ArzikiPolices.texte, fontSize: 14, height: 1.4),
      labelLarge: TextStyle(fontFamily: ArzikiPolices.texte, fontSize: 16, fontWeight: FontWeight.w600),
    );

    final formeBouton = RoundedRectangleBorder(borderRadius: BorderRadius.circular(_rayon));

    return ThemeData(
      useMaterial3: true,
      fontFamily: ArzikiPolices.texte,
      colorScheme: schema,
      scaffoldBackgroundColor: ArzikiCouleurs.blanc,
      textTheme: textes,
      appBarTheme: const AppBarTheme(
        backgroundColor: ArzikiCouleurs.vert,
        foregroundColor: ArzikiCouleurs.blanc,
        centerTitle: false,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ArzikiCouleurs.orange,
          foregroundColor: ArzikiCouleurs.blanc,
          minimumSize: const Size.fromHeight(52),
          shape: formeBouton,
          textStyle: textes.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ArzikiCouleurs.vert,
          side: const BorderSide(color: ArzikiCouleurs.vert, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          shape: formeBouton,
          textStyle: textes.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: ArzikiCouleurs.vert),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ArzikiCouleurs.fondCarte,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(_rayon)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_rayon),
          borderSide: const BorderSide(color: ArzikiCouleurs.bordure),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_rayon),
          borderSide: const BorderSide(color: ArzikiCouleurs.vert, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: ArzikiCouleurs.fondCarte,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_rayon),
          side: const BorderSide(color: ArzikiCouleurs.bordure),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: ArzikiCouleurs.jaune,
        labelStyle: TextStyle(fontFamily: ArzikiPolices.texte, color: ArzikiCouleurs.texte, fontWeight: FontWeight.w600),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
