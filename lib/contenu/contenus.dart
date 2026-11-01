// Contenus éditoriaux d'ARZIKI : pages d'information, FAQ, actualités, contacts.
// Tous ces textes sont modifiables depuis la console d'administration
// (page « Contenus ») ; chaque modification est inscrite au journal d'audit.
// Les textes légaux sont provisoires, en attente de validation par l'avocat.

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
      SectionContenu('Le fondateur',
          'MOUSSA SALEY ZOUZOU OUMARA est conseiller en investissement certifié USAID et fondateur de '
              'NEXUS International. Il a accompagné des financements validés de 30 millions et de 160 millions '
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
              "les conditions.\n3. Entrez le code reçu par SMS.\n4. Déposez vos pièces d'identité.\n5. Attendez la "
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
    intro: "Version provisoire, en attente de validation par l'avocat de NEXUS International.",
    sections: const [
      SectionContenu('Objet',
          "Les présentes conditions encadrent l'utilisation de l'application ARZIKI, éditée par NEXUS International, "
              'qui met en relation des entreprises ayant une commande ferme, des fournisseurs, des notaires et les '
              "membres d'un cercle privé de participants."),
      SectionContenu('Accès',
          "L'inscription est personnelle. L'accès aux opérations du Cercle est réservé aux personnes invitées ou "
              "admises, dont l'identité et l'origine des fonds ont été vérifiées."),
      SectionContenu('Engagements',
          "Chaque utilisateur s'engage à fournir des informations exactes et des documents authentiques. ARZIKI "
              'peut suspendre un compte en cas de manquement.'),
      SectionContenu('Fonds',
          'ARZIKI ne détient jamais les fonds des opérations. Les frais de service et les cotisations sont encaissés '
              'par un agrégateur de paiement agréé.'),
      SectionContenu('Responsabilité',
          'Les participations comportent un risque de perte. Les marges indiquées sont des objectifs. Les actes '
              'notariés font foi en cas de différence avec les informations affichées.'),
    ],
  ),
  PagesId.confidentialite: PageContenu(
    id: PagesId.confidentialite,
    titre: 'Politique de confidentialité',
    version: TextesLegaux.versionConditions,
    majLe: _dateVersion,
    intro: 'Version provisoire, conforme aux principes de la loi togolaise n° 2019-014 sur la protection des '
        "données personnelles, en attente de validation par l'avocat.",
    sections: const [
      SectionContenu('Données collectées',
          "Identité, coordonnées, pièces justificatives, informations sur votre entreprise ou l'origine de vos fonds, "
              "et l'historique de vos opérations."),
      SectionContenu('Utilisation',
          'Vérifier votre identité, instruire les dossiers, respecter nos obligations légales et vous informer du '
              "suivi de vos opérations. Aucune donnée n'est vendue."),
      SectionContenu('Conservation et sécurité',
          'Les pièces sont stockées de façon chiffrée. Les contrats et justificatifs sont conservés pendant la durée '
              'imposée par la loi.'),
      SectionContenu('Vos droits',
          'Vous pouvez télécharger vos données et demander la suppression de votre compte depuis Paramètres, ou '
              'écrire à operation@amanexus.com.'),
    ],
  ),
  PagesId.risques: PageContenu(
    id: PagesId.risques,
    titre: 'Avertissement sur les risques',
    version: TextesLegaux.versionConditions,
    majLe: _dateVersion,
    intro: TextesLegaux.avertissementRisque,
    sections: const [
      SectionContenu('Risques principaux',
          "Retard ou défaut de paiement de l'acheteur, retard de livraison, litige commercial, baisse de la marge "
              'réelle par rapport à la marge visée.'),
      SectionContenu('Ce que fait ARZIKI pour les limiter',
          'Vérification de chaque commande, garanties proportionnées au montant, encadrement notarial, plafonds de '
              'concentration par opération, par acheteur et par secteur.'),
    ],
  ),
  PagesId.mentions: PageContenu(
    id: PagesId.mentions,
    titre: 'Mentions légales',
    version: TextesLegaux.versionConditions,
    majLe: _dateVersion,
    intro: 'Informations sur l\'éditeur de l\'application ARZIKI.',
    sections: const [
      SectionContenu('Éditeur', 'NEXUS International\nRCCM TG-LFW-01-2025-A10-03200\n18 rue Léopold Sédar Senghor, Tokoin Wuiti, Lomé, Togo'),
      SectionContenu('Directeur de la publication', 'MOUSSA SALEY ZOUZOU OUMARA'),
      SectionContenu('Contact', 'operation@amanexus.com\n+228 91 97 80 80'),
      SectionContenu('Photographies', 'Images générées pour ARZIKI, sans logo ni texte lisible.'),
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
