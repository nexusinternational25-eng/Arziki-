// Banque d'images ARZIKI (assets/images). Photos générées pour ARZIKI,
// sans logo ni texte lisible, et sans drapeau (décision du propriétaire).
// Liste et prompts : document « ARZIKI, logos et banque d'images ».

class Images {
  Images._();

  static const _d = 'assets/images';

  // Accueil et présentation (portrait)
  static const commercante = '$_d/accueil_commercante.jpg';
  static const entrepreneurEntrepot = '$_d/accueil_entrepreneur_entrepot.jpg';
  static const livraisonChantier = '$_d/accueil_livraison_chantier.jpg';
  static const pharmacie = '$_d/accueil_pharmacie.jpg';
  static const fournisseurPme = '$_d/accueil_fournisseur_pme.jpg';
  static const dirigeanteSignature = '$_d/accueil_dirigeante_signature.jpg';

  // Fiches d'opération (paysage)
  static const opPharmacie = '$_d/operation_pharmacie.jpg';
  static const opBtp = '$_d/operation_btp.jpg';
  static const opCereales = '$_d/operation_cereales.jpg';
  static const opIntrants = '$_d/operation_intrants_agricoles.jpg';
  static const opBureau = '$_d/operation_equipements_bureau.jpg';
  static const opFlotte = '$_d/operation_flotte_logistique.jpg';

  // Le Cercle
  static const cercleApplication = '$_d/cercle_application.jpg';
  static const cercleNotaire = '$_d/cercle_notaire.jpg';
  static const cercleDossier = '$_d/cercle_transmission_dossier.jpg';
  static const cercleDiaspora = '$_d/cercle_diaspora.jpg';

  // Services
  static const servicesConseil = '$_d/services_conseil.jpg';
  static const servicesAnalyse = '$_d/services_analyse.jpg';
  static const servicesCamions = '$_d/services_parc_camions.jpg';

  // Ambiance
  static const marche = '$_d/ambiance_marche.jpg';
  static const zemidjan = '$_d/ambiance_zemidjan.jpg';
  static const equipe = '$_d/ambiance_equipe.jpg';
  static const coucherSoleil = '$_d/ambiance_coucher_soleil.jpg';

  // Partenariats
  static const convoi = '$_d/partenariat_convoi.jpg';
  static const equipementIndustriel = '$_d/partenariat_equipement.jpg';
  static const reunionInvestisseurs = '$_d/partenariat_reunion_investisseurs.jpg';
  static const port = '$_d/partenariat_port.jpg';

  static const toutes = [
    commercante, entrepreneurEntrepot, livraisonChantier, pharmacie, fournisseurPme, dirigeanteSignature,
    opPharmacie, opBtp, opCereales, opIntrants, opBureau, opFlotte,
    cercleApplication, cercleNotaire, cercleDossier, cercleDiaspora,
    servicesConseil, servicesAnalyse, servicesCamions,
    marche, zemidjan, equipe, coucherSoleil,
    convoi, equipementIndustriel, reunionInvestisseurs, port,
  ];
}
