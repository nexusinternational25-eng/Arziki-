#!/usr/bin/env python3
"""Construit le site NEXUS International (amanexus.com) dans deploiement-lws/.

Usage : python3 site/construire.py

Le contenu de chaque page est écrit une seule fois ici, en français et en anglais
(et en arabe pour le Desk Algérie-Niger). Le script produit, pour chaque page et
chaque langue, un fichier HTML complet avec :
- un en-tête et un pied de page communs ;
- le référencement naturel : title, description, adresse canonique, hreflang,
  Open Graph, carte Twitter, données structurées JSON-LD ;
- des liens relatifs, pour que le site marche aussi dans un dossier de test.
Il produit aussi sitemap.xml, robots.txt, .htaccess et les images en WebP.

Règles (CLAUDE.md, section 24) : aucun nom de personne, aucun chiffre non autorisé,
aucune page publique ne s'adresse aux investisseurs ni n'affiche de marge, de taux
ou de rendement ; « contrats passés devant notaire » ; avertissement R8 sur arziki.html.
"""

import html
import json
import shutil
from pathlib import Path

from PIL import Image

RACINE = Path(__file__).resolve().parent.parent
SOURCE = RACINE / "site"
SORTIE = RACINE / "deploiement-lws"
DOMAINE = "https://www.amanexus.com"
APP = "arziki/app/"  # application web ARZIKI (chemin configurable)
# Tant que l'application web n'est pas construite dans deploiement-lws/arziki/app/
# (étape 7), les boutons mènent vers la démonstration en ligne.
APP_EN_LIGNE = "https://arziki-rosy.vercel.app/app/"


def adresse_app(p):
    return p + APP if (SORTIE / APP / "index.html").exists() else APP_EN_LIGNE

EMAIL = "nexusinternational25@gmail.com"
EMAIL_COPIE = "operation@amanexus.com"
WHATSAPP = "+228 91 97 80 80"
WA = "22891978080"
ADRESSE = "18 rue Léopold Sédar Senghor, Tokoin Wuiti, Lomé, Togo"
RCCM = "TG-LFW-01-2025-A10-03200"

R8 = {
    "fr": "ARZIKI ne fait ni crédit ni collecte d'épargne. Chaque opération fait l'objet de contrats passés devant notaire. Toute participation comporte un risque de perte.",
    "en": "ARZIKI does not lend money or collect savings. Every operation is governed by contracts signed before a notary. Any participation carries a risk of loss.",
}

e = html.escape


def T(lang, fr, en, ar=None):
    """Texte selon la langue."""
    if lang == "ar":
        return ar if ar is not None else fr
    return fr if lang == "fr" else en


# ---------------------------------------------------------------------------
# Images : WebP léger (1200 et 640 px de large)
# ---------------------------------------------------------------------------

IMAGES = {
    # ancien site
    "accueil": "site/images_source/hero-african-business.jpg",
    "croissance": "site/images_source/hero-financial-growth.jpg",
    "poignee": "site/images_source/hero-handshake-international.jpg",
    "juridique": "site/images_source/hero-legal-documents.jpg",
    "monde": "site/images_source/hero-world-connections.jpg",
    "agriculture": "site/images_source/sector-agriculture.jpg",
    "chantier": "site/images_source/sector-construction.jpg",
    "financement": "site/images_source/service-financing.jpg",
    "recouvrement": "site/images_source/service-recovery.jpg",
    "equipe": "site/images_source/team-international.jpg",
    "logo": "site/images_source/logo-nexus.jpg",
    "logo-ama": "site/images_source/logo-ama.jpg",
    # banque d'images ARZIKI
    "port": "assets/images/partenariat_port.jpg",
    "convoi": "assets/images/partenariat_convoi.jpg",
    "marche": "assets/images/ambiance_marche.jpg",
    "commercante": "assets/images/accueil_commercante.jpg",
    "entrepot": "assets/images/accueil_entrepreneur_entrepot.jpg",
    "reunion": "assets/images/partenariat_reunion_investisseurs.jpg",
    "signature": "assets/images/accueil_dirigeante_signature.jpg",
    "notaire": "assets/images/cercle_notaire.jpg",
    "conseil": "assets/images/services_conseil.jpg",
    "analyse": "assets/images/services_analyse.jpg",
    "formation": "assets/images/ambiance_equipe.jpg",
    "camions": "assets/images/services_parc_camions.jpg",
    "arziki-logo": "assets/logo/arziki_logo.png",
}


def preparer_images():
    dossier = SORTIE / "images"
    dossier.mkdir(parents=True, exist_ok=True)
    for nom, chemin in IMAGES.items():
        im = Image.open(RACINE / chemin)
        im = im.convert("RGBA" if nom.endswith("logo") else "RGB")
        for largeur in (1200, 640):
            copie = im.copy()
            if copie.width > largeur:
                copie = copie.resize((largeur, round(copie.height * largeur / copie.width)), Image.LANCZOS)
            copie.save(dossier / f"{nom}-{largeur}.webp", "WEBP", quality=72, method=6)
    # Icône et image de partage
    logo = Image.open(RACINE / IMAGES["logo"]).convert("RGB")
    logo.resize((180, 180), Image.LANCZOS).save(SORTIE / "apple-touch-icon.png")
    logo.resize((48, 48), Image.LANCZOS).save(SORTIE / "favicon.png")
    partage = Image.open(RACINE / IMAGES["poignee"]).convert("RGB").resize((1200, 800), Image.LANCZOS)
    partage.crop((0, 85, 1200, 715)).save(dossier / "partage.jpg", quality=80)


def img(p, nom, alt, classe="", eager=False):
    """Image responsive en WebP, avec dimensions pour éviter les sauts de mise en page."""
    im = Image.open(RACINE / IMAGES[nom])
    h = round(im.height * 1200 / im.width)
    charge = 'fetchpriority="high"' if eager else 'loading="lazy" decoding="async"'
    return (
        f'<img src="{p}images/{nom}-1200.webp" srcset="{p}images/{nom}-640.webp 640w, {p}images/{nom}-1200.webp 1200w" '
        f'sizes="(max-width: 700px) 100vw, 600px" width="1200" height="{h}" alt="{e(alt)}" {charge}'
        + (f' class="{classe}"' if classe else "")
        + ">"
    )


# ---------------------------------------------------------------------------
# Pages : chemins et métadonnées
# ---------------------------------------------------------------------------

# id -> (fichier, langues)
PAGES = {
    "accueil": ("index.html", ["fr", "en"]),
    "expertises": ("expertises.html", ["fr", "en"]),
    "formations": ("formations.html", ["fr", "en"]),
    "services": ("services.html", ["fr", "en"]),
    "arziki": ("arziki.html", ["fr", "en"]),
    "desk": ("algerie-niger.html", ["fr", "ar", "en"]),
    "contact": ("contact.html", ["fr", "en"]),
    "mentions": ("mentions-legales.html", ["fr", "en"]),
    "confidentialite": ("confidentialite.html", ["fr", "en"]),
}


def chemin(id_, lang):
    """Chemin relatif depuis la racine du site."""
    fichier = PAGES[id_][0]
    prefixe = "" if lang == "fr" else f"{lang}/"
    if fichier == "index.html":
        return prefixe
    return prefixe + fichier


def url(id_, lang):
    return f"{DOMAINE}/{chemin(id_, lang)}"


def lien(depuis_lang, id_, lang=None):
    """Lien relatif d'une page (écrite dans depuis_lang) vers une autre page."""
    cible = chemin(id_, lang or depuis_lang)
    relatif = ("" if depuis_lang == "fr" else "../") + cible
    return relatif or "./"


def prefixe(lang):
    return "" if lang == "fr" else "../"


MENU = [
    ("accueil", "Accueil", "Home", "الرئيسية"),
    ("expertises", "Nos expertises", "Our expertise", "خبراتنا"),
    ("formations", "Formations", "Training", "التكوين"),
    ("services", "Business Services", "Business Services", "خدمات الأعمال"),
    ("arziki", "ARZIKI", "ARZIKI", "ARZIKI"),
    ("desk", "Desk Algérie-Niger", "Algeria-Niger Desk", "مكتب الجزائر - النيجر"),
    ("contact", "Contact", "Contact", "اتصل بنا"),
]


# ---------------------------------------------------------------------------
# Gabarit commun
# ---------------------------------------------------------------------------

ORGANISATION = {
    "@type": ["Organization", "ProfessionalService"],
    "@id": f"{DOMAINE}/#organisation",
    "name": "NEXUS International",
    "url": f"{DOMAINE}/",
    "logo": f"{DOMAINE}/images/logo-640.webp",
    "image": f"{DOMAINE}/images/partage.jpg",
    "email": EMAIL,
    "telephone": "+22891978080",
    "address": {
        "@type": "PostalAddress",
        "streetAddress": "18 rue Léopold Sédar Senghor, Tokoin Wuiti",
        "addressLocality": "Lomé",
        "addressCountry": "TG",
    },
    "areaServed": ["Togo", "Bénin", "Niger", "Côte d'Ivoire", "Burkina Faso", "Sénégal", "Mali", "Ghana", "Algérie"],
    "knowsLanguage": ["fr", "en", "ar"],
    "contactPoint": {
        "@type": "ContactPoint",
        "contactType": "customer service",
        "telephone": "+22891978080",
        "email": EMAIL,
        "availableLanguage": ["French", "English", "Arabic"],
    },
}


def gabarit(id_, lang, titre, description, corps, jsonld=None, image_partage="images/partage.jpg", noindex=False):
    p = prefixe(lang)
    direction = "rtl" if lang == "ar" else "ltr"
    langues = PAGES[id_][1]
    alternates = "\n".join(
        f'  <link rel="alternate" hreflang="{l}" href="{url(id_, l)}">' for l in langues
    ) + f'\n  <link rel="alternate" hreflang="x-default" href="{url(id_, "fr")}">'
    og_locale = {"fr": "fr_FR", "en": "en_US", "ar": "ar_AR"}[lang]
    donnees = [ORGANISATION]
    if id_ != "accueil":
        donnees.append({
            "@type": "BreadcrumbList",
            "itemListElement": [
                {"@type": "ListItem", "position": 1, "name": T(lang, "Accueil", "Home", "الرئيسية"), "item": url("accueil", "fr" if lang == "ar" else lang)},
                {"@type": "ListItem", "position": 2, "name": titre.split(" | ")[0], "item": url(id_, lang)},
            ],
        })
    if jsonld:
        donnees.extend(jsonld)
    jsonld_txt = json.dumps({"@context": "https://schema.org", "@graph": donnees}, ensure_ascii=False, indent=1)

    menu = "\n".join(
        f'        <a href="{lien(lang, i, "fr" if lang == "ar" and i != "desk" else lang)}"'
        + (' aria-current="page"' if i == id_ else "")
        + f">{e(T(lang, fr, en, ar))}</a>"
        for i, fr, en, ar in MENU
    )
    choix_langues = "\n".join(
        f'        <a href="{lien(lang, id_, l)}" hreflang="{l}" lang="{l}"'
        + (' aria-current="true"' if l == lang else "")
        + f">{ {'fr': 'FR', 'en': 'EN', 'ar': 'عربي'}[l]}</a>"
        for l in langues
    )
    lang_menu = "fr" if lang == "ar" else lang

    return f"""<!DOCTYPE html>
<html lang="{lang}" dir="{direction}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{e(titre)}</title>
  <meta name="description" content="{e(description)}">
  {'<meta name="robots" content="noindex, follow">' if noindex else '<meta name="robots" content="index, follow, max-image-preview:large">'}
  <link rel="canonical" href="{url(id_, lang)}">
{alternates}
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="NEXUS International">
  <meta property="og:locale" content="{og_locale}">
  <meta property="og:title" content="{e(titre)}">
  <meta property="og:description" content="{e(description)}">
  <meta property="og:url" content="{url(id_, lang)}">
  <meta property="og:image" content="{DOMAINE}/{image_partage}">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="{e(titre)}">
  <meta name="twitter:description" content="{e(description)}">
  <meta name="twitter:image" content="{DOMAINE}/{image_partage}">
  <meta name="theme-color" content="#1B9E4B">
  <link rel="icon" type="image/png" href="{p}favicon.png">
  <link rel="apple-touch-icon" href="{p}apple-touch-icon.png">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700{'&family=Noto+Kufi+Arabic:wght@400;600;700' if lang == 'ar' else ''}&display=swap">
  <link rel="stylesheet" href="{p}style.css">
  <script type="application/ld+json">
{jsonld_txt}
  </script>
</head>
<body>
  <a class="passer" href="#contenu">{T(lang, "Aller au contenu", "Skip to content", "انتقل إلى المحتوى")}</a>
  <header class="entete">
    <div class="in">
      <a class="marque" href="{lien(lang, 'accueil', lang_menu)}">{img(p, 'logo', '', eager=True).replace('sizes="(max-width: 700px) 100vw, 600px"', 'sizes="40px"')}<span>NEXUS International</span></a>
      <nav class="menu" aria-label="{T(lang, 'Menu principal', 'Main menu', 'القائمة الرئيسية')}">
{menu}
      </nav>
      <div class="langues">
{choix_langues}
      </div>
      <button class="burger" aria-label="{T(lang, 'Ouvrir le menu', 'Open the menu', 'فتح القائمة')}" aria-expanded="false"><span></span><span></span><span></span></button>
    </div>
  </header>
  <main id="contenu">
{corps}
  </main>
{pied(lang, id_)}
  <a class="wa" href="https://wa.me/{WA}" rel="noopener">WhatsApp</a>
  <script src="{p}site.js" defer></script>
</body>
</html>
"""


def pied(lang, id_):
    lm = "fr" if lang == "ar" else lang
    r8 = f'<p class="bas"><b>{e(R8[lm])}</b></p>' if id_ == "arziki" else ""
    return f"""  <footer>
    <div class="in">
      <div class="grille">
        <div>
          <h3>NEXUS International</h3>
          <p>{T(lang, "Cabinet d'affaires basé à Lomé, actif dans 19 pays d'Afrique de l'Ouest et du Centre.", "Business advisory firm based in Lomé, active in 19 countries in West and Central Africa.", "مكتب أعمال مقره لومي، ينشط في 19 بلدا في غرب أفريقيا ووسطها.")}</p>
          <p>{e(ADRESSE)}</p>
        </div>
        <div>
          <h3>{T(lang, "Nous joindre", "Contact us", "للتواصل معنا")}</h3>
          <p>WhatsApp : <a href="https://wa.me/{WA}">{WHATSAPP}</a><br>
          E-mail : <a href="mailto:{EMAIL}">{EMAIL}</a><br>
          <a href="mailto:{EMAIL_COPIE}">{EMAIL_COPIE}</a></p>
        </div>
        <div>
          <h3>{T(lang, "Liens", "Links", "روابط")}</h3>
          <p><a href="{lien(lang, 'services', lm)}">Business Services</a><br>
          <a href="{lien(lang, 'arziki', lm)}">ARZIKI</a><br>
          <a href="{lien(lang, 'desk', lang if lang != 'en' else 'en')}">{T(lang, "Desk Algérie-Niger", "Algeria-Niger Desk", "مكتب الجزائر - النيجر")}</a><br>
          <a href="{lien(lang, 'mentions', lm)}">{T(lang, "Mentions légales", "Legal notice", "الإشعارات القانونية")}</a><br>
          <a href="{lien(lang, 'confidentialite', lm)}">{T(lang, "Confidentialité", "Privacy", "سياسة الخصوصية")}</a></p>
        </div>
      </div>
      {r8}
      <p class="bas">© NEXUS International · RCCM {RCCM}</p>
    </div>
  </footer>"""


def formulaire(lang, nom_formulaire, besoins=None, pays=None, entreprise=True, dates=False):
    """Formulaire commun : vers contact.php, champ piège et horodatage anti-robot."""
    p = prefixe(lang)
    page = chemin(nom_formulaire[0], lang) or "index.html"
    options_besoin = ""
    if besoins:
        options_besoin = f"""
      <label>{T(lang, "Votre besoin", "Your need", "حاجتكم")}
        <select name="besoin" required>
          <option value="">{T(lang, "Choisissez", "Choose", "اختر")}</option>
          {''.join(f'<option>{e(b)}</option>' for b in besoins)}
        </select>
      </label>"""
    options_pays = ""
    if pays:
        options_pays = f"""
      <label>{T(lang, "Pays", "Country", "البلد")}
        <select name="pays" required>
          <option value="">{T(lang, "Choisissez", "Choose", "اختر")}</option>
          {''.join(f'<option>{e(x)}</option>' for x in pays)}
        </select>
      </label>"""
    return f"""
    <form class="formulaire" method="post" action="{p}contact.php" id="formulaire">
      <p id="message-envoi" hidden data-ok="{e(T(lang, "Merci, votre message est bien envoyé. Nous vous répondons rapidement.", "Thank you, your message has been sent. We will reply shortly.", "شكرا، تم إرسال رسالتكم. سنرد عليكم قريبا."))}" data-ko="{e(T(lang, "Le message n'a pas pu partir. Vérifiez les champs ou écrivez-nous sur WhatsApp.", "The message could not be sent. Check the fields or write to us on WhatsApp.", "تعذر إرسال الرسالة. تحققوا من الحقول أو راسلونا عبر واتساب."))}"></p>
      <input type="hidden" name="formulaire" value="{e(nom_formulaire[1])}">
      <input type="hidden" name="page" value="{e(page)}">
      <input type="hidden" name="langue" value="{lang}">
      <input type="hidden" name="t" value="">
      <div class="piege" aria-hidden="true"><label>Site web <input type="text" name="site_web" tabindex="-1" autocomplete="off"></label></div>
      <div class="duo">
        <label>{T(lang, "Nom complet", "Full name", "الاسم الكامل")}<input name="nom" required minlength="2" maxlength="120" autocomplete="name"></label>
        {'<label>' + T(lang, "Entreprise ou organisation", "Company or organisation", "المؤسسة أو الهيئة") + '<input name="entreprise" maxlength="160" autocomplete="organization"></label>' if entreprise else ''}
      </div>
      <div class="duo">
        <label>E-mail<input type="email" name="email" maxlength="160" autocomplete="email"></label>
        <label>{T(lang, "Téléphone ou WhatsApp", "Phone or WhatsApp", "الهاتف أو واتساب")}<input type="tel" name="telephone" maxlength="40" autocomplete="tel" placeholder="+228"></label>
      </div>{options_besoin}{options_pays}{('<label>' + T(lang, "Dates prévues", "Planned dates") + '<input name="dates" maxlength="80"></label>') if dates else ''}
      <label>{T(lang, "Votre message", "Your message", "رسالتكم")}<textarea name="message" required minlength="10" maxlength="5000" rows="5"></textarea></label>
      <label class="case"><input type="checkbox" name="consentement" value="oui" required> <span>{T(lang, "J'accepte que NEXUS International utilise ces informations pour répondre à ma demande, selon la politique de confidentialité.", "I agree that NEXUS International may use this information to reply to my request, in line with the privacy policy.", "أوافق على أن تستخدم نيكسوس إنترناشونال هذه المعلومات للرد على طلبي، وفق سياسة الخصوصية.")}</span></label>
      <p class="discret">{T(lang, "Indiquez au moins un e-mail ou un numéro de téléphone.", "Please give at least an e-mail address or a phone number.", "يرجى ذكر بريد إلكتروني أو رقم هاتف على الأقل.")}</p>
      <button class="bouton" type="submit">{T(lang, "Envoyer", "Send", "إرسال")}</button>
    </form>"""


def faq_jsonld(questions):
    return {
        "@type": "FAQPage",
        "mainEntity": [
            {"@type": "Question", "name": q, "acceptedAnswer": {"@type": "Answer", "text": r}} for q, r in questions
        ],
    }


def faq_html(questions):
    return "\n".join(f"      <details><summary>{e(q)}</summary><p>{e(r)}</p></details>" for q, r in questions)


def hero(p, image, sur, titre, texte, actions="", fil=None, chiffres=""):
    return f"""    <div class="hero">
      {img(p, image, '', 'fond', eager=True)}
      <div class="in">
        {fil or ''}
        <span class="sur">{e(sur)}</span>
        <h1>{e(titre)}</h1>
        <p>{e(texte)}</p>
        {('<div class="actions">' + actions + '</div>') if actions else ''}
        {chiffres}
      </div>
    </div>"""


def fil_ariane(lang, nom):
    return f'<p class="fil"><a href="{lien(lang, "accueil", "fr" if lang == "ar" else lang)}">{T(lang, "Accueil", "Home", "الرئيسية")}</a> › {e(nom)}</p>'


# ---------------------------------------------------------------------------
# Contenu : familles d'expertises (anciens services + métier réel, rien supprimé)
# ---------------------------------------------------------------------------

def familles(lang):
    return [
        ("", T(lang, "Financement", "Financing"), "financement", [
            T(lang, "Mobilisation de ressources et levée de fonds", "Resource mobilisation and fundraising"),
            T(lang, "Ingénierie financière et montage de dossiers de financement", "Financial engineering and funding applications"),
            T(lang, "Mémorandums d'investissement et modèles financiers", "Investment memorandums and financial models"),
            T(lang, "Partenariats public-privé (PPP)", "Public-private partnerships (PPP)"),
            T(lang, "Projets immobiliers : faisabilité, financement, montage", "Real estate projects: feasibility, funding, structuring"),
        ]),
        ("o", T(lang, "Affaires et intermédiation", "Business and brokerage"), "poignee", [
            T(lang, "Intermédiation et origination d'affaires", "Deal brokerage and origination"),
            T(lang, "Lobbying institutionnel", "Institutional advocacy"),
            T(lang, "Études de marché et implantation", "Market studies and market entry"),
            T(lang, "Due diligence commerciale, financière et opérationnelle", "Commercial, financial and operational due diligence"),
            T(lang, "Assistance pour l'obtention d'agréments et de licences", "Support to obtain approvals and licences"),
        ]),
        ("r", T(lang, "Juridique et recouvrement", "Legal and debt recovery"), "recouvrement", [
            T(lang, "Recouvrement international amiable, avec le cabinet partenaire AMA", "Amicable international debt recovery, with our partner firm AMA"),
            T(lang, "Dossiers complexes et sensibles, plusieurs pays", "Complex and sensitive cross-border cases"),
            T(lang, "Assistance juridique et contractuelle (OHADA, UEMOA)", "Legal and contract support (OHADA, WAEMU)"),
            T(lang, "Agent d'affaires et apport d'affaires", "Business agent and introductions"),
        ]),
        ("j", T(lang, "Formation", "Training"), "formation", [
            T(lang, "Formations sur mesure : présentiel, à distance, en entreprise", "Tailor-made training: on site, remote, in-house"),
            T(lang, "Gouvernance, gestion financière, leadership", "Governance, financial management, leadership"),
            T(lang, "Droit humanitaire, droit de l'enfant, protection des données", "Humanitarian law, child rights, data protection"),
            T(lang, "Entrepreneuriat des jeunes", "Youth entrepreneurship"),
        ]),
    ]


def cartes_familles(lang, p, detail=False):
    out = []
    for classe, titre, image, items in familles(lang):
        out.append(f"""        <article class="carte famille {classe}">
          {img(p, image, titre)}
          <div class="c">
            <h3>{e(titre)}</h3>
            <ul>{''.join(f'<li>{e(i)}</li>' for i in items)}</ul>
          </div>
        </article>""")
    return "\n".join(out)


# ---------------------------------------------------------------------------
# Pages
# ---------------------------------------------------------------------------

def page_accueil(lang):
    p = prefixe(lang)
    faq = [
        (T(lang, "Que fait NEXUS International ?", "What does NEXUS International do?"),
         T(lang, "NEXUS International est un cabinet d'affaires basé à Lomé. Il mobilise des ressources et des financements, prépare les dossiers et mémorandums d'investissement, met en relation les entreprises, accompagne le recouvrement amiable avec le cabinet partenaire AMA, et forme les équipes.",
           "NEXUS International is a business advisory firm based in Lomé. It mobilises resources and funding, prepares funding applications and investment memorandums, connects companies, supports amicable debt recovery with its partner firm AMA, and trains teams.")),
        (T(lang, "Dans quels pays intervenez-vous ?", "Which countries do you work in?"),
         T(lang, "Dans 19 pays d'Afrique de l'Ouest et du Centre, francophones et anglophones, dont le Togo, le Bénin, le Niger, la Côte d'Ivoire, le Burkina Faso, le Sénégal, le Mali et le Ghana.",
           "In 19 countries in West and Central Africa, both French- and English-speaking, including Togo, Benin, Niger, Côte d'Ivoire, Burkina Faso, Senegal, Mali and Ghana.")),
        (T(lang, "Le premier rendez-vous est-il payant ?", "Is the first meeting charged?"),
         T(lang, "Non. La première consultation stratégique est gratuite. Nous vous remettons ensuite une offre écrite.",
           "No. The first strategy consultation is free. We then send you a written proposal.")),
        (T(lang, "Combien de temps dure un recouvrement amiable ?", "How long does amicable debt recovery take?"),
         T(lang, "En moyenne de 21 à 90 jours selon le dossier, les pays concernés et la réponse du débiteur.",
           "On average 21 to 90 days, depending on the case, the countries involved and the debtor's response.")),
    ]
    chiffres = f"""<div class="chiffres">
          <div><b>19</b>{T(lang, "pays couverts", "countries covered")}</div>
          <div><b>30 M USD</b>{T(lang, "financement validé", "funding approved")}</div>
          <div><b>160 M USD</b>{T(lang, "financement validé", "funding approved")}</div>
          <div><b>15 ans +</b>{T(lang, "d'expérience en recouvrement international", "of international debt recovery experience")}</div>
        </div>"""
    corps = hero(
        p, "accueil",
        T(lang, "Cabinet d'affaires · Lomé, Togo", "Business advisory firm · Lomé, Togo"),
        T(lang, "Financer vos projets, sécuriser vos affaires en Afrique de l'Ouest", "Funding your projects, securing your business in West Africa"),
        T(lang, "Levée de fonds, ingénierie financière, intermédiation, recouvrement et formation : NEXUS International accompagne les entreprises et les institutions dans 19 pays d'Afrique de l'Ouest et du Centre.",
          "Fundraising, financial engineering, brokerage, debt recovery and training: NEXUS International supports companies and institutions in 19 countries in West and Central Africa."),
        f'<a class="bouton" href="{lien(lang, "contact")}">{T(lang, "Consultation gratuite", "Free consultation")}</a><a class="bouton clair" href="{lien(lang, "expertises")}">{T(lang, "Nos expertises", "Our expertise")}</a>',
        chiffres=chiffres,
    ) + f"""
    <section>
      <div class="in">
        <span class="sur">{T(lang, "Ce que nous faisons", "What we do")}</span>
        <h2>{T(lang, "Quatre familles d'expertises", "Four areas of expertise")}</h2>
        <p class="intro">{T(lang, "Une équipe d'experts aux compétences juridiques, financières, stratégiques, techniques et institutionnelles, avec le cabinet partenaire AMA pour l'expertise juridique et le recouvrement.", "A team of experts with legal, financial, strategic, technical and institutional skills, working with our partner firm AMA for legal expertise and debt recovery.")}</p>
        <div class="grille">
{cartes_familles(lang, p)}
        </div>
        <div class="actions"><a class="bouton vert" href="{lien(lang, 'expertises')}">{T(lang, "Voir toutes nos expertises", "See all our expertise")}</a></div>
      </div>
    </section>
    <section class="doux">
      <div class="in">
        <span class="sur">{T(lang, "Nos nouvelles activités", "Our new activities")}</span>
        <h2>{T(lang, "Trois offres pour aller plus loin", "Three offers to go further")}</h2>
        <div class="grille">
          <article class="carte">{img(p, 'port', 'Port de Lomé')}<div class="c"><span class="etiquette o">Business Services</span><h3>{T(lang, "Vos affaires à Lomé", "Your business in Lomé")}</h3><p>{T(lang, "Accueil de délégations, achat pour compte et expédition Lomé-Niamey, représentation de marques, produits du Sahel.", "Hosting business delegations, purchasing on your behalf and shipping Lomé to Niamey, brand representation, Sahel products.")}</p><a class="lien" href="{lien(lang, 'services')}">{T(lang, "Découvrir", "Discover")} →</a></div></article>
          <article class="carte">{img(p, 'entrepot', T(lang, 'Entrepreneur dans son entrepôt', 'Entrepreneur in a warehouse'))}<div class="c"><span class="etiquette">ARZIKI</span><h3>{T(lang, "Financez vos commandes", "Fund your orders")}</h3><p>{T(lang, "Une commande ferme, pas la trésorerie pour acheter ? ARZIKI vous aide, avec des contrats passés devant notaire. Et prépare vos dossiers.", "A firm order but no cash to buy the goods? ARZIKI helps you, with contracts signed before a notary. And prepares your files.")}</p><a class="lien" href="{lien(lang, 'arziki')}">{T(lang, "Découvrir", "Discover")} →</a></div></article>
          <article class="carte">{img(p, 'convoi', T(lang, 'Convoi de camions', 'Truck convoy'))}<div class="c"><span class="etiquette j">Desk</span><h3>{T(lang, "Algérie, Niger et côte ouest-africaine", "Algeria, Niger and the West African coast")}</h3><p>{T(lang, "Un pont d'affaires entre l'Algérie et le Niger, prolongé vers les ports de Lomé et de Cotonou.", "A business bridge between Algeria and Niger, extended to the ports of Lomé and Cotonou.")}</p><a class="lien" href="{lien(lang, 'desk')}">{T(lang, "Découvrir", "Discover")} →</a></div></article>
        </div>
      </div>
    </section>
    <section>
      <div class="in deux">
        <div class="photo">{img(p, 'equipe', T(lang, "L'équipe NEXUS International en réunion", "The NEXUS International team in a meeting"))}</div>
        <div>
          <span class="sur">{T(lang, "Pourquoi nous", "Why us")}</span>
          <h2>{T(lang, "Une expertise reconnue", "Recognised expertise")}</h2>
          <ul class="liste">
            <li>{T(lang, "Conseiller en investissement certifié USAID CATALYZE Sahel", "USAID CATALYZE Sahel certified investment advisor")}</li>
            <li>{T(lang, "Certification du CESAG (Dakar) en diagnostic économique et financier de l'entreprise", "CESAG (Dakar) certification in economic and financial business diagnosis")}</li>
            <li>{T(lang, "Des financements validés de 30 M USD et de 160 M USD", "Approved funding of USD 30 M and USD 160 M")}</li>
            <li>{T(lang, "Plusieurs centaines de millions de FCFA mobilisés pour plus d'une centaine d'entreprises agricoles et agroalimentaires dans le cadre du programme USAID CATALYZE", "Several hundred million CFA francs mobilised for more than a hundred agricultural and agri-food companies under the USAID CATALYZE programme")}</li>
            <li>{T(lang, "Agréé par les autorités compétentes, présent dans 19 pays avec un réseau de partenaires locaux", "Approved by the relevant authorities, present in 19 countries with a network of local partners")}</li>
          </ul>
        </div>
      </div>
    </section>
    <section class="doux">
      <div class="in deux">
        <div>
          <span class="sur">{T(lang, "Formations", "Training")}</span>
          <h2>{T(lang, "Renforcer les compétences de vos équipes", "Building your teams' skills")}</h2>
          <p class="intro">{T(lang, "Sept programmes, en présentiel, à distance ou dans vos locaux : gouvernance, gestion financière, leadership, droit humanitaire, droit de l'enfant, protection des données, entrepreneuriat des jeunes.", "Seven programmes, on site, remote or in-house: governance, financial management, leadership, humanitarian law, child rights, data protection, youth entrepreneurship.")}</p>
          <a class="bouton vert" href="{lien(lang, 'formations')}">{T(lang, "Voir les formations", "See the programmes")}</a>
        </div>
        <div class="photo">{img(p, 'formation', T(lang, 'Session de formation', 'Training session'))}</div>
      </div>
    </section>
    <section>
      <div class="in">
        <span class="sur">{T(lang, "Questions fréquentes", "Frequently asked questions")}</span>
        <h2>{T(lang, "Vos questions", "Your questions")}</h2>
{faq_html(faq)}
      </div>
    </section>
    <section class="doux">
      <div class="in deux">
        <div>
          <h2>{T(lang, "Parlons de votre projet", "Let's talk about your project")}</h2>
          <p class="intro">{T(lang, "Première consultation stratégique gratuite. Réponse sous 48 heures ouvrées.", "Free first strategy consultation. Reply within 48 working hours.")}</p>
          <p>WhatsApp : <a href="https://wa.me/{WA}">{WHATSAPP}</a><br>E-mail : <a href="mailto:{EMAIL}">{EMAIL}</a></p>
        </div>
{formulaire(lang, ('accueil', 'Accueil'), besoins=[T(lang, 'Levée de fonds ou financement', 'Fundraising or funding'), T(lang, 'Intermédiation ou affaires', 'Brokerage or business'), T(lang, 'Recouvrement de créances', 'Debt recovery'), T(lang, 'Juridique (OHADA, UEMOA)', 'Legal (OHADA, WAEMU)'), T(lang, 'Formation', 'Training'), T(lang, 'Autre', 'Other')])}
      </div>
    </section>"""
    return (
        T(lang, "NEXUS International | Cabinet d'affaires à Lomé, Togo", "NEXUS International | Business advisory firm in Lomé, Togo"),
        T(lang, "Cabinet d'affaires basé à Lomé (Togo), actif dans 19 pays d'Afrique : levée de fonds, ingénierie financière, intermédiation, recouvrement de créances avec AMA, juridique OHADA, formation. Consultation gratuite.",
          "Business advisory firm based in Lomé (Togo), active in 19 African countries: fundraising, financial engineering, brokerage, debt recovery with AMA, OHADA legal support, training. Free consultation."),
        corps,
        [faq_jsonld(faq)],
    )


def page_expertises(lang):
    p = prefixe(lang)
    details = [
        ("financement", T(lang, "Mobilisation de ressources et levée de fonds", "Resource mobilisation and fundraising"),
         T(lang, "Nous identifions les sources de financement adaptées (banques, fonds, bailleurs, partenaires financiers), préparons le dossier et accompagnons les rendez-vous jusqu'à la décision.", "We identify suitable funding sources (banks, funds, donors, investors), prepare the file and support the meetings until the decision.")),
        ("croissance", T(lang, "Ingénierie financière et mémorandums d'investissement", "Financial engineering and investment memorandums"),
         T(lang, "Structuration du montage, modèle financier, mémorandum d'investissement : des documents clairs, chiffrés et vérifiables.", "Deal structuring, financial model, investment memorandum: clear, quantified and verifiable documents.")),
        ("chantier", T(lang, "Partenariats public-privé et projets immobiliers", "Public-private partnerships and real estate projects"),
         T(lang, "Accompagnement des PPP complexes et des projets immobiliers : études de faisabilité, recherche de financements, sécurisation juridique et contractuelle des montages.", "Support for complex PPPs and real estate projects: feasibility studies, funding search, legal and contractual structuring.")),
        ("poignee", T(lang, "Intermédiation, origination d'affaires et lobbying institutionnel", "Brokerage, deal origination and institutional advocacy"),
         T(lang, "Nous mettons en relation les entreprises avec des partenaires, clients et institutions, et portons leurs dossiers auprès des décideurs.", "We connect companies with partners, clients and institutions, and present their cases to decision-makers.")),
        ("monde", T(lang, "Études de marché, implantation, agréments et licences", "Market studies, market entry, approvals and licences"),
         T(lang, "Études sectorielles et de faisabilité, feuille de route d'implantation, démarches pour obtenir agréments et licences sans blocage administratif.", "Sector and feasibility studies, market entry roadmap, procedures to obtain approvals and licences without administrative delays.")),
        ("analyse", T(lang, "Due diligence", "Due diligence"),
         T(lang, "Analyse commerciale, financière et opérationnelle d'une opportunité ou d'un partenaire, pour décider en connaissance de cause.", "Commercial, financial and operational analysis of an opportunity or a partner, for informed decisions.")),
        ("recouvrement", T(lang, "Recouvrement international amiable", "Amicable international debt recovery"),
         T(lang, "Avec le cabinet partenaire AMA : dossiers multi-pays, complexes et sensibles, traités avec discrétion. Délai moyen de 21 à 90 jours. Plus de 15 ans d'expérience.", "With our partner firm AMA: cross-border, complex and sensitive cases, handled discreetly. Average time 21 to 90 days. More than 15 years of experience.")),
        ("juridique", T(lang, "Assistance juridique et contractuelle", "Legal and contract support"),
         T(lang, "Contrats, conformité et sécurisation de vos opérations selon le droit OHADA et les règles de l'UEMOA.", "Contracts, compliance and securing your operations under OHADA law and WAEMU rules.")),
    ]
    services_jsonld = [
        {"@type": "Service", "name": t, "description": d, "provider": {"@id": f"{DOMAINE}/#organisation"}, "areaServed": "Afrique de l'Ouest"}
        for _, t, d in details
    ]
    cartes = "\n".join(
        f"""          <article class="carte">{img(p, im, t)}<div class="c"><h3>{e(t)}</h3><p>{e(d)}</p></div></article>"""
        for im, t, d in details
    )
    corps = hero(p, "croissance", T(lang, "Nos expertises", "Our expertise"),
                 T(lang, "Financement, affaires, juridique et formation", "Funding, business, legal and training"),
                 T(lang, "Tous nos métiers, regroupés en quatre familles, pour un interlocuteur unique du premier rendez-vous à la réussite du projet.", "All our services, grouped into four areas, for a single contact from the first meeting to project success."),
                 fil=fil_ariane(lang, T(lang, "Nos expertises", "Our expertise"))) + f"""
    <section>
      <div class="in">
        <h2>{T(lang, "Les quatre familles", "The four areas")}</h2>
        <div class="grille">
{cartes_familles(lang, p)}
        </div>
      </div>
    </section>
    <section class="doux">
      <div class="in">
        <h2>{T(lang, "Le détail de nos interventions", "Our services in detail")}</h2>
        <div class="grille">
{cartes}
        </div>
      </div>
    </section>
    <section>
      <div class="in deux">
        <div>
          <h2>{T(lang, "Comment nous travaillons", "How we work")}</h2>
          <ol class="etapes">
            <li>{T(lang, "Consultation gratuite pour comprendre votre besoin", "Free consultation to understand your need")}</li>
            <li>{T(lang, "Offre écrite : contenu, délai, honoraires", "Written proposal: scope, timeline, fees")}</li>
            <li>{T(lang, "Mission, avec un point d'avancement régulier", "Assignment, with regular progress updates")}</li>
            <li>{T(lang, "Remise des livrables et suivi", "Delivery and follow-up")}</li>
          </ol>
        </div>
{formulaire(lang, ('expertises', 'Nos expertises'), besoins=[t for _, t, _ in details] + [T(lang, 'Autre', 'Other')])}
      </div>
    </section>"""
    return (
        T(lang, "Levée de fonds, recouvrement, juridique OHADA | NEXUS International", "Fundraising, debt recovery, OHADA legal | NEXUS International"),
        T(lang, "Levée de fonds, ingénierie financière, mémorandums, PPP et immobilier, intermédiation et lobbying, études de marché, agréments, due diligence, recouvrement avec AMA, juridique OHADA et UEMOA.",
          "Fundraising, financial engineering, memorandums, PPP and real estate, brokerage and advocacy, market studies, licences, due diligence, debt recovery with AMA, OHADA and WAEMU legal support."),
        corps, services_jsonld,
    )


def page_formations(lang):
    p = prefixe(lang)
    programmes = [
        (T(lang, "Droit humanitaire international", "International humanitarian law"),
         T(lang, "Les principes du droit humanitaire, les conventions de Genève et les obligations légales de protection des personnes.", "The principles of humanitarian law, the Geneva Conventions and legal duties to protect people."),
         [T(lang, "Conventions de Genève", "Geneva Conventions"), T(lang, "Droit des conflits", "Law of armed conflict"), T(lang, "Protection civile", "Civil protection"), T(lang, "Responsabilité légale", "Legal liability")]),
        (T(lang, "Gouvernance et administration", "Governance and administration"),
         T(lang, "Bonnes pratiques de gouvernance, gestion administrative et conformité pour une organisation transparente et efficace.", "Good governance, administrative management and compliance for a transparent and effective organisation."),
         [T(lang, "Gouvernance d'entreprise", "Corporate governance"), T(lang, "Gestion administrative", "Administrative management"), T(lang, "Conformité légale", "Legal compliance"), T(lang, "Audit interne", "Internal audit")]),
        (T(lang, "Entrepreneuriat des jeunes", "Youth entrepreneurship"),
         T(lang, "Créer son entreprise : business plan, recherche de financement, gestion et marketing.", "Starting a business: business plan, funding, management and marketing."),
         [T(lang, "Création d'entreprise", "Starting a business"), "Business plan", T(lang, "Financement", "Funding"), T(lang, "Marketing digital", "Digital marketing")]),
        (T(lang, "Protection des données et sécurité", "Data protection and security"),
         T(lang, "Règles de protection des données, cybersécurité et bonnes pratiques pour protéger votre organisation.", "Data protection rules, cybersecurity and good practices to protect your organisation."),
         [T(lang, "Conformité", "Compliance"), T(lang, "Cybersécurité", "Cybersecurity"), T(lang, "Gestion des risques", "Risk management"), T(lang, "Audit de sécurité", "Security audit")]),
        (T(lang, "Gestion financière avancée", "Advanced financial management"),
         T(lang, "Analyse financière, trésorerie et planification budgétaire pour mieux piloter vos ressources.", "Financial analysis, cash management and budgeting to better steer your resources."),
         [T(lang, "Analyse financière", "Financial analysis"), T(lang, "Gestion de trésorerie", "Cash management"), T(lang, "Planification budgétaire", "Budget planning"), T(lang, "Décision d'investissement", "Investment decisions")]),
        (T(lang, "Leadership et management stratégique", "Leadership and strategic management"),
         T(lang, "Management d'équipe, prise de décision et conduite du changement.", "Team management, decision-making and change management."),
         [T(lang, "Leadership", "Leadership"), T(lang, "Gestion d'équipe", "Team management"), T(lang, "Stratégie", "Strategy"), T(lang, "Gestion du changement", "Change management")]),
        (T(lang, "Formations spécialisées et due diligence", "Specialised training and due diligence"),
         T(lang, "Droit de l'enfant, formations sur mesure pour institutions, ONG et entreprises, et évaluation des risques pour sécuriser vos décisions.", "Child rights, tailor-made training for institutions, NGOs and companies, and risk assessment to secure your decisions."),
         [T(lang, "Droit de l'enfant", "Child rights"), T(lang, "Cadres juridiques nationaux et internationaux", "National and international legal frameworks"), T(lang, "Sur mesure", "Tailor-made"), "Due diligence"]),
    ]
    cartes = "\n".join(
        f"""          <article class="carte"><div class="c"><h3>{e(t)}</h3><p>{e(d)}</p><div class="modules">{''.join(f'<span>{e(m)}</span>' for m in mods)}</div></div></article>"""
        for t, d, mods in programmes
    )
    jsonld = [{"@type": "Course", "name": t, "description": d, "provider": {"@id": f"{DOMAINE}/#organisation"}} for t, d, _ in programmes]
    corps = hero(p, "formation", T(lang, "Formations", "Training"),
                 T(lang, "Nos programmes de formation", "Our training programmes"),
                 T(lang, "En présentiel, à distance ou dans vos locaux, pour les institutions, les ONG et les entreprises. Une attestation est remise à chaque participant.", "On site, remote or in-house, for institutions, NGOs and companies. Each participant receives a certificate."),
                 fil=fil_ariane(lang, T(lang, "Formations", "Training"))) + f"""
    <section>
      <div class="in">
        <h2>{T(lang, "Sept programmes", "Seven programmes")}</h2>
        <div class="grille">
{cartes}
        </div>
      </div>
    </section>
    <section class="doux">
      <div class="in deux">
        <div>
          <h2>{T(lang, "Demander un devis", "Request a quote")}</h2>
          <p class="intro">{T(lang, "Indiquez le programme, le nombre de participants et le lieu souhaité. Nous vous envoyons une proposition écrite.", "Tell us the programme, number of participants and preferred location. We will send you a written proposal.")}</p>
        </div>
{formulaire(lang, ('formations', 'Formations'), besoins=[t for t, _, _ in programmes])}
      </div>
    </section>"""
    return (
        T(lang, "Formations professionnelles à Lomé | NEXUS International", "Professional training in Lomé | NEXUS International"),
        T(lang, "Formations sur mesure pour institutions, ONG et entreprises : gouvernance, gestion financière, leadership, droit humanitaire, droit de l'enfant, protection des données, entrepreneuriat.",
          "Tailor-made training for institutions, NGOs and companies: governance, financial management, leadership, humanitarian law, child rights, data protection, entrepreneurship."),
        corps, jsonld,
    )


def page_services(lang):
    """Business Services : contenu du fichier services.html fourni par le propriétaire,
    intégré au design commun."""
    p = prefixe(lang)
    offres = [
        ("reunion", T(lang, "Accueil des délégations", "Business delegation support"),
         T(lang, "Accueil à l'aéroport, hôtel à tarif négocié, chauffeur, interprète, programme de rendez-vous et visites de sites.", "Airport welcome, hotel at negotiated rates, driver, interpreter, meeting schedule and site visits."), T(lang, "Service phare", "Flagship")),
        ("camions", T(lang, "Achat pour compte Lomé-Niamey", "Sourcing and shipping Lomé-Niamey"),
         T(lang, "Nous achetons, contrôlons et expédions vos marchandises depuis Lomé vers le Niger et le Sahel, avec photos à chaque étape.", "We buy, inspect and ship your goods from Lomé to Niger and the Sahel, with photos at every step."), ""),
        ("signature", T(lang, "Représentation de marques", "Brand representation"),
         T(lang, "Producteurs étrangers : nous plaçons vos produits auprès des distributeurs au Togo et au Niger, sans que vous ouvriez de bureau.", "Foreign producers: we place your products with distributors in Togo and Niger, without you opening an office."), ""),
        ("marche", T(lang, "Produits du Sahel", "Sahel produce"),
         T(lang, "Oignon, souchet, sésame, gomme arabique : nous mettons en relation coopératives du Niger et acheteurs de la côte.", "Onion, tiger nuts, sesame, gum arabic: we connect Niger cooperatives with coastal buyers."), ""),
    ]
    cartes = "\n".join(
        f"""          <article class="carte">{img(p, im, t)}<div class="c">{('<span class="etiquette o">' + e(badge) + '</span>') if badge else ''}<h3>{e(t)}</h3><p>{e(d)}</p></div></article>"""
        for im, t, d, badge in offres
    )
    formules = [
        (T(lang, "Essentiel", "Essential"), T(lang, "1 journée", "1 day"), T(lang, "À partir de 75 000 FCFA par jour", "From 75,000 FCFA per day"),
         [T(lang, "Accueil à l'aéroport", "Airport welcome"), T(lang, "Transfert à l'hôtel", "Hotel transfer"), T(lang, "Chauffeur et véhicule", "Driver and vehicle"), T(lang, "Assistance téléphonique", "Phone assistance"), T(lang, "Puce téléphone locale", "Local SIM card")], ""),
        (T(lang, "Affaires", "Business"), T(lang, "Séjour de 3 jours", "3-day stay"), T(lang, "À partir de 300 000 FCFA", "From 300,000 FCFA"),
         [T(lang, "Tout l'Essentiel", "Everything in Essential"), T(lang, "Réservation de l'hôtel", "Hotel booking"), T(lang, "Programme des visites", "Visit schedule"), T(lang, "Interprète si besoin", "Interpreter if needed"), T(lang, "2 à 4 rendez-vous organisés", "2 to 4 arranged meetings"), T(lang, "Dîner d'affaires", "Business dinner")], "o"),
        ("Mission", T(lang, "Sur mesure", "Tailor-made"), T(lang, "Sur devis", "On quotation"),
         [T(lang, "Tout Affaires", "Everything in Business"), T(lang, "Rendez-vous ciblés et préparés", "Targeted, prepared meetings"), T(lang, "Lettre d'invitation et visa", "Invitation letter and visa"), T(lang, "Visites du port et des sites", "Port and site visits"), T(lang, "Note de synthèse après mission", "Post-mission report"), T(lang, "Suivi des contacts", "Contact follow-up")], "j"),
    ]
    cartes_formules = "\n".join(
        f"""          <article class="carte famille {c}"><div class="c"><span class="etiquette{(' ' + c) if c else ''}">{e(n)}</span><h3>{e(duree)}</h3><p><b>{e(prix)}</b></p><ul>{''.join(f'<li>{e(x)}</li>' for x in items)}</ul></div></article>"""
        for n, duree, prix, items, c in formules
    )
    jsonld = [{"@type": "Service", "name": t, "description": d, "provider": {"@id": f"{DOMAINE}/#organisation"}, "areaServed": ["Togo", "Niger"]} for _, t, d, _ in offres]
    jsonld.append({"@type": "OfferCatalog", "name": T(lang, "Formules d'accueil des délégations", "Delegation packages"),
                   "itemListElement": [{"@type": "Offer", "name": n, "description": prix, "priceCurrency": "XOF"} for n, _, prix, _, _ in formules]})
    corps = hero(p, "port", T(lang, "Lomé, porte d'entrée de l'Afrique de l'Ouest", "Lomé, gateway to West Africa"),
                 T(lang, "Votre partenaire d'affaires sur place à Lomé", "Your on-the-ground business partner in Lomé"),
                 T(lang, "Vous venez au Togo pour le port, une usine, des fournisseurs ou un investissement ? Nous organisons tout : accueil, hôtel, transport, interprète et rendez-vous ciblés. Vous vous concentrez sur vos affaires.",
                   "Coming to Togo for the port, a factory, suppliers or an investment? We handle everything: airport pickup, hotel, transport, interpreter and targeted meetings. You focus on business."),
                 f'<a class="bouton" href="https://wa.me/{WA}" rel="noopener">{T(lang, "Écrire sur WhatsApp", "Message us on WhatsApp")}</a><a class="bouton clair" href="#formules">{T(lang, "Voir nos formules", "See our packages")}</a>',
                 fil=fil_ariane(lang, "Business Services")) + f"""
    <section>
      <div class="in">
        <span class="sur">Business Services</span>
        <h2>{T(lang, "Nos services", "Our services")}</h2>
        <p class="intro">{T(lang, "Un seul interlocuteur pour vos missions, vos achats et vos échanges commerciaux entre la côte et le Sahel.", "One single point of contact for your business trips, purchases and trade between the coast and the Sahel.")}</p>
        <div class="grille">
{cartes}
        </div>
      </div>
    </section>
    <section class="doux" id="formules">
      <div class="in">
        <h2>{T(lang, "Formules d'accueil des délégations", "Delegation packages")}</h2>
        <p class="intro">{T(lang, "Des formules claires, adaptables à votre programme.", "Clear packages, tailored to your schedule.")}</p>
        <div class="grille">
{cartes_formules}
        </div>
        <p class="discret" style="margin-top:18px">{T(lang, "Hébergement facturé en plus, aux tarifs négociés avec nos hôtels partenaires.", "Accommodation billed separately, at rates negotiated with our partner hotels.")}</p>
      </div>
    </section>
    <section>
      <div class="in deux">
        <div>
          <h2>{T(lang, "Comment ça marche", "How it works")}</h2>
          <p class="intro">{T(lang, "Quatre étapes simples, de votre demande à votre retour.", "Four simple steps, from your request to your return.")}</p>
          <ol class="etapes">
            <li><b>{T(lang, "Votre demande", "Your request")}</b> : {T(lang, "dates, objet du voyage, besoins : un message suffit.", "dates, purpose, needs: one message is enough.")}</li>
            <li><b>{T(lang, "Programme et devis", "Plan and quote")}</b> : {T(lang, "nous vous envoyons un programme et un devis sous 48 heures.", "we send you a schedule and a quote within 48 hours.")}</li>
            <li><b>{T(lang, "Votre séjour", "Your stay")}</b> : {T(lang, "nous vous accompagnons du premier au dernier jour.", "we are with you from the first to the last day.")}</li>
            <li><b>{T(lang, "Le suivi", "Follow-up")}</b> : {T(lang, "nous assurons la suite de vos contacts après votre départ.", "we follow up on your contacts after you leave.")}</li>
          </ol>
        </div>
        <div>
          <h2>{T(lang, "Pourquoi nous ?", "Why us?")}</h2>
          <p class="intro">{T(lang, "Un cabinet d'affaires installé à Lomé, actif dans toute l'Afrique de l'Ouest.", "A business firm based in Lomé, active across West Africa.")}</p>
          <ul class="liste">
            <li><b>{T(lang, "Ancrés à Lomé et au Niger", "Rooted in Lomé and Niger")}</b> : {T(lang, "un pied sur la côte, un pied au Sahel, nous connaissons le corridor.", "one foot on the coast, one in the Sahel, we know the corridor.")}</li>
            <li><b>{T(lang, "Un réseau d'affaires réel", "A real business network")}</b> : {T(lang, "banques, industriels, transitaires, administrations, partenaires de confiance.", "banks, manufacturers, freight agents, public bodies and trusted partners.")}</li>
            <li><b>{T(lang, "Bilingue", "Bilingual")}</b> : {T(lang, "français et anglais, interprètes pour les autres langues.", "French and English, interpreters for other languages.")}</li>
          </ul>
        </div>
      </div>
    </section>
    <section class="doux">
      <div class="in deux">
        <div>
          <h2>{T(lang, "Vous préparez un voyage à Lomé ?", "Planning a trip to Lomé?")}</h2>
          <p class="intro">{T(lang, "Dites-nous vos dates et ce que vous venez faire. Nous revenons vers vous rapidement avec un programme.", "Tell us your dates and the purpose of your visit. We will quickly get back to you with a plan.")}</p>
          <p>{T(lang, "Besoin de financer une commande ?", "Need to fund an order?")} <a href="{lien(lang, 'arziki')}">{T(lang, "Découvrez ARZIKI", "Discover ARZIKI")}</a>.</p>
        </div>
{formulaire(lang, ('services', 'Business Services'), besoins=[t for _, t, _, _ in offres] + [T(lang, 'Autre', 'Other')], dates=True)}
      </div>
    </section>"""
    return (
        T(lang, "Business Services | Accueil d'affaires à Lomé, Lomé-Niamey", "Business Services | Business support in Lomé, Lomé-Niamey"),
        T(lang, "NEXUS International vous accueille à Lomé : délégations d'affaires, rendez-vous, hôtel, chauffeur, interprète, achat pour compte et expédition vers le Niger, produits du Sahel.",
          "NEXUS International welcomes you in Lomé: business delegations, meetings, hotel, driver, interpreter, sourcing and shipping to Niger, Sahel produce."),
        corps, jsonld,
    )


def page_arziki(lang):
    """arziki.html corrigée (mission, section 8) : centrée sur les entreprises."""
    p = prefixe(lang)
    app = adresse_app(p)
    besoins = [T(lang, "Financer une commande", "Fund an order"), T(lang, "Dossier clés en main", "Turnkey funding file"), "Business plan",
               T(lang, "États financiers", "Financial statements"), T(lang, "Formation", "Training"), T(lang, "Autre", "Other")]
    faq = [
        (T(lang, "Qu'est-ce qu'une commande financée ?", "What is a funded order?"),
         T(lang, "Vous avez une commande ferme d'un client identifié. Un partenaire achète la marchandise au fournisseur et vous la revend avec une majoration fixe, payable à une échéance convenue. Vous connaissez le prix avant de signer.",
           "You have a firm order from an identified client. A partner buys the goods from the supplier and resells them to you with a fixed mark-up, payable on an agreed due date. You know the price before signing.")),
        (T(lang, "ARZIKI avance-t-il de l'argent ?", "Does ARZIKI advance money?"),
         R8[lang] + T(lang, " ARZIKI est un intermédiaire : il vérifie, met en relation et perçoit une commission.", " ARZIKI is an intermediary: it checks, connects and earns a commission.")),
        (T(lang, "Quels documents préparer ?", "Which documents should I prepare?"),
         T(lang, "Le bon de commande ou le marché, le devis du fournisseur, le RCCM et le NIF de l'entreprise, la pièce d'identité du dirigeant et la déclaration du bénéficiaire effectif.",
           "The purchase order or contract, the supplier's quote, the company's trade register and tax numbers, the manager's ID and the beneficial owner declaration.")),
    ]
    corps = hero(p, "entrepot", "ARZIKI",
                 T(lang, "Financez vos commandes, préparez vos dossiers", "Fund your orders, prepare your files"),
                 T(lang, "Une commande ferme mais pas la trésorerie pour acheter la marchandise ? ARZIKI vérifie la commande et vous met en relation avec un partenaire qui achète pour vous. Et nos experts préparent vos dossiers.",
                   "A firm order but no cash to buy the goods? ARZIKI checks the order and connects you with a partner who buys for you. And our experts prepare your files."),
                 f'<a class="bouton" href="{app}">{T(lang, "Découvrir l\'application", "Discover the app")}</a><a class="bouton clair" href="#formulaire">{T(lang, "Faire une demande", "Make a request")}</a>',
                 fil=fil_ariane(lang, "ARZIKI")) + f"""
    <section>
      <div class="in deux">
        <div>
          <span class="sur">{T(lang, "Commande financée", "Funded order")}</span>
          <h2>{T(lang, "Comment ça marche", "How it works")}</h2>
          <ol class="etapes">
            <li>{T(lang, "Vous soumettez votre commande ferme, le devis du fournisseur et les garanties que vous proposez.", "You submit your firm order, the supplier's quote and the guarantees you offer.")}</li>
            <li>{T(lang, "ARZIKI vérifie votre client, le fournisseur et les prix.", "ARZIKI checks your client, the supplier and the prices.")}</li>
            <li>{T(lang, "Un partenaire achète la marchandise et vous la revend à terme, à un prix fixé par écrit.", "A partner buys the goods and resells them to you on deferred terms, at a price fixed in writing.")}</li>
            <li>{T(lang, "Les contrats et les garanties sont passés devant notaire. Le fournisseur est payé directement.", "Contracts and guarantees are signed before a notary. The supplier is paid directly.")}</li>
            <li>{T(lang, "Vous livrez votre client et vous réglez à l'échéance.", "You deliver your client and pay on the due date.")}</li>
          </ol>
          <p class="discret">{T(lang, "Pour les PME comme pour les grandes entreprises, avec un réseau de fournisseurs qui acceptent aussi le paiement différé. Togo, Niger, Bénin.", "For SMEs and large companies alike, with a network of suppliers who also accept deferred payment. Togo, Niger, Benin.")}</p>
        </div>
        <div class="photo">{img(p, 'chantier', T(lang, 'Livraison de matériaux sur un chantier', 'Building materials delivered to a site'))}</div>
      </div>
    </section>
    <section class="doux">
      <div class="in">
        <span class="sur">{T(lang, "Services aux entreprises", "Business services")}</span>
        <h2>{T(lang, "Vos dossiers préparés par des experts", "Your files prepared by experts")}</h2>
        <div class="grille">
          <article class="carte"><div class="c"><h3>{T(lang, "Dossier clés en main", "Turnkey funding file")}</h3><p>{T(lang, "Un dossier de financement complet, à présenter tel quel à une banque, un arrangeur ou une société de leasing.", "A complete funding file, to present as it is to a bank, an arranger or a leasing company.")}</p></div></article>
          <article class="carte"><div class="c"><h3>Business plan</h3><p>{T(lang, "Projections, rentabilité et stratégie, au format attendu par les financeurs.", "Projections, profitability and strategy, in the format funders expect.")}</p></div></article>
          <article class="carte"><div class="c"><h3>{T(lang, "États financiers", "Financial statements")}</h3><p>{T(lang, "Mise en forme et analyse de vos comptes (SYSCOHADA) pour rassurer les partenaires ; états certifiés avec un expert-comptable agréé partenaire.", "Structuring and analysis of your accounts (SYSCOHADA) to reassure partners; certified statements with an approved partner accountant.")}</p></div></article>
          <article class="carte"><div class="c"><h3>{T(lang, "Formation et recherche d'arrangeurs", "Training and arranger search")}</h3><p>{T(lang, "Gestion financière et préparation au financement pour vos équipes ; recherche de l'arrangeur adapté à un grand projet.", "Financial management and funding readiness for your teams; finding the right arranger for a large project.")}</p></div></article>
        </div>
      </div>
    </section>
    <section>
      <div class="in">
        <span class="sur">{T(lang, "Confiance", "Trust")}</span>
        <h2>{T(lang, "Un cadre clair", "A clear framework")}</h2>
        <div class="grille">
          <article class="carte"><div class="c"><h3>{T(lang, "Contrats passés devant notaire", "Contracts signed before a notary")}</h3><p>{T(lang, "Vente à terme et garanties sont signées devant notaire. L'argent ne passe jamais par l'application.", "Deferred sale and guarantees are signed before a notary. Money never goes through the app.")}</p></div></article>
          <article class="carte"><div class="c"><h3>{T(lang, "Garanties adaptées au montant", "Guarantees suited to the amount")}</h3><p>{T(lang, "Réserve de propriété, nantissement de créance, cautionnement, hypothèque, selon le montant.", "Retention of title, pledge of receivables, surety, mortgage, depending on the amount.")}</p></div></article>
          <article class="carte"><div class="c"><h3>{T(lang, "Expertise reconnue", "Recognised expertise")}</h3><p>{T(lang, "Une équipe qui a accompagné des financements validés de 30 M USD et de 160 M USD.", "A team that has supported approved funding of USD 30 M and USD 160 M.")}</p></div></article>
        </div>
      </div>
    </section>
    <section class="doux">
      <div class="in">
        <h2>{T(lang, "Questions fréquentes", "Frequently asked questions")}</h2>
{faq_html(faq)}
      </div>
    </section>
    <section>
      <div class="in deux">
        <div>
          <h2>{T(lang, "Faire une demande", "Make a request")}</h2>
          <p class="intro">{T(lang, "Dites-nous ce dont vous avez besoin. Nous vous répondons rapidement.", "Tell us what you need. We will reply quickly.")}</p>
          <div class="actions"><a class="bouton vert" href="{app}">{T(lang, "Ouvrir l'application ARZIKI", "Open the ARZIKI app")}</a></div>
          <p class="avertissement" style="margin-top:24px">{e(R8[lang])}</p>
        </div>
{formulaire(lang, ('arziki', 'ARZIKI'), besoins=besoins)}
      </div>
    </section>
    <section class="doux">
      <div class="in">
        <p class="discret"><a href="{app}">{T(lang, "Espace partenaires financiers (sur invitation)", "Financial partners area (by invitation)")}</a></p>
      </div>
    </section>"""
    return (
        T(lang, "ARZIKI | Financer une commande ferme au Togo", "ARZIKI | Fund a firm order in Togo"),
        T(lang, "Une commande ferme sans trésorerie ? ARZIKI vous met en relation avec un partenaire qui achète pour vous, contrats passés devant notaire. Dossiers, business plans, états financiers.",
          "A firm order but no cash? ARZIKI checks the order and connects you with a partner who buys for you, with contracts signed before a notary. Turnkey files, business plans, financial statements."),
        corps, [faq_jsonld(faq), {"@type": "Service", "name": "ARZIKI", "description": T(lang, "Commande financée et services aux entreprises", "Funded orders and business services"), "provider": {"@id": f"{DOMAINE}/#organisation"}, "areaServed": "Togo"}],
    )


def page_desk(lang):
    p = prefixe(lang)
    t = lambda fr, en, ar: T(lang, fr, en, ar)
    pays = [t("Algérie", "Algeria", "الجزائر"), t("Niger", "Niger", "النيجر"), t("Autre", "Other", "بلد آخر")]
    corps = hero(p, "convoi", t("Desk Algérie-Niger", "Algeria-Niger Desk", "مكتب الجزائر - النيجر"),
                 t("Un pont d'affaires entre l'Algérie, le Niger et la côte ouest-africaine",
                   "A business bridge between Algeria, Niger and the West African coast",
                   "جسر أعمال بين الجزائر والنيجر وساحل غرب أفريقيا"),
                 t("NEXUS International, intermédiaire de confiance entre l'Algérie et le Niger, dans les deux sens, avec un prolongement vers les ports de Lomé et de Cotonou.",
                   "NEXUS International, a trusted intermediary between Algeria and Niger, in both directions, extended to the ports of Lomé and Cotonou.",
                   "نيكسوس إنترناشونال، وسيط موثوق بين الجزائر والنيجر في الاتجاهين، مع امتداد نحو ميناءي لومي وكوتونو."),
                 f'<a class="bouton" href="#formulaire">{t("Déposer une demande", "Send a request", "تقديم طلب")}</a>',
                 fil=fil_ariane(lang, t("Desk Algérie-Niger", "Algeria-Niger Desk", "مكتب الجزائر - النيجر"))) + f"""
    <section>
      <div class="in">
        <div class="grille">
          <article class="carte famille">
            <div class="c">
              <span class="sur">{t("Pour les entreprises algériennes", "For Algerian companies", "للمؤسسات الجزائرية")}</span>
              <h2>{t("Réussir au Niger", "Succeeding in Niger", "النجاح في النيجر")}</h2>
              <ul>
                <li>{t("Informations sur le marché nigérien", "Information on the Nigerien market", "معلومات عن السوق النيجرية")}</li>
                <li>{t("Installation au Niger", "Setting up in Niger", "الاستقرار في النيجر")}</li>
                <li>{t("Vérification de partenaires et d'entreprises", "Checking partners and companies", "التحقق من الشركاء والمؤسسات")}</li>
                <li>{t("Mise en relation avec des distributeurs", "Introductions to distributors", "ربط العلاقات مع الموزعين")}</li>
                <li>{t("Accompagnement sur place", "On-the-ground support", "المرافقة في عين المكان")}</li>
                <li>{t("Canaux de distribution vers Lomé et Cotonou, par conteneurs", "Distribution channels to Lomé and Cotonou, by container", "قنوات توزيع نحو لومي وكوتونو عبر الحاويات")}</li>
              </ul>
            </div>
          </article>
          <article class="carte famille o">
            <div class="c">
              <span class="sur">{t("Pour les opérateurs nigériens", "For Nigerien businesses", "للمتعاملين النيجريين")}</span>
              <h2>{t("Acheter en Algérie", "Buying from Algeria", "الشراء من الجزائر")}</h2>
              <ul>
                <li>{t("Recherche de produits algériens, agroalimentaire notamment", "Sourcing Algerian products, especially food", "البحث عن منتجات جزائرية، لا سيما الغذائية")}</li>
                <li>{t("Mise en relation avec des fabricants", "Introductions to manufacturers", "ربط العلاقات مع المصنعين")}</li>
                <li>{t("Accompagnement dans les démarches", "Help with procedures", "المرافقة في الإجراءات")}</li>
              </ul>
            </div>
          </article>
        </div>
      </div>
    </section>
    <section class="doux">
      <div class="in deux">
        <div>
          <h2>{t("Notre ancrage", "Our roots", "حضورنا")}</h2>
          <ul class="liste">
            <li>{t("Un réseau à Niamey, Tahoua et Agadez : transporteurs et opérateurs du commerce transfrontalier", "A network in Niamey, Tahoua and Agadez: hauliers and cross-border traders", "شبكة في نيامي وتاهوا وأغاديس: ناقلون ومتعاملون في التجارة العابرة للحدود")}</li>
            <li>{t("Une connaissance de l'Algérie, où notre dirigeant a fait ses études", "Knowledge of Algeria, where our managing director studied", "معرفة بالجزائر، حيث درس مديرنا")}</li>
            <li>{t("Un bureau à Lomé, à côté du port", "An office in Lomé, near the port", "مكتب في لومي، قرب الميناء")}</li>
            <li>{t("Deux langues de travail : arabe et français", "Two working languages: Arabic and French", "لغتا عمل: العربية والفرنسية")}</li>
          </ul>
        </div>
        <div class="photo">{img(p, 'port', t('Port de Lomé', 'Port of Lomé', 'ميناء لومي'))}</div>
      </div>
    </section>
    <section>
      <div class="in">
        <h2>{t("Comment ça marche", "How it works", "كيف نعمل")}</h2>
        <ol class="etapes">
          <li>{t("Vous déposez votre demande", "You send your request", "تقدمون طلبكم")}</li>
          <li>{t("Nous l'analysons et vous proposons une offre écrite", "We analyse it and send a written offer", "ندرسه ونرسل لكم عرضا مكتوبا")}</li>
          <li>{t("Nous vous mettons en relation avec les bons interlocuteurs", "We connect you with the right people", "نربطكم بالمحاورين المناسبين")}</li>
          <li>{t("Nous vous accompagnons jusqu'à la conclusion", "We support you until the deal is done", "نرافقكم حتى إبرام الاتفاق")}</li>
        </ol>
      </div>
    </section>
    <section class="doux">
      <div class="in deux">
        <div>
          <h2>{t("Déposer une demande", "Send a request", "تقديم طلب")}</h2>
          <p class="intro">{t("Décrivez votre projet en quelques lignes. Nous vous répondons en arabe ou en français.", "Describe your project in a few lines. We reply in Arabic or French.", "صفوا مشروعكم في بضعة أسطر. نرد عليكم بالعربية أو بالفرنسية.")}</p>
          <p class="discret">{t("Initiative privée de NEXUS International. Ce site n'est pas un site officiel des gouvernements algérien ou nigérien.", "A private initiative of NEXUS International. This is not an official website of the Algerian or Nigerien governments.", "مبادرة خاصة من نيكسوس إنترناشونال. هذا الموقع ليس موقعا رسميا للحكومة الجزائرية ولا للحكومة النيجرية.")}</p>
        </div>
{formulaire(lang, ('desk', 'Desk Algérie-Niger'), pays=pays)}
      </div>
    </section>"""
    return (
        t("Desk Algérie-Niger | Affaires Algérie, Niger, Lomé, Cotonou",
          "Algeria-Niger Desk | Business Algeria, Niger, Lomé, Cotonou",
          "مكتب الجزائر - النيجر | الأعمال بين الجزائر والنيجر"),
        t("Entreprises algériennes au Niger, opérateurs nigériens en Algérie : information, installation, vérification de partenaires, mise en relation, distribution vers Lomé et Cotonou.",
          "Algerian companies in Niger, Nigerien businesses sourcing in Algeria: information, set-up, partner checks, introductions, distribution to Lomé and Cotonou.",
          "المؤسسات الجزائرية في النيجر والمتعاملون النيجريون في الجزائر: المعلومة، الاستقرار، التحقق من الشركاء، ربط العلاقات، التوزيع نحو لومي وكوتونو."),
        corps, [{"@type": "Service", "name": t("Desk Algérie-Niger", "Algeria-Niger Desk", "مكتب الجزائر - النيجر"), "provider": {"@id": f"{DOMAINE}/#organisation"}, "areaServed": ["Algérie", "Niger", "Togo", "Bénin"]}],
    )


def page_contact(lang):
    p = prefixe(lang)
    corps = hero(p, "poignee", T(lang, "Contact", "Contact"), T(lang, "Parlons de votre projet", "Let's talk about your project"),
                 T(lang, "Première consultation stratégique gratuite. Écrivez-nous ou appelez-nous sur WhatsApp.", "Free first strategy consultation. Write to us or call us on WhatsApp."),
                 fil=fil_ariane(lang, "Contact")) + f"""
    <section>
      <div class="in deux">
        <div>
          <h2>{T(lang, "Nos coordonnées", "Our details")}</h2>
          <ul class="liste">
            <li>WhatsApp : <a href="https://wa.me/{WA}">{WHATSAPP}</a></li>
            <li>E-mail : <a href="mailto:{EMAIL}">{EMAIL}</a></li>
            <li>{T(lang, "Copie", "Copy")} : <a href="mailto:{EMAIL_COPIE}">{EMAIL_COPIE}</a></li>
            <li>{T(lang, "Adresse", "Address")} : {e(ADRESSE)}</li>
          </ul>
        </div>
{formulaire(lang, ('contact', 'Contact'), besoins=[T(lang, 'Nos expertises', 'Our expertise'), T(lang, 'Formations', 'Training'), 'Business Services', 'ARZIKI', T(lang, 'Desk Algérie-Niger', 'Algeria-Niger Desk'), T(lang, 'Autre', 'Other')])}
      </div>
    </section>"""
    return (
        T(lang, "Contact | NEXUS International, Lomé, Togo", "Contact | NEXUS International, Lomé, Togo"),
        T(lang, "Contactez NEXUS International à Lomé : WhatsApp +228 91 97 80 80, nexusinternational25@gmail.com. Première consultation stratégique gratuite.",
          "Contact NEXUS International in Lomé: WhatsApp +228 91 97 80 80, nexusinternational25@gmail.com. Free first strategy consultation."),
        corps, [],
    )


def page_mentions(lang):
    corps = f"""    <section>
      <div class="in">
        <h1>{T(lang, "Mentions légales", "Legal notice")}</h1>
        <h2>{T(lang, "Éditeur", "Publisher")}</h2>
        <p>NEXUS International<br>RCCM {RCCM}<br>{e(ADRESSE)}<br>E-mail : {EMAIL}<br>WhatsApp : {WHATSAPP}</p>
        <h2>{T(lang, "Directeur de la publication", "Publication director")}</h2>
        <p>{T(lang, "Le CEO de NEXUS International", "The CEO of NEXUS International")}</p>
        <h2>{T(lang, "Hébergement", "Hosting")}</h2>
        <p>LWS (Ligne Web Services), Paris, France. {T(lang, "Application ARZIKI : Google Cloud (Firebase).", "ARZIKI app: Google Cloud (Firebase).")}</p>
        <h2>{T(lang, "Propriété intellectuelle", "Intellectual property")}</h2>
        <p>{T(lang, "Les marques NEXUS International et ARZIKI, les logos et les contenus de ce site appartiennent à NEXUS International.", "The NEXUS International and ARZIKI brands, logos and content of this site belong to NEXUS International.")}</p>
        <h2>{T(lang, "Données personnelles", "Personal data")}</h2>
        <p>{T(lang, "Voir la politique de confidentialité.", "See the privacy policy.")} <a href="{lien(lang, 'confidentialite')}">{T(lang, "Politique de confidentialité", "Privacy policy")}</a></p>
      </div>
    </section>"""
    return (T(lang, "Mentions légales | NEXUS International", "Legal notice | NEXUS International"),
            T(lang, "Mentions légales du site amanexus.com : éditeur, hébergement, propriété intellectuelle.", "Legal notice of amanexus.com: publisher, hosting, intellectual property."), corps, [])


def page_confidentialite(lang):
    corps = f"""    <section>
      <div class="in">
        <h1>{T(lang, "Politique de confidentialité", "Privacy policy")}</h1>
        <p>{T(lang, "NEXUS International protège vos données personnelles conformément à la loi togolaise n° 2019-014 relative à la protection des données à caractère personnel.", "NEXUS International protects your personal data in line with Togolese law no. 2019-014 on personal data protection.")}</p>
        <h2>{T(lang, "Données collectées", "Data collected")}</h2>
        <p>{T(lang, "Par les formulaires : nom, entreprise, e-mail, téléphone, pays, votre besoin et votre message. Aucun traceur publicitaire n'est utilisé sur ce site.", "Through the forms: name, company, e-mail, phone, country, your need and your message. No advertising trackers are used on this site.")}</p>
        <h2>{T(lang, "Utilisation", "Use")}</h2>
        <p>{T(lang, "Uniquement pour répondre à votre demande et vous adresser une offre. Vos données ne sont ni vendues ni louées.", "Only to reply to your request and send you an offer. Your data is never sold or rented.")}</p>
        <h2>{T(lang, "Destinataires et conservation", "Recipients and retention")}</h2>
        <p>{T(lang, "Les messages sont reçus par l'équipe NEXUS International (nexusinternational25@gmail.com et operation@amanexus.com) et conservés trois ans après le dernier échange.", "Messages are received by the NEXUS International team (nexusinternational25@gmail.com and operation@amanexus.com) and kept for three years after the last exchange.")}</p>
        <h2>{T(lang, "Vos droits", "Your rights")}</h2>
        <p>{T(lang, "Vous pouvez demander l'accès, la rectification ou la suppression de vos données en écrivant à nexusinternational25@gmail.com. Vous pouvez aussi saisir l'Instance de protection des données à caractère personnel (IPDCP).", "You may request access to, correction or deletion of your data by writing to nexusinternational25@gmail.com. You may also contact the Togolese data protection authority (IPDCP).")}</p>
      </div>
    </section>"""
    return (T(lang, "Politique de confidentialité | NEXUS International", "Privacy policy | NEXUS International"),
            T(lang, "Comment NEXUS International utilise et protège les données envoyées par les formulaires du site.", "How NEXUS International uses and protects data sent through the site's forms."), corps, [])


CONSTRUCTEURS = {
    "accueil": page_accueil,
    "expertises": page_expertises,
    "formations": page_formations,
    "services": page_services,
    "arziki": page_arziki,
    "desk": page_desk,
    "contact": page_contact,
    "mentions": page_mentions,
    "confidentialite": page_confidentialite,
}


# ---------------------------------------------------------------------------
# Fichiers techniques
# ---------------------------------------------------------------------------

def sitemap():
    lignes = ['<?xml version="1.0" encoding="UTF-8"?>',
              '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">']
    for id_, (_, langues) in PAGES.items():
        priorite = "1.0" if id_ == "accueil" else ("0.3" if id_ in ("mentions", "confidentialite") else "0.8")
        for l in langues:
            lignes.append("  <url>")
            lignes.append(f"    <loc>{url(id_, l)}</loc>")
            for l2 in langues:
                lignes.append(f'    <xhtml:link rel="alternate" hreflang="{l2}" href="{url(id_, l2)}"/>')
            lignes.append(f'    <xhtml:link rel="alternate" hreflang="x-default" href="{url(id_, "fr")}"/>')
            lignes.append(f"    <priority>{priorite}</priority>")
            lignes.append("  </url>")
    lignes.append("</urlset>")
    return "\n".join(lignes) + "\n"


ROBOTS = f"""# amanexus.com : tout est ouvert aux moteurs de recherche, sauf l'application web ARZIKI.
User-agent: *
Allow: /
Disallow: /{APP}
Disallow: /contact.php

Sitemap: {DOMAINE}/sitemap.xml
"""

HTACCESS = f"""# Site NEXUS International (hébergement LWS).
# Directives simples, compatibles avec l'hébergement mutualisé LWS.

# 1. HTTPS obligatoire, et adresse avec « www » (une seule adresse pour Google).
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteCond %{{HTTPS}} off
RewriteRule ^ https://%{{HTTP_HOST}}%{{REQUEST_URI}} [L,R=301]
RewriteCond %{{HTTP_HOST}} ^amanexus\\.com$ [NC]
RewriteRule ^ https://www.amanexus.com%{{REQUEST_URI}} [L,R=301]
# 2. Anciennes adresses du site React vers les nouvelles pages.
RewriteRule ^about/?$ /index.html [L,R=301]
RewriteRule ^sectors/?$ /expertises.html [L,R=301]
RewriteRule ^training/?$ /formations.html [L,R=301]
RewriteRule ^testimonials/?$ /index.html [L,R=301]
RewriteRule ^contact/?$ /contact.html [L,R=301]
# 3. Application web ARZIKI : toute adresse inconnue renvoie vers son index.html.
RewriteCond %{{REQUEST_URI}} ^/{APP}
RewriteCond %{{REQUEST_FILENAME}} !-f
RewriteCond %{{REQUEST_FILENAME}} !-d
RewriteRule ^ /{APP}index.html [L]
</IfModule>

ErrorDocument 404 /404.html
AddDefaultCharset UTF-8
AddType image/webp .webp
AddType application/wasm .wasm

# 4. Cache des fichiers statiques (images, styles, scripts, polices).
<IfModule mod_expires.c>
ExpiresActive On
ExpiresByType image/webp "access plus 1 year"
ExpiresByType image/png "access plus 1 year"
ExpiresByType image/jpeg "access plus 1 year"
ExpiresByType text/css "access plus 1 month"
ExpiresByType application/javascript "access plus 1 month"
ExpiresByType text/html "access plus 10 minutes"
</IfModule>
<IfModule mod_deflate.c>
AddOutputFilterByType DEFLATE text/html text/css application/javascript application/json image/svg+xml application/xml text/xml
</IfModule>

# 5. Sécurité de base.
<IfModule mod_headers.c>
Header always set X-Content-Type-Options "nosniff"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
Header always set X-Frame-Options "SAMEORIGIN"
</IfModule>
"""


def page_404():
    return gabarit("accueil", "fr", "Page introuvable | NEXUS International",
                   "Cette page n'existe pas ou a été déplacée.",
                   f"""    <section>
      <div class="in">
        <h1>Page introuvable</h1>
        <p class="intro">Cette page n'existe pas ou a été déplacée.</p>
        <div class="actions"><a class="bouton" href="/">Retour à l'accueil</a><a class="bouton contour" href="/contact.html">Nous contacter</a></div>
      </div>
    </section>""", noindex=True).replace('href="style.css"', 'href="/style.css"').replace('src="site.js"', 'src="/site.js"').replace('src="images/', 'src="/images/').replace('href="favicon.png"', 'href="/favicon.png"')


def construire():
    if SORTIE.exists():
        for f in SORTIE.iterdir():
            if f.name == APP.split("/")[0]:
                continue  # l'application web ARZIKI est construite à part
            if f.is_dir():
                shutil.rmtree(f)
            else:
                f.unlink()
    SORTIE.mkdir(exist_ok=True)
    preparer_images()
    for id_, (fichier, langues) in PAGES.items():
        for lang in langues:
            titre, description, corps, jsonld = CONSTRUCTEURS[id_](lang)
            dossier = SORTIE if lang == "fr" else SORTIE / lang
            dossier.mkdir(exist_ok=True)
            (dossier / fichier).write_text(gabarit(id_, lang, titre, description, corps, jsonld), encoding="utf-8")
    (SORTIE / "404.html").write_text(page_404(), encoding="utf-8")
    (SORTIE / "sitemap.xml").write_text(sitemap(), encoding="utf-8")
    (SORTIE / "robots.txt").write_text(ROBOTS, encoding="utf-8")
    (SORTIE / ".htaccess").write_text(HTACCESS, encoding="utf-8")
    for f in ("style.css", "site.js", "contact.php"):
        shutil.copy(SOURCE / f, SORTIE / f)
    print(f"Site construit dans {SORTIE}")


if __name__ == "__main__":
    construire()
