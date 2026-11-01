// Textes des pages « Mentions légales » et « Confidentialité ».
// Les éléments à confirmer sont listés dans A_COMPLETER.md.

import type { Texte } from "./contenu";

export type Bloc = { titre: Texte; paragraphes: Texte[] };

export const MISE_A_JOUR: Texte = { fr: "1er novembre 2026", ar: "1 نوفمبر 2026" };

export const MENTIONS: Bloc[] = [
  {
    titre: { fr: "Nature du portail", ar: "طبيعة البوابة" },
    paragraphes: [
      {
        fr: "Initiative privée de NEXUS International. Ce portail n'est pas un site officiel des gouvernements algérien ou nigérien.",
        ar: "مبادرة خاصة من نيكسوس إنترناشونال. هذه البوابة ليست موقعا رسميا للحكومة الجزائرية ولا للحكومة النيجرية.",
      },
      {
        fr: "Le portail n'utilise aucun drapeau, aucune armoirie ni aucun logo officiel d'un État ou d'une administration. Les informations sur la coopération entre l'Algérie et le Niger sont données à titre d'information générale.",
        ar: "لا تستعمل البوابة أي علم أو شعار رسمي لأي دولة أو إدارة. وتقدم المعلومات المتعلقة بالتعاون بين الجزائر والنيجر على سبيل الإعلام العام.",
      },
    ],
  },
  {
    titre: { fr: "Éditeur", ar: "الناشر" },
    paragraphes: [
      {
        fr: "NEXUS International, cabinet de mobilisation de ressources et d'ingénierie financière, Lomé, Togo.",
        ar: "نيكسوس إنترناشونال، مكتب تعبئة الموارد والهندسة المالية، لومي، توغو.",
      },
      {
        fr: "Contact : operation@amanexus.com, WhatsApp +228 91 97 80 80.",
        ar: "للتواصل: operation@amanexus.com، واتساب ‎+228 91 97 80 80.",
      },
      {
        fr: "Directeur de la publication : le directeur de NEXUS International.",
        ar: "مدير النشر: مدير نيكسوس إنترناشونال.",
      },
    ],
  },
  {
    titre: { fr: "Hébergement", ar: "الاستضافة" },
    paragraphes: [
      {
        fr: "Le site est hébergé par Vercel Inc., 440 N Barranca Ave #4133, Covina, CA 91723, États-Unis (vercel.com). Les demandes sont stockées chez Supabase (supabase.com).",
        ar: "يستضيف الموقع Vercel Inc.، ‏440 N Barranca Ave #4133, Covina, CA 91723، الولايات المتحدة الأمريكية (vercel.com). وتحفظ الطلبات لدى Supabase ‏(supabase.com).",
      },
    ],
  },
  {
    titre: { fr: "Rôle de NEXUS International", ar: "دور نيكسوس إنترناشونال" },
    paragraphes: [
      {
        fr: "NEXUS International agit comme intermédiaire. Le portail ne met pas les parties en contact direct. Les services sont rendus sur la base d'une offre de service écrite et acceptée.",
        ar: "تعمل نيكسوس إنترناشونال بصفة وسيط، ولا تضع البوابة الأطراف في اتصال مباشر. وتقدم الخدمات على أساس عرض خدمة مكتوب ومقبول.",
      },
      {
        fr: "Les informations publiées sont générales. Elles ne remplacent pas un conseil juridique, fiscal ou douanier adapté à votre situation. Aucun délai ni aucun résultat n'est promis.",
        ar: "المعلومات المنشورة عامة، ولا تغني عن استشارة قانونية أو جبائية أو جمركية ملائمة لوضعكم. ولا يتم الوعد بأي أجل ولا بأي نتيجة.",
      },
    ],
  },
  {
    titre: { fr: "Propriété intellectuelle", ar: "الملكية الفكرية" },
    paragraphes: [
      {
        fr: "Les textes, la carte et la présentation du portail appartiennent à NEXUS International. Toute reproduction suppose son accord écrit.",
        ar: "النصوص والخريطة وتصميم البوابة ملك لنيكسوس إنترناشونال، وكل استنساخ يتطلب موافقتها الكتابية.",
      },
    ],
  },
];

export const CONFIDENTIALITE: Bloc[] = [
  {
    titre: { fr: "Responsable du traitement", ar: "المسؤول عن المعالجة" },
    paragraphes: [
      {
        fr: "NEXUS International, Lomé, Togo. Contact pour toute question sur vos données : operation@amanexus.com.",
        ar: "نيكسوس إنترناشونال، لومي، توغو. للتواصل بشأن معطياتكم: operation@amanexus.com.",
      },
    ],
  },
  {
    titre: { fr: "Données collectées", ar: "المعطيات المجمعة" },
    paragraphes: [
      {
        fr: "Lorsque vous déposez une demande : nom, entreprise, fonction, pays, profil, service et secteur, budget indicatif, e-mail, téléphone ou WhatsApp, message, langue préférée, date de la demande et page d'origine.",
        ar: "عند تقديم طلب: الاسم، والمؤسسة، والوظيفة، والبلد، والصفة، والخدمة والقطاع، والميزانية التقريبية، والبريد الإلكتروني، والهاتف أو واتساب، والرسالة، واللغة المفضلة، وتاريخ الطلب والصفحة التي أرسل منها.",
      },
      {
        fr: "Pour protéger le formulaire contre les abus, une empreinte non réversible de votre adresse IP est conservée en mémoire pendant une heure au plus. Le site ne dépose aucun cookie publicitaire ni de mesure d'audience.",
        ar: "لحماية الاستمارة من التجاوزات، تحفظ بصمة غير قابلة للعكس لعنوان IP الخاص بكم في الذاكرة مدة ساعة على الأكثر. ولا يضع الموقع أي ملفات تعريف ارتباط إشهارية أو لقياس الجمهور.",
      },
    ],
  },
  {
    titre: { fr: "Finalité", ar: "الغرض" },
    paragraphes: [
      {
        fr: "Vos données servent uniquement à étudier votre demande, à vous répondre, à vous adresser une offre de service et à suivre la relation commerciale. Elles ne sont ni vendues ni louées.",
        ar: "تستعمل معطياتكم حصريا لدراسة طلبكم، والرد عليكم، وإرسال عرض خدمة إليكم، ومتابعة العلاقة التجارية. ولا تباع ولا تؤجر.",
      },
      {
        fr: "Elles peuvent être communiquées à un partenaire seulement avec votre accord et pour les besoins de la mission que vous avez confiée à NEXUS International.",
        ar: "ولا يمكن إطلاع أي شريك عليها إلا بموافقتكم ولأغراض المهمة التي أوكلتموها إلى نيكسوس إنترناشونال.",
      },
    ],
  },
  {
    titre: { fr: "Durée de conservation", ar: "مدة الحفظ" },
    paragraphes: [
      {
        fr: "Les demandes sans suite sont conservées 3 ans à compter du dernier échange, puis supprimées. Les données liées à une mission réalisée sont conservées pendant la durée imposée par les obligations comptables et légales.",
        ar: "تحفظ الطلبات التي لم تتبع بمهمة مدة 3 سنوات من تاريخ آخر تبادل، ثم تحذف. أما المعطيات المرتبطة بمهمة منجزة فتحفظ طوال المدة التي تفرضها الالتزامات المحاسبية والقانونية.",
      },
    ],
  },
  {
    titre: { fr: "Vos droits", ar: "حقوقكم" },
    paragraphes: [
      {
        fr: "Vous pouvez demander l'accès à vos données, leur rectification, leur suppression ou vous opposer à leur traitement, en écrivant à operation@amanexus.com. Nous vous répondons dans les meilleurs délais.",
        ar: "يمكنكم طلب الاطلاع على معطياتكم أو تصحيحها أو حذفها أو الاعتراض على معالجتها، بالكتابة إلى operation@amanexus.com. وسنجيبكم في أقرب الآجال.",
      },
      {
        fr: "Le traitement respecte les textes applicables à la protection des données personnelles, notamment la loi togolaise n° 2019-014 du 29 octobre 2019.",
        ar: "تحترم المعالجة النصوص المطبقة في مجال حماية المعطيات الشخصية، ولا سيما القانون التوغولي رقم 2019-014 المؤرخ في 29 أكتوبر 2019.",
      },
    ],
  },
  {
    titre: { fr: "Sécurité et sous-traitants", ar: "الأمن والمتعاملون من الباطن" },
    paragraphes: [
      {
        fr: "Les échanges avec le site sont chiffrés (HTTPS). Les demandes sont stockées chez Supabase, les e-mails envoyés par Resend et le site hébergé par Vercel. L'accès aux demandes est réservé à l'équipe de NEXUS International.",
        ar: "المبادلات مع الموقع مشفرة (HTTPS). وتحفظ الطلبات لدى Supabase، وترسل الرسائل الإلكترونية عبر Resend، ويستضيف الموقع Vercel. ويقتصر الاطلاع على الطلبات على فريق نيكسوس إنترناشونال.",
      },
    ],
  },
];
