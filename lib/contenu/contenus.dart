// Contenus éditoriaux d'ARZIKI : pages d'information, FAQ, actualités, contacts.
// Tous ces textes sont modifiables depuis la console d'administration
// (page « Contenus ») ; chaque modification est inscrite au journal d'audit.
// Les textes légaux sont rédigés et publiés en version 1.0 (décision du propriétaire).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session.dart';
import '../core/images.dart';
import '../core/textes_legaux.dart';

class SectionContenu {
  const SectionContenu(this.titre, this.texte);
  final String titre;
  final String texte;
}

class PageContenu {
  const PageContenu({
    required this.id,
    required this.titre,
    required this.intro,
    required this.sections,
    this.image,
    this.version,
    this.majLe,
  });
  final String id;
  final String titre;
  final String intro;
  final List<SectionContenu> sections;
  final String? image;
  final String? version;
  final DateTime? majLe;

  PageContenu copier({String? titre, String? intro, List<SectionContenu>? sections, DateTime? majLe}) => PageContenu(
        id: id,
        titre: titre ?? this.titre,
        intro: intro ?? this.intro,
        sections: sections ?? this.sections,
        image: image,
        version: version,
        majLe: majLe ?? this.majLe,
      );
}

enum CategorieFaq {
  entreprises('Entreprises'),
  /// Questions réservées aux partenaires financiers connectés (section 24.2).
  membres('Partenaires financiers'),
  fournisseurs('Fournisseurs'),
  paiements('Paiements'),
  securite('Sécurité');

  const CategorieFaq(this.libelle);
  final String libelle;
}

class QuestionFaq {
  const QuestionFaq(this.categorie, this.question, this.reponse);
  final CategorieFaq categorie;
  final String question;
  final String reponse;
}

class Actualite {
  const Actualite({required this.id, required this.titre, required this.texte, required this.image, required this.date});
  final String id;
  final String titre;
  final String texte;
  final String image;
  final DateTime date;
}

/// Coordonnées de contact (modifiables depuis la console).
class Contacts {
  const Contacts({
    this.whatsapp = '+228 91 97 80 80',
    this.telephone = '+228 91 97 80 80',
    this.email = 'operation@amanexus.com',
    this.adresse = '18 rue Léopold Sédar Senghor, Tokoin Wuiti, Lomé, Togo',
    this.horaires = 'Du lundi au vendredi, de 8 h à 17 h 30 ; le samedi, de 9 h à 13 h',
  });
  final String whatsapp;
  final String telephone;
  final String email;
  final String adresse;
  final String horaires;

  /// Numéro au format international sans espaces, pour WhatsApp et les appels.
  String get whatsappChiffres => whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
  String get telephoneChiffres => telephone.replaceAll(RegExp(r'[^0-9+]'), '');
}

/// Identifiants des pages.
class PagesId {
  PagesId._();
  static const aPropos = 'a-propos';
  static const commentCaMarche = 'comment-ca-marche';
  static const cercle = 'le-cercle';
  static const securite = 'securite';
  static const aide = 'aide';
  static const cgu = 'conditions';
  static const cguPartenaires = 'conditions-partenaires';
  static const confidentialite = 'confidentialite';
  static const risques = 'risques';
  static const mentions = 'mentions-legales';
}

final _dateVersion = DateTime(2026, 11, 21);

final Map<String, PageContenu> pagesParDefaut = {
  PagesId.aPropos: const PageContenu(
    id: PagesId.aPropos,
    titre: "À propos d'ARZIKI",
    image: Images.reunionInvestisseurs,
    intro: 'ARZIKI signifie « prospérité » en haoussa. Notre mission : aider les entreprises à honorer leurs '
        'commandes fermes et à préparer des dossiers solides, avec des contrats passés devant notaire.',
    sections: [
      SectionContenu('Notre mission',
          "Trop d'entreprises perdent une commande ferme faute de trésorerie pour acheter la marchandise. "
              "ARZIKI vérifie la commande, met l'entreprise en relation avec des partenaires qui achètent la "
              "marchandise pour elle, et suit l'opération jusqu'à l'échéance. ARZIKI prépare aussi des dossiers "
              'clés en main, des business plans et des états financiers.'),
      SectionContenu('Ce que fait ARZIKI, et ce qu\'il ne fait pas',
          'ARZIKI est un intermédiaire : il met en relation et perçoit une commission. Il ne fait ni crédit ni '
              "collecte d'épargne, n'achète ni ne vend lui-même la marchandise, et ne détient jamais l'argent des "
              'opérations : les fonds vont directement au fournisseur ou sur le compte séquestre du notaire.'),
      SectionContenu('Nos valeurs',
          "Transparence : l'entreprise connaît dès le départ le prix d'achat, le prix de revente et l'échéance.\n"
              'Rigueur : chaque client final et chaque commande sont vérifiés par notre équipe avant toute décision.\n'
              'Respect : des engagements écrits, des contrats passés devant notaire, une relation de long terme.'),
      SectionContenu('La direction',
          'ARZIKI est dirigée par le CEO de NEXUS International, conseiller en investissement certifié USAID '
              'CATALYZE Sahel et certifié par le CESAG de Dakar en diagnostic économique et financier de '
              "l'entreprise. Il a accompagné des financements validés de 30 M USD et de 160 M USD, et mobilisé "
              "plusieurs centaines de millions de FCFA pour plus d'une centaine d'entreprises agricoles et "
              'agroalimentaires dans le cadre du programme USAID CATALYZE.'),
      SectionContenu('Une offre de NEXUS International',
          "ARZIKI est édité par NEXUS International, cabinet d'affaires basé à Lomé. "
              'Adresse : 18 rue Léopold Sédar Senghor, Tokoin Wuiti, Lomé, Togo.'),
    ],
  ),
  PagesId.commentCaMarche: const PageContenu(
    id: PagesId.commentCaMarche,
    titre: 'Comment ça marche',
    image: Images.livraisonChantier,
    intro: "La commande financée en cinq étapes : de votre bon de commande jusqu'au paiement à l'échéance.",
    sections: [
      SectionContenu('1. Vous soumettez votre commande',
          "Vous avez une commande ferme d'un client identifié. Vous la soumettez dans l'application avec le bon "
              'de commande ou le marché, le devis du fournisseur, le montant, le délai et les garanties que vous proposez.'),
      SectionContenu('2. ARZIKI analyse',
          'Notre équipe contacte directement votre client, vérifie le fournisseur et les prix, rencontre le '
              'dirigeant et vous indique les garanties adaptées au montant.'),
      SectionContenu('3. Vente à terme',
          'Si le dossier est retenu, un partenaire achète la marchandise au fournisseur, puis vous la revend '
              "avec une majoration fixe en FCFA, convenue à l'avance et payable à une échéance précise. Vous "
              'connaissez le prix de revente avant de signer.'),
      SectionContenu('4. Contrats passés devant notaire',
          'La vente à terme et les garanties sont signées devant notaire. Le fournisseur est payé directement : '
              "l'argent ne passe jamais par ARZIKI."),
      SectionContenu("5. Livraison et paiement à l'échéance",
          "Vous recevez la marchandise, vous livrez votre client, puis vous réglez le prix de revente à l'échéance. "
              "Chaque étape est suivie dans l'application."),
      SectionContenu('Le rôle de chacun',
          "L'entreprise réalise la commande et règle à l'échéance. Le fournisseur livre. Le partenaire achète la "
              'marchandise et la revend à terme. Le notaire reçoit les actes et les fonds en séquestre. ARZIKI '
              'vérifie, met en relation et suit le dossier, contre une commission.'),
    ],
  ),
  // Page réservée aux partenaires financiers connectés (section 24.2) : jamais affichée aux visiteurs.
  PagesId.cercle: const PageContenu(
    id: PagesId.cercle,
    titre: 'Espace partenaires financiers',
    image: Images.cercleDiaspora,
    intro: "Un cercle privé, sur invitation nominative de l'administrateur. Chaque partenaire est partie à un "
        'contrat précis, opération par opération.',
    sections: [
      SectionContenu('Votre rôle',
          'Sur chaque opération qui vous est proposée, vous pouvez acheter tout ou partie de la marchandise au '
              "fournisseur, puis la revendre à l'entreprise avec une majoration fixe, payable à l'échéance."),
      SectionContenu("La manifestation d'intérêt n'engage pas",
          "Le bouton « Je suis intéressé » n'engage à rien. Seule la signature devant notaire vous engage."),
      SectionContenu('Les règles',
          "L'application ne détient jamais votre argent : les fonds vont au fournisseur ou sur le compte séquestre "
              "du notaire. Votre identité et l'origine de vos fonds sont vérifiées avant tout accès. Aucun paiement "
              'en espèces. Le cercle reste limité en nombre de partenaires.'),
      SectionContenu('Les risques',
          'Toute participation comporte un risque de perte : retard ou défaut de paiement, litige, mise en œuvre '
              'des garanties. Ne vous engagez qu\'avec des sommes dont vous n\'avez pas besoin à court terme.'),
    ],
  ),
  PagesId.securite: const PageContenu(
    id: PagesId.securite,
    titre: 'Sécurité et notaire',
    image: Images.cercleNotaire,
    intro: 'Chaque opération fait l\'objet de contrats passés devant notaire, avec des garanties adaptées au '
        "montant. L'argent des opérations ne transite jamais par l'application.",
    sections: [
      SectionContenu('Les vérifications',
          'Avant toute décision, notre équipe vérifie que le client final existe, confirme le bon de commande '
              'directement avec lui, contrôle le fournisseur et ses prix, rencontre le dirigeant et attribue une '
              'note de risque.'),
      SectionContenu('Les garanties possibles',
          'Réserve de propriété sur la marchandise, nantissement de la créance sur votre client, cautionnement, '
              'hypothèque, nantissement de matériel ou du fonds de commerce. Chacune est signée devant notaire et, '
              'si besoin, inscrite au RCCM.'),
      SectionContenu('Le rôle du notaire',
          'Le notaire reçoit les actes signés, conserve les fonds sur son compte séquestre quand il y en a, et '
              'confirme le paiement au fournisseur.'),
      SectionContenu('Protection de vos données',
          "Vos pièces d'identité sont stockées dans un espace privé, jamais par un lien public, et ne sont "
              "visibles que par vous et l'équipe de vérification. Les administrateurs se connectent avec une double "
              'vérification. Toute action sensible est inscrite dans un journal qui ne peut pas être modifié.'),
    ],
  ),
  PagesId.aide: const PageContenu(
    id: PagesId.aide,
    titre: "Centre d'aide",
    image: Images.equipe,
    intro: 'Des guides pas à pas, et une équipe joignable par WhatsApp, téléphone ou e-mail.',
    sections: [
      SectionContenu('Créer mon compte',
          "1. Ouvrez l'application et choisissez votre profil.\n2. Saisissez votre numéro de téléphone et acceptez "
              "les conditions.\n3. Vérifiez votre numéro par WhatsApp (ou par SMS).\n4. Envoyez vos pièces d'identité.\n5. Attendez la "
              'validation : vous recevez une notification.'),
      SectionContenu('Soumettre une commande à financer',
          '1. Touchez le bouton orange « Nouvelle demande ».\n2. Renseignez le client final, la commande, le '
              'fournisseur, le montant et le délai.\n3. Joignez le bon de commande et le devis.\n4. Indiquez les '
              'garanties que vous proposez, vérifiez le récapitulatif et envoyez.'),
      SectionContenu('Commander un service',
          "1. Ouvrez l'onglet Services.\n2. Choisissez une offre et décrivez votre besoin.\n3. Recevez le devis, "
              "réglez l'acompte de 50 %.\n4. Suivez l'avancement et téléchargez votre livrable."),
    ],
  ),
  PagesId.cgu: PageContenu(
    id: PagesId.cgu,
    titre: "Conditions d'utilisation : entreprises",
    version: TextesLegaux.versionConditions,
    majLe: _dateVersion,
    intro: "Les présentes conditions générales d'utilisation (les « Conditions ») s'appliquent aux entreprises qui "
        "utilisent l'application ARZIKI et son site. En créant un compte, vous les acceptez sans réserve.",
    sections: const [
      SectionContenu('1. Éditeur',
          'ARZIKI est éditée par NEXUS International, RCCM TG-LFW-01-2025-A10-03200, dont le siège est situé '
              '18 rue Léopold Sédar Senghor, Tokoin Wuiti, Lomé, Togo (« NEXUS International » ou « ARZIKI »).'),
      SectionContenu('2. Objet du service',
          "ARZIKI aide les entreprises titulaires d'une commande ferme à en financer l'achat par une vente à terme : "
              'un partenaire achète la marchandise au fournisseur et la revend à l\'entreprise avec une majoration fixe, '
              'payable à une échéance convenue. ARZIKI vend aussi des services : dossiers clés en main, business plans, '
              "états financiers, formation, recherche d'arrangeurs."),
      SectionContenu("3. Rôle d'ARZIKI",
          'ARZIKI est un intermédiaire (courtier) : il vérifie les dossiers, met en relation et perçoit une '
              "commission. Il ne fait ni crédit ni collecte d'épargne, n'achète ni ne vend la marchandise, et ne "
              "détient jamais l'argent des opérations. Chaque opération fait l'objet de contrats passés devant notaire."),
      SectionContenu('4. Inscription et compte',
          "Le compte est réservé aux entreprises régulièrement immatriculées. Il n'est actif qu'après vérification "
              "du RCCM, du NIF, de la pièce d'identité du dirigeant et du bénéficiaire effectif. Le compte est personnel : "
              'vous êtes responsable de la confidentialité de vos codes.'),
      SectionContenu('5. Soumission d\'une commande',
          "L'entreprise fournit des informations exactes et des pièces authentiques : bon de commande ou marché, devis "
              'du fournisseur, coordonnées du client final. ARZIKI peut contacter directement le client final et le '
              'fournisseur. Une demande peut être refusée sans que le refus ouvre droit à indemnité.'),
      SectionContenu('6. Vente à terme',
          "Le prix d'achat, la majoration, le prix de revente et l'échéance sont fixés par écrit avant toute signature. "
              "L'entreprise devient propriétaire de la marchandise selon les termes du contrat (réserve de propriété le cas "
              "échéant) et règle le prix de revente à l'échéance. Seule la signature devant notaire engage les parties."),
      SectionContenu('7. Garanties',
          "Selon le montant, l'entreprise peut avoir à constituer une réserve de propriété, un nantissement de la "
              'créance sur son client, un cautionnement, une hypothèque ou un nantissement de matériel ou de fonds de '
              'commerce, signés devant notaire et inscrits au RCCM si nécessaire.'),
      SectionContenu('8. Retard et recouvrement',
          "En cas de retard de paiement à l'échéance, l'opération passe en retard puis, si besoin, en recouvrement. "
              'Les garanties peuvent alors être mises en œuvre selon les contrats signés.'),
      SectionContenu('9. Services payants',
          'Les frais de service et les commissions sont payés par mobile money ou carte bancaire, via un agrégateur '
              "de paiement agréé, jamais en espèces. L'acompte de 50 % et le solde ne sont plus remboursables une fois "
              'le travail commencé. Une facture est émise pour chaque paiement.'),
      SectionContenu('10. Signature électronique',
          "La validation dans l'application (case à cocher, code PIN, horodatage) complète les actes passés devant "
              'notaire ; elle ne les remplace pas.'),
      SectionContenu('11. Responsabilité',
          "ARZIKI met en œuvre les moyens raisonnables pour vérifier les dossiers. Il n'est pas partie aux ventes et "
              "ne répond pas de l'exécution des contrats par les parties."),
      SectionContenu('12. Suspension et clôture',
          'ARZIKI peut suspendre un compte en cas de fausse déclaration, de pièce falsifiée ou de soupçon de '
              'blanchiment. Les documents sont conservés dix ans.'),
      SectionContenu('13. Modification des Conditions',
          "Toute modification est notifiée dans l'application avec un nouveau numéro de version, que vous acceptez "
              'de nouveau.'),
      SectionContenu('14. Droit applicable et litiges',
          'Les Conditions sont régies par le droit togolais et les Actes uniformes OHADA. À défaut de règlement '
              'amiable, les tribunaux de Lomé sont compétents.'),
      SectionContenu('15. Contact',
          'NEXUS International, nexusinternational25@gmail.com (copie : operation@amanexus.com), +228 91 97 80 80.'),
    ],
  ),
  // Réservées aux partenaires financiers invités (section 24.2) : jamais affichées aux visiteurs.
  PagesId.cguPartenaires: PageContenu(
    id: PagesId.cguPartenaires,
    titre: "Conditions d'utilisation : partenaires financiers",
    version: TextesLegaux.versionConditions,
    majLe: _dateVersion,
    intro: "Ces conditions s'appliquent aux partenaires financiers invités par ARZIKI. Elles complètent les "
        'contrats signés devant notaire pour chaque opération.',
    sections: const [
      SectionContenu('1. Accès sur invitation',
          "L'espace partenaires est accessible uniquement sur invitation nominative de l'administrateur. Le nombre "
              "de partenaires est limité. Aucune opération n'est visible avant la validation de votre identité, de "
              "votre domicile, de l'origine de vos fonds et de votre déclaration de personne politiquement exposée."),
      SectionContenu('2. Nature des opérations',
          'Chaque opération est une vente à terme : vous achetez tout ou partie de la marchandise au fournisseur, puis '
              "vous la revendez à l'entreprise avec une majoration fixe, payable à l'échéance. ARZIKI ne fait ni crédit "
              "ni collecte d'épargne et n'émet aucun titre : vous êtes partie à un contrat précis, opération par "
              'opération.'),
      SectionContenu("3. Manifestation d'intérêt",
          "Le bouton « Je suis intéressé » n'engage ni vous ni ARZIKI. Seule la signature devant notaire vous engage."),
      SectionContenu('4. Fonds',
          "Les fonds vont directement au fournisseur ou sur le compte séquestre du notaire. L'application ne détient "
              'jamais votre argent. Aucun paiement en espèces.'),
      SectionContenu('5. Risques',
          'Toute participation comporte un risque de perte. La majoration est convenue par contrat, mais son '
              'paiement dépend de la bonne exécution de la vente par l\'entreprise.'),
      SectionContenu('6. Confidentialité',
          'Les informations sur les opérations, les entreprises et les autres partenaires sont confidentielles. '
              'Vous ne les communiquez à personne.'),
      SectionContenu('7. Commission ARZIKI',
          'ARZIKI perçoit une commission de courtage, précisée dans le contrat de courtage de chaque opération.'),
      SectionContenu('8. Droit applicable',
          'Droit togolais et Actes uniformes OHADA. À défaut de règlement amiable, tribunaux de Lomé.'),
    ],
  ),
  PagesId.confidentialite: PageContenu(
    id: PagesId.confidentialite,
    titre: 'Politique de confidentialité',
    version: TextesLegaux.versionConditions,
    majLe: _dateVersion,
    intro: 'ARZIKI protège vos données personnelles conformément à la loi togolaise n° 2019-014 du 29 octobre 2019 '
        'relative à la protection des données à caractère personnel. Cette politique explique quelles données nous '
        'utilisons, pourquoi, et quels sont vos droits.',
    sections: const [
      SectionContenu('1. Responsable du traitement',
          'NEXUS International, RCCM TG-LFW-01-2025-A10-03200, 18 rue Léopold Sédar Senghor, Tokoin Wuiti, Lomé, '
              'Togo. Contact : nexusinternational25@gmail.com, copie à operation@amanexus.com.'),
      SectionContenu('2. Données collectées',
          "Identité (nom, prénom, date de naissance, pièce d'identité, selfie de contrôle), coordonnées (téléphone, "
              'e-mail, adresse), informations sur votre entreprise (RCCM, NIF, statuts, dirigeants), informations '
              'financières (origine des fonds, justificatifs bancaires, déclaration de personne politiquement exposée, '
              'bénéficiaire effectif, paiements), documents des '
              'opérations, et données techniques de connexion (date, appareil, journal des actions sensibles).'),
      SectionContenu('3. Finalités',
          "Créer et gérer votre compte ; vérifier votre identité et l'origine de vos fonds ; instruire les demandes "
              'de commande financée ; gérer les opérations, les manifestations d\'intérêt et les paiements ; vous informer de '
              "l'avancement de vos dossiers ; respecter nos obligations légales, notamment en matière de lutte contre "
              'le blanchiment de capitaux et le financement du terrorisme ; assurer la sécurité du service.'),
      SectionContenu('4. Fondements',
          "L'exécution du contrat qui vous lie à ARZIKI, le respect de nos obligations légales, notre intérêt "
              'légitime à sécuriser le service et, pour les communications facultatives, votre consentement, que vous '
              'pouvez retirer à tout moment dans Paramètres.'),
      SectionContenu('5. Destinataires',
          "Vos données sont accessibles uniquement aux personnes habilitées d'ARZIKI et, pour ce qui les concerne, "
              "au notaire chargé de l'opération, aux autres parties à l'opération dans la limite nécessaire, à notre "
              "agrégateur de paiement et à nos hébergeurs. Une entreprise ne voit jamais l'identité des partenaires. "
              "Aucune donnée n'est vendue ni louée."),
      SectionContenu('6. Hébergement et transferts',
          "Les données de l'application sont hébergées par Google Cloud (Firebase) dans un centre de données situé "
              'en Afrique du Sud (Johannesburg), avec des garanties contractuelles de protection. ARZIKI se conformera '
              'à toute obligation de localisation des données fixée par l\'autorité togolaise.'),
      SectionContenu('7. Durées de conservation',
          "Les données du compte sont conservées pendant toute la durée de la relation. Les pièces d'identité, "
              'contrats, justificatifs de paiement et documents des opérations sont conservés dix ans après la fin de '
              "la relation, comme l'imposent les règles comptables OHADA et la réglementation contre le blanchiment. "
              'Les données techniques de connexion sont conservées un an.'),
      SectionContenu('8. Sécurité',
          "Les documents sont stockés de façon chiffrée, dans un espace propre à chaque utilisateur. L'accès des "
              'administrateurs exige une double vérification, toute action sensible est inscrite dans un journal '
              "infalsifiable, et les captures d'écran sont bloquées sur les écrans de pièces d'identité et de "
              'contrats.'),
      SectionContenu('9. Vos droits',
          "Vous disposez d'un droit d'accès, de rectification, d'opposition et de suppression de vos données, dans "
              'la limite des durées légales de conservation. Vous pouvez télécharger vos données et demander la '
              'suppression de votre compte depuis Paramètres, ou écrire à nexusinternational25@gmail.com. Nous répondons '
              "dans un délai d'un mois. Vous pouvez également saisir l'Instance de protection des données à "
              'caractère personnel (IPDCP).'),
      SectionContenu('10. Modifications',
          "Toute modification de cette politique vous est notifiée dans l'application, avec sa date et son numéro "
              'de version.'),
    ],
  ),
  PagesId.risques: PageContenu(
    id: PagesId.risques,
    titre: 'Avertissement',
    version: TextesLegaux.versionConditions,
    majLe: _dateVersion,
    intro: TextesLegaux.avertissementR8,
    sections: const [
      SectionContenu('Les principaux risques',
          "Retard ou défaut de paiement à l'échéance ; retard ou défaut de livraison du fournisseur ; litige "
              'commercial sur la qualité ou la quantité ; difficulté de mise en œuvre d\'une garantie. Chacun de ces '
              'événements peut retarder le paiement ou entraîner une perte.'),
      SectionContenu('Ce que fait ARZIKI pour limiter les risques',
          'Vérification de chaque commande auprès du client final, contrôle du fournisseur et des prix, garanties '
              'adaptées au montant, contrats passés devant notaire, suivi des échéances et des retards. Ces mesures '
              'réduisent les risques sans les supprimer.'),
    ],
  ),
  PagesId.mentions: PageContenu(
    id: PagesId.mentions,
    titre: 'Mentions légales',
    version: TextesLegaux.versionConditions,
    majLe: _dateVersion,
    intro: "Informations sur l'éditeur et les hébergeurs de l'application ARZIKI.",
    sections: const [
      SectionContenu('Éditeur', 'NEXUS International\nRCCM TG-LFW-01-2025-A10-03200\n18 rue Léopold Sédar Senghor, Tokoin Wuiti, Lomé, Togo'),
      SectionContenu('Directeur de la publication', 'Le CEO de NEXUS International'),
      SectionContenu('Contact', 'nexusinternational25@gmail.com\noperation@amanexus.com\n+228 91 97 80 80'),
      SectionContenu('Hébergement',
          'Application : Google Cloud (Firebase), centre de données de Johannesburg, Afrique du Sud.\n'
              'Site internet et application web : LWS (Ligne Web Services), Paris, France.'),
      SectionContenu('Propriété intellectuelle',
          "La marque ARZIKI, son logo et l'ensemble des contenus sont la propriété de NEXUS International."),
      SectionContenu('Photographies', 'Images réalisées pour ARZIKI, sans logo ni texte lisible.'),
    ],
  ),
};

const List<QuestionFaq> faqParDefaut = [
  QuestionFaq(CategorieFaq.entreprises, "Qu'est-ce qu'une commande ferme ?",
      'Un bon de commande ou un marché signé par un client identifié, avec une quantité, un prix et une date de livraison. ARZIKI le confirme directement auprès de votre client.'),
  QuestionFaq(CategorieFaq.entreprises, 'Combien de temps dure l\'analyse ?',
      'En général de 5 à 10 jours ouvrés, selon la rapidité de réponse de votre client et du fournisseur.'),
  QuestionFaq(CategorieFaq.entreprises, "Qu'est-ce qu'une vente à terme ?",
      'Un partenaire achète la marchandise au fournisseur, puis vous la revend avec une majoration fixe en FCFA, payable à une échéance convenue. Vous connaissez le prix de revente avant de signer.'),
  QuestionFaq(CategorieFaq.entreprises, 'Quelles garanties sont demandées ?',
      'Elles dépendent du montant : réserve de propriété, nantissement de la créance sur votre client, cautionnement, hypothèque, nantissement de matériel ou du fonds de commerce. Consultez la page Sécurité et notaire.'),
  QuestionFaq(CategorieFaq.entreprises, "ARZIKI avance-t-il de l'argent ?",
      "Non. ARZIKI ne fait ni crédit ni collecte d'épargne. C'est un intermédiaire : il met en relation et perçoit une commission. Chaque opération fait l'objet de contrats passés devant notaire."),
  QuestionFaq(CategorieFaq.membres, "« Je suis intéressé » m'engage-t-il ?",
      "Non. La manifestation d'intérêt n'engage à rien. Seule la signature devant notaire vous engage."),
  QuestionFaq(CategorieFaq.membres, 'Mon argent passe-t-il par ARZIKI ?',
      "Non. Les fonds vont directement au fournisseur ou sur le compte séquestre du notaire. L'application suit seulement les justificatifs."),
  QuestionFaq(CategorieFaq.membres, 'Puis-je perdre de l\'argent ?',
      "Oui. Toute participation comporte un risque de perte : retard, défaut de paiement, litige. Ne vous engagez qu'avec des sommes dont vous n'avez pas besoin à court terme."),
  QuestionFaq(CategorieFaq.fournisseurs, 'Qui me paie ?',
      'Le partenaire qui achète la marchandise, directement ou par le compte séquestre du notaire, une fois les contrats signés devant notaire.'),
  QuestionFaq(CategorieFaq.fournisseurs, 'Comment déclarer une livraison ?',
      'Dans votre espace, ouvrez le bon de commande, ajoutez les photos et le bordereau signé, puis validez.'),
  QuestionFaq(CategorieFaq.paiements, 'Comment payer un service ?',
      "Par mobile money ou carte bancaire, via un agrégateur de paiement agréé. Vous recevez une facture dans l'application."),
  QuestionFaq(CategorieFaq.paiements, 'Les frais de service sont-ils remboursables ?',
      "L'acompte de 50 % et le solde ne sont plus remboursables une fois le travail commencé. Le devis précise toujours le contenu et le délai."),
  QuestionFaq(CategorieFaq.paiements, 'Puis-je payer en espèces ?',
      'Non. Aucun paiement en espèces : mobile money, carte bancaire ou virement, avec justificatif.'),
  QuestionFaq(CategorieFaq.securite, 'Mes documents sont-ils protégés ?',
      "Oui. Ils sont stockés dans un espace privé et visibles uniquement par vous et l'équipe de vérification. Les captures d'écran sont bloquées sur les écrans sensibles."),
];


final List<Actualite> actualitesParDefaut = [
  Actualite(
    id: 'a1',
    titre: 'Préparer votre dossier de commande',
    texte: 'Un bon de commande signé, un devis récent du fournisseur et vos derniers états financiers : '
        'les trois pièces qui accélèrent la vérification.',
    image: Images.dirigeanteSignature,
    date: DateTime(2026, 10, 28),
  ),
  Actualite(
    id: 'a2',
    titre: 'Nouvelle session de formation à Lomé',
    texte: "« Préparer son dossier de financement », le 12 décembre 2026 à Lomé. Places limitées, inscription dans l'onglet Services.",
    image: Images.equipe,
    date: DateTime(2026, 10, 30),
  ),
  Actualite(
    id: 'a3',
    titre: 'Pourquoi passer devant notaire',
    texte: "Chaque opération ARZIKI fait l'objet de contrats passés devant notaire : ce que cela change pour vous.",
    image: Images.cercleNotaire,
    date: DateTime(2026, 10, 25),
  ),
];

class EtatContenus {
  const EtatContenus({required this.pages, required this.faq, required this.actualites, this.contacts = const Contacts()});
  final Map<String, PageContenu> pages;
  final List<QuestionFaq> faq;
  final List<Actualite> actualites;
  final Contacts contacts;

  EtatContenus avec({Map<String, PageContenu>? pages, List<QuestionFaq>? faq, List<Actualite>? actualites, Contacts? contacts}) =>
      EtatContenus(
        pages: pages ?? this.pages,
        faq: faq ?? this.faq,
        actualites: actualites ?? this.actualites,
        contacts: contacts ?? this.contacts,
      );
}

/// Contenus modifiables. En production, ils seront lus dans Firestore (collection « contenus »).
class ControleurContenus extends Notifier<EtatContenus> {
  @override
  EtatContenus build() => EtatContenus(
        pages: Map.of(pagesParDefaut),
        faq: List.of(faqParDefaut),
        actualites: List.of(actualitesParDefaut),
      );

  void _auditer(String acteurUid, String action, String cible) {
    ref.read(baseDemoProvider).auditer(acteurUid, action, cible);
  }

  void modifierPage(String acteurUid, String id, {required String titre, required String intro, required List<SectionContenu> sections}) {
    final page = state.pages[id]!;
    state = state.avec(pages: {
      ...state.pages,
      id: page.copier(titre: titre, intro: intro, sections: sections, majLe: DateTime.now()),
    });
    _auditer(acteurUid, 'modifier_contenu', 'contenus/$id');
  }

  void enregistrerActualite(String acteurUid, Actualite a) {
    final liste = [...state.actualites.where((x) => x.id != a.id), a]..sort((x, y) => y.date.compareTo(x.date));
    state = state.avec(actualites: liste);
    _auditer(acteurUid, 'modifier_actualite', 'actualites/${a.id}');
  }

  void supprimerActualite(String acteurUid, String id) {
    state = state.avec(actualites: state.actualites.where((x) => x.id != id).toList());
    _auditer(acteurUid, 'retirer_actualite', 'actualites/$id');
  }

  void enregistrerQuestion(String acteurUid, int? index, QuestionFaq q) {
    final liste = List.of(state.faq);
    if (index == null) {
      liste.add(q);
    } else {
      liste[index] = q;
    }
    state = state.avec(faq: liste);
    _auditer(acteurUid, 'modifier_faq', 'faq/${index ?? liste.length - 1}');
  }

  void modifierContacts(String acteurUid, Contacts c) {
    state = state.avec(contacts: c);
    _auditer(acteurUid, 'modifier_contacts', 'contenus/contacts');
  }
}

final contenusProvider = NotifierProvider<ControleurContenus, EtatContenus>(ControleurContenus.new);
