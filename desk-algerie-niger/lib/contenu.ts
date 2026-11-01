// Contenu éditorial du portail, en français et en arabe.
// Pour modifier un texte : changer la valeur « fr » ou « ar » ci-dessous.
// Règle : aucun chiffre ni aucun fait qui ne figure pas déjà ici.

import type { Langue } from "@/i18n/routing";

export type Texte = { fr: string; ar: string };
export type Liste = { fr: string[]; ar: string[] };

/** Renvoie le texte dans la langue active. */
export function tr<T>(valeur: { fr: T; ar: T }, langue: Langue): T {
  return valeur[langue];
}

export const CONTACT = {
  email: "operation@amanexus.com",
  whatsappAffiche: "+228 91 97 80 80",
  whatsappLien: "22891978080",
};

// ---------------------------------------------------------------------------
// Services
// ---------------------------------------------------------------------------

export type Service = {
  slug: string;
  image: string;
  titre: Texte;
  resume: Texte;
  inclus: Liste;
  livrables: Liste;
};

export const SERVICES: Service[] = [
  {
    slug: "s-installer-au-niger",
    image: "agadez-ville.jpg",
    titre: { fr: "S'installer au Niger", ar: "تأسيس نشاطكم في النيجر" },
    resume: {
      fr: "Créer votre société, obtenir le registre de commerce, comprendre la fiscalité, trouver un local et recruter, avec un seul interlocuteur.",
      ar: "إنشاء شركتكم، والقيد في السجل التجاري، وفهم النظام الجبائي، وإيجاد مقر، وتوظيف العمال، مع محاور واحد.",
    },
    inclus: {
      fr: [
        "Choix de la forme juridique adaptée à votre projet",
        "Constitution de la société et immatriculation au registre du commerce",
        "Immatriculation fiscale et explication des obligations déclaratives",
        "Recherche et visite d'un local ou d'un bureau, appui à la négociation du bail",
        "Appui au recrutement du personnel local",
        "Suivi des démarches administratives jusqu'au démarrage de l'activité",
      ],
      ar: [
        "اختيار الشكل القانوني الملائم لمشروعكم",
        "تأسيس الشركة وقيدها في السجل التجاري",
        "التسجيل الجبائي وشرح الالتزامات التصريحية",
        "البحث عن محل أو مكتب ومعاينته، والمساعدة في التفاوض على عقد الإيجار",
        "المساعدة في توظيف العمال المحليين",
        "متابعة الإجراءات الإدارية إلى غاية انطلاق النشاط",
      ],
    },
    livrables: {
      fr: [
        "Feuille de route des démarches",
        "Dossier de constitution complet",
        "Tableau des obligations fiscales et sociales",
        "Compte rendu écrit de chaque étape",
      ],
      ar: [
        "خارطة طريق للإجراءات",
        "ملف تأسيس كامل",
        "جدول الالتزامات الجبائية والاجتماعية",
        "تقرير مكتوب عن كل مرحلة",
      ],
    },
  },
  {
    slug: "verifier-une-entreprise",
    image: "reunion-affaires.jpg",
    titre: { fr: "Vérifier une entreprise", ar: "التحقق من مؤسسة" },
    resume: {
      fr: "Avant de signer ou de payer, savoir si votre futur partenaire existe légalement, s'il a une activité réelle et quelle est sa réputation.",
      ar: "قبل التوقيع أو الدفع، تأكدوا من الوجود القانوني لشريككم المستقبلي، ومن نشاطه الفعلي، ومن سمعته.",
    },
    inclus: {
      fr: [
        "Vérification de l'immatriculation et des dirigeants déclarés",
        "Visite sur place des locaux ou du site d'activité",
        "Recueil d'informations auprès de partenaires commerciaux, dans le respect de la loi",
        "Recherche de litiges ou d'incidents publics connus",
        "Comparaison entre l'activité annoncée et l'activité constatée",
      ],
      ar: [
        "التحقق من القيد في السجل التجاري ومن المسيرين المصرح بهم",
        "زيارة ميدانية للمقرات أو لموقع النشاط",
        "جمع المعلومات لدى الشركاء التجاريين، في إطار احترام القانون",
        "البحث عن النزاعات أو الحوادث العلنية المعروفة",
        "مقارنة النشاط المعلن بالنشاط الملاحظ ميدانيا",
      ],
    },
    livrables: {
      fr: ["Rapport de vérification écrit", "Photos de la visite sur place", "Avis motivé avant tout engagement"],
      ar: ["تقرير تحقق مكتوب", "صور الزيارة الميدانية", "رأي معلل قبل أي التزام"],
    },
  },
  {
    slug: "information-reglementaire",
    image: "port-lome-conteneurs.jpg",
    titre: { fr: "Information réglementaire", ar: "المعلومة التنظيمية" },
    resume: {
      fr: "Douane, export et import, commerce frontalier, zones franches : des réponses claires sur les règles qui s'appliquent à votre opération.",
      ar: "الجمارك، والتصدير والاستيراد، والتجارة الحدودية، والمناطق الحرة: أجوبة واضحة عن القواعد التي تطبق على عمليتكم.",
    },
    inclus: {
      fr: [
        "Identification des formalités douanières pour vos produits",
        "Documents requis à l'export depuis l'Algérie et à l'import au Niger",
        "Règles du commerce frontalier et points de passage",
        "Point sur les zones franches existantes ou à l'étude",
        "Veille sur les nouveaux textes qui concernent votre secteur",
      ],
      ar: [
        "تحديد الإجراءات الجمركية الخاصة بمنتجاتكم",
        "الوثائق المطلوبة للتصدير من الجزائر وللاستيراد إلى النيجر",
        "قواعد التجارة الحدودية ونقاط العبور",
        "عرض حول المناطق الحرة القائمة أو قيد الدراسة",
        "متابعة النصوص الجديدة التي تخص قطاعكم",
      ],
    },
    livrables: {
      fr: ["Note réglementaire adaptée à votre cas", "Liste des documents à préparer", "Séance de questions et réponses"],
      ar: ["مذكرة تنظيمية خاصة بحالتكم", "قائمة الوثائق الواجب تحضيرها", "جلسة أسئلة وأجوبة"],
    },
  },
  {
    slug: "mise-en-relation",
    image: "poignee-de-main.jpg",
    titre: { fr: "Mise en relation", ar: "ربط العلاقات" },
    resume: {
      fr: "Trouver le bon fournisseur, distributeur, sous-traitant ou partenaire industriel, présélectionné et vérifié par nos équipes.",
      ar: "إيجاد المورد أو الموزع أو المناول أو الشريك الصناعي المناسب، بعد انتقائه والتحقق منه من طرف فرقنا.",
    },
    inclus: {
      fr: [
        "Définition précise de votre besoin et de vos critères",
        "Recherche et présélection de partenaires potentiels",
        "Vérification de base de chaque partenaire retenu",
        "Organisation des échanges et des rendez-vous, NEXUS restant l'intermédiaire",
        "Suivi jusqu'à la première commande ou au premier contrat",
      ],
      ar: [
        "تحديد دقيق لحاجتكم ولمعاييركم",
        "البحث عن الشركاء المحتملين وانتقاؤهم",
        "تحقق أولي من كل شريك يقع عليه الاختيار",
        "تنظيم المبادلات والمواعيد، مع بقاء نيكسوس وسيطا",
        "المتابعة إلى غاية أول طلبية أو أول عقد",
      ],
    },
    livrables: {
      fr: ["Liste commentée de partenaires présélectionnés", "Fiche de présentation de chaque partenaire", "Compte rendu des rendez-vous"],
      ar: ["قائمة معلقة بالشركاء المنتقين", "بطاقة تعريفية لكل شريك", "محاضر المواعيد"],
    },
  },
  {
    slug: "distribution-logistique",
    image: "convoi-transsaharien.jpg",
    titre: { fr: "Distribution et logistique", ar: "التوزيع والإمداد" },
    resume: {
      fr: "Acheminer et distribuer vos produits : réseau Agadez et Tahoua, desserte de Niamey, Maradi et Zinder, ports de Lomé et Cotonou, par la route transsaharienne et par la mer depuis Oran.",
      ar: "نقل منتجاتكم وتوزيعها: شبكة أغاديس وتاهوا، وتغطية نيامي ومرادي وزيندر، وموانئ لومي وكوتونو، عبر الطريق العابر للصحراء وعن طريق البحر انطلاقا من وهران.",
    },
    inclus: {
      fr: [
        "Choix de l'itinéraire : route transsaharienne, ou voie maritime depuis Oran vers Lomé ou Cotonou",
        "Mise en relation avec des transporteurs et des transitaires",
        "Appui au stockage et à la distribution à Agadez et Tahoua",
        "Desserte de Niamey, Maradi et Zinder",
        "Recherche de distributeurs locaux",
      ],
      ar: [
        "اختيار المسار: الطريق العابر للصحراء، أو الطريق البحري من وهران نحو لومي أو كوتونو",
        "الربط مع الناقلين ووكلاء العبور",
        "المساعدة في التخزين والتوزيع في أغاديس وتاهوا",
        "تغطية نيامي ومرادي وزيندر",
        "البحث عن موزعين محليين",
      ],
    },
    livrables: {
      fr: ["Schéma logistique proposé", "Contacts vérifiés de transporteurs et de transitaires", "Liste des étapes et des documents de transport"],
      ar: ["مخطط إمداد مقترح", "جهات اتصال بناقلين ووكلاء عبور تم التحقق منهم", "قائمة مراحل النقل ووثائقه"],
    },
  },
  {
    slug: "financement-banque",
    image: "banque-financement.jpg",
    titre: { fr: "Financement et banque", ar: "التمويل والبنوك" },
    resume: {
      fr: "Monter un dossier bancable, mettre en place un crédit documentaire, préfinancer une commande : le savoir-faire de NEXUS en ingénierie financière.",
      ar: "إعداد ملف قابل للتمويل، ووضع اعتماد مستندي، والتمويل المسبق لطلبية: خبرة نيكسوس في الهندسة المالية.",
    },
    inclus: {
      fr: [
        "Diagnostic du besoin de financement",
        "Montage d'un dossier bancable : plan d'affaires, prévisions, sûretés proposées",
        "Accompagnement sur les crédits documentaires",
        "Recherche de solutions de préfinancement des commandes",
        "Présentation du dossier aux banques et aux partenaires financiers",
      ],
      ar: [
        "تشخيص الحاجة إلى التمويل",
        "إعداد ملف قابل للتمويل: مخطط أعمال، وتقديرات، وضمانات مقترحة",
        "المرافقة في الاعتمادات المستندية",
        "البحث عن حلول للتمويل المسبق للطلبيات",
        "عرض الملف على البنوك والشركاء الماليين",
      ],
    },
    livrables: {
      fr: ["Dossier de financement complet", "Plan de financement", "Liste des interlocuteurs financiers sollicités"],
      ar: ["ملف تمويل كامل", "مخطط التمويل", "قائمة الجهات المالية التي تم الاتصال بها"],
    },
  },
];

export function trouverService(slug: string) {
  return SERVICES.find((s) => s.slug === slug);
}

// ---------------------------------------------------------------------------
// Secteurs
// ---------------------------------------------------------------------------

export const SECTEURS: { code: string; image: string; titre: Texte; texte: Texte }[] = [
  {
    code: "agroalimentaire",
    image: "entrepot-agroalimentaire.jpg",
    titre: { fr: "Agroalimentaire", ar: "الصناعات الغذائية" },
    texte: {
      fr: "Produits alimentaires transformés, conserves, huiles et produits de base : recherche de fournisseurs, de distributeurs et de solutions de stockage.",
      ar: "المنتجات الغذائية المحولة، والمصبرات، والزيوت، والمواد الأساسية: البحث عن موردين وموزعين وحلول للتخزين.",
    },
  },
  {
    code: "ciment",
    image: "convoi-transsaharien.jpg",
    titre: { fr: "Ciment et matériaux", ar: "الإسمنت ومواد البناء" },
    texte: {
      fr: "Ciment, fer, matériaux de construction : approvisionnement de chantiers et de revendeurs, logistique adaptée aux charges lourdes.",
      ar: "الإسمنت والحديد ومواد البناء: تموين الورشات والتجار، وإمداد ملائم للحمولات الثقيلة.",
    },
  },
  {
    code: "energie",
    image: "energie-centrale.jpg",
    titre: { fr: "Énergie et hydrocarbures", ar: "الطاقة والمحروقات" },
    texte: {
      fr: "Sous-traitance autour des projets en cours (Sonatrach à Kafra, Sonelgaz à Niamey, Naftal pour le GPL) : services, maintenance, équipements, personnel.",
      ar: "المناولة حول المشاريع الجارية (سوناطراك في كفرا، وسونلغاز في نيامي، ونفطال في غاز البترول المميع): خدمات، وصيانة، وتجهيزات، ويد عاملة.",
    },
  },
  {
    code: "travaux-publics",
    image: "hero-route-sahara.jpg",
    titre: { fr: "Travaux publics", ar: "الأشغال العمومية" },
    texte: {
      fr: "Routes, bâtiments, ouvrages : sous-traitance, location de matériel et fourniture de matériaux, dans le sillage de la route transsaharienne.",
      ar: "الطرق والمباني والمنشآت: المناولة، وكراء العتاد، وتوريد المواد، في سياق الطريق العابر للصحراء.",
    },
  },
  {
    code: "elevage",
    image: "marche-niamey.jpg",
    titre: { fr: "Élevage", ar: "تربية المواشي" },
    texte: {
      fr: "L'élevage tient une place importante au Niger : commerce du bétail, aliments du bétail, produits vétérinaires, transformation.",
      ar: "تحتل تربية المواشي مكانة مهمة في النيجر: تجارة المواشي، والأعلاف، والمواد البيطرية، والتحويل.",
    },
  },
  {
    code: "formation",
    image: "formation-equipe.jpg",
    titre: { fr: "Formation", ar: "التكوين" },
    texte: {
      fr: "Formation technique et professionnelle, échanges universitaires, transfert de compétences entre entreprises des deux pays.",
      ar: "التكوين التقني والمهني، والتبادل الجامعي، ونقل الكفاءات بين مؤسسات البلدين.",
    },
  },
];

// ---------------------------------------------------------------------------
// Contexte : « Pourquoi maintenant »
// ---------------------------------------------------------------------------

export const CONTEXTE = {
  introduction: {
    fr: "Sous l'impulsion de Son Excellence Monsieur Abdelmadjid TEBBOUNE, Président de la République Algérienne Démocratique et Populaire, et de Son Excellence le Général d'Armée Abdourahamane TIANI, Président de la République du Niger, Chef de l'État, les relations entre les deux pays sont entrées en 2026 dans une phase concrète.",
    ar: "بتوجيه من فخامة السيد عبد المجيد تبون، رئيس الجمهورية الجزائرية الديمقراطية الشعبية، وفخامة الفريق أول عبد الرحمن تياني، رئيس جمهورية النيجر، رئيس الدولة، دخلت العلاقات بين البلدين سنة 2026 مرحلة ملموسة.",
  } as Texte,
  dates: [
    {
      date: { fr: "15 et 16 février 2026", ar: "15 و16 فيفري 2026" },
      texte: { fr: "Visite du Président Tiani à Alger.", ar: "زيارة الرئيس تياني إلى الجزائر العاصمة." },
    },
    {
      date: { fr: "23 et 24 mars 2026", ar: "23 و24 مارس 2026" },
      texte: {
        fr: "Deuxième session de la Grande commission mixte algéro-nigérienne, à Niamey.",
        ar: "الدورة الثانية للجنة المختلطة الكبرى الجزائرية النيجرية، بنيامي.",
      },
    },
  ] as { date: Texte; texte: Texte }[],
  projets: [
    { fr: "Forage de Sonatrach à Kafra", ar: "حفر سوناطراك في كفرا" },
    { fr: "Centrale de 40 MW de Sonelgaz à Niamey", ar: "محطة بقدرة 40 ميغاواط لسونلغاز في نيامي" },
    { fr: "Projets de Naftal pour le GPL", ar: "مشاريع نفطال في مجال غاز البترول المميع" },
    { fr: "Route transsaharienne", ar: "الطريق العابر للصحراء" },
    { fr: "Zone franche à l'étude à In-Guezzam", ar: "منطقة حرة قيد الدراسة في عين قزام" },
    {
      fr: "Succursale d'Algerian Bank of Senegal en préparation à Niamey",
      ar: "فرع لبنك Algerian Bank of Senegal قيد التحضير في نيامي",
    },
  ] as Texte[],
};

// ---------------------------------------------------------------------------
// Étapes de travail
// ---------------------------------------------------------------------------

export const ETAPES: { titre: Texte; texte: Texte }[] = [
  {
    titre: { fr: "Vous décrivez votre besoin", ar: "تصفون حاجتكم" },
    texte: {
      fr: "Par le formulaire ou par WhatsApp, en arabe ou en français.",
      ar: "عبر الاستمارة أو عبر واتساب، بالعربية أو بالفرنسية.",
    },
  },
  {
    titre: { fr: "Nous vous proposons une offre", ar: "نقترح عليكم عرضا" },
    texte: {
      fr: "Après un premier échange, vous recevez une offre de service écrite, avec son contenu et son prix.",
      ar: "بعد تبادل أولي، تتلقون عرض خدمة مكتوبا يحدد محتواه وسعره.",
    },
  },
  {
    titre: { fr: "Nous travaillons des deux côtés", ar: "نعمل على جانبي الحدود" },
    texte: {
      fr: "Nos équipes agissent en Algérie et au Niger et vous rendent compte à chaque étape.",
      ar: "تعمل فرقنا في الجزائر وفي النيجر وتطلعكم على سير العمل في كل مرحلة.",
    },
  },
  {
    titre: { fr: "Vous avancez vers le contrat", ar: "تتقدمون نحو العقد" },
    texte: {
      fr: "NEXUS reste votre intermédiaire jusqu'à la signature et au-delà, si vous le souhaitez.",
      ar: "تبقى نيكسوس وسيطكم إلى غاية التوقيع، وبعده إن رغبتم في ذلك.",
    },
  },
];

// ---------------------------------------------------------------------------
// Les deux publics
// ---------------------------------------------------------------------------

export type Public = {
  slug: "entreprises-algeriennes" | "operateurs-nigeriens";
  profil: "algerie" | "niger";
  image: string;
  titre: Texte;
  accroche: Texte;
  besoins: Liste;
  faq: { q: Texte; r: Texte }[];
};

const FAQ_INTERMEDIAIRE = {
  q: {
    fr: "NEXUS me met-il en contact direct avec l'autre partie ?",
    ar: "هل تضعني نيكسوس في اتصال مباشر مع الطرف الآخر؟",
  },
  r: {
    fr: "Non. NEXUS reste l'intermédiaire tout au long de la mission. C'est ce qui nous permet de vérifier les informations et de suivre chaque étape pour vous.",
    ar: "لا. تبقى نيكسوس الوسيط طوال مدة المهمة، وهذا ما يسمح لنا بالتحقق من المعلومات ومتابعة كل مرحلة لحسابكم.",
  },
};

const FAQ_RESULTAT = {
  q: {
    fr: "Pouvez-vous promettre un marché ou un financement ?",
    ar: "هل يمكنكم أن تعدوا بصفقة أو بتمويل؟",
  },
  r: {
    fr: "Non. Nous mettons notre méthode et notre réseau à votre service, mais aucun résultat ni aucun délai ne peut être promis à l'avance. La décision finale appartient toujours à vos interlocuteurs.",
    ar: "لا. نضع منهجيتنا وشبكتنا في خدمتكم، لكن لا يمكن الوعد مسبقا بأي نتيجة ولا بأي أجل. يبقى القرار النهائي دائما لمحاوريكم.",
  },
};

export const PUBLICS: Public[] = [
  {
    slug: "entreprises-algeriennes",
    profil: "algerie",
    image: "poignee-de-main.jpg",
    titre: { fr: "Pour les entreprises algériennes", ar: "للمؤسسات الجزائرية" },
    accroche: {
      fr: "Vous visez le marché nigérien, vous cherchez un distributeur ou vous voulez vous installer à Niamey ? Nous préparons le terrain et nous vous accompagnons sur place.",
      ar: "تستهدفون السوق النيجرية، أو تبحثون عن موزع، أو تريدون الاستقرار في نيامي؟ نهيئ لكم الأرضية ونرافقكم ميدانيا.",
    },
    besoins: {
      fr: [
        "S'installer au Niger ou y ouvrir une représentation",
        "Vérifier un client ou un distributeur avant d'expédier",
        "Comprendre la douane et les documents d'export",
        "Trouver un distributeur à Niamey, Agadez, Tahoua, Maradi ou Zinder",
        "Proposer vos services en sous-traitance autour des grands projets",
        "Sécuriser le paiement d'une commande par crédit documentaire",
      ],
      ar: [
        "الاستقرار في النيجر أو فتح تمثيلية فيها",
        "التحقق من زبون أو موزع قبل الإرسال",
        "فهم الإجراءات الجمركية ووثائق التصدير",
        "إيجاد موزع في نيامي أو أغاديس أو تاهوا أو مرادي أو زيندر",
        "عرض خدماتكم في المناولة حول المشاريع الكبرى",
        "تأمين دفع ثمن طلبية عبر اعتماد مستندي",
      ],
    },
    faq: [
      FAQ_INTERMEDIAIRE,
      {
        q: { fr: "Combien coûte une mission ?", ar: "كم تكلف المهمة؟" },
        r: {
          fr: "Chaque mission fait l'objet d'une offre de service écrite, établie après un premier échange sur votre besoin. Vous décidez ensuite, en connaissant le prix.",
          ar: "تكون كل مهمة موضوع عرض خدمة مكتوب، يعد بعد تبادل أولي حول حاجتكم. ثم تقررون وأنتم على علم بالسعر.",
        },
      },
      {
        q: { fr: "Dans quelle langue travaillez-vous ?", ar: "بأي لغة تعملون؟" },
        r: {
          fr: "En arabe et en français, à l'écrit comme à l'oral. Vos documents peuvent être préparés dans l'une ou l'autre langue.",
          ar: "بالعربية وبالفرنسية، كتابة وشفاهة. ويمكن إعداد وثائقكم بإحدى اللغتين.",
        },
      },
      FAQ_RESULTAT,
    ],
  },
  {
    slug: "operateurs-nigeriens",
    profil: "niger",
    image: "partenariat-marche.jpg",
    titre: { fr: "Pour les opérateurs nigériens", ar: "للمتعاملين النيجريين" },
    accroche: {
      fr: "Vous cherchez un fournisseur algérien fiable, vous voulez représenter une marque ou financer une commande ? Nous trouvons, nous vérifions et nous suivons pour vous.",
      ar: "تبحثون عن مورد جزائري موثوق، أو تريدون تمثيل علامة تجارية، أو تمويل طلبية؟ نبحث ونتحقق ونتابع لحسابكم.",
    },
    besoins: {
      fr: [
        "Trouver un fournisseur algérien fiable : agroalimentaire, ciment, matériaux, équipements",
        "Vérifier une entreprise algérienne avant de commander",
        "Organiser le transport depuis l'Algérie, par la route ou par la mer",
        "Devenir distributeur d'une marque algérienne au Niger",
        "Monter un dossier de financement pour une commande",
        "Former vos équipes avec des partenaires algériens",
      ],
      ar: [
        "إيجاد مورد جزائري موثوق: صناعات غذائية، إسمنت، مواد بناء، تجهيزات",
        "التحقق من مؤسسة جزائرية قبل الطلب",
        "تنظيم النقل من الجزائر، برا أو بحرا",
        "أن تصبحوا موزعين لعلامة جزائرية في النيجر",
        "إعداد ملف تمويل لطلبية",
        "تكوين فرقكم مع شركاء جزائريين",
      ],
    },
    faq: [
      FAQ_INTERMEDIAIRE,
      {
        q: { fr: "Je ne parle pas arabe. Est-ce un problème ?", ar: "لا أتكلم العربية. هل هذا مشكل؟" },
        r: {
          fr: "Non. Notre équipe travaille en français et en arabe et fait le lien avec vos interlocuteurs algériens.",
          ar: "لا. يعمل فريقنا بالفرنسية وبالعربية ويتولى الربط مع محاوريكم الجزائريين.",
        },
      },
      {
        q: { fr: "Pouvez-vous financer ma commande ?", ar: "هل يمكنكم تمويل طلبيتي؟" },
        r: {
          fr: "Nous montons votre dossier et le présentons à des banques et à des partenaires financiers. La décision de financement leur appartient.",
          ar: "نعد ملفكم ونعرضه على البنوك والشركاء الماليين. ويعود قرار التمويل إليهم.",
        },
      },
      FAQ_RESULTAT,
    ],
  },
];

// ---------------------------------------------------------------------------
// Villes de la route (carte de l'accueil)
// ---------------------------------------------------------------------------

export const VILLES: { code: string; nom: Texte; lat: number; lon: number; pays: "dz" | "ne" }[] = [
  { code: "alger", nom: { fr: "Alger", ar: "الجزائر العاصمة" }, lat: 36.75, lon: 3.06, pays: "dz" },
  { code: "ghardaia", nom: { fr: "Ghardaïa", ar: "غرداية" }, lat: 32.49, lon: 3.67, pays: "dz" },
  { code: "tamanrasset", nom: { fr: "Tamanrasset", ar: "تمنراست" }, lat: 22.79, lon: 5.52, pays: "dz" },
  { code: "in-guezzam", nom: { fr: "In-Guezzam", ar: "عين قزام" }, lat: 19.57, lon: 5.77, pays: "dz" },
  { code: "assamaka", nom: { fr: "Assamaka", ar: "أساماكا" }, lat: 19.35, lon: 5.80, pays: "ne" },
  { code: "agadez", nom: { fr: "Agadez", ar: "أغاديس" }, lat: 16.97, lon: 7.99, pays: "ne" },
  { code: "tahoua", nom: { fr: "Tahoua", ar: "تاهوا" }, lat: 14.89, lon: 5.27, pays: "ne" },
  { code: "niamey", nom: { fr: "Niamey", ar: "نيامي" }, lat: 13.51, lon: 2.11, pays: "ne" },
];
