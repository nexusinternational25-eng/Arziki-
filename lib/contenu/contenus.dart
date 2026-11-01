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
  membres('Membres du Cercle'),
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
  static const confidentialite = 'confidentialite';
  static const risques = 'risques';
  static const mentions = 'mentions-legales';
}

final _dateVersion = DateTime(2026, 11, 1);

final Map<String, PageContenu> pagesParDefaut = {
  PagesId.aPropos: const PageContenu(
    id: PagesId.aPropos,
    titre: "À propos d'ARZIKI",
    image: Images.reunionInvestisseurs,
    intro: 'ARZIKI signifie « prospérité » en haoussa. Notre mission : permettre aux entreprises togolaises '
        "d'honorer leurs commandes fermes, en réunissant le financement de l'achat autour d'un cadre clair, "
        'vérifié et encadré par notaire.',
    sections: [
      SectionContenu('Notre mission',
          "Trop d'entreprises perdent une commande ferme faute de trésorerie pour acheter la marchandise. "
              "ARZIKI vérifie la commande, organise le financement de l'achat avec un fournisseur partenaire ou "
              "avec le Cercle Arziki, et suit l'opération jusqu'au paiement de l'acheteur final."),
      SectionContenu('Nos valeurs',
          "Transparence : chaque participant voit les étapes, les documents et les résultats de l'opération.\n"
              'Rigueur : chaque acheteur et chaque commande sont vérifiés par notre équipe avant toute décision.\n'
              'Respect : des engagements écrits, un notaire à chaque étape, et une relation de long terme avec nos clients.'),
      SectionContenu('La direction',
          'ARZIKI est dirigée par le CEO de NEXUS International, conseiller en investissement certifié USAID. '
              'Il a accompagné des financements validés de 30 millions et de 160 millions '
              "de dollars américains, et mobilisé plusieurs centaines de millions de FCFA pour plus d'une "
              "centaine d'entreprises."),
      SectionContenu('Une offre de NEXUS International',
          'ARZIKI est édité par NEXUS International, cabinet de conseil en financement basé à Lomé. '
              'Adresse : 18 rue Léopold Sédar Senghor, Tokoin Wuiti, Lomé, Togo.'),
    ],
  ),
  PagesId.commentCaMarche: const PageContenu(
    id: PagesId.commentCaMarche,
    titre: 'Comment ça marche',
    image: Images.livraisonChantier,
    intro: "La Commande Financée en cinq étapes : de votre bon de commande jusqu'au partage de la marge.",
    sections: [
      SectionContenu('1. Vous déposez votre commande',
          "Vous avez une commande ferme d'un acheteur identifié. Vous la déposez dans l'application avec le bon "
              "de commande, le devis du fournisseur et vos coûts. L'application calcule votre marge prévisionnelle."),
      SectionContenu('2. ARZIKI vérifie',
          "Notre équipe contacte directement l'acheteur, vérifie le fournisseur et les prix, rencontre le dirigeant "
              'et propose les garanties adaptées au montant.'),
      SectionContenu("3. L'achat est financé",
          "Selon le dossier, le fournisseur accepte d'être payé plus tard, ou le Cercle Arziki réunit le montant "
              'nécessaire. Les fonds vont directement au fournisseur ou sur le compte séquestre du notaire.'),
      SectionContenu('4. Vous livrez',
          "Le fournisseur livre la marchandise, vous livrez votre client. Chaque étape est suivie dans l'application."),
      SectionContenu('5. La marge est partagée',
          "L'acheteur final paie sur le compte désigné. Le fournisseur est réglé, puis la marge nette est partagée "
              'selon le contrat, sous le contrôle du notaire.'),
      SectionContenu('Format PME',
          'De 2 000 000 à 30 000 000 FCFA. Partage par défaut de la marge nette : entreprise 45 %, '
              'investisseurs 30 %, ARZIKI 25 %. Frais de montage : 100 000 FCFA.'),
      SectionContenu('Format Entreprises',
          'De 30 000 000 à 300 000 000 FCFA, pour les fournisseurs de grands comptes. ARZIKI 20 % de la marge '
              "nette, le reste entre l'entreprise et les investisseurs selon le contrat. Frais de structuration : 1 %."),
      SectionContenu('Le rôle de chacun',
          "L'entreprise réalise la commande. Le fournisseur livre la marchandise. Le Cercle finance l'achat quand "
              "c'est nécessaire. Le notaire conserve les actes, reçoit les fonds en séquestre et contrôle les paiements. "
              'ARZIKI vérifie, coordonne et rend compte.'),
    ],
  ),
  PagesId.cercle: const PageContenu(
    id: PagesId.cercle,
    titre: 'Le Cercle Arziki',
    image: Images.cercleDiaspora,
    intro: 'Un cercle privé de membres et de partenaires qui choisissent les opérations commerciales auxquelles '
        'ils participent. On y entre uniquement sur invitation ou après admission par un administrateur.',
    sections: [
      SectionContenu('Membre',
          'Accès aux opérations PME. Participation minimale : 500 000 FCFA par opération. Cotisation annuelle : 50 000 FCFA.'),
      SectionContenu('Partenaire',
          'Accès aux opérations PME et Entreprises. Participation minimale : 10 000 000 FCFA. Cotisation annuelle : 250 000 FCFA.'),
      SectionContenu('Partenaire stratégique',
          "Accès à toutes les opérations, possibilité d'être désigné chef de file d'un pool. Participation minimale : "
              '50 000 000 FCFA. Cotisation selon convention.'),
      SectionContenu('Les règles du Cercle',
          "L'application ne détient jamais votre argent : les versements vont au fournisseur ou sur le compte "
              "séquestre du notaire. Votre identité et l'origine de vos fonds sont vérifiées avant toute participation. "
              'Aucun versement en espèces au-delà de 5 000 000 FCFA. Le Cercle reste limité à 100 personnes.'),
      SectionContenu('Comment être invité',
          "Si vous connaissez un membre ou l'équipe ARZIKI, demandez un code d'invitation personnel. Sinon, créez "
              'votre compte avec « Je souhaite rejoindre le Cercle » et déposez votre candidature : un administrateur '
              "l'examine et vous répond."),
    ],
  ),
  PagesId.securite: const PageContenu(
    id: PagesId.securite,
    titre: 'Sécurité et notaire',
    image: Images.cercleNotaire,
    intro: 'Chaque opération est encadrée par un notaire partenaire, avec des garanties proportionnées au montant. '
        "Votre argent ne transite jamais par l'application.",
    sections: [
      SectionContenu('Les vérifications',
          "Avant toute décision, notre équipe vérifie que l'acheteur existe, confirme le bon de commande directement "
              'avec lui, contrôle le fournisseur et ses prix, rencontre le dirigeant et attribue une note de risque.'),
      SectionContenu('Le rôle du notaire',
          'Le notaire conserve les actes signés, reçoit les fonds sur son compte séquestre et confirme chaque '
              'décaissement : paiement du fournisseur, puis partage final.'),
      SectionContenu('Protection de vos données',
          "Vos pièces d'identité sont stockées de façon chiffrée et ne sont visibles que par vous et l'équipe de "
              'vérification. Les administrateurs se connectent avec une double vérification. Toute action sensible '
              'est inscrite dans un journal qui ne peut pas être modifié.'),
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
              "les conditions.\n3. Vérifiez votre numéro par WhatsApp (ou par SMS).\n4. Déposez vos pièces d'identité.\n5. Attendez la "
              'validation : vous recevez une notification.'),
      SectionContenu('Déposer une demande de Commande Financée',
          "1. Touchez le bouton orange « Nouvelle demande ».\n2. Renseignez l'acheteur, la commande, le fournisseur "
              'et vos coûts.\n3. Joignez le bon de commande et le devis.\n4. Vérifiez le récapitulatif et envoyez.'),
      SectionContenu('Participer à une opération du Cercle',
          "1. Ouvrez « Opérations ouvertes » et choisissez une fiche.\n2. Lisez l'avertissement sur les risques.\n"
              '3. Indiquez votre montant et validez.\n4. Suivez les instructions de versement et déposez votre preuve.'),
      SectionContenu('Commander un service',
          "1. Ouvrez l'onglet Services.\n2. Choisissez une offre et décrivez votre besoin.\n3. Recevez le devis, "
              "réglez l'acompte de 50 %.\n4. Suivez l'avancement et téléchargez votre livrable."),
    ],
  ),
  PagesId.cgu: PageContenu(
    id: PagesId.cgu,
    titre: "Conditions d'utilisation",
    version: TextesLegaux.versionConditions,
    majLe: _dateVersion,
    intro: "Les présentes conditions générales d'utilisation (les « Conditions ») encadrent l'accès et l'utilisation "
        "de l'application ARZIKI et de son site. En créant un compte, vous les acceptez sans réserve.",
    sections: const [
      SectionContenu('1. Éditeur',
          'ARZIKI est éditée par NEXUS International, RCCM TG-LFW-01-2025-A10-03200, dont le siège est situé '
              '18 rue Léopold Sédar Senghor, Tokoin Wuiti, Lomé, Togo (« NEXUS International » ou « ARZIKI »).'),
      SectionContenu('2. Objet du service',
          "ARZIKI organise la Commande Financée : une entreprise titulaire d'une commande ferme d'un acheteur "
              "identifié obtient le financement de l'achat de la marchandise, soit auprès d'un fournisseur qui accepte "
              "d'être payé plus tard, soit auprès des membres du Cercle Arziki, cercle privé de participants. ARZIKI "
              'vérifie les dossiers, coordonne les intervenants et rend compte de chaque étape. Chaque opération est '
              'encadrée par un notaire partenaire. ARZIKI propose également des services de conseil opérés par NEXUS '
              'International.'),
      SectionContenu('3. Inscription et compte',
          "L'inscription est réservée aux personnes majeures et aux entreprises régulièrement immatriculées. Le compte "
              'est personnel : vous êtes responsable de la confidentialité de vos codes (codes de vérification, code PIN, mot de '
              "passe) et de toute action réalisée depuis votre compte. Un compte reste en attente jusqu'à la "
              "vérification de l'identité de son titulaire par ARZIKI, qui peut refuser une inscription sans avoir à "
              'motiver sa décision.'),
      SectionContenu('4. Accès au Cercle Arziki',
          'Le Cercle est privé. On y entre uniquement sur invitation nominative ou après admission par un '
              "administrateur, une fois l'identité et l'origine des fonds vérifiées. Les opérations ne sont visibles "
              "que par les membres admis, selon leur niveau. Le Cercle ne s'adresse pas au public et ne constitue "
              'pas une offre au public.'),
      SectionContenu('5. Fonds des opérations',
          'ARZIKI ne détient jamais les fonds des opérations et ne tient aucun compte au nom des utilisateurs. Les '
              'versements des participants sont effectués par virement ou par mobile money directement au fournisseur '
              "ou sur le compte séquestre du notaire, avec la référence indiquée dans l'application. Aucun versement en "
              "espèces n'est accepté au-delà de 5 000 000 FCFA. La participation n'est confirmée qu'après "
              'vérification de la preuve de versement.'),
      SectionContenu('6. Nature des participations',
          'Une participation est un engagement dans une opération commerciale, rémunéré par une part de la marge '
              'nette réellement dégagée, selon le contrat de participation et les actes signés devant notaire. La '
              'marge indiquée sur une fiche est un objectif. Le participant peut perdre tout ou partie de sa mise. '
              "En cas de différence entre l'application et les actes notariés, les actes notariés font foi."),
      SectionContenu('7. Obligations des utilisateurs',
          "Chaque utilisateur s'engage à fournir des informations exactes et à jour, des documents authentiques, à "
              "respecter les engagements pris dans le cadre d'une opération et à ne pas utiliser ARZIKI à des fins "
              'frauduleuses, notamment de blanchiment de capitaux ou de financement du terrorisme. Toute déclaration '
              'inexacte peut entraîner la suspension immédiate du compte.'),
      SectionContenu('8. Frais et paiements',
          'Les frais de dossier, les cotisations annuelles et les prix des services sont indiqués avant tout '
              "paiement. Ils sont réglés par l'intermédiaire d'un agrégateur de paiement agréé (mobile money ou carte). "
              'Les services sont payés à 50 % à la commande et à 50 % à la livraison ; les sommes versées ne sont plus '
              'remboursables une fois le travail commencé. Un reçu est disponible dans l\'application.'),
      SectionContenu('9. Signature électronique',
          "La validation d'un engagement par case à cocher, code PIN et horodatage vaut signature électronique "
              'simple. Elle complète les actes signés devant notaire, qui restent la référence.'),
      SectionContenu('10. Responsabilité',
          'ARZIKI met en œuvre les moyens nécessaires à la vérification des dossiers et au bon fonctionnement de '
              "l'application, sans pouvoir répondre de la défaillance d'un acheteur, d'un fournisseur ou d'un autre "
              'intervenant, ni des interruptions liées au réseau ou à un cas de force majeure.'),
      SectionContenu('11. Suspension et clôture',
          'ARZIKI peut suspendre ou clôturer un compte en cas de manquement aux présentes Conditions. Vous pouvez '
              "demander la clôture de votre compte depuis Paramètres ; les engagements en cours restent dus jusqu'à "
              'leur terme.'),
      SectionContenu('12. Propriété intellectuelle',
          'La marque ARZIKI, le logo, les textes, les images et le logiciel sont la propriété de NEXUS International. '
              'Toute reproduction sans autorisation écrite est interdite.'),
      SectionContenu('13. Modification des Conditions',
          "ARZIKI peut modifier les présentes Conditions. La nouvelle version est notifiée dans l'application et doit "
              'être acceptée pour continuer à utiliser le service.'),
      SectionContenu('14. Droit applicable et litiges',
          "Les présentes Conditions sont soumises au droit togolais et aux actes uniformes de l'OHADA. En cas de "
              "différend, les parties recherchent d'abord une solution amiable ; à défaut, les juridictions "
              'compétentes de Lomé sont seules saisies.'),
      SectionContenu('15. Contact', 'NEXUS International, operation@amanexus.com, +228 91 97 80 80.'),
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
              'Togo. Contact : operation@amanexus.com.'),
      SectionContenu('2. Données collectées',
          "Identité (nom, prénom, date de naissance, pièce d'identité, selfie de contrôle), coordonnées (téléphone, "
              'e-mail, adresse), informations sur votre entreprise (RCCM, NIF, statuts, dirigeants), informations '
              'financières (origine des fonds, justificatifs bancaires, participations, paiements), documents des '
              'opérations, et données techniques de connexion (date, appareil, journal des actions sensibles).'),
      SectionContenu('3. Finalités',
          "Créer et gérer votre compte ; vérifier votre identité et l'origine de vos fonds ; instruire les demandes "
              'de Commande Financée ; gérer les opérations, les participations et les paiements ; vous informer de '
              "l'avancement de vos dossiers ; respecter nos obligations légales, notamment en matière de lutte contre "
              'le blanchiment de capitaux et le financement du terrorisme ; assurer la sécurité du service.'),
      SectionContenu('4. Fondements',
          "L'exécution du contrat qui vous lie à ARZIKI, le respect de nos obligations légales, notre intérêt "
              'légitime à sécuriser le service et, pour les communications facultatives, votre consentement, que vous '
              'pouvez retirer à tout moment dans Paramètres.'),
      SectionContenu('5. Destinataires',
          "Vos données sont accessibles uniquement aux personnes habilitées d'ARZIKI et, pour ce qui les concerne, "
              "au notaire chargé de l'opération, aux autres parties à l'opération dans la limite nécessaire, à notre "
              "agrégateur de paiement et à nos hébergeurs. Une entreprise ne voit jamais l'identité des participants. "
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
              'suppression de votre compte depuis Paramètres, ou écrire à operation@amanexus.com. Nous répondons '
              "dans un délai d'un mois. Vous pouvez également saisir l'Instance de protection des données à "
              'caractère personnel (IPDCP).'),
      SectionContenu('10. Modifications',
          "Toute modification de cette politique vous est notifiée dans l'application, avec sa date et son numéro "
              'de version.'),
    ],
  ),
  PagesId.risques: PageContenu(
    id: PagesId.risques,
    titre: 'Avertissement sur les risques',
    version: TextesLegaux.versionConditions,
    majLe: _dateVersion,
    intro: TextesLegaux.avertissementRisque,
    sections: const [
      SectionContenu('Les principaux risques',
          "Retard ou défaut de paiement de l'acheteur final ; retard ou défaut de livraison du fournisseur ; litige "
              'commercial sur la qualité ou la quantité livrée ; frais réels supérieurs aux frais prévus ; difficulté '
              "de mise en œuvre d'une garantie. Chacun de ces événements peut réduire la marge réelle, retarder le "
              'partage ou entraîner une perte partielle ou totale de la mise.'),
      SectionContenu("Ce n'est pas une épargne disponible",
          "Une participation est immobilisée jusqu'à la clôture de l'opération. Elle ne peut pas être retirée avant "
              "le terme. Ne participez qu'avec des sommes dont vous n'avez pas besoin à court terme et répartissez vos "
              'participations entre plusieurs opérations.'),
      SectionContenu('Ce que fait ARZIKI pour limiter les risques',
          "Vérification de chaque commande auprès de l'acheteur, contrôle du fournisseur et des prix, garanties "
              'proportionnées au montant, encadrement notarial et compte séquestre, plafonds de concentration par '
              'opération, par acheteur et par secteur, suivi des retards et rapport mensuel. Ces mesures réduisent les '
              'risques sans les supprimer.'),
      SectionContenu('Avant de participer',
          "Lisez la fiche de l'opération et le contrat de participation, posez vos questions à l'équipe ARZIKI, et "
              'vérifiez que le montant envisagé correspond à votre situation.'),
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
      SectionContenu('Contact', 'operation@amanexus.com\n+228 91 97 80 80'),
      SectionContenu('Hébergement',
          'Application : Google Cloud (Firebase), centre de données de Johannesburg, Afrique du Sud.\n'
              'Site internet : Vercel Inc., San Francisco, États-Unis.'),
      SectionContenu('Propriété intellectuelle',
          "La marque ARZIKI, son logo et l'ensemble des contenus sont la propriété de NEXUS International."),
      SectionContenu('Photographies', 'Images réalisées pour ARZIKI, sans logo ni texte lisible.'),
    ],
  ),
};

const List<QuestionFaq> faqParDefaut = [
  QuestionFaq(CategorieFaq.entreprises, "Qu'est-ce qu'une commande ferme ?",
      "Un bon de commande ou un contrat signé par un acheteur identifié, avec une quantité, un prix et une date de livraison. ARZIKI le confirme directement auprès de l'acheteur."),
  QuestionFaq(CategorieFaq.entreprises, 'Combien de temps dure la vérification ?',
      "En général de 5 à 10 jours ouvrés, selon la rapidité de réponse de l'acheteur et du fournisseur."),
  QuestionFaq(CategorieFaq.entreprises, 'Quelle marge minimale faut-il ?',
      "La marge nette prévue doit atteindre au moins 8 % après tous les frais. L'application vous prévient si ce n'est pas le cas."),
  QuestionFaq(CategorieFaq.entreprises, 'Quelles garanties sont demandées ?',
      'Elles dépendent du montant : simple contrat signé sous 5 M FCFA, caution et nantissements au-delà, acte notarié et hypothèque pour les grandes opérations. Consultez la page Sécurité et notaire.'),
  QuestionFaq(CategorieFaq.membres, 'Comment rejoindre le Cercle ?',
      "Avec un code d'invitation personnel, ou en déposant une candidature. Dans les deux cas, un administrateur vérifie votre identité avant d'activer votre compte."),
  QuestionFaq(CategorieFaq.membres, 'Mon argent passe-t-il par ARZIKI ?',
      "Non. Vous versez directement au fournisseur ou sur le compte séquestre du notaire, puis vous déposez votre preuve de versement dans l'application."),
  QuestionFaq(CategorieFaq.membres, 'Puis-je perdre ma mise ?',
      "Oui. Il s'agit d'une participation à une opération commerciale : vous pouvez perdre tout ou partie de votre mise. Ne participez qu'avec des sommes dont vous n'avez pas besoin à court terme."),
  QuestionFaq(CategorieFaq.membres, 'Comment la marge est-elle calculée ?',
      "Marge nette réelle = encaissement réel moins prix d'achat moins frais réels. La part des investisseurs est répartie au prorata des versements confirmés."),
  QuestionFaq(CategorieFaq.fournisseurs, "Qu'est-ce que le paiement différé ?",
      "Vous livrez la marchandise et vous êtes réglé à 30, 45, 60 ou 90 jours, sur le compte désigné de l'opération, sous contrôle du notaire."),
  QuestionFaq(CategorieFaq.fournisseurs, 'Comment déclarer une livraison ?',
      'Dans votre espace, ouvrez le bon de commande, ajoutez les photos et le bordereau signé, puis validez.'),
  QuestionFaq(CategorieFaq.paiements, 'Comment payer un service ou une cotisation ?',
      "Par T-Money, Flooz ou carte bancaire, via notre agrégateur de paiement agréé. Vous recevez un reçu dans l'application."),
  QuestionFaq(CategorieFaq.paiements, 'Les frais de service sont-ils remboursables ?',
      "L'acompte de 50 % et le solde ne sont plus remboursables une fois le travail commencé. Le devis précise toujours le contenu et le délai."),
  QuestionFaq(CategorieFaq.paiements, 'Puis-je verser en espèces ?',
      'Pas au-delà de 5 000 000 FCFA. Les participations se font par virement ou mobile money, avec justificatif.'),
  QuestionFaq(CategorieFaq.securite, 'Mes documents sont-ils protégés ?',
      "Oui. Ils sont chiffrés et visibles uniquement par vous et l'équipe de vérification. Les captures d'écran sont bloquées sur les écrans sensibles."),
  QuestionFaq(CategorieFaq.securite, 'Qui peut voir les opérations du Cercle ?',
      "Uniquement les membres admis, dont l'identité est vérifiée. Les visiteurs et les entreprises ne voient jamais les participations des autres."),
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
    texte: "« Préparer son dossier de crédit », le 21 novembre 2026 à Lomé. Places limitées, inscription dans l'onglet Services.",
    image: Images.equipe,
    date: DateTime(2026, 10, 30),
  ),
  Actualite(
    id: 'a3',
    titre: 'Le notaire, garant du cadre',
    texte: 'Pourquoi chaque opération ARZIKI passe par un notaire partenaire, et ce que cela change pour vous.',
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
